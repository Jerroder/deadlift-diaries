//
//  SetProgressView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-18.
//

import SwiftUI
import AVFAudio
import ActivityKit

struct RestBox: View {
    let restDuration: Double
    let remaining: Duration
    let isActive: Bool
    let isCompleted: Bool
    
    private let restColor = Color(red: 0xFF / 255, green: 0xBC / 255, blue: 0x8E / 255)
    
    var body: some View {
        TimelineView(.animation) { _ in
            GeometryReader { geo in
                let progress: Double = {
                    if isCompleted {
                        return 1
                    }
                    
                    guard isActive else {
                        return 0
                    }
                    
                    let components = remaining.components
                    let remainingSeconds = Double(components.seconds) +
                    Double(components.attoseconds) / 1_000_000_000_000_000_000
                    
                    return min(max(1 - remainingSeconds / restDuration, 0), 1)
                }()
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(restColor.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(restColor)
                        .frame(width: geo.size.width * progress)
                }
            }
        }
    }
}

struct SetProgressView: View {
    @Bindable var exercise: PerformedExercise
    
    @State private var currentSetIndex: Int = 0
    @State private var isResting: Bool = false
    @State private var isPaused: Bool = false
    @State private var restRemaining: Duration
    @State private var restStartDate: Date?
    @State private var restTask: Task<Void, Never>?
    
    @AppStorage("sendNotification") private var sendNotification: Bool = false
    @AppStorage("selectedSoundID") private var selectedSoundID: Int = 1075
    
    private let liveActivityManager = TimerLiveActivityManager.shared
    @State private var restSessionID = UUID()
    
    private var sets: [PerformedSet] {
        (exercise.sets ?? []).sorted { $0.setNumber < $1.setNumber }
    }
    
    private var restDuration: Int {
        exercise.sourceExercise?.restSeconds ?? 60
    }
    
    private var completedRestIndex: Int {
        sets.firstIndex(where: { !$0.completed }) ?? sets.count
    }
    
    private var restSeconds: Int {
        Int(restRemaining.components.seconds)
    }
    
    private var restTimeString: String {
        let totalSeconds = max(0, restSeconds)
        
        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        }
        
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    init(exercise: PerformedExercise) {
        self.exercise = exercise
        self._restRemaining = State(
            initialValue: .seconds(exercise.sourceExercise?.restSeconds ?? 60)
        )
    }
    
    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let segmentCount = sets.count * 2 - 1
                let spacing: CGFloat = 6
                let totalSpacing = CGFloat(segmentCount - 1) * spacing
                let segmentWidth = (geo.size.width - totalSpacing) / CGFloat(segmentCount)
                
                HStack(spacing: spacing) {
                    ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                        Button {
                            skipToSet(index)
                        } label: {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(set.completed ? Color.accentColor : Color.accentColor.opacity(0.3))
                                .frame(width: segmentWidth, height: 20)
                        }
                        .buttonStyle(.plain)
                        
                        if index < sets.count - 1 {
                            RestBox(
                                restDuration: Double(restDuration),
                                remaining: restRemaining,
                                isActive: index == currentSetIndex && isResting,
                                isCompleted: index < completedRestIndex - 1
                            )
                            .frame(width: segmentWidth, height: 20)
                        }
                    }
                }
            }
            .frame(height: 20)
            
            Text("remaining_x".localized(with: restTimeString, comment: "Remaining: x"))
                .font(.title)
            
            if #available(iOS 26.0, *) {
                restButton()
                    .buttonStyle(.glassProminent)
            } else {
                restButton()
                    .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            completeCurrentSet()
            currentSetIndex = completedRestIndex - 1
            if completedRestIndex == sets.count {
                restRemaining = .seconds(0)
            }
        }
//        .onDisappear {
//            restTask?.cancel()
//            restTask = nil
//        }
    }
    
    @ViewBuilder
    private func restButton() -> some View {
        if isResting {
            Button(isPaused ? "Resume" : "Pause") {
                if isPaused { // Resume
                    isPaused = false
                    runRestTimer()
                } else { // Pause
                    isPaused = true
                    restTask?.cancel()
                    restTask = nil
                    cancelPendingNotifications()
                }
            }
        } else {
            Button("Start rest") {
                startRest()
            }
            .disabled(completedRestIndex >= sets.count)
        }
    }
    
    private func skipToSet(_ index: Int) {
        guard sets.indices.contains(index) else {
            return
        }
        
        restTask?.cancel()
        restTask = nil
        
        cancelPendingNotifications()
        restRemaining = .seconds(restDuration)
        
        withTransaction(Transaction(animation: nil)) {
            isResting = false
            restSessionID = UUID()
            restStartDate = nil
            currentSetIndex = index
            
            for (i, set) in sets.enumerated() {
                set.completed = i <= index
            }
        }
        
        if completedRestIndex == sets.count {
            restRemaining = .seconds(0)
        }
    }
    
    private func completeCurrentSet() {
        guard sets.indices.contains(currentSetIndex) else {
            return
        }
        
        sets[currentSetIndex].completed = true
    }
    
    private func startRest() {
        restTask?.cancel()
        restTask = nil
        
        cancelPendingNotifications()
        
        restSessionID = UUID()
        
        isResting = true
        isPaused = false
        restRemaining = .seconds(restDuration)
        
        runRestTimer()
    }
    
    private func runRestTimer() {
        if sendNotification {
            scheduleNotification()
        }
        
        let sessionID = restSessionID
        
        Task {
            await liveActivityManager.start(
                sessionID: sessionID,
                currentSet: currentSetIndex + 1,
                totalSets: sets.count,
                restSeconds: restSeconds
            )
        }
        
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: restRemaining)
        
        restTask = Task { @MainActor in
            while !Task.isCancelled {
                let now = clock.now
                let newRemaining = deadline - now
                
                if newRemaining <= .zero {
                    finishRest(sessionID: sessionID)
                    break
                }
                
                restRemaining = newRemaining
                
                do {
                    try await clock.sleep(
                        until: now.advanced(by: .milliseconds(100))
                    )
                } catch {
                    break
                }
            }
        }
    }
    
    private func finishRest(sessionID: UUID) {
        restTask?.cancel()
        restTask = nil
        
        cancelPendingNotifications()
        playSystemSound()
        
        restRemaining = .seconds(restDuration)
        isResting = false
        restStartDate = nil
        
        currentSetIndex += 1
        completeCurrentSet()
        
        if completedRestIndex == sets.count {
            Task {
                await liveActivityManager.end(sessionID: sessionID)
            }
            
            restRemaining = .seconds(0)
        }
    }
    
    // MARK: - Notification Functions
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "timer_is_up".localized(comment: "The timer is up")
        content.body = "rest_is_over".localized(comment: "Rest is over")
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(restSeconds), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for \(restRemaining) seconds from now.")
            }
        }
    }
    
    private func cancelPendingNotifications() {
        print("Cancelling next notification.")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
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
