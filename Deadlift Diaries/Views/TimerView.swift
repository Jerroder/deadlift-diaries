//
//  TimerView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI

struct TimerView: View {
    @AppStorage("totalSets") private var totalSets: Int = 5
    @AppStorage("currentSet") private var currentSet: Int = 1
    @AppStorage("restDuration") private var restDuration: Int = 60
    @AppStorage("timeRemaining") private var timeRemaining: Int = 60
    @State private var isTimerRunning: Bool = false
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 20) {
            Stepper("Total Sets: \(totalSets)", value: $totalSets, in: 1...20)
                .onChange(of: totalSets) { oldValue, newValue in
                    if currentSet > newValue {
                        currentSet = newValue
                    }
                }
            Stepper("Rest Duration: \(restDuration) sec", value: $restDuration, in: 10...300, step: 5)
                .onChange(of: restDuration) { oldValue, newValue in
                    timeRemaining = newValue
                }
            
            Text("\(currentSet)/\(totalSets)")
                .font(.title)
            Text("\(timeRemaining) sec")
                .font(.title)
            
            HStack {
                Spacer()
                Button(action: toggleTimer) {
                    Text(isTimerRunning ? "Pause" : "Start")
                }
                Spacer()
                Button("Reset") {
                    timer?.invalidate()
                    isTimerRunning = false
                    currentSet = 1
                    timeRemaining = restDuration
                }
                Spacer()
            }
        }
        .padding()
    }
    
    private func toggleTimer() {
        if isTimerRunning {
            timer?.invalidate()
        } else {
            startTimer()
        }
        isTimerRunning.toggle()
    }
    
    private func startTimer() {
        timeRemaining = restDuration - 1
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timeRemaining -= 1
                timer?.invalidate()
                isTimerRunning = false
                if currentSet < totalSets {
                    currentSet += 1
                }
                timeRemaining = restDuration
            }
        }
    }
}
