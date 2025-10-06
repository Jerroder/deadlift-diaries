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
        let isICouldEnabled = UserDefaults.standard.bool(forKey: "isICouldEnabled")
        do {
            container = try ModelContainer(
                for: Mesocycle.self,
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
        }
        .modelContainer(for: [Mesocycle.self, Week.self, Workout.self, Exercise.self])
    }
}
