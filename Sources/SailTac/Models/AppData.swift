//
//  AppData.swift
//  sail-tac
//
//  Created by Bryan Aamot on 12/16/24.
//


import SwiftUI

let useLocalServer = true

#if !SKIP
let iPad = UIDevice.current.userInterfaceIdiom == .pad
#else
let iPad = false // UIDevice.current.userInterfaceIdiom == .pad
#endif

// see: https://developer.android.com/studio/run/emulator-networking
#if !SKIP
let endPoint =  useLocalServer ? "http://localhost:8080" : "https://services.sailtac.com"
let websocketEndpoint = useLocalServer ? "ws://localhost:8080" : "wss://services.sailtac.com"
#else
let endPoint =  useLocalServer ? "http://10.0.2.2:8080" : "https://services.sailtac.com"
let websocketEndpoint = useLocalServer ? "ws://localhost:8080" : "wss://services.sailtac.com"
#endif

// Defines the event types handled by EventQueueManager<EventType>
enum EventType: String, EventTypeProtocol {
    case updateCourse = "UpdateCourse"
    case moveMark = "MoveMark"
    case updateMarks = "UpdateMarks"
}

struct ErrorResponse: Codable {
    let error: Bool
    let reason: String
}

struct Club: Codable, Identifiable, Hashable {
    var id: String = ""
    var name: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var city: String = ""
    var country: String = ""
    var year_established: Int = 0
    var last_modified: Date?
}

struct Course: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var wind: Double
    var clubID: String
    var marks: [Mark]
    var lastModified: Date
}

struct Mark: Codable, Identifiable, Hashable {
    var id: String = ""
    var type: MarkType = .fixed
    var name: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var parent: String = ""
}

enum MarkType: String, Codable, Identifiable, CaseIterable {
    case fixed = "fixed"
    case relative = "relative"

    var id: String { self.rawValue }

    var localizedName: String {
        switch self {
        case .fixed:
            return "Fixed Mark"
        case .relative:
            return "Relative Mark"
        }
    }

    var description: String {
        switch self {
        case .fixed:
            return "Fixed Marks are positioned anywhere you like (examples: Committee Boat, Course Buoy)"
        case .relative:
            return "As you change the wind direction, these marks rotate around a Fixed Mark. (examples: Start Line, Weather Marks, Leeward Marks)"
        }
    }
}

struct LatLon: Codable, Hashable {
    var lat: Double
    var lon: Double
    
    static func == (lhs: LatLon, rhs: LatLon) -> Bool {
        lhs.lat == rhs.lat && lhs.lon == rhs.lon
    }
}

struct Location: Codable {
    let name: String
    var velocity: Double
    var heading: Double
    var coordinate: LatLon
}

struct MoveMarkEvent: Hashable {
    let courseID: String
    let markID: String
    let latLon: LatLon
    
    static func == (lhs: MoveMarkEvent, rhs: MoveMarkEvent) -> Bool {
        lhs.markID == rhs.markID
    }
}

struct UpdateMarksEvent: Hashable {
    let courseID: String
    let marks: [Mark]
    let wind: Double
    
    static func == (lhs: UpdateMarksEvent, rhs: UpdateMarksEvent) -> Bool {
        lhs.courseID == rhs.courseID
    }
}

enum SailingDistance: String, CaseIterable {
    case feet = "feet"
    case meters = "meters"
    case miles = "miles"
    case kilometers = "kilometers"
    case boatLength = "boats"

    var symbol: String {
        return self.rawValue
    }
    
    var unitName: String {
//        let formatter = MeasurementFormatter()
//        let name = formatter.string(from: unit)
        return self.rawValue
    }
    
    func toMeters(distance: Double) -> Double {
        switch self {
        case .feet:
            let measurement = Measurement(value: distance, unit: UnitLength.feet)
            return measurement.converted(to: UnitLength.meters).value
        case .meters:
            let measurement = Measurement(value: distance, unit: UnitLength.meters)
            return measurement.converted(to: UnitLength.meters).value
        case .miles:
            let measurement = Measurement(value: distance, unit: UnitLength.miles)
            return measurement.converted(to: UnitLength.meters).value
        case .kilometers:
            let measurement = Measurement(value: distance, unit: UnitLength.kilometers)
            return measurement.converted(to: UnitLength.meters).value
        case .boatLength:
            return distance * AppData.boatLength
        }
    }
    
