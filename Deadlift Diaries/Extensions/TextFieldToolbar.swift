//
//  TextFieldToolbar.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-09-22.
//

import SwiftUI

struct TextFieldToolbarDone: ViewModifier {
    var focusedField: FocusState<FocusableField?>.Binding

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        
                        Button {
                            focusedField.wrappedValue = nil
                        } label: {
                            Image(systemName: "checkmark")
                                .padding(15)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive())
                        .padding(.bottom, 15)
                    }
                    .sharedBackgroundVisibility(.hidden)
                }
        } else {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("done".localized(comment: "Done")) {
                            focusedField.wrappedValue = nil
                        }
                    }
                }
        }
    }
}

struct TextFieldToolbarDoneWithChevrons: ViewModifier {
    var fields: [FocusableField]
    var focusedField: FocusState<FocusableField?>.Binding

    private var currentIndex: Int? {
        guard let current = focusedField.wrappedValue else {
            return nil
        }

        return fields.firstIndex(of: current)
    }

    private var canGoUp: Bool {
        guard let currentIndex else {
            return false
        }

        return currentIndex > 0
    }

    private var canGoDown: Bool {
        guard let currentIndex else {
            return false
        }

        return currentIndex < fields.count - 1
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Button {
                            if let currentIndex, canGoUp {
                                focusedField.wrappedValue = fields[currentIndex - 1]
                            }
                        } label: {
                            Image(systemName: "chevron.up")
                                .padding(15)
                        }
                        .disabled(!canGoUp)
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive())
                        .padding(.bottom, 15)
                        
                        Button {
                            if let currentIndex, canGoDown {
                                focusedField.wrappedValue = fields[currentIndex + 1]
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .padding(15)
                        }
                        .disabled(!canGoDown)
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive())
                        .padding(.bottom, 15)
                        
                        Spacer()
                        
                        Button {
                            focusedField.wrappedValue = nil
                        } label: {
                            Image(systemName: "checkmark")
                                .padding(15)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive())
                        .padding(.bottom, 15)
                    }
                    .sharedBackgroundVisibility(.hidden)
                }
        } else {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("done".localized(comment: "Done")) {
                            focusedField.wrappedValue = nil
                        }
                    }
                }
        }
    }
}

extension View {
    func withTextFieldToolbarDone(focusedField: FocusState<FocusableField?>.Binding) -> some View {
        self.modifier(
            TextFieldToolbarDone(focusedField: focusedField)
        )
    }

    func withTextFieldToolbarDoneWithChevrons(fields: [FocusableField], focusedField: FocusState<FocusableField?>.Binding) -> some View {
        self.modifier(
            TextFieldToolbarDoneWithChevrons(fields: fields, focusedField: focusedField)
        )
    }
}
