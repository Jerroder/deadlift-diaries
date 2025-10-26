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
    
    @State private var selectedWeekIDs: Set<UUID> = Set<Week.ID>()
    @State private var isShowingMesocyclePicker: Bool = false
    
    @FocusState.Binding var focusedField: FocusableField?
    
    private var sortedWeeks: [Week] {
        mesocycle.weeks!.sorted { $0.startDate < $1.startDate }
    }
    
    // MARK: - Main view
    
    var body: some View {
        buildWeekRows()
            .navigationTitle(mesocycle.name)
            .navigationBarBackButtonHidden(editMode?.wrappedValue.isEditing == true)
            .sheet(isPresented: $isShowingMesocyclePicker) {
                mesocyclePickerSheet()
            }
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                if #available(iOS 26.0, *) {
                    Button(action: addNewWeek) {
                        Image(systemName: "plus")
                            .font(.system(size: 22))
                            .padding([.leading, .trailing], 0)
                            .padding([.top, .bottom], 6)
                    }
                    .padding()
                    .buttonStyle(.glassProminent)
                } else {
                    Button(action: addNewWeek) {
                        Image(systemName: "plus")
                            .font(.system(size: 22))
                            .padding([.leading, .trailing], 0)
                            .padding([.top, .bottom], 6)
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    leadingToolbarItems()
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    EditButton()
                }
            }
            .environment(\.editMode, Binding(
                get: { editMode?.wrappedValue ?? .inactive },
                set: { editMode?.wrappedValue = $0 }
            ))
    }
    
    // MARK: - ViewBuilder functions
    
    @ViewBuilder
    private func buildWeekRows() -> some View {
        List(selection: $selectedWeekIDs) {
            ForEach(sortedWeeks, id: \.id) { week in
                let isPast: Bool = isWeekPast(week)
                NavigationLink {
                    WorkoutView(week: week, focusedField: $focusedField)
                } label: {
                    weekRow(week: week, isPast: isPast)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteWeek(week)
                    } label: {
                        Label("delete".localized(comment: "Delete"), systemImage: "trash")
                    }
                }
                .tag(week.id)
            }
        }
    }
    
    @ViewBuilder
    private func weekRow(week: Week, isPast: Bool) -> some View {
        VStack(alignment: .leading) {
            Text("week_x".localized(with: week.number, comment: "Week x"))
                .font(.headline)
            Text("start_xdate".localized(with: week.startDate.formattedRelative(), comment: "Start:"))
                .font(.subheadline)
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .opacity(isPast ? 0.5 : 1.0)
    }
    
    @ViewBuilder
    private func mesocyclePickerSheet() -> some View {
        NavigationStack {
            let fetchDescriptor: FetchDescriptor<Mesocycle> = FetchDescriptor<Mesocycle>(sortBy: [SortDescriptor(\.startDate)])
            let targetMesocycles: [Mesocycle] = (try? modelContext.fetch(fetchDescriptor))?.filter { $0.id != mesocycle.id } ?? []
            
            List(targetMesocycles) { targetMesocycle in
                Button(action: {
                    copyWeeks(to: targetMesocycle)
                    isShowingMesocyclePicker = false
                }) {
                    VStack(alignment: .leading) {
                        Text(targetMesocycle.name)
                            .font(.headline)
                        Text("start_xdate".localized(with: targetMesocycle.startDate.formatted(date: .abbreviated, time: .omitted), comment: "Start:"))
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
            }
            .navigationTitle("copy_to_mesocycle".localized(comment: "Copy to mesocycle"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark", action: { isShowingMesocyclePicker = false })
                }
            }
        }
    }
    
    @ViewBuilder
    private func leadingToolbarItems() -> some View {
        if editMode?.wrappedValue.isEditing == true {
            Menu {
                if selectedWeekIDs.isEmpty {
                    Button(action: {
                        selectedWeekIDs = Set(mesocycle.weeks!.map { $0.id })
                    }) {
                        Label("select_all".localized(comment: "Select all"), systemImage: "checkmark.circle.fill")
                    }
                } else {
                    Button(action: { isShowingMesocyclePicker = true }) {
                        Label("copy".localized(comment: "Copy"), systemImage: "doc.on.doc")
                    }
                    Button(role: .destructive, action: deleteSelectedWeeks) {
                        Label("delete".localized(comment: "Delete"), systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func isWeekPast(_ week: Week) -> Bool {
        let endDate: Date = Calendar.current.date(byAdding: .day, value: 6, to: week.startDate)!
        return Calendar.current.startOfDay(for: endDate) < Calendar.current.startOfDay(for: Date())
    }
    
    private func addNewWeek() {
        let newWeekNumber: Int = (sortedWeeks.map { $0.number }.max() ?? 0) + 1
        let lastWeekStartDate: Date = sortedWeeks.last?.startDate ?? mesocycle.startDate
        let newWeekStartDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: lastWeekStartDate)!
        
        let newWeek: Week = Week(number: newWeekNumber, startDate: newWeekStartDate)
        mesocycle.weeks!.append(newWeek)
        newWeek.mesocycle = mesocycle
        modelContext.insert(newWeek)
        mesocycle.numberOfWeeks = sortedWeeks.count + 1
    }
    
    private func deleteWeek(_ week: Week) {
        if let index: Int = sortedWeeks.firstIndex(where: { $0.id == week.id }) {
            modelContext.delete(sortedWeeks[index])
            renumberWeeks()
        }
    }
    
    private func copyWeeks(to targetMesocycle: Mesocycle) {
        let selectedWeeks: [Week] = sortedWeeks.filter { selectedWeekIDs.contains($0.id) }
        guard !selectedWeeks.isEmpty else { return }
        
        let lastTargetWeek: Week? = targetMesocycle.weeks!.sorted { $0.startDate < $1.startDate }.last
        
        let baseStartDate: Date = lastTargetWeek != nil ?
        Calendar.current.date(byAdding: .day, value: 7, to: lastTargetWeek!.startDate)! :
        targetMesocycle.startDate
        
        var lastCopiedWeekStartDate: Date = baseStartDate
        let maxWeekNumber: Int = targetMesocycle.weeks!.map { $0.number }.max() ?? 0
        
        for (index, week) in selectedWeeks.enumerated() {
            let newWeekNumber: Int = maxWeekNumber + 1 + index
            let newWeekStartDate: Date = index == 0 ?
            lastCopiedWeekStartDate :
            Calendar.current.date(byAdding: .day, value: 7, to: lastCopiedWeekStartDate)!
            
            copyWeek(week, to: targetMesocycle, newNumber: newWeekNumber, newStartDate: newWeekStartDate)
            lastCopiedWeekStartDate = newWeekStartDate
        }
        
        targetMesocycle.numberOfWeeks = targetMesocycle.weeks!.count
        selectedWeekIDs.removeAll()
    }
    
    private func copyWeek(_ week: Week, to targetMesocycle: Mesocycle, newNumber: Int, newStartDate: Date) {
        let newWeek: Week = Week(number: newNumber, startDate: newStartDate)
        targetMesocycle.weeks!.append(newWeek)
        newWeek.mesocycle = targetMesocycle
        modelContext.insert(newWeek)
        
        for workout in week.workouts!.sorted(by: { $0.date < $1.date }) {
            copyWorkout(workout, to: newWeek, originalWeekStartDate: week.startDate, newWeekStartDate: newStartDate)
        }
    }
    
    private func copyWorkout(_ workout: Workout, to newWeek: Week, originalWeekStartDate: Date, newWeekStartDate: Date) {
        let daysOffset: Int = Calendar.current.dateComponents([.day], from: originalWeekStartDate, to: newWeekStartDate).day ?? 0
        let newWorkoutDate: Date = Calendar.current.date(byAdding: .day, value: daysOffset, to: workout.date)!
        
        let newWorkout: Workout = Workout(
            name: workout.name,
            orderIndex: workout.orderIndex,
            date: newWorkoutDate
        )
        newWeek.workouts!.append(newWorkout)
        newWorkout.week = newWeek
        modelContext.insert(newWorkout)
        
        let exercises = workout.exercises!.sorted { $0.orderIndex < $1.orderIndex }
        var exerciseMapping: [UUID: UUID] = [:]
        
        for exercise in exercises {
            let newExercise: Exercise = Exercise(
                name: exercise.name,
                weight: exercise.weight,
                sets: exercise.sets,
                reps: exercise.reps,
                duration: exercise.duration,
                restTime: exercise.restTime,
                isTimeBased: exercise.isTimeBased,
                orderIndex: exercise.orderIndex,
                timeBeforeNext: exercise.timeBeforeNext
            )
            newWorkout.exercises!.append(newExercise)
            newExercise.workout = newWorkout
            modelContext.insert(newExercise)
            
            exerciseMapping[exercise.id] = newExercise.id
        }
        
        for exercise in exercises {
            if let partnerID = exercise.supersetPartnerID,
               let newPartnerID = exerciseMapping[partnerID] {
                if let newExercise = newWorkout.exercises!.first(where: { $0.id == exerciseMapping[exercise.id] }) {
                    newExercise.supersetPartnerID = newPartnerID
                }
            }
        }
    }

    
    private func copyExercise(_ exercise: Exercise, to newWorkout: Workout) {
        let newExercise: Exercise = Exercise(
            name: exercise.name,
            weight: exercise.weight,
            sets: exercise.sets,
            reps: exercise.reps,
            duration: exercise.duration,
            restTime: exercise.restTime,
            isTimeBased: exercise.isTimeBased,
            orderIndex: exercise.orderIndex,
            timeBeforeNext: exercise.timeBeforeNext
        )
        newWorkout.exercises!.append(newExercise)
        newExercise.workout = newWorkout
        modelContext.insert(newExercise)
    }
    
    private func deleteSelectedWeeks() {
        let weeksToDelete: [Week] = sortedWeeks.filter { selectedWeekIDs.contains($0.id) }
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