    func convert(distance: Double, to unit: SailingDistance) -> Double {
        let meters = self.toMeters(distance: distance)
        let measurement1 = Measurement(value: meters, unit: UnitLength.meters)
        switch unit {
        case .feet: return measurement1.converted(to: UnitLength.feet).value
        case .meters: return meters
        case .miles: return measurement1.converted(to: UnitLength.miles).value
        case .kilometers: return measurement1.converted(to: UnitLength.kilometers).value
        case .boatLength: return meters / AppData.boatLength
        }
    }
}

class AppData: NSObject, ObservableObject {
    private static var singleton: AppData?
    @Published private(set) var signedIn = false
    @Published private(set) var userID = ""
    @Published private(set) var sessionID = ""
    @Published private(set) var firstName = ""
    @Published private(set) var lastName = ""
    @Published private(set) var selectedClubID = ""
    @Published private(set) var joinedCourses = [String]()
    @Published private(set) var clubs = [Club]()
    @Published private(set) var clubID = ""
    @Published var courses = [Course]()
    @Published var coursesLastUpdated: Date = Date()
    @Published private(set) var networkActivity = false
    @Published private(set) var locations = [String: Location]()
    @Published var heading: Double = 0.0
    @Published var location = LatLon(lat: 0.0, lon: 0.0)
    @Published var unitLength: SailingDistance {
        didSet {
            UserDefaults.standard.set(unitLength.symbol, forKey: "unitLength")
        }
    }
    @Published var unitLength2: SailingDistance {
        didSet {
            UserDefaults.standard.set(unitLength2.symbol, forKey: "unitLength2")
        }
    }
    @AppStorage("name") var name = ""
    static let boatLength = 6.0
    
    private var eventQueueManager: EventQueueManager<EventType>?
    var pingTimer: Timer?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var compassManager: CompassManager?
    
    override init() {
        let savedSymbol = UserDefaults.standard.string(forKey: "unitLength") ?? UnitLength.meters.symbol
        self.unitLength = SailingDistance(rawValue: savedSymbol) ?? .meters
        let savedSymbol2 = UserDefaults.standard.string(forKey: "unitLength2") ?? UnitLength.meters.symbol
        self.unitLength2 = SailingDistance(rawValue: savedSymbol2) ?? .meters
    }
    
    static var shared: AppData {
        if singleton == nil {
            let appData = AppData()
            singleton = appData

            appData.eventQueueManager = EventQueueManager(updateRate: 1.0, queueSize: { count in
                DispatchQueue.main.async {
                    appData.networkActivity = count > 0
                }
            }) { event in
                Task {
                    do {
                        try await appData.handleEvent(event)
                    } catch {
                        logger.error("Failed to handle event \(error)")
                    }
                }
            }
            appData.compassManager = CompassManager(
                heading: Binding(
                    get: { appData.heading },
                    set: { appData.heading = $0 }),
                latitude: Binding(
                    get: { appData.location.lat},
                    set: { appData.location.lat = $0 }),
                longitude: Binding(
                    get: { appData.location.lon },
                    set: { appData.location.lon = $0 })
            )
        }
        return singleton!
    }
}

// Timer / EventQueue
extension AppData {
    
    func handleEvent(_ event: Event<EventType>) async throws {
        switch event.type {
        case .updateCourse:
            if let course = event.payload as? Course {
                try await updateCourse(course: course)
            }
        case .moveMark:
            if let mark = event.payload as? MoveMarkEvent {
                try await moveMark(courseID: mark.courseID, markID: mark.markID, latLon: mark.latLon)
            }
        case .updateMarks:
            if let updateMarksEvent = event.payload as? UpdateMarksEvent,
               var course = courses.first(where: {$0.id == updateMarksEvent.courseID}) {
                course.marks = updateMarksEvent.marks
                course.wind = updateMarksEvent.wind
                try await updateCourse(course: course)
            }
            break
        }
    }

    func queueServerUpdate(_ event: Event<EventType>) {
        if let eventQueueManager {
            eventQueueManager.addEvent(event)
            networkActivity = true
        }
    }
}

