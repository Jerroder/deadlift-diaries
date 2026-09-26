//
//  WorkoutExercise.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-13.
//

/* Exercise
    Bench Press

WorkoutExercise
    Bench Press, 3 x 8 @ 80kg, 2:30 rest, position 1 in Upper A */

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
                    if let session = following.session {
                        matchingCopy.removeFromSessionIfNeeded(session, modelContext: modelContext)
                    }
                    
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
                
                // If the following workout's session was already started before this edit,
                // make sure its performed exercises reflect the change too.
                if let session = following.session {
                    matchingCopy.addToSessionIfNeeded(session, modelContext: modelContext)
                    matchingCopy.syncSessionIfNeeded(session, modelContext: modelContext)
                }
            } else if let clone = makeCopy(for: following) {
                modelContext.insert(clone)
                following.exercises?.append(clone)
                
                if let session = following.session {
                    clone.addToSessionIfNeeded(session, modelContext: modelContext)
                }
            }
        }
    }
    
    func removeFromSuperset(modelContext: ModelContext) {
        guard let scheduledWorkout, let supersetID else {
            return
        }
        
        if let sibling = (scheduledWorkout.exercises ?? []).first(where: { $0.supersetID == supersetID && $0.id != id }) {
            sibling.supersetID = nil
            sibling.supersetPosition = nil
            
            sibling.propagateToFollowingWorkouts(deleted: false, modelContext: modelContext)
            sibling.syncOwnPerformedExercise(modelContext: modelContext)
        }
        
        propagateToFollowingWorkouts(deleted: true, modelContext: modelContext)
        removeFromOwnSessionIfNeeded(modelContext: modelContext)
        
        scheduledWorkout.exercises?.removeAll { $0.id == id }
        modelContext.delete(self)
    }
    
    // MARK: - Session Syncing
    
    private func performedExercise(in session: WorkoutSession) -> PerformedExercise? {
        performedExercises?.first { $0.workoutSession?.id == session.id }
    }
    
    private func addToSessionIfNeeded(_ session: WorkoutSession, modelContext: ModelContext) {
        guard performedExercise(in: session) == nil else {
            return
        }
        
        let performedExercise = PerformedExercise(from: self, orderIndex: order)
        performedExercise.sourceExercise = self
        performedExercise.workoutSession = session
        
        modelContext.insert(performedExercise)
        session.exercises?.append(performedExercise)
    }
    
    private func syncSessionIfNeeded(_ session: WorkoutSession, modelContext: ModelContext) {
        performedExercise(in: session)?.syncTargets(from: self, modelContext: modelContext)
    }
    
    private func removeFromSessionIfNeeded(_ session: WorkoutSession, modelContext: ModelContext) {
        guard let performed = performedExercise(in: session) else {
            return
        }
        
        modelContext.delete(performed)
    }
    
    private var ownPerformedExercise: PerformedExercise? {
        guard let session = scheduledWorkout?.session else {
            return nil
        }
        
        return performedExercise(in: session)
    }
    
    func syncOwnPerformedExercise(modelContext: ModelContext) {
        guard let session = scheduledWorkout?.session else {
            return
        }
        
        syncSessionIfNeeded(session, modelContext: modelContext)
    }
    
    func addToOwnSessionIfNeeded(modelContext: ModelContext) {
        guard let session = scheduledWorkout?.session else {
            return
        }
        
        addToSessionIfNeeded(session, modelContext: modelContext)
    }
    
    func removeFromOwnSessionIfNeeded(modelContext: ModelContext) {
        guard let session = scheduledWorkout?.session else {
            return
        }
        
        removeFromSessionIfNeeded(session, modelContext: modelContext)
    }
}
