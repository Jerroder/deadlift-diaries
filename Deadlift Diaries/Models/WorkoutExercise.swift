/* Exercise
    Bench Press

WorkoutExercise
    Bench Press, 3 x 8 @ 80kg, 2:30 rest, position 1 in Upper A
*/

import SwiftData
import SwiftUI

enum SupersetPosition: Int, Codable {
    case first
    case second
}

@Model
final class WorkoutExercise: Identifiable {
    var id: UUID = UUID()

    var order: Int = 0
    
    var supersetID: UUID?
    var supersetPosition: SupersetPosition?

    var targetSets: Int = 0
    var targetReps: Int = 0

    var targetWeight: Double?
    var restSeconds: Int?

    var timeBeforeNext: Int?

    var notes: String?

    // The global exercise this refers to
    var exercise: Exercise?

    // The workout template containing this exercise
    var workoutTemplate: WorkoutTemplate?
    
    @Relationship(inverse: \PerformedExercise.sourceExercise)
    var performedExercises: [PerformedExercise]? = []
    
    var isInSuperset: Bool {
        supersetID != nil
    }

    init(exercise: Exercise, order: Int, targetSets: Int, targetReps: Int,
         targetWeight: Double? = nil, restSeconds: Int? = nil, timeBeforeNext: Int? = nil, notes: String? = nil,
         supersetID: UUID? = nil, supersetPosition: SupersetPosition? = nil) {
        self.exercise = exercise
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restSeconds = restSeconds
        self.timeBeforeNext = timeBeforeNext
        self.notes = notes
        self.supersetID = supersetID
        self.supersetPosition = supersetPosition
    }
}
