//
//  WorkoutView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    let week: Week
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @State private var selectedWorkout: Workout?
    @State private var isAddingNewWorkout = false
    @State private var newWorkoutName = ""
    @State private var newWorkoutDate = Date()
    @State private var selectedWorkoutIDs = Set<Workout.ID>()
    @State private var isShowingWeekPicker = false
    
    private var weekDateRange: ClosedRange<Date> {
        let startDate = week.startDate
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate)!
        return startDate...endDate
    }
    
    private var availableWeeks: [Week] {
        guard let mesocycle = week.mesocycle else { return [] }
        return mesocycle.weeks
            .filter { $0.id != week.id }
            .sorted { $0.startDate < $1.startDate }
    }
    
    private var sortedWorkouts: [Workout] {
        week.workouts.sorted(by: { $0.date < $1.date })
    }
    
    var body: some View {
        List(selection: $selectedWorkoutIDs) {
            buildWorkoutRows()
        }
        .navigationTitle("Week \(week.number)")
        .navigationBarBackButtonHidden(editMode?.wrappedValue.isEditing == true)
        .onAppear {
            selectedWorkoutIDs.removeAll()
        }
        .sheet(item: $selectedWorkout) { workout in
            workoutEditSheet(workout: workout)
        }
        .sheet(isPresented: $isAddingNewWorkout) {
            workoutEditSheet(workout: nil)
        }
        .sheet(isPresented: $isShowingWeekPicker) {
            weekPickerSheet
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
    private func buildWorkoutRows() -> some View {
        ForEach(sortedWorkouts) { workout in
            workoutRow(for: workout)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteWorkout(workout)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .tag(workout.id)
        }
    }
    
    @ViewBuilder
    private func workoutRow(for workout: Workout) -> some View {
        let isPast: Bool = Calendar.current.startOfDay(for: workout.date) < Calendar.current.startOfDay(for: Date())
        
        Section {
            if editMode?.wrappedValue.isEditing == true {
                Button(action: {
                    selectedWorkout = workout
                }) {
                    HStack {
                        Text(workout.name)
                            .font(.headline)
                        Text(workout.date.formattedRelative())
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Spacer()
                    }
                    .opacity(isPast ? 0.5 : 1.0)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                NavigationLink {
                    ExerciseView(workout: workout)
                } label: {
                    HStack {
                        Text(workout.name)
                            .font(.headline)
                        Text(workout.date.formattedRelative())
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Spacer()
                    }
                    .opacity(isPast ? 0.5 : 1.0)
                    .contentShape(Rectangle())
                }
            }
        }
    }
    
    @ViewBuilder
    private func workoutEditSheet(workout: Workout?) -> some View {
        NavigationStack {
            Form {
                TextField("Workout Name", text: workout == nil ? $newWorkoutName : Binding(
                    get: { workout!.name },
                    set: { workout!.name = $0 }
                ))
                .withTextFieldToolbar()
                DatePicker(
                    "Date",
                    selection: workout == nil ? $newWorkoutDate : Binding(
                        get: { workout!.date },
                        set: { workout!.date = $0 }
                    ),
                    in: weekDateRange,
                    displayedComponents: .date
                )
            }
            .navigationTitle(workout == nil ? "New Workout" : "Rename Workout")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        if workout == nil {
                            let orderIndex = (week.workouts.map { $0.orderIndex }.max() ?? 0) + 1
                            let workout = Workout(name: newWorkoutName, orderIndex: orderIndex, date: newWorkoutDate)
                            week.workouts.append(workout)
                            workout.week = week
                            modelContext.insert(workout)
                        }
                        selectedWorkout = nil
                        isAddingNewWorkout = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        selectedWorkout = nil
                        isAddingNewWorkout = false
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var leadingToolbarItems: some View {
        if editMode?.wrappedValue.isEditing == true {
            if !selectedWorkoutIDs.isEmpty {
                Menu {
                    Button(action: {
                        isShowingWeekPicker = true
                    }) {
                        Label("Copy", systemImage: "document.on.document")
                    }
                    Button(role: .destructive, action: {
                        deleteSelectedWorkouts()
                    }) {
                        Label("Delete", systemImage: "trash")
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
        Button("", systemImage: "plus") {
            isAddingNewWorkout = true
            newWorkoutName = ""
            newWorkoutDate = calculateDefaultWorkoutDate()
        }
    }
    
    @ViewBuilder
    private var weekPickerSheet: some View {
        NavigationStack {
            List(availableWeeks) { targetWeek in
                Button(action: {
                    copyWorkouts(to: targetWeek)
                    isShowingWeekPicker = false
                }) {
                    VStack(alignment: .leading) {
                        Text("Week \(targetWeek.number)")
                            .font(.headline)
                        Text("Start: \(targetWeek.startDate.formattedRelative())")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
            }
            .navigationTitle("Copy to Week")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isShowingWeekPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func copyWorkouts(to targetWeek: Week) {
        let selectedWorkouts = week.workouts.filter { selectedWorkoutIDs.contains($0.id) }
        let maxOrderIndex = targetWeek.workouts.map { $0.orderIndex }.max() ?? 0
        
        for (index, workout) in selectedWorkouts.enumerated() {
            let newWorkout = Workout(
                name: workout.name,
                orderIndex: maxOrderIndex + index + 1,
                date: workout.date
            )
            targetWeek.workouts.append(newWorkout)
            newWorkout.week = targetWeek
            modelContext.insert(newWorkout)
            
            for exercise in workout.exercises {
                let newExercise = Exercise(
                    name: exercise.name,
                    weight: exercise.weight,
                    sets: exercise.sets,
                    reps: exercise.reps,
                    duration: exercise.duration,
                    restTime: exercise.restTime,
                    isTimeBased: exercise.isTimeBased,
                    orderIndex: exercise.orderIndex
                )
                newWorkout.exercises.append(newExercise)
                newExercise.workout = newWorkout
                modelContext.insert(newExercise)
            }
        }
        selectedWorkoutIDs.removeAll()
    }
    
    private func deleteWorkout(_ workout: Workout) {
        if let index = week.workouts.firstIndex(where: { $0.id == workout.id }) {
            modelContext.delete(week.workouts[index])
        }
    }
    
    private func deleteSelectedWorkouts() {
        let workoutsToDelete = week.workouts.filter { selectedWorkoutIDs.contains($0.id) }
        for workout in workoutsToDelete {
            modelContext.delete(workout)
        }
        selectedWorkoutIDs.removeAll()
        try? modelContext.save()
    }
    
    private func calculateDefaultWorkoutDate() -> Date {
        guard let lastWorkout = week.workouts.sorted(by: { $0.date < $1.date }).last else {
            return week.startDate
        }
        return Calendar.current.date(byAdding: .day, value: 1, to: lastWorkout.date) ?? week.startDate
    }
}

