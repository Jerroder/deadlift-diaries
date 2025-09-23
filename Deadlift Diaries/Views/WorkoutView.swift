//
//  WorkoutView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    let week: Week
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @State private var isShowingWorkoutSheet = false
    @State private var selectedWorkout: Workout?
    @State private var workoutName = ""
    
    var body: some View {
        List {
            ForEach(week.workouts.sorted { $0.orderIndex < $1.orderIndex }) { workout in
                Section {
                    if editMode?.wrappedValue.isEditing == true {
                        Button(action: {
                            selectedWorkout = workout
                            workoutName = workout.name
                            isShowingWorkoutSheet = true
                        }) {
                            HStack {
                                Text(workout.name)
                                    .font(.headline)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        NavigationLink {
                            ExerciseView(workout: workout)
                        } label: {
                            HStack {
                                Text(workout.name)
                                    .font(.headline)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
            .onDelete(perform: deleteWorkouts)
        }
        .navigationTitle("Week \(week.number)")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                EditButton()
                
                Button("", systemImage: "plus") {
                    selectedWorkout = nil
                    workoutName = ""
                    isShowingWorkoutSheet = true
                }
            }
        }
        .sheet(isPresented: $isShowingWorkoutSheet) {
            NavigationStack {
                Form {
                    TextField("Workout Name", text: $workoutName)
                        .withTextFieldToolbar()
                }
                .navigationTitle(selectedWorkout == nil ? "New Workout" : "Rename Workout")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("", systemImage: "checkmark") {
                            if let workout = selectedWorkout {
                                workout.name = workoutName
                            } else {
                                let orderIndex = (week.workouts.map { $0.orderIndex }.max() ?? 0) + 1
                                let workout = Workout(name: workoutName, orderIndex: orderIndex)
                                week.workouts.append(workout)
                                workout.week = week
                                modelContext.insert(workout)
                            }
                            isShowingWorkoutSheet = false
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("", systemImage: "xmark") {
                            isShowingWorkoutSheet = false
                        }
                    }
                }
            }
        }
        .environment(\.editMode, Binding(
            get: { editMode?.wrappedValue ?? .inactive },
            set: { editMode?.wrappedValue = $0 }
        ))
    }
    
    private func deleteWorkouts(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(week.workouts[index])
        }
    }
}
