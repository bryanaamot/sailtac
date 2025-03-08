//
//  Fields.swift
//  sail-tac
//
//  Created by Bryan Aamot on 12/16/24.
//

import SwiftUI

struct StyledTextField: View {
    let title: String
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            let darkMode = colorScheme == .dark
            TextField(title, text: $text)
                .textInputAutocapitalization(.never)
                #if !SKIP
                .padding(10)
                #endif
                .background(darkMode ?  Color(white: 0.2) : Color(white: 0.9))
                .foregroundColor(darkMode ? .white : .black)
                #if !SKIP
                .cornerRadius(8)
                #endif
                #if SKIP
                .padding(-6)
                .cornerRadius(8)
                .clipped()
                #endif
        }
    }
}

struct StyledPasswordField: View {
    let title: String
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            let darkMode = colorScheme == .dark
            SecureField(title, text: $text)
                .textInputAutocapitalization(.never)
                #if !SKIP
                .padding(10)
                #endif
                .background(darkMode ?  Color(white: 0.2) : Color(white: 0.9))
                .foregroundColor(darkMode ? .white : .black)
                #if !SKIP
                .cornerRadius(8)
                #endif
                #if SKIP
                .padding(-6)
                .cornerRadius(8)
                .clipped()
                #endif
        }
    }
}

struct StyledDoubleField: View {
    let title: String
    @Binding var value: Double
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            let darkMode = colorScheme == .dark
            TextField(title, text:  Binding(
                get: {
                    String("\((value*100.0).rounded()/100.0)")
                },
                set: { newValue in
                    if let newFloatValue = Double(newValue) {
                        value = newFloatValue
                    }
                }))
                #if !SKIP
                .padding(10)
                #endif
                .background(darkMode ?  Color(white: 0.2) : Color(white: 0.9))
                .foregroundColor(darkMode ? .white : .black)
                #if !SKIP
                .cornerRadius(8)
                #endif
                #if SKIP
                .padding(-6)
                .cornerRadius(8)
                .clipped()
                #endif

        }
        .padding()
    }
}

struct StyledIntField: View {
    let title: String
    @Binding var value: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            let darkMode = colorScheme == .dark
            TextField(title, text:  Binding(
                get: {
                    String(value)
                },
                set: { newValue in
                    if let newIntValue = Int(newValue) {
                        value = newIntValue
                    }
                }))
                #if !SKIP
                .padding(10)
                #endif
                .background(darkMode ?  Color(white: 0.2) : Color(white: 0.9))
                .foregroundColor(darkMode ? .white : .black)
                #if !SKIP
                .cornerRadius(8)
                #endif
                #if SKIP
                .padding(-6)
                .cornerRadius(8)
                .clipped()
                #endif

        }
        .padding()
    }
}


#if !SKIP
@available(iOS 18.0, *)
#Preview {
    @Previewable @State var text = "bryan@brainware.net"
    StyledTextField(title: "", text: $text)
}
#endif
