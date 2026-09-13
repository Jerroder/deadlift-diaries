// The WorkoutTemplate contains WorkoutExercises, not Exercises directly

import SwiftData
import SwiftUI

@Model
final class WorkoutTemplate {
    var id: UUID = UUID()

    var name: String = ""
    var notes: String = ""
    var colorHex: String?

    @Relationship(deleteRule: .cascade)
    var exercises: [WorkoutExercise] = []

    init(
        name: String,
        notes: String = "",
        colorHex: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.colorHex = colorHex
    }
}
