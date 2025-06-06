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
            Text("Program: \(program.name)")
                .font(.title)

            Text("Description: \(program.description)")
                .font(.subheadline)
            List {
                ForEach(program.weeks, id: \.id) { week in
                    DisplayWeeks(week: week)
                }
            }

            Spacer()
        }
        .padding()
        .navigationBarTitle("Program Details", displayMode: .inline)
        .navigationBarItems(
            leading: Button(action: {
                print("Edit button tapped!")
            }) {
                Text("Edit")
            },
            trailing: Button(action: addWeek) {
                Image(systemName: "plus")
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
            Text("Week Number: \(week.weekNumber)")
            
            NavigationLink(destination: WorkoutView(week: week)) {
                VStack(alignment: .leading) {
                    Text("Week: \(week.weekNumber)")
                    Text("Next Workout: \(week.workouts.first?.name ?? "No workouts")")
                }
                .padding()
                .background(Color.clear)
                .cornerRadius(5)
            }
        }
        .padding(.vertical, 8)
    }
}
