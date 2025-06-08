//
//  WeekView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData
import Foundation

struct WeekView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme

    @Bindable var program: Program

    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(program.weeks.sorted { $0.creationDate < $1.creationDate }, id: \.id) { week in
                    DisplayWeeks(week: week)
                }
                .onDelete(perform: deleteWeek)
            }
        }
        .background(Color(colorScheme == .light ? UIColor.secondarySystemBackground : UIColor.systemBackground))
        .navigationTitle(program.name.isEmpty ? "Program details" : program.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button(action: {
                        withAnimation {
                            isEditing.toggle()
                        }
                    }) {
                        Text(isEditing ? "Done" : "Edit")
                    }
                    Button(action: addWeek) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
//        .onAppear {
//            print("Current \(program.weeks.map { $0.weekNumber }): \(program.weeks.map { $0.id })")
//        }
    }

    private func addWeek() {
        let newWeek = Week(weekNumber: program.weeks.count + 1, workouts: [])
        withAnimation {
            program.weeks.append(newWeek)
        }
        try? modelContext.save()
    }

    private func deleteWeek(at indexSet: IndexSet) {
        withAnimation {
            program.weeks.sort { $0.creationDate < $1.creationDate }

            for index in indexSet {
                let objectId = program.weeks[index].persistentModelID
                let weekToDelete = modelContext.model(for: objectId)
                modelContext.delete(weekToDelete)
                program.weeks.remove(at: index)
            }

            for index in program.weeks.indices {
                program.weeks[index].weekNumber = index + 1
            }

            try? modelContext.save()
        }
    }
}

struct DisplayWeeks: View {
    @Bindable var week: Week

    var body: some View {
        VStack {
            Text("Week \(week.weekNumber)")
            
            NavigationLink(destination: WorkoutView(week: week)) {
                VStack(alignment: .leading) {
                    Text("Next Workout: \(week.workouts.first?.name ?? "No workouts")")
                }
                //.padding()
                .background(Color.clear)
                .cornerRadius(5)
            }
        }
        .padding(.vertical, 8)
    }
}
