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
        .navigationTitle("week".localized(comment: "Week") + " \(week.weekNumber)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button(action: {
                        print("Edit button tapped!")
                    }) {
                        Text("edit".localized(comment: "Edit"))
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
        let newWorkout = Workout()
        withAnimation {
            week.workouts.append(newWorkout)
        }
        selectedWorkout = newWorkout
        try? modelContext.save()
    }

    private func deleteWorkout(at indexSet: IndexSet) {
        withAnimation {
            week.workouts.sort { $0.creationDate < $1.creationDate }

            for index in indexSet.sorted(by: >) {
                let objectId = week.workouts[index].persistentModelID
                let workoutToDelete = modelContext.model(for: objectId)
                modelContext.delete(workoutToDelete)
                week.workouts.remove(at: index)
            }

            try? modelContext.save()
        }
    }
}

struct DisplayWorkouts: View {
    @Bindable var workout: Workout

    var body: some View {
        VStack(alignment: .leading) {
            Text(workout.name.isEmpty ? "workout".localized(comment: "Workout") : "\(workout.name)").font(.title)

            ForEach(workout.exercises.sorted { $0.creationDate < $1.creationDate }, id: \.id) { exercise in
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 4))
                    Text("\(exercise.name) \(exercise.weight)" + "weight_format".localized(comment: "kg") + " - \(exercise.sets)x\(exercise.reps)")
                }
            }
            .padding(.leading, 20)
        }
    }
}
