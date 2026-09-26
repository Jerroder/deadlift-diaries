//
//  WorkoutSession.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-13.
//

import SwiftData
import SwiftUI

@Model
final class WorkoutSession {
    var id: UUID = UUID()

    var startedAt: Date = Date()
    var completedAt: Date?

    var scheduledWorkout: ScheduledWorkout?

    @Relationship(deleteRule: .cascade)
    var exercises: [PerformedExercise]? = []

    init(scheduledWorkout: ScheduledWorkout? = nil) {
        self.id = UUID()
        self.scheduledWorkout = scheduledWorkout
    }
}
