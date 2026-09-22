//
//  RestTimerManager.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-22.
//

import Foundation
import Observation
import ActivityKit
import AVFAudio
import UserNotifications

@MainActor
@Observable
final class RestTimerManager {
    static let shared = RestTimerManager()
    
    // MARK: - Observable state
    
    private(set) var isResting = false
    private(set) var isPaused = false
    private(set) var remaining: Duration = .zero
    
    private(set) var currentSetIndex: Int = 0
    private(set) var totalSets: Int = 0
    
    // Unique identifier for the current rest session.
    private(set) var sessionID: UUID?
    private(set) var exerciseID: UUID?
    
    // MARK: - Private state
    
    private var restTask: Task<Void, Never>?
    
    private var restDuration: Duration = .zero
    private var selectedSoundID: Int = 1075
    
    private var timerActivity: Activity<TimerWidgetAttributes>?
    
    var onFinish: ((UUID, Int) -> Void)?
    
    private init() {}
    
    // MARK: - Start
    
    func start(
        exerciseID: UUID,
        setIndex: Int,
        totalSets: Int,
        duration: Duration,
        selectedSoundID: Int,
        sendNotification: Bool
    ) {
        stop()
        
        let sessionID = UUID()
        
        self.sessionID = sessionID
        self.exerciseID = exerciseID
        self.currentSetIndex = setIndex
        self.totalSets = totalSets
        self.restDuration = duration
        self.remaining = duration
        self.selectedSoundID = selectedSoundID
        
        isResting = true
        isPaused = false
        
        if sendNotification {
            scheduleNotification()
        }
        
        startLiveActivity()
        
        runTimer(sessionID: sessionID)
    }
    
    // MARK: - Pause
    
    func pause() {
        guard isResting, !isPaused else {
            return
        }
        
        isPaused = true
        
        restTask?.cancel()
        restTask = nil
        
        cancelPendingNotifications()
        updateLiveActivity()
    }
    
    // MARK: - Resume
    
    func resume(sendNotification: Bool) {
        guard isResting, isPaused else {
            return
        }
        
        guard let sessionID else {
            return
        }
        
        isPaused = false
        
        if sendNotification {
            scheduleNotification()
        }
        
        updateLiveActivity()
        runTimer(sessionID: sessionID)
    }
    
    // MARK: - Stop
    
    func stop() {
        restTask?.cancel()
        restTask = nil
        
        cancelPendingNotifications()
        endLiveActivity()
        
        isResting = false
        isPaused = false
        remaining = .zero
        
        sessionID = nil
        exerciseID = nil
    }
    
    // MARK: - Timer
    
    private func runTimer(sessionID: UUID) {
        restTask?.cancel()
        
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: remaining)
        
        restTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            
            while !Task.isCancelled {
                let now = clock.now
                let newRemaining = deadline - now
                
                if newRemaining <= .zero {
                    finish(sessionID: sessionID)
                    return
                }
                
                self.remaining = newRemaining
                
                do {
                    try await clock.sleep(
                        until: now.advanced(by: .milliseconds(100))
                    )
                } catch {
                    return
                }
            }
        }
    }
    
    // MARK: - Finish
    
    private func finish(sessionID: UUID) {
        guard self.sessionID == sessionID else {
            return
        }
        
        guard let exerciseID = self.exerciseID else {
            return
        }
        
        let finishedSetIndex = self.currentSetIndex
        let isLastSet = currentSetIndex >= totalSets - 1
        let completion = self.onFinish
        
        restTask?.cancel()
        restTask = nil
        
        cancelPendingNotifications()
        playSystemSound()
        
        isResting = false
        isPaused = false
        remaining = .zero
        
        self.sessionID = nil
        self.exerciseID = nil
        self.onFinish = nil
        
        if isLastSet {
            endLiveActivity()
        }
        
        completion?(exerciseID, finishedSetIndex)
    }
    
    // MARK: - Notifications
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "timer_is_up".localized(
            comment: "The timer is up"
        )
        content.body = "rest_is_over".localized(
            comment: "Rest is over"
        )
        content.sound = .default
        
        let seconds = max(
            1,
            Double(remaining.components.seconds) +
            Double(remaining.components.attoseconds) /
            1_000_000_000_000_000_000
        )
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: seconds,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "rest-timer",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print(
                    "Error scheduling notification: \(error.localizedDescription)"
                )
            }
        }
    }
    
    private func cancelPendingNotifications() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["rest-timer"]
            )
    }
    
    // MARK: - Sound
    
    private func playSystemSound() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(
                .ambient,
                options: .duckOthers
            )
            try audioSession.setActive(true)
        } catch {
            print(
                "Failed to set audio session category: \(error)"
            )
        }
        
        guard selectedSoundID != 0 else {
            try? audioSession.setActive(false)
            return
        }
        
        let soundID = selectedSoundID
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AudioServicesPlaySystemSound(UInt32(soundID))
        }
        
        let duration: Double = soundID == 1328 ? 2.0 : 1.0
        
        DispatchQueue.main.asyncAfter(
            deadline: .now() + duration
        ) {
            do {
                try audioSession.setActive(false)
            } catch {
                print(
                    "Failed to deactivate audio session: \(error)"
                )
            }
        }
    }
    
    // MARK: - Live Activity
    
    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        let attributes = TimerWidgetAttributes(
            timerType: "rest"
        )
        
        let now = Date()
        let duration = durationAsTimeInterval(remaining)
        let endTime = now.addingTimeInterval(duration)
        
        let contentState =
        TimerWidgetAttributes.ContentState(
            timeRemaining: duration,
            totalDuration: duration,
            currentSet: currentSetIndex + 1,
            totalSets: totalSets,
            isResting: true,
            isRunning: true,
            startTime: now,
            endTime: endTime
        )
        
        do {
            timerActivity = try Activity.request(
                attributes: attributes,
                content: .init(
                    state: contentState,
                    staleDate: endTime
                ),
                pushType: nil
            )
        } catch {
            print(
                "Error starting Live Activity: \(error.localizedDescription)"
            )
        }
    }
    
    private func updateLiveActivity() {
        guard let activity = timerActivity else {
            return
        }
        
        let duration = durationAsTimeInterval(remaining)
        let now = Date()
        let endTime = now.addingTimeInterval(duration)
        
        let state =
        TimerWidgetAttributes.ContentState(
            timeRemaining: duration,
            totalDuration: durationAsTimeInterval(restDuration),
            currentSet: currentSetIndex + 1,
            totalSets: totalSets,
            isResting: isResting,
            isRunning: !isPaused,
            startTime: isPaused ? nil : now,
            endTime: endTime
        )
        
        Task {
            await activity.update(
                ActivityContent(
                    state: state,
                    staleDate: endTime
                )
            )
        }
    }
    
    private func endLiveActivity() {
        guard let activity = timerActivity else {
            return
        }
        
        let state =
        TimerWidgetAttributes.ContentState(
            timeRemaining: 0,
            totalDuration: durationAsTimeInterval(restDuration),
            currentSet: currentSetIndex + 1,
            totalSets: totalSets,
            isResting: false,
            isRunning: false,
            startTime: nil,
            endTime: Date()
        )
        
        Task {
            await activity.end(
                ActivityContent(
                    state: state,
                    staleDate: nil
                ),
                dismissalPolicy: .immediate
            )
        }
        
        timerActivity = nil
    }
    
    private func durationAsTimeInterval(_ duration: Duration) -> TimeInterval {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
    }

}
