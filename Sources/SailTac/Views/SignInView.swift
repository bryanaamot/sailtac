//
//  SignInView.swift
//  sail-tac
//
//  Created by Bryan Aamot on 12/16/24.
//


import SwiftUI
import OSLog

struct SignInView: View {
    @State var email = "bryan@brainware.net"
    @State var password = "password"
    @State var firstName = "Bryan"
    @State var lastName = "Aamot"
    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    @State var registering = false
    @State var showProgressView = false
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        VStack(spacing: 0) {
            Image("sailtac_logo", bundle: .module)
                .resizable()
                .frame(width: 180, height: 180)
            
            Text("SailTac")
                .font(.largeTitle)

            Text(registering ? "Register to share race courses and events." : "Sign In")
                .foregroundColor(.gray)
                .padding(.horizontal, 50)
                .multilineTextAlignment(.center)
            
            VStack {
                StyledTextField(title: "Email", text: $email)
                    .keyboardType(.emailAddress)

                StyledPasswordField(title: "Password", text: $password)
                
                if registering {
                    StyledTextField(title: "First Name", text: $firstName)
                    StyledTextField(title: "Last Name", text: $lastName)
                }
                    
            }
            .font(.system(size: 20))
            .frame(width: 300)
            .padding(.vertical, 50)
            
            Group {
                if registering {
                    Button("Register") {
                        Task {
                            showProgressView = true
                            do {
                                try await appData.register(email: email, password: password, firstName: firstName, lastName: lastName)
                                alertTitle = "Success"
                                alertMessage = "Check your email"
                                showAlert = true
                                registering = false
                            } catch let error as NSError {
                                alertTitle = "Error"
                                if let userInfoDescription = error.userInfo["description"] as? String {
                                    alertMessage = userInfoDescription
                                } else {
                                    alertMessage = error.localizedDescription
                                }
                                showAlert = true
                            }
                            showProgressView = false
                        }
                    }
                    .font(.system(size: 20))
                    .buttonStyle(.borderedProminent)
                    .disabled(showProgressView)
                    .padding(.bottom, 25)
                    
                    Button("I've already registered") {
                        withAnimation {
                            registering = !registering
                        }
                    }
                } else {
                    Button("Sign In") {
                        Task {
                            showProgressView = true
                            do {
                                try await appData.login(email: email, password: password)
                            } catch let error as NSError {
                                alertTitle = "Error"
                                if let userInfoDescription = error.userInfo["description"] as? String {
                                    alertMessage = userInfoDescription
                                } else {
                                    alertMessage = error.localizedDescription
                                }
                                showAlert = true
                            }
                            showProgressView = false
                        }
                    }
                    .font(.system(size: 20))
                    .buttonStyle(.borderedProminent)
                    .disabled(showProgressView)
                    .padding(.bottom, 25)
                    
                    Button("I need to Register first") {
                        withAnimation {
                            registering = !registering
                        }
                    }
                    
                }
            }
            .transition(.opacity)
            .animation(.easeInOut, value: registering)
            
            if showProgressView {
                ProgressView()
                    .padding()
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
        } message: {
            Text(alertMessage)
        }
    }
}

#Preview {
    SignInView()
}
