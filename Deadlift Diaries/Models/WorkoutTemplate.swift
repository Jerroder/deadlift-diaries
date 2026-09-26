//
//  WorkoutTemplate.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-13.
//

/* WorkoutTemplate contains WorkoutExercises, not Exercises directly */

import SwiftData
import SwiftUI

@Model
final class WorkoutTemplate {
    var id: UUID = UUID()

    var name: String = ""
    var notes: String?

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var trainingBlock: TrainingBlock?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workoutTemplate)
    var exercises: [WorkoutExercise]? = []

    @Relationship(deleteRule: .cascade, inverse: \ScheduledWorkout.workoutTemplate)
    var scheduledWorkouts: [ScheduledWorkout]? = []

    @Relationship(inverse: \WorkoutSchedule.workoutTemplate)
    var workoutTemplates: [WorkoutSchedule]? = []

    init(name: String, notes: String? = nil) {
        self.name = name
        self.notes = notes
    }
}
