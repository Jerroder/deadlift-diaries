//
//  ProgramView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData

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
//                .onTapGesture { // breaks UX
//                    focusedField = nil
//                }
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
        let newProgram = Program(name: "", weeks: [], orderIndex: programs.count)
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
}

struct DisplayPrograms: View {
    @Bindable var program: Program
    @FocusState.Binding var focusedField: UUID?

    var body: some View {
        Section {
            VStack {
                TextField("program_name".localized(comment: "Program Name"), text: $program.name)
                    .focused($focusedField, equals: program.id)

                NavigationLink(destination: WeekView(program: program)) {
                    VStack(alignment: .leading) {
                        Text(program.weeks.first?.weekNumber != nil ? "\(program.weeks.count) \(program.weeks.count == 1 ? "week".localized(comment: "week") : "weeks".localized(comment: "weeks"))" : "")
                        Text("next_workout".localized(comment: "Next workout") + ": " + (program.weeks.first?.workouts.first?.name ?? "no_workouts".localized(comment: "No workouts")))
                    }
                    .background(Color.clear)
                    .cornerRadius(5)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