// Login / Register
extension AppData {
    
    struct LogoutResponse: Codable {
        let error: Bool
        let reason: String?
        let message: String?
    }
    
    func logout() async throws {
        let jsonBody: [String: String] = [
            "sessionID": sessionID
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody) else {
            throw URLError(.badURL)
        }
        let url = URL(string: "\(endPoint)/logout")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let logoutResponse = try JSONDecoder().decode(LogoutResponse.self, from: data)
        switch httpResponse.statusCode {
        case 200...299:
            // Success
            await MainActor.run {
                self.signedIn = false
                self.userID = ""
                self.sessionID = ""
                self.firstName = ""
                self.lastName = ""
            }
        default:
            throw URLError(.unknown, userInfo: ["description": logoutResponse.reason ?? ""])
        }
    }
    
    struct LoginResponse: Codable {
        let error: Bool
        let userID: String
        let sessionID: String
        let firstName: String
        let lastName: String
        let message: String?
    }
    
    /// Send signin request to the server
    func login(email: String, password: String) async throws {
        // Create the request body
        let jsonBody: [String: String] = [
            "email": email,
            "password": password
        ]
        
        // Encode the JSON body
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody) else {
            throw URLError(.badURL)
        }
        
        // Configure the URLRequest
        let url = URL(string: "\(endPoint)/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Perform the network request using async/await
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check the response status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            // Success
            let response = try JSONDecoder().decode(LoginResponse.self, from: data)
            
            await MainActor.run {
                self.signedIn = true
                self.userID = response.userID
                self.sessionID = response.sessionID
                self.firstName = response.firstName
                self.lastName = response.lastName
            }
            
            // Connect to websocket service
            webSocketConnect(sessionID: sessionID, userID: userID)
            
        case 400:
            throw URLError(.badURL, userInfo: ["description": "Bad Request"])
        case 401:
            throw URLError(.userAuthenticationRequired, userInfo: ["description": "Invalid email or password"])
        case 403:
            throw URLError(.noPermissionsToReadFile, userInfo: ["description": "Forbidden"])
        case 404:
            throw URLError(.fileDoesNotExist, userInfo: ["description": "Not Found"])
        case 500...599:
            throw URLError(.badServerResponse, userInfo: ["description": "Server Error"])
        default:
            throw URLError(.unknown, userInfo: ["description": "Unknown HTTP Error"])
        }
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) async throws {
        // Create the request body
        let jsonBody: [String: String] = [
            "email": email,
            "password": password,
            "firstName": firstName,
            "lastName": lastName
        ]
        
        // Encode the JSON body
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody) else {
            throw URLError(.badURL)
        }
        
        // Configure the URLRequest
        let url = URL(string: "\(endPoint)/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Perform the network request using async/await
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            // Success
            break
        case 400:
            throw URLError(.badURL, userInfo: ["description": "Bad Request"])
        case 401:
            throw URLError(.userAuthenticationRequired, userInfo: ["description": "Invalid email or password"])
        case 403:
            throw URLError(.noPermissionsToReadFile, userInfo: ["description": "Forbidden"])
        case 404:
            throw URLError(.fileDoesNotExist, userInfo: ["description": "Not Found"])
        case 500...599:
            throw URLError(.badServerResponse, userInfo: ["description": "Server Error"])
        default:
            throw URLError(.unknown, userInfo: ["description": "Unknown HTTP Error"])
        }
    }
}

// Clubs
extension AppData {
    func getClubs() async throws {
        let request = URLRequest(url: URL(string: "\(endPoint)/clubs")!)
        let (data, _) = try await URLSession.shared.data(for: request)
        try await MainActor.run {
            clubs = try JSONDecoder().decode([Club].self, from: data)
        }
    }
    
    static func addClub(club: Club) async throws -> Club {
        guard let jsonData = try? JSONEncoder().encode(club) else {
            throw URLError(.badURL)
        }
        
        let urlString = "\(endPoint)/clubs"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Club.self, from: data)
    }
    
    static func updateClub(club: Club) async throws {
        guard let jsonData = try? JSONEncoder().encode(club) else {
            throw URLError(.badURL)
        }
        
        var urlString = "\(endPoint)/clubs"
        urlString += "/\(club.id)"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
        if errorResponse.error {
            throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: errorResponse.reason])
        }

    }
}

