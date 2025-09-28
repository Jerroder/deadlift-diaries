//
//  TextFieldToolbar.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-09-22.
//

import SwiftUI

struct TextFieldToolbar: ViewModifier {
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("", systemImage: "checkmark") {
                        isFocused = false
                    }
                }
            }
    }
}

extension View {
    func withTextFieldToolbar() -> some View {
        self.modifier(TextFieldToolbar())
    }
}
