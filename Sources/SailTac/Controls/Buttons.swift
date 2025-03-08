//
//  DismissView.swift
//  sail-tac
//
//  Created by Bryan Aamot on 12/28/24.
//

import SwiftUI

struct DismissButton : View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Text("X")
                    .font(.system(size: 24))
                    .padding(10)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct MapButton<Content: View>: View {
    let action: () -> Void
    let content: () -> Content
    @Environment(\.colorScheme) var colorScheme
    
    init(action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }

    var body: some View {
        Button(action: action) {
            content()
                .padding(.horizontal)
                .font(.system(size: 12, weight: .bold))
                .frame(height: 50)
                .background(colorScheme == .dark ? Color.black.opacity(0.7) : Color.white.opacity(0.7))
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                .cornerRadius(8)
        }
    }
}