// Marks
extension AppData {
    
    // Adds a mark to a copy of the course and sends it to the server to be updated
    func addMark(_ mark: Mark, courseID: String) async throws {
        if var course = courses.first(where: {$0.id == courseID}) {
            course.marks.append(mark)
            try await updateCourse(course: course)
        }
    }
    
    func deleteMark(courseID: String, markID: String) async throws {
        if var course = courses.first(where: {$0.id == courseID}),
           let markIndex = course.marks.firstIndex(where: { $0.id == markID }) {
            course.marks.remove(at: markIndex)
            try await updateCourse(course: course)
        }
    }
    
    // Moves a mark in a copy of the course and sends it to the server to be updated
    func moveMark(courseID: String, markID: String, latLon: LatLon) async throws {
        if var course = courses.first(where: {$0.id == courseID}),
           let markIndex = course.marks.firstIndex(where: { $0.id == markID }) {
            // Update the latitude and longitude
            course.marks[markIndex].latitude = latLon.lat
            course.marks[markIndex].longitude = latLon.lon
            try await updateCourse(course: course)
        }
    }
    
    // Moves a mark in a copy of the course and sends it to the server to be updated
    func saveMark(courseID: String, mark: Mark) async throws {
        if var course = courses.first(where: {$0.id == courseID}),
           let markIndex = course.marks.firstIndex(where: { $0.id == mark.id }) {
            // Update the latitude and longitude
            course.marks[markIndex] = mark
            try await updateCourse(course: course)
        }
    }
    
    static func markBearing(marks: [Mark], parentId: String, wind: Double, latitude: Double, longitude: Double) -> Int {
        var normalizedBearing = 0
        if let parent = marks.first(where: { $0.id == parentId }) {
            let bearing = Bearing.bearingToLocation(lat1: parent.latitude, lon1: parent.longitude, lat2: latitude, lon2: longitude)
            normalizedBearing = Bearing.minus180To180(bearing - wind)
        }
        return normalizedBearing
    }

    static func markDistance(marks: [Mark], parentId: String, wind: Double, latitude: Double, longitude: Double) -> Double {
        var distance = 0.0
        if let parent = marks.first(where: { $0.id == parentId }) {
            distance = Bearing.distanceToLocation(lat1: parent.latitude, lon1: parent.longitude, lat2: latitude, lon2: longitude)
        }
        return distance
    }
    
    static func roundToSignificantDigits(_ number: Double, digits: Int) -> Double {
        guard number != 0.0 else { return 0.0 }
        
        let scale = pow(10, Double(digits - Int(ceil(log10(abs(number))))))
        return (number * scale).rounded() / scale
    }
}

// Courses
extension AppData {
    func getCoursesForClub(clubID: String) async throws {
        let request = URLRequest(url: URL(string: "\(endPoint)/clubs/\(clubID)/courses")!)
        let (data, _) = try await URLSession.shared.data(for: request)
        try await MainActor.run {
            self.clubID = clubID
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            courses = try decoder.decode([Course].self, from: data)
            coursesLastUpdated = Date()
        }
    }
    
    static func addCourse(course: Course) async throws -> Course {
        guard let jsonData = try? JSONEncoder().encode(course) else {
            throw URLError(.badURL)
        }
        
        let urlString = "\(endPoint)/courses"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let newCourse = try JSONDecoder().decode(Course.self, from: data)
        return newCourse
    }
    
    func deleteCourse(courseID: String) async throws {
        var request = URLRequest(url: URL(string: "\(endPoint)/courses/\(courseID)/")!)
        request.httpMethod = "DELETE"
        _ = try await URLSession.shared.data(for: request)
        try await getCoursesForClub(clubID: clubID)
    }

    
    private func updateCourse(course: Course) async throws {
        // Encode the JSON body
        guard let jsonData = try? JSONEncoder().encode(course) else {
            throw URLError(.badURL)
        }
        
        let urlString = "\(endPoint)/courses/\(course.id)"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.setValue(sessionID, forHTTPHeaderField: "Session-ID")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
        if errorResponse.error {
            throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: errorResponse.reason])
        }
        setCourse(course: course)
    }
}

// Websocket
extension AppData {
    
