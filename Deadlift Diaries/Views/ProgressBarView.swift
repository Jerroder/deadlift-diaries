//
//  ProgressBarView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-10-06.
//

import AudioToolbox
import AVFoundation
import SwiftUI

struct ProgressBarView: View {
    let totalSets: Int
    @Binding var currentSet: Int
    let restDuration: Double
    let timeBeforeNextExercise: Double
    @Binding var isTimerRunning: Bool
    @Binding var elapsed: Double
    let isTimeBased: Bool
    let duration: Double
    
    @AppStorage("selectedSoundID") private var selectedSoundID: Int = 1075
    @AppStorage("isExerciseDone") private var isExerciseDone: Bool = false
    
    @State private var restProgress: CGFloat = 0
    @State private var timer: DispatchSourceTimer?
    @State private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    @State private var timeStarted: Double?
    @State private var timeRemaining: Double = 60.0
    @State private var isExerciseInterval: Bool = true
    
    // accentColor is 0x5DA79B
    let orange: Color = Color(red: 0xFF/255, green: 0xBC/255, blue: 0x8E/255)
    let yellow: Color = Color(red: 0xFF/255, green: 0xD6/255, blue: 0x8E/255)
    let red: Color = Color(red: 0xF5/255, green: 0x89/255, blue: 0x96/255)
    let blue: Color = Color(red: 0x68/255, green: 0x83/255, blue: 0xAE/255)
    let green: Color = Color(red: 0x8D/255, green: 0xD9/255, blue: 0x79/255)
    
    private var realDuration: Double {
        if isExerciseDone {
            return timeBeforeNextExercise
        } else if isTimeBased {
            if isExerciseInterval {
                return duration
            } else {
                return restDuration
            }
        } else {
            return restDuration
        }
    }
    
    private var nbSet: Int {
        isTimeBased ? totalSets * 2 : totalSets
    }
    
    // MARK: - Main view
    
