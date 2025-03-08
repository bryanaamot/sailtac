//
//  EventQueueManager.swift
//  sail-tac
//
//  Created by Bryan Aamot on 1/12/25.
//

import Foundation

// define event type as a generic
protocol EventTypeProtocol: Hashable {}

struct Event<T: EventTypeProtocol>: Hashable {
    let type: T
    let payload: AnyHashable
}

/// Manages a queue of events, ensuring events of the same type are not duplicated.
///
/// Processes the queue at a specified update rate by invoking a provided event handler.
///
/// Timer is lazy initialized and stopped when no longer needed.
/// Events are delayed by the specified timer interval if no events are in the queue.
/// Generics are used for the EventType so this class is reusable.
class EventQueueManager<T: EventTypeProtocol> {
    private var updateRate: Double
    private var eventQueue: Set<Event<T>> = []
    private let handleEvent: (Event<T>) -> Void

    private let queue = DispatchQueue.main
    private let lock = NSLock()
    private let queueSize: (Int) -> Void
    private var timer: Timer?
    
    /// Initializes a new `EventQueueManager`.
    /// - Parameters:
    ///   - updateRate: The interval, in seconds, at which the queue should be processed.
    ///   - handleEvent: A closure that processes an event.
    init(updateRate: Double, queueSize: @escaping (Int) -> Void, handleEvent: @escaping (Event<T>) -> Void) {
        self.updateRate = updateRate
        self.queueSize = queueSize
        self.handleEvent = handleEvent
    }
    
    /// Adds an event to the queue if an event of the same type does not already exist.
    /// Starts the timer to process the queue if it is not already running.
    /// - Parameter event: The event to add to the queue.
    func addEvent(_ event: Event<T>) {
        // provide thread safe access to th queue
        queue.async { [weak self] in
            guard let self = self else { return }

            // Start lazy timer
            if timer == nil || !timer!.isValid {
                // Note: scheduledTimer relies relies on the main queue's run loop to function properly
                // This will not fire if the queue is not DisplatchQueue.main
                timer = Timer.scheduledTimer(withTimeInterval: updateRate, repeats: true) { _ in
                    self.processQueue()
                    
                    // Kill the timer if we don't need it anymore
                    if self.eventQueue.isEmpty  {
                        self.timer?.invalidate()
                        self.timer = nil
                    }
                }
            }

            // Check if an event of the same type already exists
            lock.lock()
            if let existingEvent = self.eventQueue.first(where: { $0.type == event.type }) {
                self.eventQueue.remove(existingEvent) // Remove the existing event
            }
            self.eventQueue.insert(event)
            DispatchQueue.main.async {
                self.queueSize(self.eventQueue.count)
            }
            lock.unlock()
        }
    }
    
    // Process the queue (to be called by the global timer)
    private func processQueue() {
        var eventsToProcess: [Event<T>] = []
        
        // Safely access and clear the queue
        lock.lock()
        eventsToProcess = Array(eventQueue)
        eventQueue.removeAll()
        lock.unlock()
        DispatchQueue.main.async {
            self.queueSize(self.eventQueue.count)
        }
        
        // Handle each event
        for event in eventsToProcess {
            handleEvent(event)
        }
    }
}

