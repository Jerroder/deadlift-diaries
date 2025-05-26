//
//  ContentView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-24.
//

import SwiftUI
import SwiftData

struct ProgramDetailView: View {
    let program: Program

    var body: some View {
        VStack(alignment: .leading) {
            Text("Program: \(program.name)")
                .font(.title)

            Text("Description: \(program.description)")
                .font(.subheadline)

            ForEach(program.weeks, id: \.weekNumber) { week in
                VStack(alignment: .leading) {
                    Text("Week \(week.weekNumber)")
                        .font(.headline)

                    ForEach(week.workouts, id: \.name) { workout in
                        Text("Workout: \(workout.name)")
                            .font(.subheadline)
                        
                        ForEach(workout.exercises, id: \.name) { exercise in
                            Text("Exercise: \(exercise.name), Sets: \(exercise.sets), Reps: \(exercise.reps)")
                                .font(.caption)
                        }
                    }
                }
                .padding(.vertical)
            }

            Spacer()
        }
        .padding()
        .navigationBarTitle("Program Details")
    }
}

struct ProgramView: View {
    @State private var programs: [Program] = []
    @FocusState private var focusedField: UUID?

    var body: some View {
        NavigationView {
            List {
                ForEach($programs, id: \.id) { $program in
                    VStack(alignment: .leading) {
                        TextField("Program Name", text: $program.name)
                            .focused($focusedField, equals: program.id)
                        
                        NavigationLink(destination: ProgramDetailView(program: program)) {
                            VStack(alignment: .leading) {
                                Text("Week: \(program.weeks.first?.weekNumber ?? 0)")
                                Text("Next Workout: \(program.weeks.first?.workouts.first?.name ?? "No workouts")")
                            }
                            .padding()
                            .background(Color.clear)
                            .cornerRadius(5)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
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
        let exercise = Exercise(name: "Push-ups", description: "Do 10 push-ups", duration: 60, sets: 3, reps: 10)
        let workout = Workout(name: "Upper Body", description: "Upper body workout", duration: 1800, exercises: [exercise])
        let week = Week(weekNumber: 1, workouts: [workout])
        let newProgram = Program(name: "", description: "A new fitness plan", duration: 86400, weeks: [week])
        withAnimation {
            programs.append(newProgram)
        }
        focusedField = newProgram.id
    }
}

struct TimerView: View {
    var body: some View {
        Text("Timer").font(.title)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            ProgramView().tabItem {
                Image(systemName: "calendar")
                Text("Programs")
            }
            
            TimerView().tabItem {
                Image(systemName: "timer")
                Text("Timer")
            }
        }
    }
}

#Preview {
    ContentView()
}
