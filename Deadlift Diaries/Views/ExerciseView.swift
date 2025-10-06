//
//  ExerciseView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData

struct ExerciseView: View {
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    
    @State private var selectedExercise: Exercise?
    @State private var isAddingNewExercise: Bool = false
    @State private var newExerciseName: String = ""
    @State private var newExerciseSets: Int = 5
    @State private var newExerciseRestTime: Double = 60.0
    @State private var newExerciseIsTimeBased: Bool = false
    @State private var newExerciseReps: Int = 8
    @State private var newExerciseDuration: Double = 30.0
    @State private var newExerciseWeight: Double = 50.0
    @State private var newExerciseTimeBeforeNext: Double = 120.0
    @State private var selectedExerciseIDs: Set<UUID> = Set<Exercise.ID>()
    @State private var isShowingWorkoutPicker: Bool = false
    @State private var expandedExerciseID: UUID?
    @State private var showingRestPicker: Bool = false
    @State private var showingDurationPicker: Bool = false
    @State private var showingTimeBeforeNextPicker: Bool = false
    
    @State private var isKeyboardShowing: Bool = false
    @FocusState.Binding var isTextFieldFocused: Bool
    
    @State private var isTimerRunning: [UUID: Bool] = [:]
    
    private let unit: Unit = isMetricSystem() ? Unit(symbol: "kg") : Unit(symbol: "lbs")
    
    private var availableWorkouts: [Workout] {
        guard let mesocycle = workout.week?.mesocycle else { return [] }
        return mesocycle.weeks!.flatMap { $0.workouts! }.filter { $0.id != workout.id }
    }
    
