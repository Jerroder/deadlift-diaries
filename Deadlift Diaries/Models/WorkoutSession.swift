//
//  WorkoutSession.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-13.
//

/* A ScheduledWorkout becomes a WorkoutSession when it's opened and started */

import SwiftData
import SwiftUI

@Model
final class WorkoutSession {
    var id: UUID = UUID()

    var startedAt: Date = Date()
    var completedAt: Date?

    // Workout duration timer: only persisted once the first exercise's timer is started.
    var isTimerCommitted: Bool = false
    var timerElapsed: Double = 0
    var timerResumedAt: Date?
    
    // In-memory only: runs from when the workout is opened until the timer is committed.
    @Transient var provisionalTimerStart: Date?

    var scheduledWorkout: ScheduledWorkout?

    @Relationship(deleteRule: .cascade)
    var exercises: [PerformedExercise]? = []
    
    func isFirstExercise(_ exercise: PerformedExercise) -> Bool {
        let first = (exercises ?? []).min {
            if $0.orderIndex != $1.orderIndex {
                return $0.orderIndex < $1.orderIndex
            }
            
            return ($0.supersetPosition?.rawValue ?? 0) < ($1.supersetPosition?.rawValue ?? 0)
        }
        
        return first?.id == exercise.id
    }
    
    func timerElapsedSeconds(at now: Date) -> Double {
        if !isTimerCommitted {
            return provisionalTimerStart.map { now.timeIntervalSince($0) } ?? 0
        }
        
        return timerElapsed + (timerResumedAt.map { now.timeIntervalSince($0) } ?? 0)
    }
    
    func commitTimer(at now: Date = Date()) {
        guard !isTimerCommitted else {
            return
        }
        
        let start = provisionalTimerStart ?? now
        
        provisionalTimerStart = nil
        isTimerCommitted = true
        startedAt = start
        timerElapsed = 0
        timerResumedAt = completedAt == nil ? start : nil
    }
    
    func pauseTimer(at now: Date = Date()) {
        guard let timerResumedAt else {
            return
        }
        
        timerElapsed += now.timeIntervalSince(timerResumedAt)
        self.timerResumedAt = nil
    }
    
    func resumeTimer(at now: Date = Date()) {
        guard isTimerCommitted, completedAt == nil, timerResumedAt == nil else {
            return
        }
        
        timerResumedAt = now
    }
    
    func resetTimer(at now: Date = Date()) {
        isTimerCommitted = false
        timerElapsed = 0
        timerResumedAt = nil
        completedAt = nil
        provisionalTimerStart = now
    }
    
    func markCompleted(at now: Date = Date()) {
        guard completedAt == nil else {
            return
        }
        
        commitTimer(at: now)
        
        pauseTimer(at: now)
        completedAt = now
    }
    
    func markIncomplete(at now: Date = Date()) {
        guard completedAt != nil else {
            return
        }
        
        completedAt = nil
        resumeTimer(at: now)
    }
    
    var isCompleted: Bool {
        guard let exercises, !exercises.isEmpty else {
            return false
        }
        
        return exercises.allSatisfy(\.isCompleted)
    }

    init(scheduledWorkout: ScheduledWorkout? = nil) {
        self.id = UUID()
        self.scheduledWorkout = scheduledWorkout
    }
}
