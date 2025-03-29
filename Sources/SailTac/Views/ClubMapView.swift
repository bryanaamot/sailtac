//
//  ClubMap.swift
//  sail-tac
//
//  Created by Bryan Aamot on 1/26/25.
//

import SwiftUI
#if !SKIP
import MapKit
#endif

@available(iOS 17.0, *)
struct ClubMapView: View {
    @EnvironmentObject private var appData: AppData
    @State private var position: MapCameraPosition = .region(.init(center: CLLocationCoordinate2D(latitude: 37.771076, longitude: -122.265211), latitudinalMeters: 5000.0, longitudinalMeters: 5000.0))
    @State var selectedClub: Club?
    @State var presented = false
    @State var isNavigationActive = false
    
    var body: some View {
        Map(position: $position) {
            ForEach(appData.clubs) { club in
                if club.latitude != 0.0, club.longitude != 0.0 {
                    let coordinate = CLLocationCoordinate2D(latitude: club.latitude, longitude: club.longitude)
                    Annotation(club.name, coordinate: coordinate) {
#if !SKIP
                        Button(action: {
                            selectedClub = club
                            presented = true
                        }) {
                            Image(systemName: "sailboat.fill") // SF Symbol for sailing
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Circle().fill(Color.blue))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                .shadow(radius: 5)
                        }
#else
                        // Google maps only allow markers on the map. They don't allow just any View
                        Marker(club.name, coordinate: coordinate) {
                            selectedClub = club
                            presented = true
                        }
#endif
                    }
                }
            }
        }
        .navigationDestination(isPresented: $presented) {
            if let selectedClub {
                CourseListView(club: selectedClub)
            }
        }
    }
}
