//
//  ProgressBarView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-10-06.
//

import AudioToolbox
import AVFoundation
import SwiftUI
import UserNotifications

struct ProgressBarView: View {
    let totalSets: Int
    @Binding var currentSet: Int
    let restDuration: Double
    let timeBeforeNextExercise: Double
    @Binding var isTimerRunning: Bool
    @Binding var elapsed: Double
    let isTimeBased: Bool
    let duration: Double
    let isCalledFromTimer: Bool
    
    @Environment(\.scenePhase) var scenePhase
    @State private var isActive: Bool = true
    
    @AppStorage("selectedSoundID") private var selectedSoundID: Int = 1075
    @AppStorage("sendNotification") private var sendNotification: Bool = false
    @AppStorage("autoStartSetAfterRest") private var autoStartSetAfterRest: Bool = false
    @AppStorage("autoStartRestAfterSet") private var autoStartRestAfterSet: Bool = false
    @AppStorage("autoResetTimer") private var autoResetTimer: Bool = false
    
    @State private var isExerciseDone: Bool = false
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
                if currentSet > nbSet {
                    return 0
                } else {
                    return duration
                }
            } else {
                return restDuration
            }
        } else {
            if currentSet > nbSet {
                return 0
            } else {
                return restDuration
            }
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
                .padding(.horizontal, totalSets > 6 ? 0 : nil)
            
            Text("remaining_x_sec".localized(with: Int(timeRemaining.rounded(.down)), comment: "Remaining: x sec"))
                .font(.title)
            
            if #available(iOS 26.0, *) {
                HStack {
                    Spacer()
                    Button(action: toggleTimer) {
                        Text(isTimerRunning ? "pause".localized(comment: "Pause") : "start".localized(comment: "Start"))
                    }
                    .disabled(currentSet > nbSet)
                    .buttonStyle(.glassProminent)
                    Spacer()
                    Button("reset".localized(comment: "Reset")) {
                        resetValues(index: 1, isExerciseInterval: true)
                    }
                    .buttonStyle(.glass)
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    Button(action: toggleTimer) {
                        Text(isTimerRunning ? "pause".localized(comment: "Pause") : "start".localized(comment: "Start"))
                    }
                    .disabled(currentSet > nbSet)
                    Spacer()
                    Button("reset".localized(comment: "Reset")) {
                        resetValues(index: 1, isExerciseInterval: true)
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
            timeRemaining = realDuration
        }
        .onChange(of: duration) {
            timeRemaining = realDuration
        }
        .onChange(of: timeBeforeNextExercise) {
            timeRemaining = realDuration
        }
        .onChange(of: totalSets) { _, newValue in
            if newValue == 1 && !isTimeBased {
                isExerciseDone = true
            } else {
                isExerciseDone = false
            }
            timeRemaining = realDuration
        }
        .onChange(of: isTimeBased) { _, newValue in
            currentSet = (isTimeBased) ? (currentSet * 2) - 1 : (currentSet / 2) + 1
            isExerciseDone = (totalSets == 1 && !isTimeBased) || (currentSet == nbSet) ? true : false
            isExerciseInterval = newValue
            timeRemaining = realDuration
        }
        .onAppear {
            isExerciseDone = (totalSets == 1 && !isTimeBased) || (currentSet == nbSet) ? true : false
            timeRemaining = realDuration
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                isActive = true
                print("App became active")
                
                if isTimerRunning, let start = timeStarted {
                    let now = Date.now.timeIntervalSince1970 * 1000
                    let totalElapsed = (now - start) / 1000
                    let remaining = max(0, realDuration - totalElapsed - elapsed)
                    timeRemaining = remaining
                    restProgress = 1 - (CGFloat(timeRemaining.rounded(.down)) / CGFloat(realDuration.rounded(.up)))
                    print("Timer recalculated on foreground: \(timeRemaining)s remaining")
                }
            case .inactive:
                print("App became inactive")
            case .background:
                isActive = false
                print("App entered background")
            @unknown default:
                print("Unknown scene phase")
            }
        }
    }
    
    // MARK: - ViewBuilder functions
    
    @ViewBuilder
    private func progressBars() -> some View {
        GeometryReader { geometry in
            let needsScrolling = totalSets > 6
            let squareWidth: Double = {
                if needsScrolling {
                    return 35 // Fixed width when scrolling
                } else {
                    return geometry.size.width / CGFloat(2 * self.totalSets) // Scale to fit when not scrolling
                }
            }()
            
            if needsScrolling {
                ScrollView(.horizontal, showsIndicators: false) {
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
                                            resetValues(index: Int(index), isExerciseInterval: false)
                                        }
                                    }
                            } else {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(orange.opacity(0.3))
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        if !isTimerRunning {
                                            resetValues(index: Int(index), isExerciseInterval: false)
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
                                            resetValues(index: Int(index), isExerciseInterval: true)
                                        }
                                    }
                            } else {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(.accentColor.opacity(0.3))
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        if !isTimerRunning {
                                            resetValues(index: Int(index), isExerciseInterval: true)
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
                                            resetValues(index: Int((index + 1) / 2), isExerciseInterval: false)
                                        }
                                    }
                            } else {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(.accentColor.opacity(0.3))
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        if !isTimerRunning {
                                            resetValues(index: Int((index + 1) / 2), isExerciseInterval: false)
                                        }
                                    }
                            }
                        }
                        }
                    }
                }
                .frame(height: 20)
                }
                .frame(width: geometry.size.width, height: 20)
            } else {
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
                                                resetValues(index: Int(index), isExerciseInterval: false)
                                            }
                                        }
                                } else {
                                    Rectangle()
                                        .frame(width: squareWidth, height: 20)
                                        .foregroundColor(orange.opacity(0.3))
                                        .cornerRadius(4)
                                        .onTapGesture {
                                            if !isTimerRunning {
                                                resetValues(index: Int(index), isExerciseInterval: false)
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
                                                resetValues(index: Int(index), isExerciseInterval: true)
                                            }
                                        }
                                } else {
                                    Rectangle()
                                        .frame(width: squareWidth, height: 20)
                                        .foregroundColor(.accentColor.opacity(0.3))
                                        .cornerRadius(4)
                                        .onTapGesture {
                                            if !isTimerRunning {
                                                resetValues(index: Int(index), isExerciseInterval: true)
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
                                                resetValues(index: Int((index + 1) / 2), isExerciseInterval: false)
                                            }
                                        }
                                } else {
                                    Rectangle()
                                        .frame(width: squareWidth, height: 20)
                                        .foregroundColor(.accentColor.opacity(0.3))
                                        .cornerRadius(4)
                                        .onTapGesture {
                                            if !isTimerRunning {
                                                resetValues(index: Int((index + 1) / 2), isExerciseInterval: false)
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
    }
    
    // MARK: - Helper Functions
    
    private func resetValues(index: Int, isExerciseInterval: Bool) {
        timer?.cancel()
        timer = nil
        cancelPendingNotifications()
        isTimerRunning = false
        currentSet = index
        isExerciseDone = (currentSet == nbSet) ? true : false
        self.isExerciseInterval = isExerciseInterval
        timeRemaining = realDuration
        restProgress = 0
        timeStarted = nil
        elapsed = 0.0
        endBackgroundTask()
    }
    
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
        timeRemaining = max(0, realDuration - self.elapsed)
        cancelPendingNotifications()
        if sendNotification {
            scheduleNotification()
        }
        
        let queue: DispatchQueue = DispatchQueue(label: "com.jerroder.deadliftdiaries.timer", qos: .userInitiated)
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: .seconds(1))
        timer?.setEventHandler { [self] in
            DispatchQueue.main.async {
                let now: Double = Date.now.timeIntervalSince1970 * 1000
                let elapsedSinceStart: Double = max(0, now - (timeStarted ?? 0)) / 1000
                let totalElapsed: Double = elapsedSinceStart + self.elapsed // elapsed = accumulated paused time
                let remaining: Double = max(0, realDuration - totalElapsed)
                timeRemaining = remaining
                restProgress = 1 - (CGFloat(timeRemaining.rounded(.down)) / CGFloat(realDuration.rounded(.up)))
                
                if timeRemaining <= 0 {
                    toggleTimer()
                    
                    if isTimeBased {
                        isExerciseInterval.toggle()
                    }
                    
                    if currentSet < nbSet {
                        currentSet += 1
                        timeRemaining = realDuration
                        restProgress = 0
                        self.elapsed = 0.0
                    }
                    
                    if currentSet == nbSet && isExerciseDone {
                        currentSet += 1
                        if autoResetTimer && isCalledFromTimer {
                            resetValues(index: 1, isExerciseInterval: isTimeBased)
                        }
                    }
                    
                    if currentSet == nbSet {
                        isExerciseDone = true
                        timeRemaining = timeBeforeNextExercise
                    }
                    
                    if isTimeBased && !isExerciseDone {
                        if (isExerciseInterval && autoStartSetAfterRest) || (!isExerciseInterval && autoStartRestAfterSet) {
                            toggleTimer()
                        }
                    }
                } else if round(timeRemaining) == 1 {
                    if isActive {
                        playSystemSound()
                    }
                }
            }
        }
        timer?.resume()
    }
    
    private func stopTimer() {
        let now: Double = Date.now.timeIntervalSince1970 * 1000
        if let timeStarted = timeStarted {
            let elapsedSinceStart = max(0, now - timeStarted) / 1000
            elapsed += elapsedSinceStart
            timeRemaining = max(0, realDuration - elapsed)
        }
        timer?.cancel()
        timer = nil
        cancelPendingNotifications()
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
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "timer_is_up".localized(comment: "The timer is up")
        content.body = isExerciseInterval ? "exercise_is_over".localized(comment: "Exercise is over") : "rest_is_over".localized(comment: "Rest is over")
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeRemaining, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for \(timeRemaining) seconds from now.")
            }
        }
    }
    
    private func cancelPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
