//
//  ContentView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-24.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        TabView {
            MesocycleView(isTextFieldFocused: $isTextFieldFocused).tabItem {
                Image(systemName: "calendar")
                Text("cycles".localized(comment: "Cycles"))
            }

            TimerView().tabItem {
                Image(systemName: "timer")
                Text("timer".localized(comment: "Timer"))
            }
        }
    }
}

@MainActor
extension ModelContainer {
    static func preview(with objects: [any PersistentModel]) -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Mesocycle.self, Week.self, Workout.self, Exercise.self, configurations: config)
        
        objects.forEach { container.mainContext.insert($0) }
        
        return container
    }
}

#Preview {
    @MainActor func makePreview() -> some View {
        let exercise1 = Exercise(name: "Deadlift", weight: 150, sets: 5, reps: 8, restTime: 120, isTimeBased: false, orderIndex: 1, timeBeforeNext: 75.0)
        let exercise2 = Exercise(name: "Plank", weight: 10, sets: 5, duration: 60, restTime: 60, isTimeBased: true, orderIndex: 2, timeBeforeNext: 150.0)
        let exercise3 = Exercise(name: "Bench Press", weight: 110, sets: 5, reps: 8, restTime: 80, isTimeBased: false, orderIndex: 3, timeBeforeNext: 30.0)
        let sampleWorkout1 = Workout(name: "Workout 1", orderIndex: 1)
        sampleWorkout1.exercises.append(exercise1)
        sampleWorkout1.exercises.append(exercise2)
        sampleWorkout1.exercises.append(exercise3)
        let sampleWeek = Week(number: 1, startDate: Date.now)
        sampleWeek.workouts.append(sampleWorkout1)
        let sampleMesocycle = Mesocycle(name: "Hypertrophy", startDate: Date.now, numberOfWeeks: 0, orderIndex: 1)
        sampleMesocycle.weeks.append(sampleWeek)
        
        let allObjects: [any PersistentModel] = [exercise1, exercise2, exercise3, sampleWorkout1, sampleWeek, sampleMesocycle]
        let container = ModelContainer.preview(with: allObjects)
        
        return ContentView()
            .modelContainer(container)
    }
    return makePreview()
}
