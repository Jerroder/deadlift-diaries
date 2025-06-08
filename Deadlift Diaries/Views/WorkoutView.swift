//
//  WorkoutView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var week: Week

    @State private var selectedWorkout: Workout? = nil

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(week.workouts.sorted { $0.creationDate < $1.creationDate }, id: \.id) { workout in
                    DisplayWorkouts(workout: workout)
                        .onTapGesture {
                            selectedWorkout = workout
                        }
                }
                .onDelete(perform: deleteWorkout)
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle("Week \(week.weekNumber)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
        .sheet(item: $selectedWorkout) { workout in
            ExerciseView(workout: workout)
        }
    }

    private func addWorkout() {
        let newWorkout = Workout(name: "", description: "desc", exercises: [])
        withAnimation {
            week.workouts.append(newWorkout)
        }
        try? modelContext.save()
    }
    
    private func deleteWorkout(at indexSet: IndexSet) {
        withAnimation {
            for index in indexSet {
                let objectId = week.workouts[index].persistentModelID
                let workoutToDelete = modelContext.model(for: objectId)
                modelContext.delete(workoutToDelete)
            }
            week.workouts.remove(atOffsets: indexSet)

            try? modelContext.save()
        }
    }
}

struct DisplayWorkouts: View {
    @Bindable var workout: Workout

    var body: some View {
        VStack(alignment: .leading) {
            Text("Workout: \(workout.name)")

//            ForEach(workout.exercises, id: \.id) { exercise in
//                ExerciseView(exercise: exercise)
//            }
        }
    }
}
