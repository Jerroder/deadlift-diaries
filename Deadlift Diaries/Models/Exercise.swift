// "Bench Press" is an Exercise. Nothing more.

import SwiftData
import SwiftUI

@Model
final class Exercise {
    var id: UUID = UUID()

    var name: String = ""
    var isTimeBased: Bool = false
    var isDistanceBased: Bool = false

    var notes: String = ""

    @Relationship(inverse: \WorkoutExercise.exercise)
    var workoutExercises: [WorkoutExercise]? = []

    init(
        name: String,
        isTimeBased: Bool = false,
        isDistanceBased: Bool = false,
        notes: String = ""
    ) {
        self.name = name
        self.isTimeBased = isTimeBased
        self.isDistanceBased = isDistanceBased
        self.notes = notes
    }
}