    var body: some View {
        VStack {
            progressBars()
                .frame(height: 20)
                .padding(.horizontal)
            
            Text("Remaining: \(Int(timeRemaining.rounded(.down))) sec")
                .font(.title)
            
            if #available(iOS 26.0, *) {
                HStack {
                    Spacer()
                    Button(action: toggleTimer) {
                        Text(isTimerRunning ? "Pause" : "Start")
                    }
                    .disabled(currentSet > nbSet)
                    .buttonStyle(.glassProminent)
                    Spacer()
                    Button("Reset") {
                        timer?.cancel()
                        isTimerRunning = false
                        currentSet = 1
                        isExerciseDone = (totalSets == 1 && !isTimeBased) ? true : false
                        isExerciseInterval = true
                        timeRemaining = realDuration
                        restProgress = 0
                        timeStarted = nil
                        elapsed = 0.0
                    }
                    .buttonStyle(.glass)
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    Button(action: toggleTimer) {
                        Text(isTimerRunning ? "Pause" : "Start")
                    }
                    .disabled(currentSet > nbSet)
                    Spacer()
                    Button("Reset") {
                        timer?.cancel()
                        isTimerRunning = false
                        currentSet = 1
                        isExerciseDone = (totalSets == 1 && !isTimeBased) ? true : false
                        isExerciseInterval = true
                        timeRemaining = realDuration
                        restProgress = 0
                        timeStarted = nil
                        elapsed = 0.0
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            timeRemaining = max(0, realDuration - elapsed)
            if timeRemaining < realDuration {
                restProgress = 1 - (CGFloat(timeRemaining.rounded(.down)) / CGFloat(realDuration.rounded(.up)))
            } else {
                restProgress = 0
            }
        }
        .onChange(of: restDuration) {
            timeRemaining = restDuration
        }
        .onChange(of: duration) {
            timeRemaining = duration
        }
        .onChange(of: totalSets) { oldValue, newValue in
            if newValue == 1 && !isTimeBased {
                isExerciseDone = true
            } else {
                isExerciseDone = false
            }
            timeRemaining = realDuration
        }
        .onChange(of: isTimeBased) {
            isExerciseDone = (totalSets == 1 && !isTimeBased) ? true : false
            isExerciseInterval = true
            timeRemaining = realDuration
        }
    }
    
    // MARK: - ViewBuilder functions
    
    @ViewBuilder
    private func progressBars() -> some View {
        GeometryReader { geometry in
            let squareWidth: Double = geometry.size.width / CGFloat(2 * self.totalSets)
            HStack(spacing: 4) {
                ForEach(UInt8(1)..<2 * UInt8(self.totalSets) + 1, id: \.self) { index in
                    if isTimeBased { // time based
                        if index.isMultiple(of: 2) { // rest
                            if index == currentSet {
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .frame(width: squareWidth, height: 20)
                                        .foregroundColor(orange.opacity(0.3))
                                        .cornerRadius(4)
                                    Rectangle()
                                        .frame(width: squareWidth * self.restProgress, height: 20)
                                        .foregroundColor(orange)
                                        .cornerRadius(4)
                                        .animation(.linear, value: self.restProgress)
                                }
                            } else if index < currentSet {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(orange)
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        if !isTimerRunning {
                                            timer?.cancel()
                                            isTimerRunning = false
                                            currentSet = Int(index)
                                            if currentSet == nbSet {
                                                isExerciseDone = true
                                            } else {
                                                isExerciseDone = false
                                            }
                                            isExerciseInterval = false
                                            timeRemaining = realDuration
                                            restProgress = 0
                                            timeStarted = nil
                                            elapsed = 0.0
                                        }
                                    }
                            } else {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(orange.opacity(0.3))
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        if !isTimerRunning {
                                            timer?.cancel()
                                            isTimerRunning = false
                                            currentSet = Int(index)
                                            if currentSet == nbSet {
                                                isExerciseDone = true
                                            } else {
                                                isExerciseDone = false
                                            }
                                            isExerciseInterval = false
                                            timeRemaining = realDuration
                                            restProgress = 0
                                            timeStarted = nil
                                            elapsed = 0.0
                                        }
                                    }
                            }
                        } else { // set
                            if index == currentSet {
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .frame(width: squareWidth, height: 20)
                                        .foregroundColor(.accentColor.opacity(0.3))
                                        .cornerRadius(4)
                                    Rectangle()
                                        .frame(width: squareWidth * self.restProgress, height: 20)
                                        .foregroundColor(.accentColor)
                                        .cornerRadius(4)
                                        .animation(.linear, value: self.restProgress)
                                }
                            } else if index < currentSet {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        if !isTimerRunning {
                                            timer?.cancel()
                                            isTimerRunning = false
                                            currentSet = Int(index)
                                            if currentSet == nbSet {
                                                isExerciseDone = true
                                            } else {
                                                isExerciseDone = false
                                            }
                                            isExerciseInterval = true
                                            timeRemaining = realDuration
                                            restProgress = 0
                                            timeStarted = nil
                                            elapsed = 0.0
                                        }
                                    }
                            } else {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(.accentColor.opacity(0.3))
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        if !isTimerRunning {
                                            timer?.cancel()
                                            isTimerRunning = false
                                            currentSet = Int(index)
                                            if currentSet == nbSet {
                                                isExerciseDone = true
                                            } else {
                                                isExerciseDone = false
                                            }
                                            isExerciseInterval = true
                                            timeRemaining = realDuration
                                            restProgress = 0
                                            timeStarted = nil
                                            elapsed = 0.0
                                        }
                                    }
                            }
                        }
                    } else { // reps based
                        if index.isMultiple(of: 2) { // rest
                            if index / 2 == currentSet {
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .frame(width: squareWidth, height: 20)
                                        .foregroundColor(orange.opacity(0.3))
                                        .cornerRadius(4)
                                    Rectangle()
                                        .frame(width: squareWidth * self.restProgress, height: 20)
                                        .foregroundColor(orange)
                                        .cornerRadius(4)
                                        .animation(.linear, value: self.restProgress)
                                }
                            } else if index / 2 < currentSet {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(orange)
                                    .cornerRadius(4)
                            } else {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(orange.opacity(0.3))
                                    .cornerRadius(4)
                            }
                        } else { // set
                            if (index + 1) / 2 <= currentSet {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        if !isTimerRunning {
                                            timer?.cancel()
                                            isTimerRunning = false
                                            currentSet = Int((index + 1) / 2)
                                            if currentSet == nbSet {
                                                isExerciseDone = true
                                            } else {
                                                isExerciseDone = false
                                            }
                                            timeRemaining = realDuration
                                            restProgress = 0
                                            timeStarted = nil
                                            elapsed = 0.0
                                        }
                                    }
                            } else {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(.accentColor.opacity(0.3))
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        if !isTimerRunning {
                                            timer?.cancel()
                                            isTimerRunning = false
                                            currentSet = Int((index + 1) / 2)
                                            if currentSet == nbSet {
                                                isExerciseDone = true
                                            } else {
                                                isExerciseDone = false
                                            }
                                            timeRemaining = realDuration
                                            restProgress = 0
                                            timeStarted = nil
                                            elapsed = 0.0
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: 20)
        }
    }
    
    // MARK: - Helper Functions
    
    private func toggleTimer() {
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
        isTimerRunning.toggle()
    }
    
    private func startTimer() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [self] in
            self.endBackgroundTask()
        }
        
        timeStarted = Date.now.timeIntervalSince1970 * 1000
        
        let queue: DispatchQueue = DispatchQueue(label: "com.jerroder.deadliftdiaries", qos: .background)
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: .seconds(1))
        timer?.setEventHandler { [self] in
            DispatchQueue.main.async {
                let now: Double = Date.now.timeIntervalSince1970 * 1000
                let elapsed: Double = max(0, now - (timeStarted ?? 0)) / 1000
                let remaining: Double = max(0, realDuration - elapsed - self.elapsed)
                timeRemaining = remaining
                restProgress = 1 - (CGFloat(timeRemaining.rounded(.down)) / CGFloat(realDuration.rounded(.up)))
                
                if timeRemaining <= 0 {
                    if isTimeBased {
                        isExerciseInterval.toggle()
                    }
                    isTimerRunning = false
                    stopTimer()
                    if currentSet < nbSet {
                        currentSet += 1
                        timeRemaining = realDuration
                        restProgress = 0
                        self.elapsed = 0.0
                    }
                    
                    if currentSet == nbSet && isExerciseDone {
                        currentSet += 1
                    }
                    if currentSet == nbSet {
                        isExerciseDone = true
                        timeRemaining = timeBeforeNextExercise
                    }
                } else if timeRemaining <= 1 {
                    playSystemSound()
                }
            }
        }
        timer?.resume()
    }
    
    private func stopTimer() {
        let now: Double = Date.now.timeIntervalSince1970 * 1000
        if let timeStarted = timeStarted {
            elapsed += max(0, now - timeStarted) / 1000
            timeRemaining = max(0, realDuration - elapsed)
        }
        timer?.cancel()
        timer = nil
        endBackgroundTask()
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func playSystemSound() {
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.ambient, options: .duckOthers)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        
        if selectedSoundID != 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                AudioServicesPlaySystemSound(UInt32(selectedSoundID))
            }
            
            let duration: Double = selectedSoundID == 1328 ? 2.0 : 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                do {
                    try audioSession.setActive(false)
                } catch {
                    print("Failed to deactivate audio session: \(error)")
                }
            }
        } else {
            do {
                try audioSession.setActive(false)
            } catch {
                print("Failed to deactivate audio session: \(error)")
            }
        }
    }
}
