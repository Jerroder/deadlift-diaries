import SwiftData
import SwiftUI

@Model
final class PerformedSet {
    var id: UUID = UUID()

    var setNumber: Int = 1

    var weight: Double?
    var reps: Int?
    var duration: Double?
    var distance: Int?

    var completed: Bool = false

    var performedExercise: PerformedExercise?

    init(
        setNumber: Int,
        weight: Double? = nil,
        reps: Int? = nil,
        duration: Double? = nil,
        distance: Int? = nil
    ) {
        self.id = UUID()
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.duration = duration
        self.distance = distance
    }
}
