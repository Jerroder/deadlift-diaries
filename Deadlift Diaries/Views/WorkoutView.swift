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
    @State private var selectedWorkout: Workout?
    @State private var isAddingNewWorkout = false
    @State private var newWorkoutName = ""
    @State private var newWorkoutDate = Date()
    
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
        .sheet(item: $selectedWorkout) { workout in
            workoutEditSheet(workout: workout)
        }
        .sheet(isPresented: $isAddingNewWorkout) {
            workoutEditSheet(workout: nil)
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
    private func workoutEditSheet(workout: Workout?) -> some View {
        NavigationStack {
            Form {
                TextField("Workout Name", text: workout == nil ? $newWorkoutName : Binding(
                    get: { workout!.name },
                    set: { workout!.name = $0 }
                ))
                .withTextFieldToolbar()
                DatePicker(
                    "Date",
                    selection: workout == nil ? $newWorkoutDate : Binding(
                        get: { workout!.date },
                        set: { workout!.date = $0 }
                    ),
                    in: weekDateRange,
                    displayedComponents: .date
                )
            }
            .navigationTitle(workout == nil ? "New Workout" : "Rename Workout")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        if workout == nil {
                            let orderIndex = (week.workouts.map { $0.orderIndex }.max() ?? 0) + 1
                            let workout = Workout(name: newWorkoutName, orderIndex: orderIndex, date: newWorkoutDate)
                            week.workouts.append(workout)
                            workout.week = week
                            modelContext.insert(workout)
                        }
                        selectedWorkout = nil
                        isAddingNewWorkout = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        selectedWorkout = nil
                        isAddingNewWorkout = false
                    }
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
            isAddingNewWorkout = true
            newWorkoutName = ""
            newWorkoutDate = calculateDefaultWorkoutDate()
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
