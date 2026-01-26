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
    private static let timerSettingsMigrationKey = "hasPerformedTimerSettingsMigration"
    private static let templateMesocycleMigrationKey = "hasPerformedTemplateMesocycleMigration"
    private static let duplicateCleanupMigrationKey = "hasPerformedDuplicateCleanupMigration"
    
    static func migrateTimerSettings() {
        if UserDefaults.standard.bool(forKey: timerSettingsMigrationKey) {
            return
        }
        
        if UserDefaults.standard.object(forKey: "isContinuousModeEnabled") != nil {
            let oldValue = UserDefaults.standard.bool(forKey: "isContinuousModeEnabled")
            
            if oldValue {
                UserDefaults.standard.set(true, forKey: "autoStartSetAfterRest")
                UserDefaults.standard.set(true, forKey: "autoStartRestAfterSet")
            }
            
            UserDefaults.standard.removeObject(forKey: "isContinuousModeEnabled")
        }
        
        UserDefaults.standard.set(true, forKey: timerSettingsMigrationKey)
    }
    
    static func migrateTemplatesToMesocycles(modelContext: ModelContext) {
        if UserDefaults.standard.bool(forKey: templateMesocycleMigrationKey) {
            return
        }
        
        let templateDescriptor = FetchDescriptor<ExerciseTemplate>(
            predicate: #Predicate<ExerciseTemplate> { template in
                template.mesocycle == nil
            }
        )
        
        guard let orphanedTemplates = try? modelContext.fetch(templateDescriptor), !orphanedTemplates.isEmpty else {
            UserDefaults.standard.set(true, forKey: templateMesocycleMigrationKey)
            return
        }
        
        let mesocycleDescriptor = FetchDescriptor<Mesocycle>()
        guard let mesocycles = try? modelContext.fetch(mesocycleDescriptor), !mesocycles.isEmpty else {
            UserDefaults.standard.set(true, forKey: templateMesocycleMigrationKey)
            return
        }
        
        print("Migrating \(orphanedTemplates.count) templates to \(mesocycles.count) mesocycles")
        
        for (index, mesocycle) in mesocycles.enumerated() {
            var templateMapping: [UUID: ExerciseTemplate] = [:]
            
            for originalTemplate in orphanedTemplates {
                let newTemplate: ExerciseTemplate
                
                if index == 0 {
                    newTemplate = originalTemplate
                } else {
                    newTemplate = ExerciseTemplate(
                        name: originalTemplate.name,
                        defaultWeight: originalTemplate.defaultWeight,
                        defaultSets: originalTemplate.defaultSets,
                        defaultReps: originalTemplate.defaultReps,
                        defaultDuration: originalTemplate.defaultDuration,
                        defaultRestTime: originalTemplate.defaultRestTime,
                        isTimeBased: originalTemplate.isTimeBased,
                        isDistanceBased: originalTemplate.isDistanceBased,
                        defaultDistance: originalTemplate.defaultDistance,
                        timeBeforeNext: originalTemplate.timeBeforeNext,
                        supersetPartnerTemplateID: nil, // Will be set later
                        isTheSupersetTemplate: originalTemplate.isTheSupersetTemplate
                    )
                    modelContext.insert(newTemplate)
                }
                
                newTemplate.mesocycle = mesocycle
                templateMapping[originalTemplate.id] = newTemplate
            }
            
            for originalTemplate in orphanedTemplates {
                if let partnerID = originalTemplate.supersetPartnerTemplateID,
                   let newTemplate = templateMapping[originalTemplate.id],
                   let newPartner = templateMapping[partnerID] {
                    newTemplate.supersetPartnerTemplateID = newPartner.id
                }
            }
            
            if index > 0 {
                for originalTemplate in orphanedTemplates {
                    guard let newTemplate = templateMapping[originalTemplate.id],
                          let originalHistory = originalTemplate.history else {
                        continue
                    }
                    
                    for historyEntry in originalHistory {
                        let newHistory = ExerciseHistory(
                            date: historyEntry.date,
                            weight: historyEntry.weight,
                            reps: historyEntry.reps,
                            sets: historyEntry.sets,
                            duration: historyEntry.duration,
                            distance: historyEntry.distance
                        )
                        newHistory.template = newTemplate
                        modelContext.insert(newHistory)
                    }
                }
            }
        }
        
        do {
            try modelContext.save()
            UserDefaults.standard.set(true, forKey: templateMesocycleMigrationKey)
            print("Template to mesocycle migration completed successfully")
        } catch {
            print("Error during template migration: \(error)")
        }
    }
    
    static func cleanupDuplicateTemplates(modelContext: ModelContext) {
        if UserDefaults.standard.bool(forKey: duplicateCleanupMigrationKey) {
            return
        }
        
        let templateDescriptor = FetchDescriptor<ExerciseTemplate>()
        guard let allTemplates = try? modelContext.fetch(templateDescriptor) else {
            UserDefaults.standard.set(true, forKey: duplicateCleanupMigrationKey)
            return
        }
        
        let mesocycleDescriptor = FetchDescriptor<Mesocycle>()
        var targetMesocycle: Mesocycle?
        
        if let mesocycles = try? modelContext.fetch(mesocycleDescriptor), !mesocycles.isEmpty {
            targetMesocycle = mesocycles.first
        } else {
            let newMesocycle = Mesocycle(
                name: "Migrated Templates",
                startDate: Date(),
                numberOfWeeks: 4,
                orderIndex: 0
            )
            modelContext.insert(newMesocycle)
            targetMesocycle = newMesocycle
        }
        
        for template in allTemplates where template.mesocycle == nil {
            template.mesocycle = targetMesocycle
        }
        
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        if let allExercises = try? modelContext.fetch(exerciseDescriptor) {
            for exercise in allExercises where exercise.template == nil {
                let exerciseName = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                if let matchingTemplate = allTemplates.first(where: { 
                    $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == exerciseName 
                }) {
                    exercise.template = matchingTemplate
                }
            }
        }
        
        var regularTemplateGroups: [String: [ExerciseTemplate]] = [:]
        var supersetPairGroups: [String: [ExerciseTemplate]] = [:]
        
        for template in allTemplates {
            let normalizedName = template.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if normalizedName.isEmpty { continue }
            
            if template.supersetPartnerTemplateID != nil {
                if let partner = allTemplates.first(where: { $0.id == template.supersetPartnerTemplateID }) {
                    let mainName: String
                    let supersetName: String
                    
                    if template.isTheSupersetTemplate {
                        supersetName = normalizedName
                        mainName = partner.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    } else {
                        mainName = normalizedName
                        supersetName = partner.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    }
                    
                    let pairKey = "\(mainName)___\(supersetName)"
                    
                    if supersetPairGroups[pairKey] == nil {
                        supersetPairGroups[pairKey] = []
                    }
                    supersetPairGroups[pairKey]?.append(template)
                }
            } else {
                if regularTemplateGroups[normalizedName] == nil {
                    regularTemplateGroups[normalizedName] = []
                }
                regularTemplateGroups[normalizedName]?.append(template)
            }
        }
        
        var templatesToDelete: Set<UUID> = []
        
        for (_, duplicates) in regularTemplateGroups where duplicates.count > 1 {
            
            let sorted = duplicates.sorted { t1, t2 in
                let score1 = (t1.exercises?.count ?? 0) * 100 + (t1.history?.count ?? 0)
                let score2 = (t2.exercises?.count ?? 0) * 100 + (t2.history?.count ?? 0)
                return score1 > score2
            }
            
            guard let keepTemplate = sorted.first else { continue }
            let duplicatesToRemove = Array(sorted.dropFirst())
            
            for duplicate in duplicatesToRemove {
                if let exercises = duplicate.exercises {
                    for exercise in exercises {
                        exercise.template = keepTemplate
                    }
                }
                
                if let histories = duplicate.history {
                    var keeperHistoryDates = Set(keepTemplate.history?.map { Calendar.current.startOfDay(for: $0.date) } ?? [])
                    
                    for history in histories {
                        let historyDate = Calendar.current.startOfDay(for: history.date)
                        if !keeperHistoryDates.contains(historyDate) {
                            history.template = keepTemplate
                            keeperHistoryDates.insert(historyDate)
                        } else {
                            if let existingHistory = keepTemplate.history?.first(where: { Calendar.current.startOfDay(for: $0.date) == historyDate }) {
                                if let weight = history.weight, weight > (existingHistory.weight ?? 0) {
                                    existingHistory.weight = weight
                                }
                                if let reps = history.reps, reps > (existingHistory.reps ?? 0) {
                                    existingHistory.reps = reps
                                }
                                if history.sets > existingHistory.sets {
                                    existingHistory.sets = history.sets
                                }
                            }
                            modelContext.delete(history)
                        }
                    }
                }
                
                templatesToDelete.insert(duplicate.id)
            }
        }
        
        var processedSupersetTemplates: Set<UUID> = []
        
        for (_, templates) in supersetPairGroups {
            var pairs: [(main: ExerciseTemplate, superset: ExerciseTemplate)] = []
            
            for template in templates where !processedSupersetTemplates.contains(template.id) {
                if let partnerID = template.supersetPartnerTemplateID,
                   let partner = allTemplates.first(where: { $0.id == partnerID }),
                   !templatesToDelete.contains(template.id),
                   !templatesToDelete.contains(partner.id) {
                    
                    let main = template.isTheSupersetTemplate ? partner : template
                    let superset = template.isTheSupersetTemplate ? template : partner
                    
                    pairs.append((main: main, superset: superset))
                    processedSupersetTemplates.insert(template.id)
                    processedSupersetTemplates.insert(partner.id)
                }
            }
            
            if pairs.count > 1 {
                
                let sortedPairs = pairs.sorted { pair1, pair2 in
                    let mainExercises1 = pair1.main.exercises?.count ?? 0
                    let supersetExercises1 = pair1.superset.exercises?.count ?? 0
                    let mainHistory1 = pair1.main.history?.count ?? 0
                    let supersetHistory1 = pair1.superset.history?.count ?? 0
                    let score1 = mainExercises1 + supersetExercises1 + mainHistory1 + supersetHistory1
                    
                    let mainExercises2 = pair2.main.exercises?.count ?? 0
                    let supersetExercises2 = pair2.superset.exercises?.count ?? 0
                    let mainHistory2 = pair2.main.history?.count ?? 0
                    let supersetHistory2 = pair2.superset.history?.count ?? 0
                    let score2 = mainExercises2 + supersetExercises2 + mainHistory2 + supersetHistory2
                    
                    return score1 > score2
                }
                
                guard let keepPair = sortedPairs.first else { continue }
                let duplicatePairs = Array(sortedPairs.dropFirst())
                
                for duplicatePair in duplicatePairs {
                    if let exercises = duplicatePair.main.exercises {
                        for exercise in exercises {
                            exercise.template = keepPair.main
                        }
                    }
                    
                    if let histories = duplicatePair.main.history {
                        let keeperDates = keepPair.main.history?.map { Calendar.current.startOfDay(for: $0.date) } ?? [Date]()
                        var keeperHistoryDates = Set(keeperDates)
                        
                        for history in histories {
                            let historyDate = Calendar.current.startOfDay(for: history.date)
                            if !keeperHistoryDates.contains(historyDate) {
                                history.template = keepPair.main
                                keeperHistoryDates.insert(historyDate)
                            } else {
                                modelContext.delete(history)
                            }
                        }
                    }
                    
                    if let exercises = duplicatePair.superset.exercises {
                        for exercise in exercises {
                            exercise.template = keepPair.superset
                        }
                    }
                    
                    if let histories = duplicatePair.superset.history {
                        let keeperDates = keepPair.superset.history?.map { Calendar.current.startOfDay(for: $0.date) } ?? [Date]()
                        var keeperHistoryDates = Set(keeperDates)
                        
                        for history in histories {
                            let historyDate = Calendar.current.startOfDay(for: history.date)
                            if !keeperHistoryDates.contains(historyDate) {
                                history.template = keepPair.superset
                                keeperHistoryDates.insert(historyDate)
                            } else {
                                modelContext.delete(history)
                            }
                        }
                    }
                    
                    templatesToDelete.insert(duplicatePair.main.id)
                    templatesToDelete.insert(duplicatePair.superset.id)
                }
            }
        }
        
        for template in allTemplates where templatesToDelete.contains(template.id) {
            modelContext.delete(template)
        }
        
        do {
            try modelContext.save()
            UserDefaults.standard.set(true, forKey: duplicateCleanupMigrationKey)
        } catch {
            print("Error during duplicate cleanup: \(error)")
        }
    }
    
    static func performMigrationIfNeeded(modelContext: ModelContext) {
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
        
        var supersetGroups: [String: [Exercise]] = [:]
        var processedPairIDs: Set<String> = []
        
        for exercise in exercises where exercise.supersetPartnerID != nil {
            guard let partnerID = exercise.supersetPartnerID,
                  let partner = exercises.first(where: { $0.id == partnerID }) else {
                continue
            }
            
            let pairID = [exercise.id.uuidString, partnerID.uuidString].sorted().joined(separator: "_")
            guard !processedPairIDs.contains(pairID) else {
                continue
            }
            processedPairIDs.insert(pairID)
            
            let name1 = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let name2 = partner.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            let sortedNames = [name1, name2].sorted()
            let pairKey = "\(sortedNames[0])___\(sortedNames[1])"
            
            let mainExercise = exercise.isTheSuperset ?? false ? partner : exercise
            let supersetExercise = exercise.isTheSuperset ?? false ? exercise : partner
            
            if supersetGroups[pairKey] == nil {
                supersetGroups[pairKey] = []
            }
            supersetGroups[pairKey]?.append(mainExercise)
            supersetGroups[pairKey]?.append(supersetExercise)
        }
        
        for (_, exercisesInGroup) in supersetGroups {
            let sortedExercises = exercisesInGroup.sorted { exercise1, exercise2 in
                let date1 = exercise1.workout?.date ?? Date.distantPast
                let date2 = exercise2.workout?.date ?? Date.distantPast
                return date1 > date2
            }
            
            guard sortedExercises.count >= 2 else { continue }
            
            let mainExercise = sortedExercises.first { !($0.isTheSuperset ?? false) } ?? sortedExercises[0]
            let supersetExercise = sortedExercises.first { $0.isTheSuperset ?? false } ?? sortedExercises[1]
            
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
            
            for exercise in sortedExercises {
                if exercise.isTheSuperset ?? false {
                    exercise.template = supersetTemplate
                } else {
                    exercise.template = mainTemplate
                }
                processedExerciseIDs.insert(exercise.id)
            }
            
            var mainHistoryByDate: [Date: ExerciseHistory] = [:]
            var supersetHistoryByDate: [Date: ExerciseHistory] = [:]
            
            for exercise in sortedExercises {
                guard let workout = exercise.workout else { continue }
                let workoutDate = Calendar.current.startOfDay(for: workout.date)
                
                if exercise.isTheSuperset ?? false {
                    if supersetHistoryByDate[workoutDate] == nil {
                        let history = ExerciseHistory(
                            date: workoutDate,
                            weight: exercise.weight,
                            reps: exercise.reps,
                            sets: exercise.sets,
                            duration: exercise.duration,
                            distance: exercise.distance
                        )
                        history.template = supersetTemplate
                        modelContext.insert(history)
                        supersetHistoryByDate[workoutDate] = history
                    }
                } else {
                    if mainHistoryByDate[workoutDate] == nil {
                        let history = ExerciseHistory(
                            date: workoutDate,
                            weight: exercise.weight,
                            reps: exercise.reps,
                            sets: exercise.sets,
                            duration: exercise.duration,
                            distance: exercise.distance
                        )
                        history.template = mainTemplate
                        modelContext.insert(history)
                        mainHistoryByDate[workoutDate] = history
                    }
                }
            }
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
                processedExerciseIDs.insert(exercise.id)
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
        } catch {
            print("Error during migration: \(error)")
        }
    }
}
