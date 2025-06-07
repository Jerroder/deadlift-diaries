//
//  WorkoutView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Bindable var week: Week

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(week.workouts, id: \.id) { workout in
                    DisplayWorkouts(workout: workout)
                }
            }
        }
        .listStyle(PlainListStyle()) // Maybe not wanted
        .navigationTitle("Week \(week.weekNumber)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        print("Edit button tapped!")
                    }) {
                        Text("Edit")
                    }
                    Button(action: addWorkout) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func addWorkout() {
        let newWorkout = Workout(name: "wo name", description: "desc",exercises: [])
        withAnimation {
            week.workouts.append(newWorkout)
        }
    }
}

struct DisplayWorkouts: View {
    @Bindable var workout: Workout

    var body: some View {
        VStack(alignment: .leading) {
            Text("Workout: \(workout.name)")
                .font(.subheadline)

            ForEach(workout.exercises, id: \.id) { exercise in
                ExerciseItemView(exercise: exercise)
            }
        }
    }
}