    private var sortedExercises: [Exercise] {
        workout.exercises!.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    // MARK: - ViewBuilder variables
    
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
    
    var body: some View {
        exerciseRow()
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
                workoutPickerSheet()
            }
            .onChange(of: isAddingNewExercise) {
                showingRestPicker = false
                showingDurationPicker = false
                showingTimeBeforeNextPicker = false
            }
            .onChange(of: selectedExercise) {
                showingRestPicker = false
                showingDurationPicker = false
                showingTimeBeforeNextPicker = false
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    leadingToolbarItems()
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
    
    // MARK: - ViewBuilder functions
    
    @ViewBuilder
    private func exerciseRow() -> some View {
        List(selection: $selectedExerciseIDs) {
            ForEach(sortedExercises, id: \.id) { exercise in
                displayExercise(for: exercise)
                    .tag(exercise.id)
                    .opacity(((exercise.isTimeBased ? exercise.sets * 2 : exercise.sets) == exercise.currentSet - 1) ? 0.5 : 1)
            }
        }
    }
    
    @ViewBuilder
    private func displayExercise(for exercise: Exercise) -> some View {
        Group {
            if editMode?.wrappedValue.isEditing == true {
                Button(action: {
                    selectedExercise = exercise
                }) {
                    displayExercises(exercise: exercise, unit: unit)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                displayExercises(exercise: exercise, unit: unit)
                    .onTapGesture {
                        withAnimation {
                            if expandedExerciseID == exercise.id {
                                expandedExerciseID = nil
                            } else {
                                expandedExerciseID = exercise.id
                            }
                        }
                    }
                
                if expandedExerciseID == exercise.id {
                    ProgressBarView(
                        totalSets: exercise.sets,
                        currentSet: Binding(
                            get: { exercise.currentSet },
                            set: { exercise.currentSet = $0 }
                        ),
                        restDuration: exercise.restTime,
                        timeBeforeNextExercise: exercise.timeBeforeNext,
                        isTimerRunning: Binding(
                            get: { isTimerRunning[exercise.id] ?? false },
                            set: { isTimerRunning[exercise.id] = $0 }
                        ),
                        elapsed: Binding(
                            get: { exercise.elapsed },
                            set: { exercise.elapsed = $0 }
                        ),
                        isTimeBased: exercise.isTimeBased,
                        duration: exercise.duration ?? 30.0
                    )
                    .transition(.opacity)
                }
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteExercise(exercise)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    @ViewBuilder
    private func displayExercises(exercise: Exercise, unit: Unit) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exercise.name)
                    .font(.headline)
                
                if exercise.isTimeBased {
                    Text("Duration: \(Int(exercise.duration ?? 0)) sec")
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
                
                Text("Rest: \(Int(exercise.restTime)) sec")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            Spacer()
        }
        .contentShape(Rectangle())
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
                                let orderIndex: Int = (workout.exercises!.map { $0.orderIndex }.max() ?? 0) + 1
                                let exercise: Exercise = Exercise(
                                    name: newExerciseName,
                                    weight: newExerciseIsTimeBased ? nil : newExerciseWeight,
                                    sets: newExerciseSets,
                                    reps: newExerciseIsTimeBased ? nil : newExerciseReps,
                                    duration: newExerciseIsTimeBased ? newExerciseDuration : nil,
                                    restTime: newExerciseRestTime,
                                    isTimeBased: newExerciseIsTimeBased,
                                    orderIndex: orderIndex,
                                    timeBeforeNext: newExerciseTimeBeforeNext
                                )
                                workout.exercises!.append(exercise)
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
            TextField("Exercise name", text: exercise == nil ? $newExerciseName : Binding(
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
            
            Button(action: {
                withAnimation {
                    showingRestPicker.toggle()
                    showingDurationPicker = false
                    showingTimeBeforeNextPicker = false
                }
            }) {
                HStack {
                    HStack(spacing: 4) {
                        Text("Rest duration")
                        Text("  \(Int(exercise == nil ? newExerciseRestTime : exercise!.restTime))s ")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Image(systemName: showingRestPicker ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .fixedSize()
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if showingRestPicker {
                Picker("Rest duration", selection: Binding(
                    get: { exercise == nil ? newExerciseRestTime : exercise!.restTime },
                    set: { newValue in
                        if exercise == nil {
                            newExerciseRestTime = newValue
                        } else {
                            exercise!.restTime = newValue
                        }
                    }
                )) {
                    ForEach(Array(stride(from: 5.0, through: 300.0, by: 5.0)), id: \.self) { duration in
                        Text("\(Int(duration)) seconds").tag(duration)
                    }
                }
                .pickerStyle(.wheel)
            }
            
            Toggle("Time based", isOn: Binding(
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
                Button(action: {
                    withAnimation {
                        showingDurationPicker.toggle()
                        showingRestPicker = false
                        showingTimeBeforeNextPicker = false
                    }
                }) {
                    HStack {
                        Text("Exercise duration")
                        Text(" \(Int((exercise == nil ? newExerciseDuration : exercise!.duration) ?? 30.0))s")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Image(systemName: showingDurationPicker ? "chevron.up" : "chevron.down")
                            .font(.caption)
                        Spacer()
                    }
                    .fixedSize()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if showingDurationPicker {
                    Picker("Exercise duration", selection: Binding(
                        get: { (exercise == nil ? newExerciseDuration : exercise!.duration) ?? 30.0 },
                        set: { newValue in
                            if exercise == nil {
                                newExerciseDuration = newValue
                            } else {
                                exercise!.duration = newValue
                            }
                        }
                    )) {
                        ForEach(Array(stride(from: 5.0, through: 600.0, by: 5.0)), id: \.self) { duration in
                            Text("\(Int(duration)) seconds").tag(duration)
                        }
                    }
                    .pickerStyle(.wheel)
                }
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
            
            Button(action: {
                withAnimation {
                    showingTimeBeforeNextPicker.toggle()
                    showingRestPicker = false
                    showingDurationPicker = false
                }
            }) {
                HStack {
                    Text("Time before next exercise")
                    Text(" \(Int(exercise == nil ? newExerciseTimeBeforeNext : exercise!.timeBeforeNext))s")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Image(systemName: showingTimeBeforeNextPicker ? "chevron.up" : "chevron.down")
                        .font(.caption)
                    Spacer()
                }
                .fixedSize()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if showingTimeBeforeNextPicker {
                Picker("Time before next exercise", selection: Binding(
                    get: { exercise == nil ? newExerciseTimeBeforeNext : exercise!.timeBeforeNext },
                    set: { newValue in
                        if exercise == nil {
                            newExerciseTimeBeforeNext = newValue
                        } else {
                            exercise!.timeBeforeNext = newValue
                        }
                    }
                )) {
                    ForEach(Array(stride(from: 5.0, through: 300.0, by: 5.0)), id: \.self) { duration in
                        Text("\(Int(duration)) seconds").tag(duration)
                    }
                }
                .pickerStyle(.wheel)
            }
        }
        .withTextFieldToolbar(isKeyboardShowing: $isKeyboardShowing, isTextFieldFocused: $isTextFieldFocused)
    }
    
    @ViewBuilder
    private func leadingToolbarItems() -> some View {
        if editMode?.wrappedValue.isEditing == true {
            Menu {
                if selectedExerciseIDs.isEmpty {
                    Button(action: {
                        selectedExerciseIDs = Set(workout.exercises!.map { $0.id })
                    }) {
                        Label("Select all", systemImage: "checkmark.circle.fill")
                    }
                } else {
                    Button("Copy", systemImage: "document.on.document") {
                        isShowingWorkoutPicker = true
                    }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        deleteSelectedExercises()
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
    }
    
    @ViewBuilder
    private func workoutPickerSheet() -> some View {
        let allWorkouts: [Workout] = workout.week?.mesocycle?.weeks!.flatMap { $0.workouts! } ?? []
        let targetWorkouts: [Workout] = allWorkouts
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
        let selectedExercises: [Exercise] = workout.exercises!
            .filter { selectedExerciseIDs.contains($0.id) }
            .sorted { $0.orderIndex < $1.orderIndex }
        let maxOrderIndex: Int = targetWorkout.exercises!.map { $0.orderIndex }.max() ?? 0
        
        for (index, exercise) in selectedExercises.enumerated() {
            let newExercise: Exercise = Exercise(
                name: exercise.name,
                weight: exercise.weight,
                sets: exercise.sets,
                reps: exercise.reps,
                duration: exercise.duration,
                restTime: exercise.restTime,
                isTimeBased: exercise.isTimeBased,
                orderIndex: maxOrderIndex + index + 1,
                timeBeforeNext: exercise.timeBeforeNext
            )
            targetWorkout.exercises!.append(newExercise)
            newExercise.workout = targetWorkout
            modelContext.insert(newExercise)
        }
        selectedExerciseIDs.removeAll()
    }
    
    private func deleteExercise(_ exercise: Exercise) {
        if let index: Int = workout.exercises!.firstIndex(where: { $0.id == exercise.id }) {
            workout.exercises!.remove(at: index)
        }
    }
    
    private func deleteSelectedExercises() {
        let exercisesToDelete: [Exercise] = workout.exercises!.filter { selectedExerciseIDs.contains($0.id) }
        for exercise in exercisesToDelete {
            modelContext.delete(exercise)
        }
        selectedExerciseIDs.removeAll()
        try? modelContext.save()
    }
}
