//
//  CourseEditView.swift
//  sail-tac
//
//  Created by Bryan Aamot on 3/2/25.
//

import SwiftUI

struct CourseEditView : View {
    @State var course: Course
    
    @EnvironmentObject private var appData: AppData
    @Environment(\.dismiss) private var dismiss
    
    @State private var errorMessage = ""
    @State private var showProgressView = false
    
    var body: some View {
        VStack {
            DismissButton()
            
            StyledTextField(title: "Name", text: $course.name)

            Button("Save") {
                Task {
                    errorMessage = ""
                    showProgressView = true
                    do {
                        appData.queueServerUpdate(Event(type: EventType.updateCourse, payload: course))
                        dismiss()
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
