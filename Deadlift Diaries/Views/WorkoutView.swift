//
//  WorkoutView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI

struct WorkoutView: View {
    @ObservedObject var week: Week

    var body: some View {
        VStack(alignment: .leading) {
            Text("Week: \(week.weekNumber)")
                .font(.title)
        }
        .padding()
        .navigationBarTitle("Week Details", displayMode: .inline)
    }
}

struct WorkoutItemView: View {
    @ObservedObject var workout: Workout

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
