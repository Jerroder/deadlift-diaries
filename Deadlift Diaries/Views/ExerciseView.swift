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
    
    @State private var selectedExercise: Exercise?
    @State private var isAddingNewExercise = false
    @State private var newExerciseName = ""
    @State private var newExerciseSets = 5
    @State private var newExerciseRestTime = 60
    @State private var newExerciseIsTimeBased = false
    @State private var newExerciseReps = 8
    @State private var newExerciseDuration = 30
    @State private var newExerciseWeight = 50.0
    @State private var selectedExerciseIDs = Set<Exercise.ID>()
    @State private var isShowingWorkoutPicker = false
    
    @State private var isKeyboardShowing = false
    @FocusState.Binding var isTextFieldFocused: Bool
    
    private let unit: Unit = isMetricSystem() ? Unit(symbol: "kg") : Unit(symbol: "lbs")
    
    private var availableWorkouts: [Workout] {
        guard let mesocycle = workout.week?.mesocycle else { return [] }
        return mesocycle.weeks.flatMap { $0.workouts }.filter { $0.id != workout.id }
    }
    
    private var sortedExercises: [Exercise] {
        workout.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        List(selection: $selectedExerciseIDs) {
            buildExerciseRows
        }
        .listStyle(.plain)
        .navigationTitle(workout.name)
        .navigationBarBackButtonHidden(editMode?.wrappedValue.isEditing == true)
        .onAppear {
            selectedExerciseIDs.removeAll()
        }
        .sheet(item: $selectedExercise) { exercise in
            exerciseEditSheet(exercise: exercise)
        }
        .sheet(isPresented: $isAddingNewExercise) {
            exerciseEditSheet(exercise: nil)
        }
        .sheet(isPresented: $isShowingWorkoutPicker) {
            workoutPickerSheet
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                leadingToolbarItems
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                trailingToolbarItems
            }
        }
        .environment(\.editMode, Binding(
            get: { editMode?.wrappedValue ?? .inactive },
            set: { editMode?.wrappedValue = $0 }
        ))
    }
    
    // MARK: - Computed Properties for Views
    
    @ViewBuilder
    private var buildExerciseRows: some View {
        ForEach(sortedExercises, id: \.id) { exercise in
            exerciseRow(for: exercise)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteExercise(exercise)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .tag(exercise.id)
        }
    }
    
    @ViewBuilder
    private func exerciseEditSheet(exercise: Exercise?) -> some View {
        NavigationStack {
            exerciseEditForm(exercise: exercise)
                .navigationTitle(exercise == nil ? "New Exercise" : "Edit Exercise")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("", systemImage: "checkmark") {
                            if exercise == nil {
                                let orderIndex = (workout.exercises.map { $0.orderIndex }.max() ?? 0) + 1
                                let exercise = Exercise(
                                    name: newExerciseName,
                                    weight: newExerciseIsTimeBased ? nil : newExerciseWeight,
                                    sets: newExerciseSets,
                                    reps: newExerciseIsTimeBased ? nil : newExerciseReps,
                                    duration: newExerciseIsTimeBased ? newExerciseDuration : nil,
                                    restTime: newExerciseRestTime,
                                    isTimeBased: newExerciseIsTimeBased,
                                    orderIndex: orderIndex
                                )
                                workout.exercises.append(exercise)
                                exercise.workout = workout
                                modelContext.insert(exercise)
                            }
                            selectedExercise = nil
                            isAddingNewExercise = false
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("", systemImage: "xmark") {
                            selectedExercise = nil
                            isAddingNewExercise = false
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private func exerciseEditForm(exercise: Exercise?) -> some View {
        Form {
            TextField("Exercise Name", text: exercise == nil ? $newExerciseName : Binding(
                get: { exercise!.name },
                set: { exercise!.name = $0 }
            ))
            .focused($isTextFieldFocused)
            
            Stepper(
                "Sets: \(exercise == nil ? newExerciseSets : exercise!.sets)",
                value: exercise == nil ? $newExerciseSets : Binding(
                    get: { exercise!.sets },
                    set: { exercise!.sets = $0 }
                ),
                in: 1...20
            )
            
            HStack {
                Text("Rest Time:")
                Picker("Rest Time", selection:
                        Binding(
                            get: { exercise == nil ? newExerciseRestTime : exercise!.restTime },
                            set: { newValue in
                                if exercise == nil {
                                    newExerciseRestTime = newValue
                                } else {
                                    exercise!.restTime = newValue
                                }
                            }
                        )
                ) {
                    ForEach(Array(stride(from: 5, through: 300, by: 5)), id: \.self) { time in
                        Text("\(time) sec").tag(time)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
            }
            
            Toggle("Time Based", isOn: Binding(
                get: { exercise == nil ? newExerciseIsTimeBased : exercise!.isTimeBased },
                set: { newValue in
                    withAnimation {
                        if exercise == nil {
                            newExerciseIsTimeBased = newValue
                        } else {
                            exercise!.isTimeBased = newValue
                        }
                    }
                }
            ))
            
            if exercise == nil ? newExerciseIsTimeBased : exercise!.isTimeBased {
                Stepper(
                    "Duration: \(exercise == nil ? newExerciseDuration : exercise!.duration ?? 30) sec",
                    value: exercise == nil ? $newExerciseDuration : Binding(
                        get: { exercise!.duration ?? 30 },
                        set: { exercise!.duration = $0 }
                    ),
                    in: 10...600,
                    step: 5
                )
            } else {
                Stepper(
                    "Reps: \(exercise == nil ? newExerciseReps : exercise!.reps ?? 10)",
                    value: exercise == nil ? $newExerciseReps : Binding(
                        get: { exercise!.reps ?? 10 },
                        set: { exercise!.reps = $0 }
                    ),
                    in: 1...50
                )
                
                HStack {
                    Text("Weight:")
                    TextFieldWithUnitDouble(
                        value: Binding(
                            get: { exercise?.weight ?? newExerciseWeight },
                            set: { newValue in
                                if exercise != nil {
                                    exercise!.weight = newValue
                                } else {
                                    newExerciseWeight = newValue
                                }
                            }
                        ),
                        unit: Binding(
                            get: { unit },
                            set: { _ in }
                        )
                    )
                    .keyboardType(.decimalPad)
                }
            }
        }
        .withTextFieldToolbar(isKeyboardShowing: $isKeyboardShowing, isTextFieldFocused: $isTextFieldFocused)
    }
    
    @ViewBuilder
    private func exerciseRow(for exercise: Exercise) -> some View {
        if editMode?.wrappedValue.isEditing == true {
            Button(action: {
                selectedExercise = exercise
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
        if editMode?.wrappedValue.isEditing == true, !selectedExerciseIDs.isEmpty {
            Menu {
                Button("Copy", systemImage: "document.on.document") {
                    isShowingWorkoutPicker = true
                }
                Button("Delete", systemImage: "trash", role: .destructive) {
                    deleteSelectedExercises()
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
    }
    
    @ViewBuilder
    private var trailingToolbarItems: some View {
        EditButton()
        Button("", systemImage: "plus", action: {
            isAddingNewExercise = true
            newExerciseName = ""
            newExerciseSets = 5
            newExerciseRestTime = 60
            newExerciseIsTimeBased = false
            newExerciseReps = 8
            newExerciseDuration = 30
            newExerciseWeight = 50.0
        })
    }
    
    @ViewBuilder
    private var workoutPickerSheet: some View {
        let allWorkouts = workout.week?.mesocycle?.weeks.flatMap { $0.workouts } ?? []
        let targetWorkouts = allWorkouts
            .filter { $0.id != workout.id }
            .sorted {
                guard let weekNumber1 = $0.week?.number,
                      let weekNumber2 = $1.week?.number else {
                    return $0.date < $1.date
                }
                if weekNumber1 != weekNumber2 {
                    return weekNumber1 < weekNumber2
                } else {
                    return $0.date < $1.date
                }
            }
        
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
    
    // MARK: - Helper Functions
    
    private func copyExercises(to targetWorkout: Workout) {
        let selectedExercises = workout.exercises
            .filter { selectedExerciseIDs.contains($0.id) }
            .sorted { $0.orderIndex < $1.orderIndex }
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
    
    private func deleteExercise(_ exercise: Exercise) {
        if let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) {
            workout.exercises.remove(at: index)
        }
    }
    
    private func deleteSelectedExercises() {
        let exercisesToDelete = workout.exercises.filter { selectedExerciseIDs.contains($0.id) }
        for exercise in exercisesToDelete {
            modelContext.delete(exercise)
        }
        selectedExerciseIDs.removeAll()
        try? modelContext.save()
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    let unit: Unit
    
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
                    Text("Weight: \(String(format: "%.1f", exercise.weight ?? 0)) \(unit.symbol)")
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
