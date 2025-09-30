//
//  WeekView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData

struct WeekView: View {
    let mesocycle: Mesocycle
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    
    @State private var selectedWeekIDs = Set<Week.ID>()
    @State private var isShowingMesocyclePicker = false
    
    @FocusState.Binding var isTextFieldFocused: Bool
    
    private var sortedWeeks: [Week] {
        mesocycle.weeks.sorted { $0.startDate < $1.startDate }
    }
    
    var body: some View {
        List(selection: $selectedWeekIDs) {
            buildWeekRows
        }
        .navigationTitle(mesocycle.name)
        .navigationBarBackButtonHidden(editMode?.wrappedValue.isEditing == true)
        .onAppear {
            selectedWeekIDs.removeAll()
        }
        .sheet(isPresented: $isShowingMesocyclePicker) {
            mesocyclePickerSheet
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                leadingToolbarItems
            }
            ToolbarItemGroup(placement: .primaryAction) {
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
    private var buildWeekRows: some View {
        ForEach(sortedWeeks, id: \.id) { week in
            weekRow(for: week)
                .swipeActions(edge: .trailing) {
                    deleteSwipeAction(for: week)
                }
                .tag(week.id)
        }
    }
    
    @ViewBuilder
    private var leadingToolbarItems: some View {
        if editMode?.wrappedValue.isEditing == true {
            if !selectedWeekIDs.isEmpty {
                selectionMenu
            }
        }
    }
    
    @ViewBuilder
    private var trailingToolbarItems: some View {
        EditButton()
        addWeekButton
    }
    
    @ViewBuilder
    private var mesocyclePickerSheet: some View {
        MesocyclePickerSheet(
            currentMesocycleID: mesocycle.id,
            onCopy: { targetMesocycle in
                copyWeeks(to: targetMesocycle)
                isShowingMesocyclePicker = false
            },
            onCancel: { isShowingMesocyclePicker = false }
        )
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func weekRow(for week: Week) -> some View {
        let isPast = isWeekPast(week)
        NavigationLink {
            WorkoutView(week: week, isTextFieldFocused: $isTextFieldFocused)
        } label: {
            WeekRow(week: week, isPast: isPast)
        }
    }
    
    @ViewBuilder
    private func deleteSwipeAction(for week: Week) -> some View {
        Button(role: .destructive) {
            deleteWeek(week)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private var selectionMenu: some View {
        Menu {
            copyMenuItem
            deleteMenuItem
        } label: {
            Image(systemName: "ellipsis")
        }
    }
    
    @ViewBuilder
    private var copyMenuItem: some View {
        Button(action: { isShowingMesocyclePicker = true }) {
            Label("Copy", systemImage: "doc.on.doc")
        }
    }
    
    @ViewBuilder
    private var deleteMenuItem: some View {
        Button(role: .destructive, action: deleteSelectedWeeks) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private var addWeekButton: some View {
        Button("", systemImage: "plus", action: addNewWeek)
    }
    
    // MARK: - Helper Functions
    
    private func isWeekPast(_ week: Week) -> Bool {
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: week.startDate)!
        return Calendar.current.startOfDay(for: endDate) < Calendar.current.startOfDay(for: Date())
    }
    
    private func addNewWeek() {
        let newWeekNumber = (sortedWeeks.map { $0.number }.max() ?? 0) + 1
        let lastWeekStartDate = sortedWeeks.last?.startDate ?? mesocycle.startDate
        let newWeekStartDate = Calendar.current.date(byAdding: .day, value: 7, to: lastWeekStartDate)!
        
        let newWeek = Week(number: newWeekNumber, startDate: newWeekStartDate)
        mesocycle.weeks.append(newWeek)
        newWeek.mesocycle = mesocycle
        modelContext.insert(newWeek)
        mesocycle.numberOfWeeks = sortedWeeks.count + 1
    }
    
    private func deleteWeek(_ week: Week) {
        if let index = sortedWeeks.firstIndex(where: { $0.id == week.id }) {
            modelContext.delete(sortedWeeks[index])
            renumberWeeks()
        }
    }
    
    private func copyWeeks(to targetMesocycle: Mesocycle) {
        let selectedWeeks = sortedWeeks.filter { selectedWeekIDs.contains($0.id) }
        guard !selectedWeeks.isEmpty else { return }
        
        let lastTargetWeek = targetMesocycle.weeks.sorted { $0.startDate < $1.startDate }.last

        let baseStartDate = lastTargetWeek != nil ?
        Calendar.current.date(byAdding: .day, value: 7, to: lastTargetWeek!.startDate)! :
        targetMesocycle.startDate
        
        var lastCopiedWeekStartDate = baseStartDate
        let maxWeekNumber = targetMesocycle.weeks.map { $0.number }.max() ?? 0
        
        for (index, week) in selectedWeeks.enumerated() {
            let newWeekNumber = maxWeekNumber + 1 + index
            let newWeekStartDate = index == 0 ?
            lastCopiedWeekStartDate :
            Calendar.current.date(byAdding: .day, value: 7, to: lastCopiedWeekStartDate)!
            
            copyWeek(week, to: targetMesocycle, newNumber: newWeekNumber, newStartDate: newWeekStartDate)
            lastCopiedWeekStartDate = newWeekStartDate
        }
        
        targetMesocycle.numberOfWeeks = targetMesocycle.weeks.count
        selectedWeekIDs.removeAll()
    }
    
    private func copyWeek(_ week: Week, to targetMesocycle: Mesocycle, newNumber: Int, newStartDate: Date) {
        let newWeek = Week(number: newNumber, startDate: newStartDate)
        targetMesocycle.weeks.append(newWeek)
        newWeek.mesocycle = targetMesocycle
        modelContext.insert(newWeek)
        
        for workout in week.workouts.sorted(by: { $0.date < $1.date }) {
            copyWorkout(workout, to: newWeek, originalWeekStartDate: week.startDate, newWeekStartDate: newStartDate)
        }
    }
    
    private func copyWorkout(_ workout: Workout, to newWeek: Week, originalWeekStartDate: Date, newWeekStartDate: Date) {
        let daysOffset = Calendar.current.dateComponents([.day], from: originalWeekStartDate, to: newWeekStartDate).day ?? 0
        
        let newWorkoutDate = Calendar.current.date(byAdding: .day, value: daysOffset, to: workout.date)!
        
        let newWorkout = Workout(
            name: workout.name,
            orderIndex: workout.orderIndex,
            date: newWorkoutDate
        )
        newWeek.workouts.append(newWorkout)
        newWorkout.week = newWeek
        modelContext.insert(newWorkout)
        
        for exercise in workout.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            copyExercise(exercise, to: newWorkout)
        }
    }
    
    private func copyExercise(_ exercise: Exercise, to newWorkout: Workout) {
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
    
    private func deleteSelectedWeeks() {
        let weeksToDelete = sortedWeeks.filter { selectedWeekIDs.contains($0.id) }
        for week in weeksToDelete {
            modelContext.delete(week)
        }
        renumberWeeks()
        selectedWeekIDs.removeAll()
        try? modelContext.save()
    }
    
    private func renumberWeeks() {
        for (index, week) in sortedWeeks.enumerated() {
            week.number = index + 1
        }
        mesocycle.numberOfWeeks = sortedWeeks.count
    }
}

// MARK: - Subviews

struct WeekRow: View {
    let week: Week
    let isPast: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Week \(week.number)")
                .font(.headline)
            Text("Start: \(week.startDate.formattedRelative())")
                .font(.subheadline)
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .opacity(isPast ? 0.5 : 1.0)
    }
}

struct MesocyclePickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    let currentMesocycleID: UUID
    let onCopy: (Mesocycle) -> Void
    let onCancel: () -> Void
    
    private var targetMesocycles: [Mesocycle] {
        let fetchDescriptor = FetchDescriptor<Mesocycle>(sortBy: [SortDescriptor(\.startDate)])
        return (try? modelContext.fetch(fetchDescriptor))?.filter { $0.id != currentMesocycleID } ?? []
    }
    
    var body: some View {
        List(targetMesocycles) { targetMesocycle in
            Button(action: { onCopy(targetMesocycle) }) {
                MesocycleRow(mesocycle: targetMesocycle)
            }
        }
        .navigationTitle("Copy to Mesocycle")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
            }
        }
        
    }
    
    @ViewBuilder
    private func MesocycleRow(mesocycle: Mesocycle) -> some View {
        VStack(alignment: .leading) {
            Text(mesocycle.name)
                .font(.headline)
            Text("Start: \(mesocycle.startDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
    }
}
