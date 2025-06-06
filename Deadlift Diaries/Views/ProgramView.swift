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

    var body: some View {
        NavigationView {
            List {
                ForEach($programs, id: \.id) { $program in
                    DisplayPrograms(program: $program, focusedField: $focusedField)
                }
            }
            .listStyle(PlainListStyle())
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
        VStack {
            TextField("Program Name", text: $program.name)
                .focused($focusedField, equals: program.id)
            
            NavigationLink(destination: WeekView(program: program)) {
                VStack(alignment: .leading) {
                    Text("Week: \(program.weeks.first?.weekNumber ?? 0)")
                    Text("Next Workout: \(program.weeks.first?.workouts.first?.name ?? "No workouts")")
                }
                .padding()
                .background(Color.clear)
                .cornerRadius(5)
            }
            
            Divider()
        }
        .padding(.vertical, 8)
        .onTapGesture {
            focusedField = nil
        }
        .listRowSeparator(.hidden)
    }
}
