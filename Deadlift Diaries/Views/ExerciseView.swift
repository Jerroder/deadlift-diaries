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
    @State private var selectedExerciseIDs = Set<Exercise.ID>()
    @State private var isShowingWorkoutPicker = false
    
    private let unit: String = isMetricSystem() ? "kg" : "lbs"
    
    private var availableWorkouts: [Workout] {
        guard let mesocycle = workout.week?.mesocycle else { return [] }
        return mesocycle.weeks.flatMap { $0.workouts }.filter { $0.id != workout.id }
    }
    
    var body: some View {
        NavigationStack {
            List(selection: $selectedExerciseIDs) {
                ForEach(workout.exercises.sorted { $0.orderIndex < $1.orderIndex }, id: \.id) { exercise in
                    exerciseRow(for: exercise)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) {
                                    workout.exercises.remove(at: index)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .tag(exercise.id)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(workout.name)
        .navigationBarBackButtonHidden(editMode?.wrappedValue.isEditing == true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                leadingToolbarItems
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                trailingToolbarItems
            }
        }
        .sheet(isPresented: $isShowingExerciseSheet) {
            addExerciseSheet
        }
        .sheet(isPresented: $isShowingWorkoutPicker) {
            workoutPickerSheet
        }
        .environment(\.editMode, Binding(
            get: { editMode?.wrappedValue ?? .inactive },
            set: { editMode?.wrappedValue = $0 }
        ))
    }
    
    @ViewBuilder
    private func exerciseRow(for exercise: Exercise) -> some View {
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
    
    @ViewBuilder
    private var leadingToolbarItems: some View {
        if editMode?.wrappedValue.isEditing == true {
            if !selectedExerciseIDs.isEmpty {
                Menu {
                    Button("Copy", systemImage: "document.on.document") {
                        isShowingWorkoutPicker = true
                    }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        deleteSelectedExercises()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    @ViewBuilder
    private var trailingToolbarItems: some View {
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
    
    @ViewBuilder
    private var addExerciseSheet: some View {
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
    
    @ViewBuilder
    private var workoutPickerSheet: some View {
        NavigationStack {
            let allWorkouts = workout.week?.mesocycle?.weeks.flatMap { $0.workouts } ?? []
            let targetWorkouts = allWorkouts.filter { $0.id != workout.id }
            
            List(targetWorkouts) { targetWorkout in
                Button(action: {
                    copyExercises(to: targetWorkout)
                    isShowingWorkoutPicker = false
                }) {
                    VStack(alignment: .leading) {
                        Text(targetWorkout.name)
                            .font(.headline)
                        Text("Week \(targetWorkout.week?.number ?? 0)")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
            }
            .navigationTitle("Copy to Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isShowingWorkoutPicker = false
                    }
                }
            }
        }
    }
    
    private func copyExercises(to targetWorkout: Workout) {
        let selectedExercises = workout.exercises.filter { selectedExerciseIDs.contains($0.id) }
        let maxOrderIndex = targetWorkout.exercises.map { $0.orderIndex }.max() ?? 0
        
        for (index, exercise) in selectedExercises.enumerated() {
            let newExercise = Exercise(
                name: exercise.name,
                weight: exercise.weight,
                sets: exercise.sets,
                reps: exercise.reps,
                duration: exercise.duration,
                restTime: exercise.restTime,
                isTimeBased: exercise.isTimeBased,
                orderIndex: maxOrderIndex + index + 1
            )
            targetWorkout.exercises.append(newExercise)
            newExercise.workout = targetWorkout
            modelContext.insert(newExercise)
        }
        selectedExerciseIDs.removeAll()
    }
    
    private func deleteSelectedExercises() {
        let exercisesToDelete = workout.exercises.filter { selectedExerciseIDs.contains($0.id) }
        for exercise in exercisesToDelete {
            modelContext.delete(exercise)
        }
        selectedExerciseIDs.removeAll()
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
                    Text("Duration: \(exercise.duration ?? 0) sec")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                } else {
                    Text("Weight: \(String(format: "%.1f", exercise.weight ?? 0)) \(unit)")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                Text("Sets: \(exercise.sets)")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                if !exercise.isTimeBased {
                    Text("Reps: \(exercise.reps ?? 0)")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                Text("Rest: \(exercise.restTime) sec")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            Spacer()
        }
    }
}
