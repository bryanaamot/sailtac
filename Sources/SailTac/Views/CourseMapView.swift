//
//  CourseView.swift
//  sail-tac
//
//  Created by Bryan Aamot on 12/29/24.
//
import SwiftUI

enum MyMapType {
    case standard
    case satellite
    case hybrid
}


#if !SKIP
typealias ComposeView = FakeView
struct FakeView<C: View>: View {
    let c: (Int)->C
    init(@ViewBuilder c: @escaping (Int)->C) { self.c = c }
    var body: some View { c(0) }
}
#endif

struct CourseMapView: View {
//    @State var course: Course
    let courseID: String
    @State var wind: Double
    @State var marks: [Mark]

    // Local copies
    @State var lastWind = 0.0

    @EnvironmentObject private var appData: AppData
    @Environment(\.colorScheme) var colorScheme
    
    @State private var timer: Timer? = nil

    @State var mapCenterLatitude: Double
    @State var mapCenterLongitude: Double
    
    @State var showMoveDetails = false
    @State var markTapped = false
    @State var showAreYouSure = false
    @State var showEditMark = false
    @State var showBearing = false
    @State var selectedMarkIndex = 0
    @State var moveDetails = ""
    @State var showEditCourse = false
    @State var showAddMark = false
    
    @State var editWindDirection = false
    
    @State var mapType: MyMapType = .standard
    
    init(courseID: String, wind: Double, marks: [Mark], location: LatLon) {
        self.courseID = courseID
        self.wind = wind
        self.marks = marks
        if let bounds = Self.boundingBox(for: marks) {
//            logger.debug("bounds = \((bounds.maxLatitude + bounds.minLatitude) / 2.0)")
            self.mapCenterLatitude = (bounds.maxLatitude + bounds.minLatitude) / 2.0
            self.mapCenterLongitude = (bounds.maxLongitude + bounds.minLongitude) / 2.0
        } else {
            self.mapCenterLatitude = location.lat
            self.mapCenterLongitude = location.lon
        }
    }
    
    struct BoundingBox {
        let minLatitude: Double
        let maxLatitude: Double
        let minLongitude: Double
        let maxLongitude: Double
    }
    
    static func boundingBox(for marks: [Mark]) -> BoundingBox? {
        guard !marks.isEmpty else { return nil }

        let minLatitude = marks.min(by: { $0.latitude < $1.latitude })?.latitude ?? 0.0
        let maxLatitude = marks.max(by: { $0.latitude < $1.latitude })?.latitude ?? 0.0
        let minLongitude = marks.min(by: { $0.longitude < $1.longitude })?.longitude ?? 0.0
        let maxLongitude = marks.max(by: { $0.longitude < $1.longitude })?.longitude ?? 0.0

        return BoundingBox(minLatitude: minLatitude, maxLatitude: maxLatitude,
                           minLongitude: minLongitude, maxLongitude: maxLongitude)
    }
        
    // Updates the view's data for instant feedback
    // and queues the update to the server.
    func handleWindChange(modifiedWindValue: Double) {
        if lastWind != modifiedWindValue {
            // Calculate the wind change
            let change = modifiedWindValue - lastWind

            for (index, mark) in marks.enumerated() {
                guard mark.type == .relative,
                      let parentMark = marks.first(where: { $0.id == mark.parent }) else {
                    continue
                }
                
                let distance = Bearing.distanceToLocation(lat1: parentMark.latitude, lon1: parentMark.longitude, lat2: mark.latitude, lon2: mark.longitude)
                var angle = Bearing.bearingToLocation(lat1: parentMark.latitude, lon1: parentMark.longitude, lat2: mark.latitude, lon2: mark.longitude)
                angle = angle + change
                let (lat, lon) = Bearing.locationUsingBearing(lat: parentMark.latitude, lon: parentMark.longitude, distance: distance, angle: angle)
                var updatedMark = mark
                updatedMark.latitude = lat
                updatedMark.longitude = lon
                marks[index] = updatedMark
            }
            lastWind = modifiedWindValue
            let updateMarksEvent = UpdateMarksEvent(courseID: courseID, marks: marks, wind: wind)
            appData.queueServerUpdate(Event(type: EventType.updateMarks, payload: updateMarksEvent))
        }
    }
        
