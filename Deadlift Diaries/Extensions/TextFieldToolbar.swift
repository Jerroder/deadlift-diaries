//
//  TextFieldToolbar.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-09-22.
//

import SwiftUI

struct TextFieldToolbar: ViewModifier {
    @Binding var isKeyboardShowing: Bool
    var isTextFieldFocused: FocusState<Bool>.Binding
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .safeAreaBar(edge: .bottom) {
                    if isKeyboardShowing {
                        HStack {
                            Spacer()
                            Button {
                                print("before \(isTextFieldFocused.wrappedValue)")
                                isTextFieldFocused.wrappedValue = false
                                print("after \(isTextFieldFocused.wrappedValue)")
                            } label: {
                                Image(systemName: "checkmark")
                                    .padding()
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular.interactive())
                            .padding(.horizontal, 15)
                            .padding(.bottom, 10)
                        }
                    }
                }
                .detectKeyboard(isKeyboardShowing: $isKeyboardShowing)
                .animation(.default, value: isKeyboardShowing)
        } else {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isTextFieldFocused.wrappedValue = false
                        }
                    }
                }
        }
    }
}

extension View {
    func withTextFieldToolbar(isKeyboardShowing: Binding<Bool>, isTextFieldFocused: FocusState<Bool>.Binding) -> some View {
        self.modifier(
            TextFieldToolbar(isKeyboardShowing: isKeyboardShowing, isTextFieldFocused: isTextFieldFocused)
        )
    }
}
