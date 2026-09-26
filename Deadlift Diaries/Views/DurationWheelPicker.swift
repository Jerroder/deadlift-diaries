//
//  DurationWheelPicker.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-26.
//

import SwiftUI

struct DurationWheelPicker: View {
    @Binding var totalSeconds: Int
    
    private static let minuteOptions = Array(0...10)
    private static let secondOptions = Array(stride(from: 0, through: 55, by: 5))
    
    private var minutesBinding: Binding<Int> {
        Binding(
            get: { totalSeconds / 60 },
            set: { newMinutes in
                let newTotal = newMinutes * 60 + (totalSeconds % 60)
                totalSeconds = newTotal == 0 ? Self.secondOptions[1] : newTotal
            }
        )
    }
    
    private var secondsBinding: Binding<Int> {
        Binding(
            get: { totalSeconds % 60 },
            set: { newSeconds in
                let newTotal = (totalSeconds / 60) * 60 + newSeconds
                totalSeconds = newTotal == 0 ? Self.secondOptions[1] : newTotal
            }
        )
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Picker("minutes".localized(comment: "Minutes"), selection: minutesBinding) {
                ForEach(Self.minuteOptions, id: \.self) { minute in
                    Text("x_min".localized(with: minute, comment: "x min")).tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            
            Picker("seconds".localized(comment: "Seconds"), selection: secondsBinding) {
                ForEach(Self.secondOptions, id: \.self) { second in
                    Text("x_sec".localized(with: second, comment: "x sec")).tag(second)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
    }
}
