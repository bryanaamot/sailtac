//
//  MarkAddView.swift
//  sail-tac
//
//  Created by Bryan Aamot on 1/25/25.
//

import SwiftUI

struct MarkAddView: View {
    @Binding var showAddMark: Bool
    let courseID: String
    let wind: Double
    @Binding var marks: [Mark]
    @Binding var mapCenterLatitude: Double
    @Binding var mapCenterLongitude: Double
    
    @EnvironmentObject private var appData: AppData
    
    @State var markName = ""
    @State var markAngle = 0.0
    @State var forwardDistance = 0.0
    @State var portDistance = 0.0
    @State var markType = MarkType.fixed
    @State var markParentID = ""
    
    struct AngleReference {
        let name: String
        let angle: Double
        init(_ name: String, _ angle: Double) {
            self.name = name
            self.angle = angle
        }
    }
    
    var body: some View {
        VStack {
            Text("Add Mark")
                .font(.title)

            Text(markType.description)

            HStack {
                Text("Name")
                StyledTextField(title: "Name", text: $markName)
            }
            
            Picker("Type", selection: $markType) {
                ForEach(MarkType.allCases, id: \.id) {
                    Text($0.localizedName).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: markType) { oldType, newType in
                if newType == .relative,
                   markParentID == "",
                   marks.count > 0,
                   let mark = marks.first(where: { $0.type == .fixed }) {
                    markParentID = mark.id
                }
            }
            
            VStack {
                if marks.count == 0 {
                    Text("You need to add a Fixed Mark first.")
                } else {
                    HStack {
                        Text("Relative to")
                        Picker("Parent", selection: $markParentID) {
                            ForEach(0..<marks.count, id: \.self) { index in
                                Text(marks[index].name).tag(marks[index].id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Text("Forward Distance")
                        StyledDoubleField(title: "", value: $forwardDistance)
                            .frame(width: 100)
                        Picker("Units", selection: $appData.unitLength) {
                            ForEach(SailingDistance.allCases, id: \.self) { unit in
                                Text(unit.unitName).tag(unit)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Port Distance")
                        StyledDoubleField(title: "", value: $portDistance)
                            .frame(width: 100)
                        Picker("Units", selection: $appData.unitLength2) {
                            ForEach(SailingDistance.allCases, id: \.self) { unit in
                                Text(unit.unitName).tag(unit)
                            }
                        }
                    }
                }
            }
            .opacity(markType == .relative ? 1.0 : 0.0)
            
            Divider()
            
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    showAddMark = false
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("Add") {
                    showAddMark = false
                    handleMarkTypeSelection()
                }
                .buttonStyle(.borderedProminent)
                .disabled((markType == .relative && marks.count == 0) || markName.count == 0)
                Spacer()
            }
        }
        .padding()
    }
    
    private func handleMarkTypeSelection() {
        Task {
            do {
                var latitude = mapCenterLatitude
                var longitude = mapCenterLongitude
                if markType == .relative {
                    if let parent = marks.first(where: { $0.id == markParentID }) {
                        let forwardDistanceMeters = appData.unitLength.toMeters(distance: forwardDistance)
                        let (lat1, lon1) = Bearing.locationUsingBearing(lat: parent.latitude, lon: parent.longitude, distance: forwardDistanceMeters, angle: wind)
                        let portDistanceMeters = appData.unitLength2.toMeters(distance: portDistance)
                        let (lat2, lon2) = Bearing.locationUsingBearing(lat: lat1, lon: lon1, distance: portDistanceMeters, angle: -90.0)
                        latitude = lat2
                        longitude = lon2
                    }
                }
                let mark = Mark(id: UUID().uuidString, type: markType, name: markName, latitude: latitude, longitude: longitude, parent: markParentID)
                try await appData.addMark(mark, courseID: courseID)
            } catch {
                // TODO
            }
        }
    }
}
