//
//  ClubView.swift
//  sail-tac
//
//  Created by Bryan Aamot on 12/27/24.
//

import SwiftUI

struct ClubListView: View {
    @EnvironmentObject private var appData: AppData
    @State private var searchText: String = ""
    
    var filteredClubs: [Club] {
        appData.clubs.filter { club in
            searchText.isEmpty || club.name.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        VStack {
            TextField("Search by club name", text: $searchText)
                .padding()
            
            List(filteredClubs) { club in
                NavigationLink(destination: CourseListView(club: club)) {
                    VStack(alignment: .leading) {
                        Text("\(club.name)")
                        let year = club.year_established != 0 ? " (\(String(club.year_established)))" : ""
                        let footnote = "\(club.city), \(club.country)\(year)"
                        Text(footnote)
                            .font(.footnote)
                        Text("\(club.latitude) \(club.longitude)")
                            .font(.footnote)
                    }
                }
            }
        }
    }
}

struct AddClubView : View {
    @State var club = Club(id: "", name: "", latitude: 0.0, longitude: 0.0, city: "", country: "", year_established: 0)
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppData
    @State private var errorMessage = ""
    @State private var showProgressView = false
    
    var body: some View {
        VStack {
            DismissButton()
            
            StyledTextField(title: "Name", text: $club.name)
            StyledTextField(title: "City", text: $club.city)
            StyledTextField(title: "Country", text: $club.country)
            StyledIntField(title: "Year Established", value: $club.year_established)

            Button("Save") {
                Task {
                    errorMessage = ""
                    showProgressView = true
                    do {
                        let createRequest = Club(id: club.id, name: club.name, latitude: club.latitude, longitude: club.longitude, city: club.city, country: club.country, year_established: club.year_established)

                        // Encode the JSON body
                        guard let jsonData = try? JSONEncoder().encode(createRequest) else {
                            throw URLError(.badURL)
                        }
                        
                        let urlString = "\(endPoint)/clubs"
                        var request = URLRequest(url: URL(string: urlString)!)
                        request.httpMethod = "POST"
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.httpBody = jsonData
                        
                        let (data, _) = try await URLSession.shared.data(for: request)
                        let response = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        if response.error {
                            errorMessage = response.reason
                        } else {
                            dismiss()
                        }
                    } catch let error as NSError {
                        if let userInfoDescription = error.userInfo["description"] as? String {
                            errorMessage = userInfoDescription
                        } else {
                            errorMessage = error.localizedDescription
                        }
                    }
                    showProgressView = false
                }
            }
            .font(.system(size: 20))
            .buttonStyle(.borderedProminent)
            .disabled(showProgressView)
            .padding(.bottom, 25)

            if errorMessage != "" {
                Text(errorMessage)
            }
            Spacer()
            if showProgressView {
                ProgressView()
                    .padding()
            }
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }
}

struct ClubEditView : View {
    @State var club = Club(id: "", name: "", latitude: 0.0, longitude: 0.0, city: "", country: "", year_established: 0)
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppData
    @State private var errorMessage = ""
    @State private var showProgressView = false
    
    // add init here to convert optionals into separate field variables

    var body: some View {
        VStack {
            DismissButton()
            
            StyledTextField(title: "Name", text: $club.name)
            StyledDoubleField(title: "Latitude", value: $club.latitude)
            StyledDoubleField(title: "Longitude", value: $club.latitude)
            StyledTextField(title: "City", text: $club.city)
            StyledTextField(title: "Country", text: $club.country)
            StyledIntField(title: "Year Established", value: $club.year_established)

            Button("Save") {
                Task {
                    errorMessage = ""
                    showProgressView = true
                    do {
                        let createRequest = Club(id: club.id, name: club.name, latitude: club.latitude, longitude: club.longitude, city: club.city, country: club.country, year_established: club.year_established)

                        // Encode the JSON body
                        guard let jsonData = try? JSONEncoder().encode(createRequest) else {
                            throw URLError(.badURL)
                        }
                        
                        let urlString = "\(endPoint)/clubs/\(club.id)"
                        var request = URLRequest(url: URL(string: urlString)!)
                        request.httpMethod = "PUT"
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.httpBody = jsonData
                        
                        let (data, _) = try await URLSession.shared.data(for: request)
                        let response = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        if response.error {
                            errorMessage = response.reason
                        } else {
                            dismiss()
                        }
                    } catch let error as NSError {
                        if let userInfoDescription = error.userInfo["description"] as? String {
                            errorMessage = userInfoDescription
                        } else {
                            errorMessage = error.localizedDescription
                        }
                    }
                    showProgressView = false
                }
            }
            .font(.system(size: 20))
            .buttonStyle(.borderedProminent)
            .disabled(showProgressView)
            .padding(.bottom, 25)

            if errorMessage != "" {
                Text(errorMessage)
            }
            Spacer()
            if showProgressView {
                ProgressView()
                    .padding()
            }
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }
}

//#Preview {
//    AddEditClubView()
//}
