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
    
    @FocusState private var isWorkoutNameFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Workout Name", text: $workout.name)
                        .focused($isWorkoutNameFocused)
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
        .onAppear {
            isWorkoutNameFocused = workout.name.isEmpty // only focus the TextField if workout.name is empty
        }
    }
    
    private func addExercise() {
        let newExercise = Exercise(name: "", description: "desc")
        withAnimation {
            workout.exercises.append(newExercise)
        }
        try? modelContext.save()
    }
}

struct DisplayExercises: View {
    @Bindable var exercise: Exercise

    @State private var setNumber: String = ""
    @State private var repNumber: String = ""
    
    var body: some View {
        VStack {
            TextField("Exercise Name", text: $exercise.name)
            HStack {
                Text("Sets")
                TextField("0", text: $setNumber)
                    .keyboardType(.decimalPad)
                    .onChange(of: setNumber) { oldValue, newValue in
                        // Filter the input to ensure it's a valid number
                        let filtered = newValue.filter { $0.isNumber || $0 == "." }
                        if filtered != newValue {
                            self.setNumber = filtered
                        }

                        if let numericValue = Int(filtered) {
                            exercise.sets = numericValue
                        }
                    }
                    .onAppear {
                        setNumber = (exercise.sets == 0) ? "" : String(exercise.sets)
                    }
            }
            HStack {
                Text("Reps")
                TextField("0", text: $repNumber)
                    .keyboardType(.decimalPad)
                    .onChange(of: repNumber) { oldValue, newValue in
                        // Filter the input to ensure it's a valid number
                        let filtered = newValue.filter { $0.isNumber || $0 == "." }
                        if filtered != newValue {
                            self.repNumber = filtered
                        }

                        if let numericValue = Int(filtered) {
                            exercise.reps = numericValue
                        }
                    }
                    .onAppear {
                        repNumber = (exercise.reps == 0) ? "" : String(exercise.reps)
                    }
            }
        }
    }
}
