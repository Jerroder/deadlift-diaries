/* Exercise
    Bench Press

WorkoutExercise
    Bench Press, 3 × 8 @ 80kg, 2:30 rest, position 1 in Upper A
*/

import SwiftData
import SwiftUI

@Model
final class WorkoutExercise {
    @Attribute(.unique)
    var id: UUID
    
    var order: Int
    
    var targetSets: Int
    var targetReps: Int
    
    var targetWeight: Double?
    var restSeconds: Int?
    
    var notes: String?
    
    // The global exercise this refers to
    var exercise: Exercise?
    
    // The workout template containing this exercise
    var workoutTemplate: WorkoutTemplate?
    
    init(
        exercise: Exercise,
        order: Int,
        targetSets: Int,
        targetReps: Int,
        targetWeight: Double? = nil,
        restSeconds: Int? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.exercise = exercise
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restSeconds = restSeconds
        self.notes = notes
    }
}
