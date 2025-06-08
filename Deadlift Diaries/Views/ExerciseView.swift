//
//  ExerciseView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData

struct ExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var workout: Workout

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Workout Name", text: $workout.name)
                }
                Section {
                    ForEach(workout.exercises.sorted { $0.creationDate < $1.creationDate }) { exercise in
                        DisplayExercises(exercise: exercise)
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: addExercise) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func addExercise() {
        let newExercise = Exercise(name: "wo name", description: "desc", sets: 4, reps: 8)
        withAnimation {
            workout.exercises.append(newExercise)
        }
        try? modelContext.save()
    }
}

struct DisplayExercises: View {
    @Bindable var exercise: Exercise
    
    var body: some View {
        Text("Exercise: \(exercise.name), Sets: \(exercise.sets), Reps: \(exercise.reps)")
    }
}
