//
//  ColorExtension.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-30.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r: Double
        let g: Double
        let b: Double
        
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
            
        default:
            r = 0
            g = 0
            b = 0
        }
        
        self.init(
            red: r,
            green: g,
            blue: b
        )
    }
    
    // Used to persist a color picked in a ColorPicker (e.g. a program's color) as a string.
    func toHex() -> String {
        let uiColor = UIColor(self)
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(
            format: "#%02X%02X%02X",
            Int(round(r * 255)),
            Int(round(g * 255)),
            Int(round(b * 255))
        )
    }
}
