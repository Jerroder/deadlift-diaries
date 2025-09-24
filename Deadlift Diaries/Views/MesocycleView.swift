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
    
    @State private var isShowingMesocycleSheet = false
    @State private var selectedMesocycle: Mesocycle?
    @State private var mesocycleName = ""
    @State private var mesocycleStartDate = Date()
    @State private var mesocycleNumberOfWeeks = 4
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(mesocycles) { mesocycle in
                    Section {
                        if editMode?.wrappedValue.isEditing == true {
                            Button(action: {
                                selectedMesocycle = mesocycle
                                mesocycleName = mesocycle.name
                                mesocycleStartDate = mesocycle.startDate
                                mesocycleNumberOfWeeks = mesocycle.numberOfWeeks
                                isShowingMesocycleSheet = true
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
                .onDelete(perform: deleteMesocycles)
            }
            .navigationTitle("Mesocycles")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("", systemImage: "plus", action: {
                        selectedMesocycle = nil
                        mesocycleName = ""
                        mesocycleStartDate = Date()
                        mesocycleNumberOfWeeks = 4
                        isShowingMesocycleSheet = true
                    })
                }
            }
            .sheet(isPresented: $isShowingMesocycleSheet) {
                NavigationStack {
                    Form {
                        TextField("Name", text: $mesocycleName)
                            .withTextFieldToolbar()
                        DatePicker("Start Date", selection: $mesocycleStartDate, displayedComponents: .date)
                        Stepper("Number of Weeks: \(mesocycleNumberOfWeeks)", value: $mesocycleNumberOfWeeks, in: 1...12)
                    }
                    .navigationTitle(selectedMesocycle == nil ? "New Mesocycle" : "Edit Mesocycle")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("", systemImage: "checkmark") {
                                if let mesocycle = selectedMesocycle {
                                    mesocycle.name = mesocycleName
                                    mesocycle.startDate = mesocycleStartDate
                                    updateWeeks(for: mesocycle, newStartDate: mesocycleStartDate, newWeekCount: mesocycleNumberOfWeeks)
                                    updateWorkoutDates(for: mesocycle)
                                } else {
                                    let orderIndex = (mesocycles.map { $0.orderIndex }.max() ?? 0) + 1
                                    let mesocycle = Mesocycle(
                                        name: mesocycleName,
                                        startDate: mesocycleStartDate,
                                        numberOfWeeks: mesocycleNumberOfWeeks,
                                        orderIndex: orderIndex
                                    )
                                    modelContext.insert(mesocycle)
                                }
                                isShowingMesocycleSheet = false
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("", systemImage: "xmark") {
                                isShowingMesocycleSheet = false
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
                Text("Start: \(mesocycle.startDate.formatted(.dateTime.day().month().year()))")
                    .font(.subheadline)
                Spacer()
                Text("\(mesocycle.weeks.count) weeks")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
        .opacity(isPast ? 0.5 : 1.0)
    }
}


