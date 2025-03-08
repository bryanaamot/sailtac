//
//  CourseView.swift
//  sail-tac
//
//  Created by Bryan Aamot on 12/29/24.
//

import SwiftUI

struct CourseListView: View {
    @EnvironmentObject private var appData: AppData
    let club: Club
    @State var showEditClub = false
    @State var showAddCourse = false
    @State var sortOption = "A-Z"
    @State var actionString = ""
    @State var action: () -> Void = {}
    @State var actionIsPresented = false
    @State var showMenu = false
    
    var sortedCourses: [Course] {
        appData.courses.sorted(
            by: {
                if sortOption == "A-Z" {
                    $0.name < $1.name
                } else {
                    $0.lastModified < $1.lastModified
                }
            }
        )
    }

    var body: some View {
        VStack {
            Button(action: {
                showEditClub = true
            }) {
                Text(club.name)
                    .font(.headline)
            }
            
            if appData.courses.count == 0 {
                Text("No courses found.")
            }
            List {
                ForEach(sortedCourses) { course in
                    NavigationLink(destination: CourseMapView(courseID: course.id, wind: course.wind, marks: course.marks)) {
                        VStack(alignment: .leading) {
                            Text("\(course.name)")
                                .font(.headline)
                        }
                    }
                }
                .onDelete { offsets in
                    if let offset = offsets.first {
                        actionString = "Delete course?"
                        action = {
                            Task {
                                do {
                                    let course = sortedCourses[offset]
                                    try await appData.deleteCourse(courseID: course.id)
                                } catch {
                                    // TODO:
                                }
                            }
                        }
                        actionIsPresented = true
                    }
                }
            }
        }
        .confirmationDialog(actionString, isPresented: $actionIsPresented) {
            Button(actionString, role: .destructive, action: action)
        }
//        .navigationTitle("Courses")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Picker("Sort", selection: $sortOption) {
                        Text(verbatim: "A-Z").tag("A-Z")
                        Text(verbatim: "Newest").tag("Newest")
                    }
                    .pickerStyle(.segmented)
                    #if SKIP
                    .frame(width: 200)
                    #endif
                    
//                    Menu {
//                        Button(action: {showAddCourse = true}) { Text("Add Course") }
//                        Button(action: {showEditClub = true}) { Text("Edit Club") }
//                    } label: {
//                        Image(systemName: "plus")
//                    }
                    Button(action: {
                        showAddCourse = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showEditClub, onDismiss: {
            Task {
                do {
                    try await AppData.updateClub(club: club)
                    // TODO
                } catch {
                    // TODO
                }
            }
        }) {
            ClubEditView(club: club)
        }
        .sheet(isPresented: $showAddCourse, onDismiss: {
            Task {
                do {
                    try await appData.getCoursesForClub(clubID: club.id)
                } catch {
                    logger.error("Failed to get courses for club: \(error)")
                }
            }

        }) {
            AddCourseView(course:  Course(id: "", name: "", wind: 0.0, clubID: club.id, marks: [], lastModified: Date()))
        }
        .onAppear {
            Task {
                do {
                    try await appData.getCoursesForClub(clubID: club.id)
                } catch {
                    logger.error("Failed to get courses for club: \(error)")
                }
            }
        }
    }
}

struct AddCourseView : View {
    var editing = false
    @State var course: Course
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage = ""
    @State private var showProgressView = false
    
    // add init here to convert optionals into separate field variables

    var body: some View {
        VStack {
            DismissButton()
            
            StyledTextField(title: "Name", text: $course.name)

            Button("Save") {
                Task {
                    errorMessage = ""
                    showProgressView = true
                    do {
                        _ = try await AppData.addCourse(course: course)
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


