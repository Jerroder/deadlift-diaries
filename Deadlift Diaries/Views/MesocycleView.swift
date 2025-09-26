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
            List {
                ForEach(mesocycles) { mesocycle in
                    mesocycleRow(for: mesocycle)
                }
                .onDelete(perform: deleteMesocycles)
            }
            .navigationTitle("Mesocycles")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
    
    private func deleteMesocycles(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(mesocycles[index])
        }
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

