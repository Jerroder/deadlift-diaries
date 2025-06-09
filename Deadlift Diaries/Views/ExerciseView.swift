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
                    TextField("workout_name".localized(comment: "Workout Name"), text: $workout.name)
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
                        Text("done".localized(comment: "Done"))
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
        let newExercise = Exercise()
        withAnimation {
            workout.exercises.append(newExercise)
        }
        try? modelContext.save()
    }
}

struct DisplayExercises: View {
    @Bindable var exercise: Exercise

    @State private var weight: String = ""
    @State private var setNumber: String = ""
    @State private var repNumber: String = ""
    @State private var rest: String = ""
    
    var body: some View {
        VStack {
            TextField("exercise_name".localized(comment: "Exercise Name"), text: $exercise.name)
            HStack {
                Text("weight".localized(comment: "Weight"))
                TextField("0", text: $weight)
                    .keyboardType(.decimalPad)
                    .onChange(of: weight) { oldValue, newValue in
                        let filtered = newValue.filter { $0.isNumber || $0 == "." }
                        if filtered != newValue {
                            self.weight = filtered
                        }

                        if let numericValue = Int(filtered) {
                            exercise.weight = numericValue
                        }
                    }
                    .onAppear {
                        weight = (exercise.weight == 0) ? "" : String(exercise.weight)
                    }
                Text("weight_format".localized(comment: "kg"))
                    .padding(.leading, -200)
            }
            HStack {
                Text("sets".localized(comment: "Sets"))
                TextField("0", text: $setNumber)
                    .keyboardType(.decimalPad)
                    .onChange(of: setNumber) { oldValue, newValue in
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
                Text("reps".localized(comment: "Reps"))
                TextField("0", text: $repNumber)
                    .keyboardType(.decimalPad)
                    .onChange(of: repNumber) { oldValue, newValue in
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
            HStack {
                Text("rest".localized(comment: "Rest"))
                TextField("0", text: $rest)
                    .keyboardType(.decimalPad)
                    .onChange(of: rest) { oldValue, newValue in
                        let filtered = newValue.filter { $0.isNumber || $0 == "." }
                        if filtered != newValue {
                            self.rest = filtered
                        }

                        if let numericValue = Int(filtered) {
                            exercise.rest = numericValue
                        }
                    }
                    .onAppear {
                        rest = (exercise.rest == 0) ? "" : String(exercise.rest)
                    }
                Text("sec".localized(comment: "sec"))
                    .padding(.leading, -120)
            }
        }
    }
}
