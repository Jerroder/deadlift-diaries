//
//  TextFieldWithUnit.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-09-21.
//

import SwiftUI

// Source:
// https://medium.com/@shawky_91474/building-an-auto-expanding-textfield-with-dynamic-unit-display-in-swiftui-bd3621b10573
// https://web.archive.org/web/20250624171027/https://medium.com/@shawky_91474/building-an-auto-expanding-textfield-with-dynamic-unit-display-in-swiftui-bd3621b10573
private struct SetWidthAccordingToTextDouble: ViewModifier {
    let value: Double
    @State private var textWidth: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .frame(width: textWidth)
            .background(
                Text(String(value))
                    .fixedSize()
                    .hidden()
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.width
                    } action: { width in
                        self.textWidth = width
                    }
                
            )
    }
}

private struct SetWidthAccordingToTextInt: ViewModifier {
    let value: Int
    @State private var textWidth: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .frame(width: textWidth)
            .background(
                Text(String(value))
                    .fixedSize()
                    .hidden()
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.width
                    } action: { width in
                        self.textWidth = width + 7
                    }
                
            )
    }
}

private extension View {
    func setWidthAccordingTo(value: Double) -> some View {
        modifier(SetWidthAccordingToTextDouble(value: value))
    }
    
    func setWidthAccordingTo(value: Int) -> some View {
        modifier(SetWidthAccordingToTextInt(value: value))
    }
}

struct TextFieldWithUnitDouble: View {
    @Binding var value: Double
    @Binding var unit: Unit
    
    var body: some View {
        HStack(spacing: 2) {
            TextField("0.0", value: $value, format: .number)
                .setWidthAccordingTo(value: value)
            
            Text(unit.symbol)
        }
    }
}

struct TextFieldWithUnitInt: View {
    @Binding var value: Int
    @Binding var unit: Unit
    
    var body: some View {
        HStack(spacing: 2) {
            TextField("0", value: $value, format: .number)
                .setWidthAccordingTo(value: value)
            
            Text(unit.symbol)
        }
    }
}
