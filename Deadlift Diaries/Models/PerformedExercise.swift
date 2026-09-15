import SwiftData
import SwiftUI

@Model
final class PerformedExercise {
    var id: UUID = UUID()
    var workoutExercise: WorkoutExercise?
    var orderIndex: Int = 0
    var sets: [PerformedSet]? = []
    var elapsed: Double = 0.0

    @Relationship(inverse: \WorkoutSession.exercises)
    var workoutSessions: [WorkoutSession]? = []

    init(workoutExercise: WorkoutExercise? = nil, orderIndex: Int = 0) {
        self.workoutExercise = workoutExercise
        self.orderIndex = orderIndex
    }
}
