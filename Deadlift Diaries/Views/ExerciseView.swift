//
//  ExerciseView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData

func isMetricSystem() -> Bool {
    let locale = Locale.current
    switch locale.measurementSystem {
        case .metric:
            return true

        case .us: fallthrough
        case .uk:
            return false

        default:
            return false
    }
}

struct ExerciseView: View {
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    
    @State private var isShowingExerciseSheet = false
    @State private var selectedExercise: Exercise?
    @State private var exerciseName = ""
    @State private var exerciseSets = 5
    @State private var exerciseRestTime = 60
    @State private var exerciseIsTimeBased = false
    @State private var exerciseReps = 8
    @State private var exerciseDuration = 30
    @State private var exerciseWeight = 50.0
    
    private let unit: String = isMetricSystem() ? "kg" : "lbs"
    
    var body: some View {
        List {
            ForEach(workout.exercises.sorted { $0.orderIndex < $1.orderIndex }, id: \.id) { exercise in
                Section {
                    if editMode?.wrappedValue.isEditing == true {
                        Button(action: {
                            selectedExercise = exercise
                            exerciseName = exercise.name
                            exerciseSets = exercise.sets
                            exerciseRestTime = exercise.restTime
                            exerciseIsTimeBased = exercise.isTimeBased
                            exerciseReps = exercise.reps ?? 10
                            exerciseDuration = exercise.duration ?? 30
                            exerciseWeight = exercise.weight ?? 0.0
                            isShowingExerciseSheet = true
                        }) {
                            ExerciseRow(exercise: exercise, unit: unit)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        ExerciseRow(exercise: exercise, unit: unit)
                            .contentShape(Rectangle())
                    }
                }
            }
            .onDelete(perform: deleteExercises)
        }
        .navigationTitle(workout.name)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                EditButton()
                
                Button("", systemImage: "plus", action: {
                    selectedExercise = nil
                    exerciseName = ""
                    exerciseSets = 3
                    exerciseRestTime = 60
                    exerciseIsTimeBased = false
                    exerciseReps = 10
                    exerciseDuration = 30
                    exerciseWeight = 0.0
                    isShowingExerciseSheet = true
                })
            }
        }
        .sheet(isPresented: $isShowingExerciseSheet) {
            NavigationStack {
                Form {
                    TextField("Exercise Name", text: $exerciseName)
                        .withTextFieldToolbar()
                    Stepper("Sets: \(exerciseSets)", value: $exerciseSets, in: 1...20)
                    Stepper("Rest Time (sec): \(exerciseRestTime)", value: $exerciseRestTime, in: 10...300, step: 10)
                    Toggle("Time Based", isOn: $exerciseIsTimeBased)
                    if exerciseIsTimeBased {
                        Stepper("Duration (sec): \(exerciseDuration)", value: $exerciseDuration, in: 10...600, step: 10)
                    } else {
                        Stepper("Reps: \(exerciseReps)", value: $exerciseReps, in: 1...50)
                        Stepper("Weight (\(unit)): \(exerciseWeight, specifier: "%.1f")", value: $exerciseWeight, in: 0...200, step: 2.5)
                    }
                }
                .navigationTitle(selectedExercise == nil ? "New Exercise" : "Edit Exercise")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("", systemImage: "checkmark") {
                            if let exercise = selectedExercise {
                                exercise.name = exerciseName
                                exercise.sets = exerciseSets
                                exercise.restTime = exerciseRestTime
                                exercise.isTimeBased = exerciseIsTimeBased
                                exercise.reps = exerciseIsTimeBased ? nil : exerciseReps
                                exercise.duration = exerciseIsTimeBased ? exerciseDuration : nil
                                exercise.weight = exerciseIsTimeBased ? nil : exerciseWeight
                            } else {
                                let orderIndex = (workout.exercises.map { $0.orderIndex }.max() ?? 0) + 1
                                let exercise = Exercise(
                                    name: exerciseName,
                                    weight: exerciseIsTimeBased ? nil : exerciseWeight,
                                    sets: exerciseSets,
                                    reps: exerciseIsTimeBased ? nil : exerciseReps,
                                    duration: exerciseIsTimeBased ? exerciseDuration : nil,
                                    restTime: exerciseRestTime,
                                    isTimeBased: exerciseIsTimeBased,
                                    orderIndex: orderIndex
                                )
                                workout.exercises.append(exercise)
                                exercise.workout = workout
                                modelContext.insert(exercise)
                            }
                            isShowingExerciseSheet = false
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("", systemImage: "xmark") {
                            isShowingExerciseSheet = false
                        }
                    }
                }
            }
        }
        .environment(\.editMode, Binding(
            get: { editMode?.wrappedValue ?? .inactive },
            set: { editMode?.wrappedValue = $0 }
        ))
    }
    
    private func deleteExercises(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(workout.exercises[index])
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    let unit: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exercise.name)
                    .font(.headline)
                if exercise.isTimeBased {
                    Text("Duration: \(exercise.duration ?? 0) sec, Sets: \(exercise.sets), Rest: \(exercise.restTime) sec")
                } else {
                    Text("Weight: \(String(format: "%.1f", exercise.weight ?? 0)) \(unit), Sets: \(exercise.sets), Reps: \(exercise.reps ?? 0), Rest: \(exercise.restTime) sec")
                }
            }
            Spacer()
        }
    }
}
