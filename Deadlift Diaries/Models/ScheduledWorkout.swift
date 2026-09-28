//
//  ScheduledWorkout.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-13.
//

/* CalendarView is literally a collection of ScheduledWorkout */

import SwiftData
import SwiftUI

@Model
final class ScheduledWorkout {
    var id: UUID = UUID()
    var scheduledDate: Date = Date()
    var notes: String?
    var createdAt: Date = Date()

    // The template to use
    var workoutTemplate: WorkoutTemplate?
    
    // The recurring WorkoutSchedule that generated this occurrence, if any.
    var schedule: WorkoutSchedule?
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.scheduledWorkout)
    var exercises: [WorkoutExercise]? = []

    // If this scheduled workout has been started/completed
    var session: WorkoutSession?
    
    var isCompleted: Bool {
        session?.isCompleted ?? false
    }

    init(scheduledDate: Date, workoutTemplate: WorkoutTemplate) {
        self.scheduledDate = scheduledDate
        self.workoutTemplate = workoutTemplate
        self.createdAt = Date()
    }
    
    func pruneScheduleIfOrphaned(modelContext: ModelContext) {
        guard let schedule else {
            return
        }
        
        let remaining = (schedule.scheduledWorkouts ?? []).filter { $0.id != id }
        
        if remaining.isEmpty {
            modelContext.delete(schedule)
        }
    }
}
