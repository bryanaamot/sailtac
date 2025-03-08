//
//  ProfileView.swift
//  sail-tac
//
//  Created by Bryan Aamot on 12/27/24.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appData: AppData
    @State var errorMessage = ""
    @State var showProgressView = false

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Text("X")
                        .font(.system(size: 24))
                        .padding(10)
                }
            }
            .frame(maxWidth: .infinity)
            
            if errorMessage != "" {
                Text(errorMessage)
            }
            
            Spacer()
            Button("Log Out") {
                Task {
                    showProgressView = true
                    do {
                        try await appData.logout()
                        dismiss()
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
            
            if showProgressView {
                ProgressView()
                    .padding()
            }

            Spacer()
        }
        .frame(maxHeight: .infinity)
    }
}
