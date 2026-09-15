//
//  Deadlift_DiariesApp.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-24.
//

import SwiftData
import SwiftUI

@main
struct Deadlift_DiariesApp: App {
    let container: ModelContainer

    init() {
//        MigrationManager.migrateTimerSettings()

//        let isICouldEnabled = UserDefaults.standard.bool(forKey: "isICouldEnabled")
        let isICouldEnabled = false
        do {
            container = try ModelContainer(
                for: Exercise.self, PerformedExercise.self, PerformedSet.self, ScheduledWorkout.self, TrainingBlock.self, WorkoutExercise.self, WorkoutSession.self, WorkoutTemplate.self,
                configurations: ModelConfiguration(
                    cloudKitDatabase: isICouldEnabled ? .automatic : .none
                )
            )

//            MigrationManager.performMigrationIfNeeded(modelContext: container.mainContext)
//            MigrationManager.migrateTemplatesToMesocycles(modelContext: container.mainContext)
//            MigrationManager.cleanupDuplicateTemplates(modelContext: container.mainContext)
        } catch {
            fatalError("Failed to configure ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Exercise.self, PerformedExercise.self, PerformedSet.self, ScheduledWorkout.self, TrainingBlock.self, WorkoutExercise.self, WorkoutSchedule.self, WorkoutSession.self, WorkoutTemplate.self])
    }
}
