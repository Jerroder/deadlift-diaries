import SwiftData
import Foundation

@Model
final class PerformedExercise {
    var id: UUID = UUID()
    
    // Snapshot from WorkoutExercise
    var exerciseName: String = ""
    var targetSets: Int = 0
    var targetReps: Int = 0
    var targetWeight: Double?
    
    var orderIndex: Int = 0
    
    @Relationship(inverse: \PerformedSet.performedExercise)
    var sets: [PerformedSet]? = []
    
    // Total time spent on this exercise
    var elapsed: Double = 0
    
    @Relationship(inverse: \WorkoutSession.exercises)
    var workoutSession: WorkoutSession?
    
    @Relationship
    var sourceExercise: WorkoutExercise?
    
    init(from workoutExercise: WorkoutExercise, orderIndex: Int) {
        self.exerciseName = workoutExercise.exercise?.name ?? "Unknown"
        self.targetSets = workoutExercise.targetSets
        self.targetReps = workoutExercise.targetReps
        self.targetWeight = workoutExercise.targetWeight
        self.orderIndex = orderIndex
        
        self.sets = (0..<workoutExercise.targetSets).map { index in
            PerformedSet(setNumber: index + 1, weight: workoutExercise.targetWeight, reps: workoutExercise.targetReps)
        }
    }
}