    func webSocketConnect(sessionID: String, userID: String) {
        let url = URL(string: "\(websocketEndpoint)/connect?sessionID=\(sessionID)&userID=\(userID)")!
        disconnect()
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        webSocketReceiveMessages() // Start listening for messages
        startPing()
    }
    
    func startPing() {
        DispatchQueue.main.async {
            self.pingTimer?.invalidate() // Cancel any existing timer
            self.pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
                self?.sendPing()
            }
        }
    }
    
    func sendPing() {
//        logger.debug("Ping ->")
        let payload: [String : Any] = [
            "cmd": "ping",
            "sessionID": sessionID
        ]
        sendCommand(payload: payload)
    }
    
    func webSocketReceiveMessages() {
        Task {
            if let task:URLSessionWebSocketTask = self.webSocketTask {
                let result = try await task.receive()
                switch result {
                case .data(let data):
                    print("Received binary message: \(data)")
                case .string(let text):
                    handleIncomingMessage(text)
                @unknown default:
                    print("unknown socket result type")
                }
                self.webSocketReceiveMessages()
            }
        }
    }

    private func sendCommand(payload: [String : Any]) {
        Task {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
                let jsonString = String(data: jsonData, encoding: .utf8)
                let message = URLSessionWebSocketTask.Message.string(jsonString ?? "")
                if let task = webSocketTask {
                    try await task.send(message)
                }
            } catch {
                print("Failed to send command: \(error)")
            }
        }
    }
    
    func webSocketJoin(courseID: String) {
        let payload: [String : Any] = [
            "cmd": "join",
            "sessionID": sessionID,
            "courseID": courseID
        ]
        sendCommand(payload: payload)
        DispatchQueue.main.async {
            if !self.joinedCourses.contains(courseID) {
                self.joinedCourses.append(courseID)
            }
        }
    }

    func webSocketLeave(courseID: String) {
        let payload: [String : Any] = [
            "cmd": "leave",
            "sessionID": sessionID,
            "courseID": courseID
        ]
        sendCommand(payload: payload)
        DispatchQueue.main.async {
            self.joinedCourses.removeAll { $0 == courseID }
        }
    }
    
    func webSocketSendLocation(velocity: Double, heading: Double, latitude: Double, longitude: Double) {
        let payload: [String : Any] = [
            "cmd": "position",
            "sessionID": sessionID,
            "name": name,
            "velocity": velocity,
            "heading": heading,
            "latitude": latitude,
            "longitude": longitude
        ]
        sendCommand(payload: payload)
    }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
    }

    fileprivate struct Command: Codable {
        let cmd: String
    }
    
    fileprivate struct PositionPayload: Codable {
        let positionID: String
        let name: String
        let velocity: Double
        let heading: Double
        let latitude: Double
        let longitude: Double
    }
    
    fileprivate struct CoursePayload: Codable {
        let course: Course
    }
    

    func handleIncomingMessage(_ text: String) {

        // Parse incoming messages (latitude/longitude JSON)
        guard let data = text.data(using: .utf8),
              let command = try? JSONDecoder().decode(Command.self, from: data) else {
            logger.error("Unknown Command")
            return
        }

        switch command.cmd {
        case "position":
            guard let payload = try? JSONDecoder().decode(PositionPayload.self, from: data) else {
                logger.debug("Invalid position parameters")
                return
            }
            logger.debug("Received location update from \(payload.name): \(payload.latitude), \(payload.longitude)")
            
            DispatchQueue.main.async {
                self.locations[payload.positionID] = Location(
                    name: payload.name,
                    velocity: payload.velocity,
                    heading: payload.heading,
                    coordinate: LatLon(lat: payload.latitude, lon: payload.longitude))
            }
        case "course":
            guard let payload = try? JSONDecoder().decode(CoursePayload.self, from: data) else {
                logger.debug("Invalid course parameters")
                return
            }
            setCourse(course: payload.course)
        
        default:
            break
        }
    }
    
    func setCourse(course: Course) {
        Task {
            if let courseIndex = courses.firstIndex(where: {$0.id == course.id}) {
                DispatchQueue.main.async {
                    self.courses[courseIndex] = course
                    self.coursesLastUpdated = Date()
                }
            }
        }
    }
}
