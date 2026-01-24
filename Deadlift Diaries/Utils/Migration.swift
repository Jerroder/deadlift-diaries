//
//  Migration.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-01-24.
//

import Foundation
import SwiftData

@MainActor
class MigrationManager {
    private static let migrationKey = "hasPerformedExerciseTemplateMigration"
    
    static func performMigrationIfNeeded(modelContext: ModelContext) {
        // Check if migration has already been performed
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }
        
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.template == nil
            }
        )
        
        guard let exercises = try? modelContext.fetch(descriptor) else {
            return
        }
        
        if exercises.isEmpty {
            UserDefaults.standard.set(true, forKey: migrationKey)
            return
        }
        
        var processedExerciseIDs: Set<UUID> = []
        var templates: [String: ExerciseTemplate] = [:]
        
        for exercise in exercises where exercise.supersetPartnerID != nil && !processedExerciseIDs.contains(exercise.id) {
            guard let partnerID = exercise.supersetPartnerID,
                  let partner = exercises.first(where: { $0.id == partnerID }),
                  !processedExerciseIDs.contains(partnerID) else {
                continue
            }
            
            let mainExercise = exercise.isTheSuperset ?? false ? partner : exercise
            let supersetExercise = exercise.isTheSuperset ?? false ? exercise : partner
            
            let mainTemplate = ExerciseTemplate(
                name: mainExercise.name.trimmingCharacters(in: .whitespacesAndNewlines),
                defaultWeight: mainExercise.weight,
                defaultSets: mainExercise.sets > 0 ? mainExercise.sets : 5,
                defaultReps: mainExercise.reps,
                defaultDuration: mainExercise.duration,
                defaultRestTime: mainExercise.restTime > 0 ? mainExercise.restTime : 30.0,
                isTimeBased: mainExercise.isTimeBased,
                isDistanceBased: mainExercise.isDistanceBased ?? false,
                defaultDistance: mainExercise.distance,
                timeBeforeNext: mainExercise.timeBeforeNext > 0 ? mainExercise.timeBeforeNext : 120.0
            )
            
            let supersetTemplate = ExerciseTemplate(
                name: supersetExercise.name.trimmingCharacters(in: .whitespacesAndNewlines),
                defaultWeight: supersetExercise.weight,
                defaultSets: supersetExercise.sets,
                defaultReps: supersetExercise.reps,
                defaultDuration: supersetExercise.duration,
                defaultRestTime: supersetExercise.restTime,
                isTimeBased: supersetExercise.isTimeBased,
                isDistanceBased: supersetExercise.isDistanceBased ?? false,
                defaultDistance: supersetExercise.distance,
                timeBeforeNext: supersetExercise.timeBeforeNext,
                supersetPartnerTemplateID: nil,
                isTheSupersetTemplate: true
            )
            
            mainTemplate.supersetPartnerTemplateID = supersetTemplate.id
            supersetTemplate.supersetPartnerTemplateID = mainTemplate.id
            
            modelContext.insert(mainTemplate)
            modelContext.insert(supersetTemplate)
            
            mainExercise.template = mainTemplate
            supersetExercise.template = supersetTemplate
            
            if let workout = mainExercise.workout {
                let workoutDate = Calendar.current.startOfDay(for: workout.date)
                let history = ExerciseHistory(
                    date: workoutDate,
                    weight: mainExercise.weight,
                    reps: mainExercise.reps,
                    sets: mainExercise.sets,
                    duration: mainExercise.duration,
                    distance: mainExercise.distance
                )
                history.template = mainTemplate
                modelContext.insert(history)
            }
            
            if let workout = supersetExercise.workout {
                let workoutDate = Calendar.current.startOfDay(for: workout.date)
                let history = ExerciseHistory(
                    date: workoutDate,
                    weight: supersetExercise.weight,
                    reps: supersetExercise.reps,
                    sets: supersetExercise.sets,
                    duration: supersetExercise.duration,
                    distance: supersetExercise.distance
                )
                history.template = supersetTemplate
                modelContext.insert(history)
            }
            
            processedExerciseIDs.insert(mainExercise.id)
            processedExerciseIDs.insert(supersetExercise.id)
        }
        
        var exerciseGroups: [String: [Exercise]] = [:]
        
        for exercise in exercises where !processedExerciseIDs.contains(exercise.id) {
            let normalizedName = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if normalizedName.isEmpty {
                continue
            }
            
            if exerciseGroups[normalizedName] == nil {
                exerciseGroups[normalizedName] = []
            }
            exerciseGroups[normalizedName]?.append(exercise)
        }
        
        for (normalizedName, exerciseList) in exerciseGroups {
            let sortedExercises = exerciseList.sorted { exercise1, exercise2 in
                let score1 = (exercise1.weight != nil ? 1 : 0) + (exercise1.reps != nil ? 1 : 0) + (exercise1.sets > 0 ? 1 : 0)
                let score2 = (exercise2.weight != nil ? 1 : 0) + (exercise2.reps != nil ? 1 : 0) + (exercise2.sets > 0 ? 1 : 0)
                return score1 > score2
            }
            
            guard let representativeExercise = sortedExercises.first else { continue }
            
            let originalName = representativeExercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let template = ExerciseTemplate(
                name: originalName,
                defaultWeight: representativeExercise.weight,
                defaultSets: representativeExercise.sets > 0 ? representativeExercise.sets : 5,
                defaultReps: representativeExercise.reps,
                defaultDuration: representativeExercise.duration,
                defaultRestTime: representativeExercise.restTime > 0 ? representativeExercise.restTime : 30.0,
                isTimeBased: representativeExercise.isTimeBased,
                isDistanceBased: representativeExercise.isDistanceBased ?? false,
                defaultDistance: representativeExercise.distance,
                timeBeforeNext: representativeExercise.timeBeforeNext > 0 ? representativeExercise.timeBeforeNext : 120.0
            )
            
            modelContext.insert(template)
            templates[normalizedName] = template
            
            for exercise in exerciseList {
                exercise.template = template
            }
            
            var historyByDate: [Date: ExerciseHistory] = [:]
            
            for exercise in exerciseList {
                guard let workout = exercise.workout else { continue }
                let workoutDate = Calendar.current.startOfDay(for: workout.date)
                
                if historyByDate[workoutDate] == nil {
                    let history = ExerciseHistory(
                        date: workoutDate,
                        weight: exercise.weight,
                        reps: exercise.reps,
                        sets: exercise.sets,
                        duration: exercise.duration,
                        distance: exercise.distance
                    )
                    history.template = template
                    if template.history == nil {
                        template.history = []
                    }
                    template.history!.append(history)
                    modelContext.insert(history)
                    historyByDate[workoutDate] = history
                } else {
                    if let existingHistory = historyByDate[workoutDate] {
                        if exercise.weight != nil && (existingHistory.weight == nil || exercise.weight! > existingHistory.weight!) {
                            existingHistory.weight = exercise.weight
                        }
                        if exercise.reps != nil && (existingHistory.reps == nil || exercise.reps! > existingHistory.reps!) {
                            existingHistory.reps = exercise.reps
                        }
                        if exercise.sets > existingHistory.sets {
                            existingHistory.sets = exercise.sets
                        }
                    }
                }
            }
        }
        
        do {
            try modelContext.save()
            UserDefaults.standard.set(true, forKey: migrationKey)
            print("Exercise template migration completed successfully")
        } catch {
            print("Error during migration: \(error)")
        }
    }
}
