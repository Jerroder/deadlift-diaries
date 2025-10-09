//
//  TextFieldToolbar.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-09-22.
//

import SwiftUI

struct TextFieldToolbarDone: ViewModifier {
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
                                isTextFieldFocused.wrappedValue = false
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

struct TextFieldToolbarDoneWithChevrons: ViewModifier {
    @Binding var isKeyboardShowing: Bool
    @Binding var isSupersetToggleOn: Bool
    var focusedField: FocusState<FocusableField?>
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .safeAreaBar(edge: .bottom) {
                    if isKeyboardShowing {
                        HStack {
                            Button(action: {
                                switch focusedField.wrappedValue {
                                case .exerciseWeight:
                                    focusedField.wrappedValue = .exerciseName
                                case .supersetName:
                                    focusedField.wrappedValue = .exerciseWeight
                                case .supersetWeight:
                                    focusedField.wrappedValue = .supersetName
                                default:
                                    break
                                }
                            }) {
                                Image(systemName: "chevron.up")
                                    .padding()
                            }
                            .disabled(focusedField.wrappedValue == .exerciseName ? true : false)
                            
                            Button(action: {
                                switch focusedField.wrappedValue {
                                case .exerciseName:
                                    focusedField.wrappedValue = .exerciseWeight
                                case .exerciseWeight:
                                    focusedField.wrappedValue = .supersetName
                                case .supersetName:
                                    focusedField.wrappedValue = .supersetWeight
                                default:
                                    break
                                }
                            }) {
                                Image(systemName: "chevron.down")
                                    .padding()
                            }
                            .disabled({if (isSupersetToggleOn && focusedField.wrappedValue == .supersetWeight) ||
                                            (!isSupersetToggleOn && focusedField.wrappedValue == .exerciseWeight) {
                                return true
                            } else {
                                return false
                            }}())
                            
                            Spacer()
                            
                            Button {
                                focusedField.wrappedValue = nil
                            } label: {
                                Image(systemName: "checkmark")
                                    .padding()
                            }
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive())
                        .padding(.horizontal, 15)
                        .padding(.bottom, 10)
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
                            focusedField.wrappedValue = nil
                        }
                    }
                }
        }
    }
}

extension View {
    func withTextFieldToolbarDone(isKeyboardShowing: Binding<Bool>, isTextFieldFocused: FocusState<Bool>.Binding) -> some View {
        self.modifier(
            TextFieldToolbarDone(isKeyboardShowing: isKeyboardShowing, isTextFieldFocused: isTextFieldFocused)
        )
    }
    
    func withTextFieldToolbarDoneWithChevrons(isKeyboardShowing: Binding<Bool>, isSupersetToggleOn: Binding<Bool>, focusedField: FocusState<FocusableField?>) -> some View {
        self.modifier(
            TextFieldToolbarDoneWithChevrons(isKeyboardShowing: isKeyboardShowing, isSupersetToggleOn: isSupersetToggleOn, focusedField: focusedField)
        )
    }
}
