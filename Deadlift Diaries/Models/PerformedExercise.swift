//
//  PerformedExercise.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-13.
//

/* Actual exercise that was performed */

import SwiftData
import Foundation

@Model
final class PerformedExercise {
    var id: UUID = UUID()
    
    // Snapshot from WorkoutExercise
    var exerciseName: String = ""
    var targetSets: Int = 0
    var targetReps: Int = 0
    var targetDistance: Int = 0
    var targetWeight: Double?
    
    var orderIndex: Int = 0
    
    var supersetID: UUID?
    var supersetPosition: SupersetPosition?
    
    @Relationship(inverse: \PerformedSet.performedExercise)
    var sets: [PerformedSet]? = []
    
    // Total time spent on this exercise
    var elapsed: Double = 0
    
    var beforeNextCompleted: Bool = false
    
    @Relationship(inverse: \WorkoutSession.exercises)
    var workoutSession: WorkoutSession?
    
    @Relationship
    var sourceExercise: WorkoutExercise?
    
    var isInSuperset: Bool {
        supersetID != nil
    }
    
    init(from workoutExercise: WorkoutExercise, orderIndex: Int) {
        let isDistanceBased = workoutExercise.exercise?.isDistanceBased ?? false
        
        self.exerciseName = workoutExercise.exercise?.name ?? "unknown".localized(comment: "Unknown")
        self.targetSets = workoutExercise.targetSets
        self.targetReps = workoutExercise.targetReps
        self.targetDistance = workoutExercise.targetDistance
        self.targetWeight = workoutExercise.targetWeight
        self.orderIndex = orderIndex
        
        self.supersetID = workoutExercise.supersetID
        self.supersetPosition = workoutExercise.supersetPosition
        
        self.sets = (0..<workoutExercise.targetSets).map { index in
            PerformedSet(
                setNumber: index + 1,
                weight: workoutExercise.targetWeight,
                reps: isDistanceBased ? nil : workoutExercise.targetReps,
                distance: isDistanceBased ? workoutExercise.targetDistance : nil
            )
        }
    }
    
    init(
        exerciseName: String,
        targetSets: Int,
        targetReps: Int,
        targetDistance: Int = 0,
        targetWeight: Double? = nil,
        orderIndex: Int,
        supersetID: UUID? = nil,
        supersetPosition: SupersetPosition? = nil,
        elapsed: Double = 0,
        beforeNextCompleted: Bool = false
    ) {
        self.exerciseName = exerciseName
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetDistance = targetDistance
        self.targetWeight = targetWeight
        self.orderIndex = orderIndex
        self.supersetID = supersetID
        self.supersetPosition = supersetPosition
        self.elapsed = elapsed
        self.beforeNextCompleted = beforeNextCompleted
        self.sets = []
    }
    
    func syncTargets(from workoutExercise: WorkoutExercise, modelContext: ModelContext) {
        let isDistanceBased = workoutExercise.exercise?.isDistanceBased ?? false
        
        exerciseName = workoutExercise.exercise?.name ?? exerciseName
        targetSets = workoutExercise.targetSets
        targetReps = workoutExercise.targetReps
        targetDistance = workoutExercise.targetDistance
        targetWeight = workoutExercise.targetWeight
        orderIndex = workoutExercise.order
        supersetID = workoutExercise.supersetID
        supersetPosition = workoutExercise.supersetPosition
        
        var currentSets = (sets ?? []).sorted { $0.setNumber < $1.setNumber }
        
        for set in currentSets {
            set.weight = workoutExercise.targetWeight
            set.reps = isDistanceBased ? nil : workoutExercise.targetReps
            set.distance = isDistanceBased ? workoutExercise.targetDistance : nil
        }
        
        if currentSets.count > workoutExercise.targetSets {
            for set in currentSets.suffix(currentSets.count - workoutExercise.targetSets) {
                sets?.removeAll { $0.id == set.id }
                modelContext.delete(set)
            }
            
            currentSets = Array(currentSets.prefix(workoutExercise.targetSets))
        } else if currentSets.count < workoutExercise.targetSets {
            for _ in 0..<(workoutExercise.targetSets - currentSets.count) {
                let newSet = PerformedSet(
                    setNumber: 0,
                    weight: workoutExercise.targetWeight,
                    reps: isDistanceBased ? nil : workoutExercise.targetReps,
                    distance: isDistanceBased ? workoutExercise.targetDistance : nil
                )
                
                sets?.append(newSet)
                currentSets.append(newSet)
            }
        }
        
        for (index, set) in currentSets.enumerated() {
            set.setNumber = index + 1
        }
    }
}
