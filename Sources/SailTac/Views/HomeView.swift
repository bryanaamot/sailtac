//
//  HomeView.swift
//  sail-tac
//
//  Created by Bryan Aamot on 12/27/24.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appData: AppData
    @State var selectedValue = "Map"
    @State private var path = NavigationPath()
    @State private var showAddClub = false
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                if selectedValue == "Map" {
                    if #available(iOS 17.0, *) {
                        ClubMapView()
                    } else {
                        Text("Map requies iOS 17+")
                    }
                } else {
                    ClubListView()
                }
            }
            .navigationTitle("Clubs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Picker("Club View", selection: $selectedValue) {
                            Text(verbatim: "Map").tag("Map")
                            Text(verbatim: "List").tag("List")
                        }
                        .pickerStyle(.segmented)
                        #if SKIP
                        .frame(width: 200)
                        #endif

                        Button(action: {
                            showAddClub = true
                        }) { 
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    do {
                        try await appData.getClubs()
                    } catch {
                        // TODO:
                    }
                }
            }
            .sheet(isPresented: $showAddClub, onDismiss: {
                Task {
                    do {
                        try await appData.getClubs()
                    } catch {
                        // TODO:
                    }
                }
            }) {
                AddClubView()
                    .presentationDetents([.medium])
            }

        }
    }
}
