//
//  TextFieldToolbar.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-09-22.
//

import SwiftUI

private var keyboardToolbarWidth: CGFloat {
    let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    let width = scene?.screen.bounds.width ?? 390
    return width - 32
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
                    ToolbarItem(placement: .keyboard) {
                        HStack(spacing: 0) {
                            Button {
                                if let currentIndex, canGoUp {
                                    focusedField.wrappedValue = fields[currentIndex - 1]
                                }
                            } label: {
                                Image(systemName: "chevron.up")
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 12.5)
                                    .contentShape(Rectangle())
                            }
                            .disabled(!canGoUp)

                            Button {
                                if let currentIndex, canGoDown {
                                    focusedField.wrappedValue = fields[currentIndex + 1]
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .offset(y: 1)
                                    .padding(.horizontal, 23)
                                    .padding(.vertical, 12.5)
                                    .contentShape(Rectangle())
                            }
                            .disabled(!canGoDown)

                            Spacer()

                            Button {
                                focusedField.wrappedValue = nil
                            } label: {
                                Image(systemName: "checkmark")
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 12.5)
                                    .contentShape(Rectangle())
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 6)
                        .frame(width: keyboardToolbarWidth)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .padding(.bottom, 20)
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
    func withTextFieldToolbarDoneWithChevrons(fields: [FocusableField], focusedField: FocusState<FocusableField?>.Binding) -> some View {
        self.modifier(
            TextFieldToolbarDoneWithChevrons(fields: fields, focusedField: focusedField)
        )
    }
}
