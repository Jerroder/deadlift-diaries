import SwiftData
import SwiftUI

@Model
final class PerformedExercise {
    var id: UUID = UUID()

    var workoutExercise: WorkoutExercise?

    var orderIndex: Int = 0

    var sets: [PerformedSet] = []

    var elapsed: Double = 0

    init(
        workoutExercise: WorkoutExercise? = nil,
        orderIndex: Int = 0
    ) {
        self.id = UUID()
        self.workoutExercise = workoutExercise
        self.orderIndex = orderIndex
    }
}
