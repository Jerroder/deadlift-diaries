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
    @State private var isAddingNewWorkout: Bool = false
    @State private var newWorkoutName: String = ""
    @State private var newWorkoutDate: Date = Date()
    @State private var selectedWorkoutIDs: Set<UUID> = Set<Workout.ID>()
    @State private var isShowingWeekPicker: Bool = false
    @State private var templateWorkout: Workout? = nil
    
    @State private var isKeyboardShowing: Bool = false
    @FocusState.Binding var focusedField: FocusableField?
    
    private var weekDateRange: ClosedRange<Date> {
        let startDate = week.startDate
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate)!
        return startDate...endDate
    }
    
    private var availableWeeks: [Week] {
        guard let mesocycle = week.mesocycle else { return [] }
        return mesocycle.weeks!
            .filter { $0.id != week.id }
            .sorted { $0.startDate < $1.startDate }
    }
    
    private var sortedWorkouts: [Workout] {
        week.workouts!.sorted(by: { $0.date < $1.date })
    }
    
    private var allAvailableWorkouts: [Workout] {
        guard let mesocycle = week.mesocycle else { return [] }
        return mesocycle.weeks!
            .flatMap { $0.workouts ?? [] }
            .sorted { $0.date > $1.date }
    }
    
    private func groupedWorkoutsByWeek() -> [(week: Week, workouts: [Workout])] {
        guard let mesocycle = week.mesocycle else { return [] }
        
        return mesocycle.weeks!
            .sorted { $0.startDate < $1.startDate }
            .compactMap { week in
                let workouts = week.workouts?.sorted { $0.date < $1.date } ?? []
                return workouts.isEmpty ? nil : (week: week, workouts: workouts)
            }
    }
    
    // MARK: - Main view
    
    var body: some View {
        workoutRows()
            .navigationTitle("week_x".localized(with: week.number, comment: "Week x"))
            .navigationBarBackButtonHidden(editMode?.wrappedValue.isEditing == true)
            .sheet(item: $selectedWorkout) { workout in
                workoutEditSheet(workout: workout)
            }
            .sheet(isPresented: $isAddingNewWorkout) {
                workoutEditSheet(workout: nil)
            }
            .sheet(isPresented: $isShowingWeekPicker) {
                weekPickerSheet()
            }
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                if #available(iOS 26.0, *) {
                    Button(action: {
                        isAddingNewWorkout = true
                        newWorkoutName = ""
                        newWorkoutDate = calculateDefaultWorkoutDate()
                        templateWorkout = nil
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22))
                            .padding([.leading, .trailing], 0)
                            .padding([.top, .bottom], 6)
                    }
                    .padding()
                    .buttonStyle(.glassProminent)
                } else {
                    Button(action: {
                        isAddingNewWorkout = true
                        newWorkoutName = ""
                        newWorkoutDate = calculateDefaultWorkoutDate()
                        templateWorkout = nil
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22))
                            .padding([.leading, .trailing], 0)
                            .padding([.top, .bottom], 6)
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    leadingToolbarItems()
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .environment(\.editMode, Binding(
                get: { editMode?.wrappedValue ?? .inactive },
                set: { editMode?.wrappedValue = $0 }
            ))
    }
    
    // MARK: - ViewBuilder functions
    
    @ViewBuilder
    private func workoutRows() -> some View {
        List(selection: editMode?.wrappedValue.isEditing == true ? $selectedWorkoutIDs : .constant(Set<UUID>())) {
            ForEach(sortedWorkouts) { workout in
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
                            ExerciseView(workout: workout, focusedField: $focusedField)
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
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteWorkout(workout)
                    } label: {
                        Label("delete".localized(comment: "Delete"), systemImage: "trash")
                    }
                }
                .tag(workout.id)
            }
        }
        .onChange(of: editMode?.wrappedValue.isEditing) { _, isEditing in
            if isEditing == false {
                selectedWorkoutIDs.removeAll()
            }
        }
    }
    
    @ViewBuilder
    private func workoutEditSheet(workout: Workout?) -> some View {
        NavigationStack {
            Form {
                TextField("workout_name".localized(comment: "Workout Name"), text: workout == nil ? $newWorkoutName : Binding(
                    get: { workout!.name },
                    set: { workout!.name = $0 }
                ))
                .focused($focusedField, equals: .workoutName)
                DatePicker(
                    "date".localized(comment: "Date"),
                    selection: workout == nil ? $newWorkoutDate : Binding(
                        get: { workout!.date },
                        set: { workout!.date = $0 }
                    ),
                    in: weekDateRange,
                    displayedComponents: .date
                )
                
                if workout == nil && !allAvailableWorkouts.isEmpty {
                    Section {
                        NavigationLink {
                            templatePickerView()
                        } label: {
                            HStack {
                                Text("use_as_template".localized(comment: "Use as template"))
                                Spacer()
                                if let template = templateWorkout {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(template.name)
                                            .foregroundColor(.secondary)
                                        if let exercises = template.exercises, !exercises.isEmpty {
                                            Text("x_exercises".localized(with: exercises.count, comment: "x exercises"))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                } else {
                                    Text("empty_workout".localized(comment: "Empty workout"))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("template".localized(comment: "Template"))
                    }
                }
            }
            .withTextFieldToolbarDone(isKeyboardShowing: $isKeyboardShowing, focusedField: $focusedField)
            .navigationTitle(workout == nil ? "new_workout".localized(comment: "New Workout") : "rename_workout".localized(comment: "Rename Workout"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        if workout == nil {
                            let orderIndex: Int = (week.workouts!.map { $0.orderIndex }.max() ?? 0) + 1
                            let newWorkout: Workout = Workout(name: newWorkoutName, orderIndex: orderIndex, date: newWorkoutDate)
                            week.workouts!.append(newWorkout)
                            newWorkout.week = week
                            modelContext.insert(newWorkout)
                            
                            if let template = templateWorkout {
                                copyExercisesFromTemplate(template: template, to: newWorkout)
                            }
                        }
                        try? modelContext.save()
                        selectedWorkout = nil
                        isAddingNewWorkout = false
                        templateWorkout = nil
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
    private func leadingToolbarItems() -> some View {
        if editMode?.wrappedValue.isEditing == true {
            Menu {
                if selectedWorkoutIDs.isEmpty {
                    Button(action: {
                        selectedWorkoutIDs = Set(week.workouts!.map { $0.id })
                    }) {
                        Label("select_all".localized(comment: "Select all"), systemImage: "checkmark.circle.fill")
                    }
                } else {
                    Button(action: duplicateSelectedWorkouts) {
                        Label("duplicate".localized(comment: "Duplicate"), systemImage: "plus.square.on.square")
                    }
                    Button(action: {
                        isShowingWeekPicker = true
                    }) {
                        Label("copy".localized(comment: "Copy"), systemImage: "document.on.document")
                    }
                    Button(role: .destructive, action: {
                        deleteSelectedWorkouts()
                    }) {
                        Label("delete".localized(comment: "Delete"), systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
    }
    
    @ViewBuilder
    private func templatePickerView() -> some View {
        List {
            Section {
                Button(action: {
                    templateWorkout = nil
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("empty_workout".localized(comment: "Empty workout"))
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("start_from_scratch".localized(comment: "Start from scratch"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if templateWorkout == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            
            ForEach(groupedWorkoutsByWeek(), id: \.week.id) { group in
                Section {
                    ForEach(group.workouts) { availableWorkout in
                        Button(action: {
                            templateWorkout = availableWorkout
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(availableWorkout.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let exercises = availableWorkout.exercises, !exercises.isEmpty {
                                        Text("x_exercises".localized(with: exercises.count, comment: "x exercises"))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        let exerciseNames = exercises
                                            .sorted { $0.orderIndex < $1.orderIndex }
                                            .filter { !($0.isTheSuperset ?? false) }
                                            .prefix(3)
                                            .map { $0.name }
                                            .joined(separator: ", ")
                                        
                                        Text(exerciseNames + (exercises.count > 3 ? "..." : ""))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    } else {
                                        Text("no_exercises".localized(comment: "No exercises"))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if templateWorkout?.id == availableWorkout.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text("week_x".localized(with: group.week.number, comment: "Week x"))
                }
            }
        }
        .navigationTitle("select_template".localized(comment: "Select Template"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func weekPickerSheet() -> some View {
        NavigationStack {
            List(availableWeeks) { targetWeek in
                Button(action: {
                    copyWorkouts(to: targetWeek)
                    isShowingWeekPicker = false
                }) {
                    VStack(alignment: .leading) {
                        Text("week_x".localized(with: targetWeek.number, comment: "Week"))
                            .font(.headline)
                        Text("start_xdate".localized(with: targetWeek.startDate.formattedRelative(), comment: "Start:"))
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
            }
            .navigationTitle("copy_to_week".localized(comment: "Copy to Week"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        isShowingWeekPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func copyWorkouts(to targetWeek: Week) {
        let selectedWorkouts: [Workout] = week.workouts!.filter { selectedWorkoutIDs.contains($0.id) }
        let maxOrderIndex: Int = targetWeek.workouts!.map { $0.orderIndex }.max() ?? 0
        
        let sourceWeekStart: Date = Calendar.current.startOfDay(for: week.startDate)
        let targetWeekStart: Date = Calendar.current.startOfDay(for: targetWeek.startDate)
        let dayOffset: Int = Calendar.current.dateComponents([.day], from: sourceWeekStart, to: targetWeekStart).day!
        
        for (index, workout) in selectedWorkouts.enumerated() {
            func partner(for exercise: Exercise) -> Exercise? {
                guard let partnerID = exercise.supersetPartnerID else { return nil }
                return workout.exercises?.first { $0.id == partnerID }
            }
            
            let originalWorkoutDate: Date = Calendar.current.startOfDay(for: workout.date)
            let newWorkoutDate: Date = Calendar.current.date(byAdding: .day, value: dayOffset, to: originalWorkoutDate)!
            
            let newWorkout: Workout = Workout(
                name: workout.name,
                orderIndex: maxOrderIndex + index + 1,
                date: newWorkoutDate
            )
            targetWeek.workouts!.append(newWorkout)
            newWorkout.week = targetWeek
            modelContext.insert(newWorkout)
            
            let exercises = workout.exercises!.sorted { $0.orderIndex < $1.orderIndex }
            var exerciseMapping: [UUID: UUID] = [:]
            var processedPartnerIDs = Set<UUID>()
            
            for exercise in exercises {
                if processedPartnerIDs.contains(exercise.id) {
                    continue
                }
                
                if let partner = partner(for: exercise) {
                    let mainExercise = exercise.isTheSuperset ?? false ? partner : exercise
                    let supersetExercise = exercise.isTheSuperset ?? false ? exercise : partner
                    
                    processedPartnerIDs.insert(mainExercise.id)
                    processedPartnerIDs.insert(supersetExercise.id)
                    
                    let newMainExercise = Exercise(
                        name: mainExercise.name,
                        weight: mainExercise.weight,
                        sets: mainExercise.sets,
                        reps: mainExercise.reps,
                        duration: mainExercise.duration,
                        restTime: mainExercise.restTime,
                        isTimeBased: mainExercise.isTimeBased,
                        orderIndex: mainExercise.orderIndex,
                        timeBeforeNext: mainExercise.timeBeforeNext,
                        isDistanceBased: mainExercise.isDistanceBased
                    )
                    let newSupersetExercise = Exercise(
                        name: supersetExercise.name,
                        weight: supersetExercise.weight,
                        sets: supersetExercise.sets,
                        reps: supersetExercise.reps,
                        duration: supersetExercise.duration,
                        restTime: supersetExercise.restTime,
                        isTimeBased: supersetExercise.isTimeBased,
                        orderIndex: supersetExercise.orderIndex,
                        timeBeforeNext: supersetExercise.timeBeforeNext,
                        isTheSuperset: true,
                        isDistanceBased: supersetExercise.isDistanceBased
                    )
                    newMainExercise.supersetPartnerID = newSupersetExercise.id
                    newSupersetExercise.supersetPartnerID = newMainExercise.id
                    
                    newMainExercise.template = mainExercise.template
                    newSupersetExercise.template = supersetExercise.template
                    
                    newWorkout.exercises!.append(newMainExercise)
                    newWorkout.exercises!.append(newSupersetExercise)
                    newMainExercise.workout = newWorkout
                    newSupersetExercise.workout = newWorkout
                    
                    modelContext.insert(newMainExercise)
                    modelContext.insert(newSupersetExercise)
                    
                    exerciseMapping[mainExercise.id] = newMainExercise.id
                    exerciseMapping[supersetExercise.id] = newSupersetExercise.id
                } else {
                    let newExercise: Exercise = Exercise(
                        name: exercise.name,
                        weight: exercise.weight,
                        sets: exercise.sets,
                        reps: exercise.reps,
                        duration: exercise.duration,
                        restTime: exercise.restTime,
                        isTimeBased: exercise.isTimeBased,
                        orderIndex: exercise.orderIndex,
                        timeBeforeNext: exercise.timeBeforeNext,
                        isDistanceBased: exercise.isDistanceBased,
                        distance: exercise.distance
                    )
                    newExercise.template = exercise.template
                    newWorkout.exercises!.append(newExercise)
                    newExercise.workout = newWorkout
                    modelContext.insert(newExercise)
                    
                    exerciseMapping[exercise.id] = newExercise.id
                }
            }
        }
        
        selectedWorkoutIDs.removeAll()
        try? modelContext.save()
    }
    
    private func deleteWorkout(_ workout: Workout) {
        if let index: Int = week.workouts!.firstIndex(where: { $0.id == workout.id }) {
            modelContext.delete(week.workouts![index])
        }
    }
    
    private func deleteSelectedWorkouts() {
        let workoutsToDelete: [Workout] = week.workouts!.filter { selectedWorkoutIDs.contains($0.id) }
        for workout in workoutsToDelete {
            modelContext.delete(workout)
        }
        selectedWorkoutIDs.removeAll()
        try? modelContext.save()
    }
    
    private func duplicateSelectedWorkouts() {
        let selectedWorkouts: [Workout] = sortedWorkouts.filter { selectedWorkoutIDs.contains($0.id) }
        guard !selectedWorkouts.isEmpty else { return }
        
        let maxOrderIndex: Int = week.workouts!.map { $0.orderIndex }.max() ?? 0
        let lastWorkoutDate: Date = sortedWorkouts.last?.date ?? week.startDate
        
        for (index, workout) in selectedWorkouts.enumerated() {
            func partner(for exercise: Exercise) -> Exercise? {
                guard let partnerID = exercise.supersetPartnerID else { return nil }
                return workout.exercises?.first { $0.id == partnerID }
            }
            
            let newWorkoutDate: Date = Calendar.current.date(byAdding: .day, value: index + 1, to: lastWorkoutDate) ?? week.startDate
            
            let newWorkout: Workout = Workout(
                name: workout.name,
                orderIndex: maxOrderIndex + index + 1,
                date: newWorkoutDate
            )
            week.workouts!.append(newWorkout)
            newWorkout.week = week
            modelContext.insert(newWorkout)
            
            let exercises = workout.exercises!.sorted { $0.orderIndex < $1.orderIndex }
            var processedPartnerIDs = Set<UUID>()
            
            for exercise in exercises {
                if processedPartnerIDs.contains(exercise.id) {
                    continue
                }
                
                if let partner = partner(for: exercise) {
                    let mainExercise = exercise.isTheSuperset ?? false ? partner : exercise
                    let supersetExercise = exercise.isTheSuperset ?? false ? exercise : partner
                    
                    processedPartnerIDs.insert(mainExercise.id)
                    processedPartnerIDs.insert(supersetExercise.id)
                    
                    let newMainExercise = Exercise(
                        name: mainExercise.name,
                        weight: mainExercise.weight,
                        sets: mainExercise.sets,
                        reps: mainExercise.reps,
                        duration: mainExercise.duration,
                        restTime: mainExercise.restTime,
                        isTimeBased: mainExercise.isTimeBased,
                        orderIndex: mainExercise.orderIndex,
                        timeBeforeNext: mainExercise.timeBeforeNext,
                        isDistanceBased: mainExercise.isDistanceBased
                    )
                    let newSupersetExercise = Exercise(
                        name: supersetExercise.name,
                        weight: supersetExercise.weight,
                        sets: supersetExercise.sets,
                        reps: supersetExercise.reps,
                        duration: supersetExercise.duration,
                        restTime: supersetExercise.restTime,
                        isTimeBased: supersetExercise.isTimeBased,
                        orderIndex: supersetExercise.orderIndex,
                        timeBeforeNext: supersetExercise.timeBeforeNext,
                        isTheSuperset: true,
                        isDistanceBased: supersetExercise.isDistanceBased
                    )
                    newMainExercise.supersetPartnerID = newSupersetExercise.id
                    newSupersetExercise.supersetPartnerID = newMainExercise.id
                    
                    newMainExercise.template = mainExercise.template
                    newSupersetExercise.template = supersetExercise.template
                    
                    newWorkout.exercises!.append(newMainExercise)
                    newWorkout.exercises!.append(newSupersetExercise)
                    newMainExercise.workout = newWorkout
                    newSupersetExercise.workout = newWorkout
                    
                    modelContext.insert(newMainExercise)
                    modelContext.insert(newSupersetExercise)
                } else {
                    let newExercise: Exercise = Exercise(
                        name: exercise.name,
                        weight: exercise.weight,
                        sets: exercise.sets,
                        reps: exercise.reps,
                        duration: exercise.duration,
                        restTime: exercise.restTime,
                        isTimeBased: exercise.isTimeBased,
                        orderIndex: exercise.orderIndex,
                        timeBeforeNext: exercise.timeBeforeNext,
                        isDistanceBased: exercise.isDistanceBased,
                        distance: exercise.distance
                    )
                    newExercise.template = exercise.template
                    newWorkout.exercises!.append(newExercise)
                    newExercise.workout = newWorkout
                    modelContext.insert(newExercise)
                }
            }
        }
        
        selectedWorkoutIDs.removeAll()
        try? modelContext.save()
    }
    
    private func calculateDefaultWorkoutDate() -> Date {
        guard let lastWorkout: Workout = week.workouts!.sorted(by: { $0.date < $1.date }).last else {
            return week.startDate
        }
        return Calendar.current.date(byAdding: .day, value: 1, to: lastWorkout.date) ?? week.startDate
    }
    
    private func copyExercisesFromTemplate(template: Workout, to newWorkout: Workout) {
        func partner(for exercise: Exercise) -> Exercise? {
            guard let partnerID = exercise.supersetPartnerID else { return nil }
            return template.exercises?.first { $0.id == partnerID }
        }
        
        let exercises = template.exercises!.sorted { $0.orderIndex < $1.orderIndex }
        var processedPartnerIDs = Set<UUID>()
        
        for exercise in exercises {
            if processedPartnerIDs.contains(exercise.id) {
                continue
            }
            
            if let partner = partner(for: exercise) {
                let mainExercise = exercise.isTheSuperset ?? false ? partner : exercise
                let supersetExercise = exercise.isTheSuperset ?? false ? exercise : partner
                
                processedPartnerIDs.insert(mainExercise.id)
                processedPartnerIDs.insert(supersetExercise.id)
                
                let newMainExercise = Exercise(
                    name: mainExercise.name,
                    weight: mainExercise.weight,
                    sets: mainExercise.sets,
                    reps: mainExercise.reps,
                    duration: mainExercise.duration,
                    restTime: mainExercise.restTime,
                    isTimeBased: mainExercise.isTimeBased,
                    orderIndex: mainExercise.orderIndex,
                    timeBeforeNext: mainExercise.timeBeforeNext,
                    isDistanceBased: mainExercise.isDistanceBased
                )
                let newSupersetExercise = Exercise(
                    name: supersetExercise.name,
                    weight: supersetExercise.weight,
                    sets: supersetExercise.sets,
                    reps: supersetExercise.reps,
                    duration: supersetExercise.duration,
                    restTime: supersetExercise.restTime,
                    isTimeBased: supersetExercise.isTimeBased,
                    orderIndex: supersetExercise.orderIndex,
                    timeBeforeNext: supersetExercise.timeBeforeNext,
                    isTheSuperset: true,
                    isDistanceBased: supersetExercise.isDistanceBased
                )
                newMainExercise.supersetPartnerID = newSupersetExercise.id
                newSupersetExercise.supersetPartnerID = newMainExercise.id
                
                newMainExercise.template = mainExercise.template
                newSupersetExercise.template = supersetExercise.template
                
                newWorkout.exercises!.append(newMainExercise)
                newWorkout.exercises!.append(newSupersetExercise)
                newMainExercise.workout = newWorkout
                newSupersetExercise.workout = newWorkout
                
                modelContext.insert(newMainExercise)
                modelContext.insert(newSupersetExercise)
            } else {
                let newExercise: Exercise = Exercise(
                    name: exercise.name,
                    weight: exercise.weight,
                    sets: exercise.sets,
                    reps: exercise.reps,
                    duration: exercise.duration,
                    restTime: exercise.restTime,
                    isTimeBased: exercise.isTimeBased,
                    orderIndex: exercise.orderIndex,
                    timeBeforeNext: exercise.timeBeforeNext,
                    isDistanceBased: exercise.isDistanceBased,
                    distance: exercise.distance
                )
                newExercise.template = exercise.template
                newWorkout.exercises!.append(newExercise)
                newExercise.workout = newWorkout
                modelContext.insert(newExercise)
            }
        }
    }
}
