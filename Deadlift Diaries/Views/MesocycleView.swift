//
//  MesocycleView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftData
import SwiftUI

struct MesocycleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme

    @Query(sort: \Mesocycle.orderIndex) private var mesocycles: [Mesocycle]
    
    @State private var isEditing = false

    @FocusState private var focusedField: UUID?

    var body: some View {
        NavigationStack {
            List {
                ForEach(mesocycles) { mesocycle in
                    DisplayMesocycles(mesocycle: mesocycle, focusedField: $focusedField)
                }
                .onDelete(perform: deleteMesocycle)
                .onMove(perform: moveMesocycle)
            }
            .background(Color(colorScheme == .light ? UIColor.secondarySystemBackground : UIColor.systemBackground))
            .navigationTitle("cycles".localized(comment: "Cycles"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        withAnimation {
                            isEditing.toggle()
                        }
                    }) {
                        Text(isEditing ? "done".localized(comment: "Done") : "edit".localized(comment: "Edit"))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: addMesocycle) {
                        Image(systemName: "plus")
                    }
                }
            }
            .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
        }
    }

    private func addMesocycle() {
        let newCycle = Mesocycle(orderIndex: mesocycles.count)
        withAnimation {
            modelContext.insert(newCycle)
        }
        focusedField = newCycle.id

        try? modelContext.save()
    }

    private func deleteMesocycle(at indexSet: IndexSet) {
        withAnimation {
            let mesocyclesToDelete = indexSet.map { mesocycles[$0] }
            
            for mesocycle in mesocyclesToDelete {
                modelContext.delete(mesocycle)
            }

            try? modelContext.save()

            for index in mesocycles.indices {
                mesocycles[index].orderIndex = index
            }
            
            try? modelContext.save()
        }
    }
    
    private func moveMesocycle(from source: IndexSet, to destination: Int) {
        print("test")
        withAnimation {
            let mesocycles = mesocycles // Capture the current state of mesocycles
            
            // Calculate the new indices after moving
            let newIndices = mesocycles.indices.map { index -> Int in
                if index < destination && !source.contains(index) {
                    return index
                } else if index >= destination && !source.contains(index) {
                    return index + source.count
                } else {
                    return index - source.first! + destination
                }
            }
            
            // Update the orderIndex based on the new indices
            for index in mesocycles.indices {
                mesocycles[index].orderIndex = newIndices[index]
            }
            
            // Save the changes to the model context
            try? modelContext.save()
        }
    }
}

struct DisplayMesocycles: View {
    @Bindable var mesocycle: Mesocycle
    @FocusState.Binding var focusedField: UUID?
    
    @State private var wakeUp = Date.now
    @State private var unit: Unit = Unit(symbol: "weeks")
    @State private var duration: Int = 0

    var body: some View {
        Section {
            VStack {
                TextField("cycle_name".localized(comment: "Cycle Name"), text: $mesocycle.name) {
                    focusedField = nil
                }
                .focused($focusedField, equals: mesocycle.id)

                NavigationLink(destination: WeekView(mesocycle: mesocycle)) {
                    VStack(alignment: .leading) {
                        Text(weeksText)
                        Text(nextWorkoutText)
                    }
                    .background(Color.clear)
                    .cornerRadius(5)
                }
                
                DatePicker("Please enter a date", selection: $wakeUp, in: Date.now..., displayedComponents: .date)
                    .padding()
                
                HStack {
                    TextFieldWithUnitInt(value: $duration, unit: $unit)
                        .keyboardType(.numberPad)
                        .onChange(of: duration) { _, _ in
                            mesocycle.duration = duration
                        }
                        .onAppear {
                            duration = mesocycle.duration
                        }
                Spacer()
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var weeksText: String {
        let count = mesocycle.weeks.count
        guard count > 0 else {
            return ""
        }

        let weekOrWeeks = count == 1 ? "week".localized(comment: "week") : "weeks".localized(comment: "weeks")
        return "\(count) \(weekOrWeeks)"
    }

    private var nextWorkoutText: String {
        let workoutName = mesocycle.weeks.first?.workouts.first?.name ?? ""
        let displayText = workoutName.isEmpty ? "no_workout_planned".localized(comment: "No workout planned") : "next_workout".localized(comment: "Next workout") + ": \(workoutName)"

        return displayText
    }
}
