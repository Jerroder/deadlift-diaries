/* Exercise
    Bench Press

WorkoutExercise
    Bench Press, 3 × 8 @ 80kg, 2:30 rest, position 1 in Upper A
*/

import SwiftData
import SwiftUI

@Model
final class WorkoutExercise {
    var id: UUID = UUID()

    var exercise: Exercise?

    var orderIndex: Int = 0

    var weight: Double?
    var sets: Int = 3
    var reps: Int?
    var duration: Double?
    var distance: Int?

    var restTime: Double = 30
    var timeBeforeNext: Double = 120

    var supersetGroupID: UUID?

    var workout: WorkoutTemplate?

    init(
        exercise: Exercise? = nil,
        orderIndex: Int = 0,
        weight: Double? = nil,
        sets: Int = 3,
        reps: Int? = nil,
        duration: Double? = nil,
        distance: Int? = nil,
        restTime: Double = 30,
        timeBeforeNext: Double = 120,
        supersetGroupID: UUID? = nil
    ) {
        self.id = UUID()
        self.exercise = exercise
        self.orderIndex = orderIndex
        self.weight = weight
        self.sets = sets
        self.reps = reps
        self.duration = duration
        self.distance = distance
        self.restTime = restTime
        self.timeBeforeNext = timeBeforeNext
        self.supersetGroupID = supersetGroupID
    }
}
