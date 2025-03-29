//
//  ContentView 2.swift
//  sail-tac
//
//  Created by Bryan Aamot on 12/28/24.
//


import SwiftUI

struct SettingsView: View {
    @AppStorage("name") var name = "Skipper"
    @EnvironmentObject var appData: AppData
    @State var showProgressView = false
    @State var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Text("Heading: \(Int(round(appData.heading)))º")
                Text("Position: \(appData.location.lat)º, \(appData.location.lon)º")

//                HStack {
//                    Spacer()
//                    Button(action: {
//                        isSheetPresented = true
//                    }) {
//                        ZStack {
//                            Circle()
//                                .fill(Color.blue)
//                                .frame(width: 30, height: 30)
//                            Text(appData.firstName.prefix(1))
//                                .foregroundColor(.white)
//                                .font(.headline)
//                        }
//                        .padding(10)
//                    }
//                    .sheet(isPresented: $isSheetPresented, onDismiss: { logger.info("onDismiss called") }) {
//                        ProfileView()
//                    }
//                }
//                .frame(maxWidth: .infinity)
                
                if errorMessage != "" {
                    Text("\(errorMessage)")
                        .foregroundColor(.red)
                }
                
                if appData.signedIn {
                    Button("Log Out") {
                        Task {
                            showProgressView = true
                            do {
                                try await appData.logout()
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
                    .disabled(showProgressView)
                }

                TextField("Name", text: $name)
                Picker("Appearance", selection: $appData.appearance) {
                    Text("System").tag("")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                HStack {
                    #if SKIP
                    ComposeView { ctx in // Mix in Compose code!
                        androidx.compose.material3.Text("💚", modifier: ctx.modifier)
                    }
                    #else
                    Text(verbatim: "💙")
                    #endif
                    Text("Powered by \(androidSDK != nil ? "Jetpack Compose" : "SwiftUI")")
                }
                .foregroundStyle(.gray)
            }
            .navigationTitle("Settings")
        }
    }
}
