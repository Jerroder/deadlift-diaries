//
//  WeekView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI

struct WeekView: View {
    @ObservedObject var program: Program

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(program.weeks, id: \.id) { week in
                    DisplayWeeks(week: week)
                }
            }
        }
        .listStyle(PlainListStyle()) // Maybe not wanted
        .navigationBarTitle(program.name.isEmpty ? "Program details" : program.name, displayMode: .large)
        .navigationBarItems(
            trailing:
                HStack {
                    Button(action: {
                        print("Edit button tapped!")
                    }) {
                        Text("Edit")
                    }
                    Button(action: addWeek) {
                        Image(systemName: "plus")
                    }
                }
        )
    }
    
    private func addWeek() {
        let newWeek = Week(weekNumber: program.weeks.count + 1, workouts: [])
        withAnimation {
            program.weeks.append(newWeek)
        }
    }
}

struct DisplayWeeks: View {
    @ObservedObject var week: Week

    var body: some View {
        VStack {
            Text("Week \(week.weekNumber)")
            
            NavigationLink(destination: WorkoutView(week: week)) {
                VStack(alignment: .leading) {
                    Text("Next Workout: \(week.workouts.first?.name ?? "No workouts")")
                }
                .padding()
                .background(Color.clear)
                .cornerRadius(5)
            }
        }
        .padding(.vertical, 8)
        // .listRowSeparator(.hidden) // @TODO: figure out how to remove the top separator or add title
    }
}