    func finishedDragging() {
        let updateMarksEvent = UpdateMarksEvent(courseID: courseID, marks: marks, wind: wind)
        appData.queueServerUpdate(Event(type: EventType.updateMarks, payload: updateMarksEvent))
    }
    
    var courseName: String {
        appData.courses.first(where: {$0.id == courseID})?.name ?? "Unknown Course"
    }
    
    var body: some View {
        VStack {
            Button(action: {
                showEditCourse = true
            }) {
                Text("\(courseName)")
                    .font(.headline)
            }
            ZStack {
                ComposeView { ctx in
                    MapView(
                        mapType: $mapType,
                        wind: $wind,
                        marks: $marks,
                        latitude: $mapCenterLatitude,
                        longitude: $mapCenterLongitude,
                        showEditMark: $markTapped,
                        editMarkIndex: $selectedMarkIndex,
                        showMoveDetails: $showMoveDetails,
                        moveDetails: $moveDetails,
                        finishedDragging: finishedDragging)
#if SKIP
                    .Compose(ctx)
#endif
                }
                
                // top-center
//                VStack {
//                    Text("\(mapCenterLatitude), \(mapCenterLongitude)")
//                        .font(.system(size: 12, weight: .bold))
//                        .padding(3)
//                        .background(colorScheme == .dark ? Color.black.opacity(0.7) : Color.white.opacity(0.7))
//                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
//                    Spacer()
//                }
                
                // bottom
                VStack {
                    Spacer()
                    Slider(value: $wind, in: 0...360, step: 1.0)
#if SKIP
                        .tint(.blue)
#endif
                        .padding(.horizontal, 20)
                        .opacity(editWindDirection ? 1.0 : 0.0)
                        .onChange(of: wind) { oldValue, newValue in
                            handleWindChange(modifiedWindValue: newValue)
                        }
                    HStack(alignment: .bottom, spacing: 16) {
                        //                    MapButton {
                        //                        Task {
                        //                            do {
                        //                                try await appData.getCoursesForClub(clubID: appData.clubID)
                        //                            } catch {
                        //                                logger.error("Failed to get courses for club: \(error)")
                        //                            }
                        //                        }
                        //                    } content: {
                        //                        Text("Reload")
                        //                    }
                        
                        if !appData.joinedCourses.contains(courseID) {
                            MapButton(action: {
                                appData.webSocketJoin(courseID: courseID)
                                startSendingLocation()
                                // also reset the map location
                                mapCenterLatitude = appData.location.lat
                                mapCenterLongitude = appData.location.lon
                            }) {
                                Text("Share Location")
                            }
                        } else {
                            MapButton(action: {
                                appData.webSocketLeave(courseID: courseID)
                                stopSendingLocation()
                            }) {
                                Text("Stop Sharing")
                            }
                        }
                        MapButton(action: {
                            withAnimation {
                                editWindDirection = !editWindDirection
                            }
                        }) {
                            Text("\(Int(wind))º")
                        }
                        MapButton(action: {
                            showAddMark = true
                        }) {
                            Text("Add Mark")
                        }
                        
                    }
                    .padding(.vertical)
                }
                .padding(4)
                
                if showMoveDetails {
                    VStack {
                        Text(moveDetails)
                            .font(.system(size: 30))
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(colorScheme == .dark ? Color.black.opacity(0.75) : Color.white.opacity(0.75))
                            .cornerRadius(20)
                            .padding(24)
                        Spacer()
                    }
                }
                if showBearing {
                    BearingView(showBearing: $showBearing, marks: $marks, selectedMarkIndex: $selectedMarkIndex)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if appData.networkActivity {
                            ProgressView()
#if !SKIP
                                .progressViewStyle(CircularProgressViewStyle())
#endif
                        }
                        
                        Picker("Select Map Type", selection: $mapType) {
                            Text("Standard").tag(MyMapType.standard)
                            Text("Satellite").tag(MyMapType.satellite)
                            Text("Hybrid").tag(MyMapType.hybrid)
                        }
                        .pickerStyle(.menu)
                        
//                        Button(action: {
//                            showAddMark = true
//                        }) {
//                            Image(systemName: "plus")
//                                .font(.title2)
//                        }
                    }
                }
            }
            .alert("Mark Options", isPresented: $markTapped) {
                Button("Edit") {
                    showEditMark = true
                }
                Button("Bearing") {
                    showBearing = true
                }
                Button("Delete", role: .destructive) {
                    showAreYouSure = true
                }
                Button("Cancel", role: .cancel) {
                    markTapped = false // Note: not sure if this is needed or not
                }
            } message: {
                Text("Would you like to edit the mark or see the mark bearing?")
            }
            .alert("Are you sure?", isPresented: $showAreYouSure) {
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            let mark = marks[selectedMarkIndex]
                            try await appData.deleteMark(courseID: courseID, markID: mark.id)
                        } catch {
                            
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    showAreYouSure = false // Note: not sure if this is needed or not
                }

            }
            .sheet(isPresented: $showEditMark) {
                MarkEditView(showEditMark: $showEditMark, courseID: courseID, marks: $marks, markIndex: $selectedMarkIndex, wind: wind)
            }
            .sheet(isPresented: $showAddMark) {
                MarkAddView(showAddMark: $showAddMark, courseID: courseID, wind: wind, marks: $marks, mapCenterLatitude:
                                $mapCenterLatitude, mapCenterLongitude: $mapCenterLongitude)
            }
            .sheet(isPresented: $showEditCourse) {
                if let course = appData.courses.first(where: {$0.id == courseID}) {
                    CourseEditView(course: course)
                }
            }
            .onAppear {
                lastWind = wind
                if abs(mapCenterLatitude) < 1.0E-10, abs(mapCenterLongitude) < 1.0E-10 {
                    mapCenterLatitude = appData.location.lat
                    mapCenterLongitude = appData.location.lon
                }
            }
            .onChange(of: appData.coursesLastUpdated) {
                if let course = appData.courses.first(where: { $0.id == courseID }) {
                    logger.debug("*** Received Course Update ***")
                    // TODO: Prompt user to see if they want to receive the course update
                    self.marks = course.marks
                    self.wind = course.wind
                    lastWind = wind
                }
            }
            .onChange(of: appData.location) { oldLocation, newLocation in
                let isSharing = appData.joinedCourses.contains(courseID)
                if isSharing {
                    mapCenterLatitude = appData.location.lat
                    mapCenterLongitude = appData.location.lon
                }
            }
        }
    }
    
    private func startSendingLocation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            sendLocation()
        }
    }
    
    private func stopSendingLocation() {
        timer?.invalidate()
        timer = nil
    }
    
    func sendLocation() {
        appData.webSocketSendLocation(velocity: 0.0, heading: appData.heading, latitude: appData.location.lat, longitude: appData.location.lon)
//        updatePosition()
    }
    
//    func updatePosition() {
//        // Convert velocity from knots to meters per second
//        let speedMetersPerSecond = userVelocity * knotsToMetersPerSecond
//        
//        // Convert heading to radians
//        let headingRadians = userHeading * .pi / 180
//        
//        // Calculate the distance traveled in one second
//        let distance = speedMetersPerSecond
//        
//        // Calculate the change in latitude and longitude
//        let deltaLatitude = distance * cos(headingRadians) / earthRadiusMeters * (180 / Double.pi)
//        let deltaLongitude = distance * sin(headingRadians) / (earthRadiusMeters * cos(userLatitude * Double.pi / 180)) * (180 / Double.pi)
//        
//        // Update latitude and longitude
//        userLatitude += deltaLatitude
//        userLongitude += deltaLongitude
//        
//        // Update heading
//        userHeading += 2.0
//    }
}



