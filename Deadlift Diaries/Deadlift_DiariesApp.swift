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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Mesocycle.self, Week.self, Workout.self, Exercise.self])
    }
}
