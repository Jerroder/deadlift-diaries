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
    @State private var restProgress: CGFloat = 0
    
    let orange = Color(red: 0xFF/255, green: 0xBC/255, blue: 0x8E/255)
    let yellow = Color(red: 0xFF/255, green: 0xD6/255, blue: 0x8E/255)
    
    var body: some View {
        VStack(spacing: 20) {
            Stepper("Total Sets: \(totalSets)", value: $totalSets, in: 1...20)
                .onChange(of: totalSets) { oldValue, newValue in
                    if currentSet > newValue {
                        currentSet = newValue
                    }
                }
            HStack {
                Text("Rest Duration:")
                
                Picker("Rest Duration", selection: $restDuration) {
                    ForEach(Array(stride(from: 5, through: 300, by: 5)), id: \.self) { duration in
                        Text("\(duration) sec").tag(duration)
                    }
                }
                .pickerStyle(.wheel)
                .disabled(isTimerRunning)
                .frame(height: 150)
                .onChange(of: restDuration) { oldValue, newValue in
                    timeRemaining = newValue
                }
                
                if #available(iOS 26.0, *) {
                    VStack(spacing: 8) {
                        Button("30s") { restDuration = 30; timeRemaining = 30 }
                            .disabled(isTimerRunning)
                        Button("60s") { restDuration = 60; timeRemaining = 60 }
                            .disabled(isTimerRunning)
                        Button("90s") { restDuration = 90; timeRemaining = 90 }
                            .disabled(isTimerRunning)
                        Button("120s") { restDuration = 120; timeRemaining = 120 }
                            .disabled(isTimerRunning)
                    }
                    .buttonStyle(.glass)
                } else {
                    VStack(spacing: 8) {
                        Button("30s") { restDuration = 30; timeRemaining = 30 }
                            .disabled(isTimerRunning)
                        Button("60s") { restDuration = 60; timeRemaining = 60 }
                            .disabled(isTimerRunning)
                        Button("90s") { restDuration = 90; timeRemaining = 90 }
                            .disabled(isTimerRunning)
                        Button("120s") { restDuration = 120; timeRemaining = 120 }
                            .disabled(isTimerRunning)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
//            Text("\(currentSet)/\(totalSets)")
//                .font(.title)
            
            GeometryReader { geometry in
                let squareWidth = geometry.size.width / CGFloat(2 * self.totalSets - 1)
                HStack(spacing: 4) {
                    ForEach(1..<2*self.totalSets, id: \.self) { index in
                        if index.isMultiple(of: 2) {
                            let restNumber = index / 2
                            if restNumber == self.currentSet && (self.isTimerRunning || self.restProgress > 0) {
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .frame(width: squareWidth, height: 20)
                                        .foregroundColor(.gray)
                                        .cornerRadius(4)
                                    Rectangle()
                                        .frame(width: squareWidth * self.restProgress, height: 20)
                                        .foregroundColor(yellow)
                                        .cornerRadius(4)
                                        .animation(.linear, value: self.restProgress)
                                }
                            } else if restNumber < self.currentSet {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(orange)
                                    .cornerRadius(4)
                            } else {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(.gray)
                                    .cornerRadius(4)
                            }
                        } else {
                            let setNumber = (index + 1) / 2
                            Rectangle()
                                .frame(width: squareWidth, height: 20)
                                .foregroundColor(setNumber <= self.currentSet ? .accentColor : .gray)
                                .cornerRadius(4)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: 20)
            }
            .frame(height: 20)
            .padding(.horizontal)
            
            Text("Remaining: \(timeRemaining) sec")
                .font(.title)
            
            HStack {
                Spacer()
                Button(action: toggleTimer) {
                    Text(isTimerRunning ? "Pause" : "Start")
                }
                .disabled(currentSet >= totalSets)
                Spacer()
                Button("Reset") {
                    timer?.invalidate()
                    isTimerRunning = false
                    currentSet = 1
                    timeRemaining = restDuration
                    restProgress = 0
                }
                Spacer()
            }
        }
        .padding()
    }
    
    private func colorForIndex(_ index: Int) -> Color {
        if index.isMultiple(of: 2) {
            let restNumber = index / 2
            if restNumber < currentSet {
                return orange
            } else if restNumber == currentSet && isTimerRunning {
                return yellow
            } else {
                return .gray
            }
        } else {
            let setNumber = (index + 1) / 2
            return setNumber <= currentSet ? .accentColor : .gray
        }
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
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                restProgress = 1 - (CGFloat(timeRemaining) / CGFloat(restDuration))
            } else {
                timer?.invalidate()
                isTimerRunning = false
                if currentSet < totalSets {
                    currentSet += 1
                }
                timeRemaining = restDuration
                restProgress = 0
            }
        }
    }
}
