// The WorkoutTemplate contains WorkoutExercises, not Exercises directly

import SwiftData
import SwiftUI

@Model
final class WorkoutTemplate {
    @Attribute(.unique)
    var id: UUID
    
    var name: String
    var notes: String?
    
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(
        deleteRule: .cascade,
        inverse: \WorkoutExercise.workoutTemplate
    )
    var exercises: [WorkoutExercise] = []
    
    @Relationship(
        deleteRule: .cascade,
        inverse: \ScheduledWorkout.workoutTemplate
    )
    var scheduledWorkouts: [ScheduledWorkout] = []
    
    init(
        name: String,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
