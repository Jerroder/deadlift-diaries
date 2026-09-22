//
//  TimerLiveActivityManager.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-22.
//

import ActivityKit
import Foundation

@MainActor
final class TimerLiveActivityManager {
    static let shared = TimerLiveActivityManager()
    
    private(set) var activity: Activity<TimerWidgetAttributes>?
    private(set) var sessionID: UUID?
    
    private init() {
        // Recover an existing activity if the app process was recreated.
        activity = Activity<TimerWidgetAttributes>.activities.first
    }
    
    var isActive: Bool {
        activity != nil
    }
    
    func start(
        sessionID: UUID,
        currentSet: Int,
        totalSets: Int,
        restSeconds: Int
    ) async {
        // Starting a new rest always means there can only be one
        // timer Live Activity.
        await endCurrent()
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        let attributes = TimerWidgetAttributes(timerType: "rest")
        
        let now = Date()
        let endTime = now.addingTimeInterval(TimeInterval(restSeconds))
        
        let state = TimerWidgetAttributes.ContentState(
            timeRemaining: TimeInterval(restSeconds),
            totalDuration: TimeInterval(restSeconds),
            currentSet: currentSet,
            totalSets: totalSets,
            isResting: true,
            isRunning: true,
            startTime: now,
            endTime: endTime
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(
                    state: state,
                    staleDate: endTime
                ),
                pushType: nil
            )
            
            self.activity = activity
            self.sessionID = sessionID
            
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    func update(
        sessionID: UUID,
        currentSet: Int,
        totalSets: Int,
        restSeconds: Int,
        isResting: Bool,
        isRunning: Bool
    ) async {
        guard self.sessionID == sessionID,
              let activity else {
            return
        }
        
        let now = Date()
        let endTime = now.addingTimeInterval(TimeInterval(restSeconds))
        
        let state = TimerWidgetAttributes.ContentState(
            timeRemaining: TimeInterval(restSeconds),
            totalDuration: TimeInterval(restSeconds),
            currentSet: currentSet,
            totalSets: totalSets,
            isResting: isResting,
            isRunning: isRunning,
            startTime: isRunning ? now : nil,
            endTime: endTime
        )
        
        await activity.update(
            ActivityContent(
                state: state,
                staleDate: endTime
            )
        )
    }
    
    func end(sessionID: UUID) async {
        guard self.sessionID == sessionID,
              let activity else {
            return
        }
        
        let state = TimerWidgetAttributes.ContentState(
            timeRemaining: 0,
            totalDuration: 0,
            currentSet: 0,
            totalSets: 0,
            isResting: false,
            isRunning: false,
            startTime: nil,
            endTime: Date()
        )
        
        await activity.end(
            ActivityContent(
                state: state,
                staleDate: nil
            ),
            dismissalPolicy: .immediate
        )
        
        self.activity = nil
        self.sessionID = nil
    }
    
    func endCurrent() async {
        guard let activity else {
            return
        }
        
        let state = TimerWidgetAttributes.ContentState(
            timeRemaining: 0,
            totalDuration: 0,
            currentSet: 0,
            totalSets: 0,
            isResting: false,
            isRunning: false,
            startTime: nil,
            endTime: Date()
        )
        
        await activity.end(
            ActivityContent(
                state: state,
                staleDate: nil
            ),
            dismissalPolicy: .immediate
        )
        
        self.activity = nil
        self.sessionID = nil
    }
}
