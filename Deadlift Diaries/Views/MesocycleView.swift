//
//  MesocycleView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData

struct MesocycleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @Query(sort: \Mesocycle.startDate) private var mesocycles: [Mesocycle]
    
    @State private var selectedMesocycle: Mesocycle?
    @State private var isAddingNewMesocycle = false
    @State private var newMesocycleName = ""
    @State private var newMesocycleStartDate = Date()
    @State private var newMesocycleNumberOfWeeks = 4
    @State private var selectedMesocycleIDs = Set<Mesocycle.ID>()
    
    @ViewBuilder
    private var addMesocycleButton: some View {
        Button("", systemImage: "plus", action: {
            isAddingNewMesocycle = true
            newMesocycleName = ""
            newMesocycleStartDate = calculateStartDateForNewMesocycle()
            newMesocycleNumberOfWeeks = 4
        })
    }
    
    var body: some View {
        NavigationStack {
            List(selection: $selectedMesocycleIDs) {
                ForEach(mesocycles) { mesocycle in
                    mesocycleRow(for: mesocycle)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if let index = mesocycles.firstIndex(where: { $0.id == mesocycle.id }) {
                                    modelContext.delete(mesocycles[index])
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .tag(mesocycle.id)
                }
            }
            .navigationTitle("Mesocycles")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    leadingToolbarItems
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    EditButton()
                    addMesocycleButton
                }
            }
            .sheet(item: $selectedMesocycle) { mesocycle in
                mesocycleEditSheet(mesocycle: mesocycle)
            }
            .sheet(isPresented: $isAddingNewMesocycle) {
                mesocycleEditSheet(mesocycle: nil)
            }
            .environment(\.editMode, Binding(
                get: { editMode?.wrappedValue ?? .inactive },
                set: { editMode?.wrappedValue = $0 }
            ))
        }
    }
    
    // MARK: - Computed Properties for Views
    
    @ViewBuilder
    private func mesocycleRow(for mesocycle: Mesocycle) -> some View {
        Section {
            if editMode?.wrappedValue.isEditing == true {
                Button(action: {
                    selectedMesocycle = mesocycle
                }) {
                    MesocycleRow(mesocycle: mesocycle)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                NavigationLink {
                    WeekView(mesocycle: mesocycle)
                } label: {
                    MesocycleRow(mesocycle: mesocycle)
                        .contentShape(Rectangle())
                }
            }
        }
    }
    
    @ViewBuilder
    private var leadingToolbarItems: some View {
        if editMode?.wrappedValue.isEditing == true {
            if !selectedMesocycleIDs.isEmpty {
                Menu {
                    Button(action: duplicateSelectedMesocycles) {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                    Button(role: .destructive, action: deleteSelectedMesocycles) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        } else {
            Menu {
                Button(action: {
                    print("test")
                }) {
                    Label("info".localized(comment: "Info"), systemImage: "info.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    @ViewBuilder
    private func mesocycleEditSheet(mesocycle: Mesocycle?) -> some View {
        NavigationStack {
            Form {
                TextField("Name", text: mesocycle == nil ? $newMesocycleName : Binding(
                    get: { mesocycle!.name },
                    set: { mesocycle!.name = $0 }
                ))
                .withTextFieldToolbar()
                DatePicker("Start Date", selection: mesocycle == nil ? $newMesocycleStartDate : Binding(
                    get: { mesocycle!.startDate },
                    set: { mesocycle!.startDate = $0 }
                ), displayedComponents: .date)
                Stepper("Number of Weeks: \(mesocycle == nil ? newMesocycleNumberOfWeeks : mesocycle!.weeks.count)",
                        value: mesocycle == nil ? $newMesocycleNumberOfWeeks : Binding(
                            get: { mesocycle!.weeks.count },
                            set: { _ in }
                        ), in: 1...12)
            }
            .navigationTitle(mesocycle == nil ? "New Mesocycle" : "Edit Mesocycle")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        if let mesocycle = mesocycle {
                            updateWeeks(for: mesocycle, newStartDate: mesocycle.startDate, newWeekCount: mesocycle.weeks.count)
                            updateWorkoutDates(for: mesocycle)
                        } else {
                            let orderIndex = (mesocycles.map { $0.orderIndex }.max() ?? 0) + 1
                            let mesocycle = Mesocycle(
                                name: newMesocycleName,
                                startDate: newMesocycleStartDate,
                                numberOfWeeks: newMesocycleNumberOfWeeks,
                                orderIndex: orderIndex
                            )
                            modelContext.insert(mesocycle)
                        }
                        selectedMesocycle = nil
                        isAddingNewMesocycle = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        selectedMesocycle = nil
                        isAddingNewMesocycle = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateStartDateForNewMesocycle() -> Date {
        guard let lastMesocycle = mesocycles.sorted(by: { $0.orderIndex > $1.orderIndex }).first else {
            return Date()
        }
        
        return Calendar.current.date(byAdding: .day, value: lastMesocycle.numberOfWeeks * 7, to: lastMesocycle.startDate) ?? Date()
    }
    
    private func updateWeeks(for mesocycle: Mesocycle, newStartDate: Date, newWeekCount: Int) {
        let currentWeekCount = mesocycle.weeks.count
        
        for (index, week) in mesocycle.weeks.sorted(by: { $0.number < $1.number }).enumerated() {
            week.startDate = Calendar.current.date(byAdding: .day, value: index * 7, to: newStartDate)!
        }
        
        if newWeekCount > currentWeekCount {
            for weekNumber in currentWeekCount + 1...newWeekCount {
                let weekStartDate = Calendar.current.date(byAdding: .day, value: (weekNumber - 1) * 7, to: newStartDate)!
                let newWeek = Week(number: weekNumber, startDate: weekStartDate)
                mesocycle.weeks.append(newWeek)
                newWeek.mesocycle = mesocycle
                modelContext.insert(newWeek)
            }
        } else if newWeekCount < currentWeekCount {
            let weeksToRemove = mesocycle.weeks.sorted { $0.number > $1.number }.prefix(currentWeekCount - newWeekCount)
            for week in weeksToRemove {
                modelContext.delete(week)
            }
        }
        
        mesocycle.numberOfWeeks = newWeekCount
    }
    
    private func updateWorkoutDates(for mesocycle: Mesocycle) {
        for week in mesocycle.weeks {
            for workout in week.workouts {
                let weekStartDate = week.startDate
                let weekEndDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate)!
                
                if workout.date < weekStartDate || workout.date > weekEndDate {
                    workout.date = weekStartDate
                }
            }
        }
    }
    
    private func duplicateSelectedMesocycles() {
        let selectedMesocycles = mesocycles.filter { selectedMesocycleIDs.contains($0.id) }
        let maxOrderIndex = mesocycles.map { $0.orderIndex }.max() ?? 0
        
        for (index, mesocycle) in selectedMesocycles.enumerated() {
            let newOrderIndex = maxOrderIndex + index + 1
            let newStartDate = Calendar.current.date(byAdding: .day, value: mesocycle.numberOfWeeks * 7, to: mesocycle.startDate) ?? Date()
            
            let newMesocycle = Mesocycle(
                name: "\(mesocycle.name) Copy",
                startDate: newStartDate,
                numberOfWeeks: 0,
                orderIndex: newOrderIndex
            )
            modelContext.insert(newMesocycle)
            
            for week in mesocycle.weeks.sorted(by: { $0.number < $1.number }) {
                let newWeekStartDate = Calendar.current.date(byAdding: .day, value: (week.number - 1) * 7, to: newStartDate)!
                let newWeek = Week(number: week.number, startDate: newWeekStartDate)
                newMesocycle.weeks.append(newWeek)
                newWeek.mesocycle = newMesocycle
                modelContext.insert(newWeek)
                
                for workout in week.workouts.sorted(by: { $0.date < $1.date }) {
                    let daysFromWeekStart = Calendar.current.dateComponents([.day], from: week.startDate, to: workout.date).day ?? 0
                    let newWorkoutDate = Calendar.current.date(byAdding: .day, value: daysFromWeekStart, to: newWeekStartDate)!
                    let newWorkout = Workout(
                        name: workout.name,
                        orderIndex: workout.orderIndex,
                        date: newWorkoutDate
                    )
                    newWeek.workouts.append(newWorkout)
                    newWorkout.week = newWeek
                    modelContext.insert(newWorkout)
                    
                    for exercise in workout.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
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
                
                newMesocycle.numberOfWeeks = mesocycle.weeks.count
            }
            
            selectedMesocycleIDs.removeAll()
        }
    }
    
    private func deleteSelectedMesocycles() {
        let mesocyclesToDelete = mesocycles.filter { selectedMesocycleIDs.contains($0.id) }
        for mesocycle in mesocyclesToDelete {
            modelContext.delete(mesocycle)
        }
        selectedMesocycleIDs.removeAll()
    }
}

struct MesocycleRow: View {
    let mesocycle: Mesocycle
    
    private var isPast: Bool {
        let endDate = Calendar.current.date(byAdding: .day, value: (mesocycle.numberOfWeeks * 7) - 1, to: mesocycle.startDate)!
        return Calendar.current.startOfDay(for: endDate) < Calendar.current.startOfDay(for: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(mesocycle.name)
                .font(.headline)
            HStack {
                Text("Start: \(mesocycle.startDate.formattedRelative())")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Spacer()
                Text("\(mesocycle.weeks.count) \((mesocycle.weeks.count == 1) ? "week" : "weeks")")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
        .opacity(isPast ? 0.5 : 1.0)
    }
}
