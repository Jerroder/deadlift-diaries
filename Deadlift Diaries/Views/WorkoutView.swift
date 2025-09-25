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
    @State private var workoutDate = Date()
    
    private var weekDateRange: ClosedRange<Date> {
        let startDate = week.startDate
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate)!
        return startDate...endDate
    }
    
    var body: some View {
        List {
            ForEach(week.workouts.sorted(by: { $0.date < $1.date })) { workout in
                workoutRow(for: workout)
            }
            .onDelete(perform: deleteWorkouts)
        }
        .navigationTitle("Week \(week.number)")
        .navigationBarBackButtonHidden(editMode?.wrappedValue.isEditing == true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                leadingToolbarItems
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                trailingToolbarItems
            }
        }
        .sheet(isPresented: $isShowingWorkoutSheet) {
            NavigationStack {
                Form {
                    TextField("Workout Name", text: $workoutName)
                        .withTextFieldToolbar()
                    DatePicker(
                        "Date",
                        selection: $workoutDate,
                        in: weekDateRange,
                        displayedComponents: .date
                    )
                }
                .navigationTitle(selectedWorkout == nil ? "New Workout" : "Rename Workout")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("", systemImage: "checkmark") {
                            if let workout = selectedWorkout {
                                workout.name = workoutName
                                workout.date = workoutDate
                            } else {
                                let orderIndex = (week.workouts.map { $0.orderIndex }.max() ?? 0) + 1
                                let workout = Workout(name: workoutName, orderIndex: orderIndex, date: workoutDate)
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
    
    @ViewBuilder
    private func workoutRow(for workout: Workout) -> some View {
        let isPast: Bool = Calendar.current.startOfDay(for: workout.date) < Calendar.current.startOfDay(for: Date())
        
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
                        Text(workout.date.formattedRelative())
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Spacer()
                    }
                    .opacity(isPast ? 0.5 : 1.0)
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
                        Text(workout.date.formattedRelative())
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Spacer()
                    }
                    .opacity(isPast ? 0.5 : 1.0)
                        .contentShape(Rectangle())
                }
            }
        }
    }
    
    @ViewBuilder
    private var leadingToolbarItems: some View {
        if editMode?.wrappedValue.isEditing == true {
            Menu {
                Button(action: {
                    print("test")
                }) {
                    Label("info".localized(comment: "Info"), systemImage: "info.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    @ViewBuilder
    private var trailingToolbarItems: some View {
        EditButton()
        
        Button("", systemImage: "plus") {
            selectedWorkout = nil
            workoutName = ""
            workoutDate = calculateDefaultWorkoutDate()
            isShowingWorkoutSheet = true
        }
    }
    
    private func deleteWorkouts(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(week.workouts[index])
        }
    }
    
    private func calculateDefaultWorkoutDate() -> Date {
        guard let lastWorkout = week.workouts.sorted(by: { $0.date < $1.date }).last else {
            return week.startDate
        }
        return Calendar.current.date(byAdding: .day, value: 1, to: lastWorkout.date) ?? week.startDate
    }
}
