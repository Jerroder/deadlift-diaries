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
    var targetDistance: Int = 0

    var targetWeight: Double?
    var restSeconds: Int?

    var timeBeforeNext: Int?

    var notes: String?

    // The global exercise this refers to
    var exercise: Exercise?
    
    var workoutTemplate: WorkoutTemplate?
    
    var scheduledWorkout: ScheduledWorkout?
    
    var lineageID: UUID = UUID()
    
    @Relationship(inverse: \PerformedExercise.sourceExercise)
    var performedExercises: [PerformedExercise]? = []
    
    var isInSuperset: Bool {
        supersetID != nil
    }

    init(exercise: Exercise, order: Int, targetSets: Int, targetReps: Int, targetDistance: Int = 0,
         targetWeight: Double? = nil, restSeconds: Int? = nil, timeBeforeNext: Int? = nil, notes: String? = nil,
         supersetID: UUID? = nil, supersetPosition: SupersetPosition? = nil) {
        self.exercise = exercise
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetDistance = targetDistance
        self.targetWeight = targetWeight
        self.restSeconds = restSeconds
        self.timeBeforeNext = timeBeforeNext
        self.notes = notes
        self.supersetID = supersetID
        self.supersetPosition = supersetPosition
    }
    
    func makeCopy(for scheduledWorkout: ScheduledWorkout) -> WorkoutExercise? {
        guard let exercise else {
            return nil
        }
        
        let copy = WorkoutExercise(
            exercise: exercise,
            order: order,
            targetSets: targetSets,
            targetReps: targetReps,
            targetDistance: targetDistance,
            targetWeight: targetWeight,
            restSeconds: restSeconds,
            timeBeforeNext: timeBeforeNext,
            notes: notes,
            supersetID: supersetID,
            supersetPosition: supersetPosition
        )
        
        copy.scheduledWorkout = scheduledWorkout
        copy.lineageID = lineageID
        
        return copy
    }
    
    func propagateToFollowingWorkouts(deleted: Bool, modelContext: ModelContext) {
        guard let scheduledWorkout,
              let workoutTemplate = scheduledWorkout.workoutTemplate else {
            return
        }
        
        let followingWorkouts = (workoutTemplate.scheduledWorkouts ?? []).filter {
            $0.id != scheduledWorkout.id && $0.scheduledDate > scheduledWorkout.scheduledDate
        }
        
        for following in followingWorkouts {
            let matchingCopy = (following.exercises ?? []).first { $0.lineageID == lineageID }
            
            if deleted {
                if let matchingCopy {
                    following.exercises?.removeAll { $0.id == matchingCopy.id }
                    modelContext.delete(matchingCopy)
                }
                
                continue
            }
            
            if let matchingCopy {
                matchingCopy.exercise = exercise
                matchingCopy.order = order
                matchingCopy.targetSets = targetSets
                matchingCopy.targetReps = targetReps
                matchingCopy.targetDistance = targetDistance
                matchingCopy.targetWeight = targetWeight
                matchingCopy.restSeconds = restSeconds
                matchingCopy.timeBeforeNext = timeBeforeNext
                matchingCopy.supersetID = supersetID
                matchingCopy.supersetPosition = supersetPosition
            } else if let clone = makeCopy(for: following) {
                modelContext.insert(clone)
                following.exercises?.append(clone)
            }
        }
    }
    
    private var ownPerformedExercise: PerformedExercise? {
        guard let session = scheduledWorkout?.session else {
            return nil
        }
        
        return performedExercises?.first { $0.workoutSession?.id == session.id }
    }
    
    func syncOwnPerformedExercise(modelContext: ModelContext) {
        ownPerformedExercise?.syncTargets(from: self, modelContext: modelContext)
    }
    
    func addToOwnSessionIfNeeded(modelContext: ModelContext) {
        guard let session = scheduledWorkout?.session, ownPerformedExercise == nil else {
            return
        }
        
        let performedExercise = PerformedExercise(from: self, orderIndex: order)
        performedExercise.sourceExercise = self
        performedExercise.workoutSession = session
        
        modelContext.insert(performedExercise)
        session.exercises?.append(performedExercise)
    }
    
    func removeFromOwnSessionIfNeeded(modelContext: ModelContext) {
        guard let performed = ownPerformedExercise else {
            return
        }
        
        modelContext.delete(performed)
    }
}
