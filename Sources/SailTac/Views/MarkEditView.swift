//
//  MarkEditView.swift
//  sail-tac
//
//  Created by Bryan Aamot on 1/25/25.
//

import SwiftUI

struct MarkEditView: View {
    @Binding var showEditMark: Bool
    let courseID: String
    @Binding var marks: [Mark]
    @Binding var markIndex: Int
    let wind: Double
    
    @State var mark = Mark()
    @State var forwardDistance = 0.0
    @State var portDistance = 0.0

    @EnvironmentObject private var appData: AppData

    var body: some View {
        VStack {
            if markIndex >= 0, markIndex < marks.count {
                DismissButton()
                Spacer()
                HStack {
                    Text("Name")
                    StyledTextField(title: "Name", text: $mark.name)
                }
                if mark.type == .relative {
                    HStack {
                        Text("Forward Distance")
                        StyledDoubleField(title: "", value: $forwardDistance)
                            .frame(width: 150)
                        Picker("Units", selection: $appData.unitLength) {
                            ForEach(SailingDistance.allCases, id: \.self) { unit in
                                Text(unit.unitName).tag(unit)
                            }
                        }
                        .onChange(of: appData.unitLength) { oldUnits, newUnits in
                            forwardDistance = oldUnits.convert(distance: forwardDistance, to: newUnits)
                            forwardDistance = AppData.roundToSignificantDigits(forwardDistance, digits: 4)
                        }
                    }
                    
                    HStack {
                        Text("Port Distance")
                        StyledDoubleField(title: "", value: $portDistance)
                            .frame(width: 150)
                        Picker("Units", selection: $appData.unitLength2) {
                            ForEach(SailingDistance.allCases, id: \.self) { unit in
                                Text(unit.unitName).tag(unit)
                            }
                        }
                        .onChange(of: appData.unitLength2) { oldUnits, newUnits in
                            portDistance = oldUnits.convert(distance: portDistance, to: newUnits)
                            portDistance = AppData.roundToSignificantDigits(portDistance, digits: 4)
                        }
                    }
                } else {
                    HStack {
                        Text("Latitude")
                        StyledDoubleField(title: "Latitude", value: $mark.latitude)
                    }
                    HStack {
                        Text("Longitude")
                        StyledDoubleField(title: "Longitude", value: $mark.longitude)
                    }
                }
            }
            
            HStack {
                Spacer()
//                Button("Delete") {
//                    if markIndex >= 0, markIndex < marks.count {
//                        Task {
//                            do {
//                                try await appData.deleteMark(courseID: courseID, markID: mark.id)
//                                showEditMark = false
//                            } catch {
//                                // TODO: show error
//                            }
//                        }
//                    }
//                }
//                .buttonStyle(.borderedProminent)
//                .tint(.red)
//                Spacer()
                
                Button("Cancel") {
                    showEditMark = false
                }
                .buttonStyle(.bordered)
                Spacer()
                
                Button("Save") {
                    if markIndex >= 0, markIndex < marks.count {
                        Task {
                            do {
                                if mark.type == .relative,
                                   let parent = marks.first(where: { $0.id == mark.parent }) {
                                    let forwardDistanceMeters = appData.unitLength.toMeters(distance: forwardDistance)
                                    let (lat1, lon1) = Bearing.locationUsingBearing(lat: parent.latitude, lon: parent.longitude, distance: forwardDistanceMeters, angle: wind)
                                    let portDistanceMeters = appData.unitLength2.toMeters(distance: portDistance)
                                    let (lat2, lon2) = Bearing.locationUsingBearing(lat: lat1, lon: lon1, distance: portDistanceMeters, angle: -90.0)
                                    mark.latitude = lat2
                                    mark.longitude = lon2
                                }
                                try await appData.saveMark(courseID: courseID, mark: mark)
                                showEditMark = false
                            } catch {
                                // TODO: show error
                            }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
        }
        .padding(.horizontal)
        .presentationDetents([.medium, .large])
        .onAppear {
            if markIndex >= 0, markIndex < marks.count {
                mark = marks[markIndex]
//                let markDistance = AppData.markDistance(marks: marks, parentId: mark.parent, wind: wind, latitude: mark.latitude, longitude: mark.longitude)
//                let value = SailingDistance.meters.convert(distance: markDistance, to: appData.unitLength)
//                distance = AppData.roundToSignificantDigits(value, digits: 4)
//                bearing = AppData.markBearing(marks: marks, parentId: mark.parent, wind: wind, latitude: mark.latitude, longitude: mark.longitude)
                if let parent = marks.first(where: { $0.id == mark.parent }) {
                    let distance = Bearing.distanceToLocation(lat1: parent.latitude, lon1: parent.longitude, lat2: mark.latitude, lon2: mark.longitude)
                    let angle = Bearing.bearingToLocation(lat1: parent.latitude, lon1: parent.longitude, lat2: mark.latitude, lon2: mark.longitude)
                    let relativeBearing = angle - wind
                    let (lat, _) = Bearing.locationUsingBearing(lat: parent.latitude, lon: parent.longitude, distance: distance, angle: relativeBearing)
                    let d1 = Bearing.distanceToLocation(lat1: parent.latitude, lon1: parent.longitude, lat2: lat, lon2: parent.longitude)
                    let normalizedBearing = ((Int(relativeBearing) + 180) % 360 + 360) % 360 - 180
                    let bearing = normalizedBearing > -90 && normalizedBearing < 90 ? wind : wind + 180.0
                    let (lat1, lon1) = Bearing.locationUsingBearing(lat: parent.latitude, lon: parent.longitude, distance: d1, angle: bearing)
                    forwardDistance = SailingDistance.meters.convert(distance: d1, to: appData.unitLength)
                    forwardDistance = AppData.roundToSignificantDigits(forwardDistance, digits: 4)
                    portDistance = Bearing.distanceToLocation(lat1: lat1, lon1: lon1, lat2: mark.latitude, lon2: mark.longitude)
                    portDistance = SailingDistance.meters.convert(distance: portDistance, to: appData.unitLength2)
                    portDistance = AppData.roundToSignificantDigits(portDistance, digits: 4)

                }
            }
        }
    }
}
