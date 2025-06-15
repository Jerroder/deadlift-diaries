//
//  ProgramView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftData
import SwiftUI

struct ProgramView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme

    @Query(sort: \Program.orderIndex) private var programs: [Program]
    
    @State private var isEditing = false

    @FocusState private var focusedField: UUID?

    var body: some View {
        NavigationStack {
            List {
                ForEach(programs) { program in
                    DisplayPrograms(program: program, focusedField: $focusedField)
                }
                .onDelete(perform: deleteProgram)
                .onMove(perform: moveProgram)
            }
            .background(Color(colorScheme == .light ? UIColor.secondarySystemBackground : UIColor.systemBackground))
            .navigationTitle("programs".localized(comment: "Programs"))
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
                    Button(action: addProgram) {
                        Image(systemName: "plus")
                    }
                }
            }
            .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
        }
    }

    private func addProgram() {
        let newProgram = Program(orderIndex: programs.count)
        withAnimation {
            modelContext.insert(newProgram)
        }
        focusedField = newProgram.id

        try? modelContext.save()
    }

    private func deleteProgram(at indexSet: IndexSet) {
        withAnimation {
            let programsToDelete = indexSet.map { programs[$0] }
            
            for program in programsToDelete {
                modelContext.delete(program)
            }

            try? modelContext.save()

            for index in programs.indices {
                programs[index].orderIndex = index
            }
            
            try? modelContext.save()
        }
    }
    
    private func moveProgram(from source: IndexSet, to destination: Int) {
        print("test")
        withAnimation {
            var programs = programs // Capture the current state of programs
            
            // Calculate the new indices after moving
            let newIndices = programs.indices.map { index -> Int in
                if index < destination && !source.contains(index) {
                    return index
                } else if index >= destination && !source.contains(index) {
                    return index + source.count
                } else {
                    return index - source.first! + destination
                }
            }
            
            // Update the orderIndex based on the new indices
            for index in programs.indices {
                programs[index].orderIndex = newIndices[index]
            }
            
            // Save the changes to the model context
            try? modelContext.save()
        }
    }
}

struct DisplayPrograms: View {
    @Bindable var program: Program
    @FocusState.Binding var focusedField: UUID?

    var body: some View {
        Section {
            VStack {
                TextField("program_name".localized(comment: "Program Name"), text: $program.name) {
                    focusedField = nil
                }
                .focused($focusedField, equals: program.id)

                NavigationLink(destination: WeekView(program: program)) {
                    VStack(alignment: .leading) {
                        Text(weeksText)
                        Text(nextWorkoutText)
                    }
                    .background(Color.clear)
                    .cornerRadius(5)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var weeksText: String {
        let count = program.weeks.count
        guard count > 0 else {
            return ""
        }

        let weekOrWeeks = count == 1 ? "week".localized(comment: "week") : "weeks".localized(comment: "weeks")
        return "\(count) \(weekOrWeeks)"
    }

    private var nextWorkoutText: String {
        let workoutName = program.weeks.first?.workouts.first?.name ?? ""
        let displayText = workoutName.isEmpty ? "no_workout_planned".localized(comment: "No workout planned") : "next_workout".localized(comment: "Next workout") + ": \(workoutName)"

        return displayText
    }
}
