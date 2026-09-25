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
    
    @State private var restTimer = RestTimerManager.shared
    
    init() {
        let isICouldEnabled = UserDefaults.standard.bool(forKey: "isICouldEnabled")
        do {
            container = try ModelContainer(
                for: Exercise.self, PerformedExercise.self, PerformedSet.self, ScheduledWorkout.self, TrainingBlock.self, WorkoutExercise.self, WorkoutSchedule.self, WorkoutSession.self, WorkoutTemplate.self,
                configurations: ModelConfiguration(
                    cloudKitDatabase: isICouldEnabled ? .automatic : .none
                )
            )
        } catch {
            fatalError("Failed to configure ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(restTimer)
        }
        .modelContainer(container)
    }
}
