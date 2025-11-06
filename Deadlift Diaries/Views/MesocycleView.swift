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
    @State private var isAddingNewMesocycle: Bool = false
    @State private var newMesocycleName: String = ""
    @State private var newMesocycleStartDate: Date = Date()
    @State private var newMesocycleNumberOfWeeks: Int = 4
    @State private var selectedMesocycleIDs: Set<UUID> = Set<Mesocycle.ID>()
    @State private var isKeyboardShowing: Bool = false
    @State private var showingSoundPicker: Bool = false
    
    @FocusState.Binding var focusedField: FocusableField?
    
    // MARK: - Main view
    
    var body: some View {
        NavigationStack {
            mesocycleRows()
                .navigationTitle("mesocycles".localized(comment: "Mesocycles"))
                .onAppear {
                    selectedMesocycleIDs.removeAll()
                }
                .sheet(item: $selectedMesocycle) { mesocycle in
                    mesocycleEditSheet(mesocycle: mesocycle)
                }
                .sheet(isPresented: $isAddingNewMesocycle) {
                    mesocycleEditSheet(mesocycle: nil)
                }
                .sheet(isPresented: $showingSoundPicker) {
                    SettingsSheet(
                        isPresented: $showingSoundPicker,
                        mesocycles: mesocycles
                    )
                }
                .safeAreaInset(edge: .bottom, alignment: .trailing) {
                    if #available(iOS 26.0, *) {
                        Button(action: {
                            isAddingNewMesocycle = true
                            newMesocycleName = ""
                            newMesocycleStartDate = calculateStartDateForNewMesocycle()
                            newMesocycleNumberOfWeeks = 4
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 22))
                                .padding([.leading, .trailing], 0)
                                .padding([.top, .bottom], 6)
                        }
                        .padding()
                        .buttonStyle(.glassProminent)
                    } else {
                        Button(action: {
                            isAddingNewMesocycle = true
                            newMesocycleName = ""
                            newMesocycleStartDate = calculateStartDateForNewMesocycle()
                            newMesocycleNumberOfWeeks = 4
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 22))
                                .padding([.leading, .trailing], 0)
                                .padding([.top, .bottom], 6)
                        }
                        .padding()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        leadingToolbarItems()
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
                .environment(\.editMode, Binding(
                    get: { editMode?.wrappedValue ?? .inactive },
                    set: { editMode?.wrappedValue = $0 }
                ))
        }
    }
    
    // MARK: - ViewBuilder functions
    
    @ViewBuilder
    private func leadingToolbarItems() -> some View {
        if editMode?.wrappedValue.isEditing == true {
            Menu {
                if selectedMesocycleIDs.isEmpty {
                    Button(action: {
                        selectedMesocycleIDs = Set(mesocycles.map { $0.id })
                    }) {
                        Label("select_all".localized(comment: "Select all"), systemImage: "checkmark.circle.fill")
                    }
                } else {
                    Button(action: duplicateSelectedMesocycles) {
                        Label("duplicate".localized(comment: "Duplicate"), systemImage: "plus.square.on.square")
                    }
                    Button(role: .destructive, action: deleteSelectedMesocycles) {
                        Label("delete".localized(comment: "Delete"), systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        } else {
            Menu {
                Button(action: {
                    showingSoundPicker = true
                }) {
                    Label("settings".localized(comment: "Settings"), systemImage: "gear")
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
    }
    
    @ViewBuilder
    private func mesocycleRows() -> some View {
        List(selection: $selectedMesocycleIDs) {
            ForEach(mesocycles) { mesocycle in
                displayMesocycle(for: mesocycle)
            }
        }
    }
    
    @ViewBuilder
    private func displayMesocycle(for mesocycle: Mesocycle) -> some View {
        Section {
            if editMode?.wrappedValue.isEditing == true {
                Button(action: {
                    selectedMesocycle = mesocycle
                }) {
                    mesocycleRow(mesocycle: mesocycle)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                NavigationLink {
                    WeekView(mesocycle: mesocycle, focusedField: $focusedField)
                } label: {
                    mesocycleRow(mesocycle: mesocycle)
                        .contentShape(Rectangle())
                }
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                if let index: Int = mesocycles.firstIndex(where: { $0.id == mesocycle.id }) {
                    modelContext.delete(mesocycles[index])
                }
            } label: {
                Label("delete".localized(comment: "Delete"), systemImage: "trash")
            }
        }
        .tag(mesocycle.id)
    }
    
    @ViewBuilder
    private func mesocycleRow(mesocycle: Mesocycle) -> some View {
        let endDate: Date = Calendar.current.date(byAdding: .day, value: (mesocycle.numberOfWeeks * 7) - 1, to: mesocycle.startDate)!
        let isPast: Bool = Calendar.current.startOfDay(for: endDate) < Calendar.current.startOfDay(for: Date())
        
        VStack(alignment: .leading) {
            Text(mesocycle.name)
                .font(.headline)
            HStack {
                Text("start_xdate".localized(with: mesocycle.startDate.formattedRelative(), comment: "Start: (date)"))
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Spacer()
                Text("x_week".localized(with: mesocycle.weeks!.count, comment: "x Week(s)"))
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
        .opacity(isPast ? 0.5 : 1.0)
    }
    
    @ViewBuilder
    private func mesocycleEditSheet(mesocycle: Mesocycle?) -> some View {
        NavigationStack {
            Form {
                TextField("name".localized(comment: "Name"), text: mesocycle == nil ? $newMesocycleName : Binding(
                    get: { mesocycle!.name },
                    set: { mesocycle!.name = $0 }
                ))
                .focused($focusedField, equals: .mesocycleName)
                DatePicker("start_date".localized(comment: "Start Date"), selection: mesocycle == nil ? $newMesocycleStartDate : Binding(
                    get: { mesocycle!.startDate },
                    set: { mesocycle!.startDate = $0 }
                ), displayedComponents: .date)
                if mesocycle == nil {
                    Stepper("number_of_weeks".localized(with: newMesocycleNumberOfWeeks, comment: "Number of Weeks"),
                            value: $newMesocycleNumberOfWeeks, in: 1...12)
                }
            }
            .withTextFieldToolbarDone(isKeyboardShowing: $isKeyboardShowing, focusedField: $focusedField)
            .navigationTitle(mesocycle == nil ? "new_mesocycle".localized(comment: "New Mesocycle") : "edit_mesocycle".localized(comment: "Edit Mesocycle"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        if let mesocycle: Mesocycle = mesocycle {
                            updateWeeks(for: mesocycle, newStartDate: mesocycle.startDate, newWeekCount: mesocycle.weeks!.count)
                            updateWorkoutDates(for: mesocycle)
                        } else {
                            let orderIndex: Int = (mesocycles.map { $0.orderIndex }.max() ?? 0) + 1
                            let mesocycle: Mesocycle = Mesocycle(
                                name: newMesocycleName,
                                startDate: newMesocycleStartDate,
                                numberOfWeeks: newMesocycleNumberOfWeeks,
                                orderIndex: orderIndex
                            )
                            modelContext.insert(mesocycle)
                        }
                        try? modelContext.save()
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
        guard let lastMesocycle: Mesocycle = mesocycles.sorted(by: { $0.orderIndex > $1.orderIndex }).first else {
            return Date()
        }
        
        return Calendar.current.date(byAdding: .day, value: lastMesocycle.numberOfWeeks * 7, to: lastMesocycle.startDate) ?? Date()
    }
    
    private func updateWeeks(for mesocycle: Mesocycle, newStartDate: Date, newWeekCount: Int) {
        let currentWeekCount: Int = mesocycle.weeks!.count
        
        for (index, week) in mesocycle.weeks!.sorted(by: { $0.number < $1.number }).enumerated() {
            week.startDate = Calendar.current.date(byAdding: .day, value: index * 7, to: newStartDate)!
        }
        
        if newWeekCount > currentWeekCount {
            for weekNumber in currentWeekCount + 1...newWeekCount {
                let weekStartDate: Date = Calendar.current.date(byAdding: .day, value: (weekNumber - 1) * 7, to: newStartDate)!
                let newWeek: Week = Week(number: weekNumber, startDate: weekStartDate)
                mesocycle.weeks!.append(newWeek)
                newWeek.mesocycle = mesocycle
                modelContext.insert(newWeek)
            }
        } else if newWeekCount < currentWeekCount {
            let weeksToRemove: ArraySlice<Week> = mesocycle.weeks!.sorted { $0.number > $1.number }.prefix(currentWeekCount - newWeekCount)
            for week in weeksToRemove {
                modelContext.delete(week)
            }
        }
        
        mesocycle.numberOfWeeks = newWeekCount
        try? modelContext.save()
    }
    
    private func updateWorkoutDates(for mesocycle: Mesocycle) {
        for week in mesocycle.weeks! {
            for workout in week.workouts! {
                let weekStartDate: Date = week.startDate
                let weekEndDate: Date = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate)!
                
                if workout.date < weekStartDate || workout.date > weekEndDate {
                    workout.date = weekStartDate
                }
            }
        }
    }
    
    private func duplicateSelectedMesocycles() {
        let selectedMesocycles: [Mesocycle] = mesocycles.filter { selectedMesocycleIDs.contains($0.id) }
        let maxOrderIndex: Int = mesocycles.map { $0.orderIndex }.max() ?? 0
        
        for (index, mesocycle) in selectedMesocycles.enumerated() {
            let newOrderIndex: Int = maxOrderIndex + index + 1
            let newStartDate: Date = Calendar.current.date(byAdding: .day, value: mesocycle.numberOfWeeks * 7, to: mesocycle.startDate) ?? Date()
            
            let newMesocycle: Mesocycle = Mesocycle(
                name: "\(mesocycle.name) copy".localized(comment: "(xxx) copy"),
                startDate: newStartDate,
                numberOfWeeks: 0,
                orderIndex: newOrderIndex
            )
            modelContext.insert(newMesocycle)
            
            for week in mesocycle.weeks!.sorted(by: { $0.number < $1.number }) {
                let newWeekStartDate: Date = Calendar.current.date(byAdding: .day, value: (week.number - 1) * 7, to: newStartDate)!
                let newWeek: Week = Week(number: week.number, startDate: newWeekStartDate)
                newMesocycle.weeks!.append(newWeek)
                newWeek.mesocycle = newMesocycle
                modelContext.insert(newWeek)
                
                for workout in week.workouts!.sorted(by: { $0.date < $1.date }) {
                    let daysFromWeekStart: Int = Calendar.current.dateComponents([.day], from: week.startDate, to: workout.date).day ?? 0
                    let newWorkoutDate: Date = Calendar.current.date(byAdding: .day, value: daysFromWeekStart, to: newWeekStartDate)!
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
            }
            
            newMesocycle.numberOfWeeks = mesocycle.weeks!.count
        }
        
        selectedMesocycleIDs.removeAll()
        try? modelContext.save()
    }
    
    private func deleteSelectedMesocycles() {
        let mesocyclesToDelete: [Mesocycle] = mesocycles.filter { selectedMesocycleIDs.contains($0.id) }
        for mesocycle in mesocyclesToDelete {
            modelContext.delete(mesocycle)
        }
        selectedMesocycleIDs.removeAll()
        try? modelContext.save()
    }
}
