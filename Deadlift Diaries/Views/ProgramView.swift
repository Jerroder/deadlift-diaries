//
//  ProgramView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI

struct ProgramView: View {
    @State private var programs: [Program] = []
    @FocusState private var focusedField: UUID?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            List {
                ForEach($programs, id: \.id) { $program in
                    DisplayPrograms(program: $program, focusedField: $focusedField)
                }
                .onTapGesture {
                    focusedField = nil
                }
            }
            .background(Color(colorScheme == .light ? UIColor.secondarySystemBackground : UIColor.systemBackground))
            .navigationBarTitle("Programs", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    print("Edit button tapped!")
                }) {
                    Text("Edit")
                },
                trailing: Button(action: addProgram) {
                    Image(systemName: "plus")
                }
            )
        }
    }

    private func addProgram() {
        let newProgram = Program(name: "", description: "A new fitness plan", weeks: [])
        withAnimation {
            programs.append(newProgram)
        }
        focusedField = newProgram.id
    }
}

struct DisplayPrograms: View {
    @Binding var program: Program
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
                    // .padding() // Is compact view better?
                    .background(Color.clear)
                    .cornerRadius(5)
                }
            }
            .padding(.vertical, 8)
            // .listRowSeparator(.hidden) // @TODO: figure out how to remove the top separator or add title
        }
    }
}
