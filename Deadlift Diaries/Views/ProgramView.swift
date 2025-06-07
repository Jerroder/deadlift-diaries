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
    @FocusState private var focusedField: UUID?
    
    @State private var isEditing = false
    @State private var selectedItems = Set<UUID>()

    var body: some View {
        NavigationStack {
            List {
                ForEach(programs) { program in
                    DisplayPrograms(program: program, focusedField: $focusedField)
                }
                .onDelete(perform: deleteProgram)
                .onTapGesture {
                    focusedField = nil
                }
            }
            .background(Color(colorScheme == .light ? UIColor.secondarySystemBackground : UIColor.systemBackground))
            .navigationTitle("Programs")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation {
                            isEditing.toggle()
                        }
                    }) {
                        Text(isEditing ? "Done" : "Edit")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addProgram) {
                        Image(systemName: "plus")
                    }
                }
            }
            .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
        }
    }

    private func addProgram() {
        let newProgram = Program(name: "", description: "A new fitness plan", weeks: [], orderIndex: programs.count)
        withAnimation {
            modelContext.insert(newProgram)
        }
        focusedField = newProgram.id

        try? modelContext.save()
    }

    private func deleteProgram(at offsets: IndexSet) {
        withAnimation {
            let programsToDelete = offsets.map { programs[$0] }
            
            for program in programsToDelete {
                modelContext.delete(program)
            }

            try? modelContext.save()

            for index in programs.indices {
                programs[index].orderIndex = index
            }
        }
    }
}

struct DisplayPrograms: View {
    @Bindable var program: Program
    @FocusState.Binding var focusedField: UUID?

    var body: some View {
        Section {
            VStack {
                TextField("Program Name", text: $program.name)
                    .focused($focusedField, equals: program.id)
                
                NavigationLink(destination: WeekView(program: program)) {
                    VStack(alignment: .leading) {
                        Text(program.weeks.first?.weekNumber != nil ? "\(program.weeks.count) \(program.weeks.count == 1 ? "week" : "weeks")" : "")
                        Text("Next Workout: \(program.weeks.first?.workouts.first?.name ?? "No workouts")")
                    }
                    .background(Color.clear)
                    .cornerRadius(5)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
