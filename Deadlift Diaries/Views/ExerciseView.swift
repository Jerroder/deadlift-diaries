//
//  ExerciseView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData

struct ExerciseView: View {
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    
    @State private var selectedExercise: Exercise?
    @State private var isAddingNewExercise: Bool = false
    @State private var selectedExerciseIDs: Set<UUID> = Set<Exercise.ID>()
    @State private var isShowingWorkoutPicker: Bool = false
    @State private var expandedExerciseID: UUID?
    @State private var showingRestPicker: Bool = false
    @State private var showingDurationPicker: Bool = false
    @State private var showingDuration2Picker: Bool = false
    @State private var showingTimeBeforeNextPicker: Bool = false
    @State private var isSuperset: Bool = false
    
    @State private var newExerciseName: String = ""
    @State private var newExerciseSets: Int = 5
    @State private var newExerciseRestTime: Double = 60.0
    @State private var newExerciseIsTimeBased: Bool = false
    @State private var newExerciseReps: Int = 8
    @State private var newExerciseDuration: Double = 30.0
    @State private var newExerciseWeight: Double = 50.0
    @State private var newExerciseTimeBeforeNext: Double = 120.0
    @State private var newExerciseIsDistanceBased: Bool = false
    @State private var newExerciseDistance: Int = 200
    @State private var newExercise2Name: String = ""
    @State private var newExercise2IsTimeBased: Bool = false
    @State private var newExercise2Reps: Int = 8
    @State private var newExercise2Duration: Double = 30.0
    @State private var newExercise2Weight: Double = 50.0
    
    @State private var isKeyboardShowing: Bool = false
    @FocusState.Binding var focusedField: FocusableField?
    
    @State private var isTimerRunning: [UUID: Bool] = [:]
    
    private let weightUnit: Unit = isMetricSystem() ? Unit(symbol: "kg") : Unit(symbol: "lbs")
    private let distanceUnit: Unit = Unit(symbol: "m")
    
    private var availableWorkouts: [Workout] {
        guard let mesocycle = workout.week?.mesocycle else { return [] }
        return mesocycle.weeks!.flatMap { $0.workouts! }.filter { $0.id != workout.id }
    }
    
    private var sortedExercises: [Exercise] {
        workout.exercises!.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        exerciseRow()
            .listStyle(.plain)
            .navigationTitle(workout.name)
            .navigationBarBackButtonHidden(editMode?.wrappedValue.isEditing == true)
            .onAppear {
                selectedExerciseIDs.removeAll()
            }
            .sheet(item: $selectedExercise) { exercise in
                exerciseEditSheet(exercise: exercise)
            }
            .sheet(isPresented: $isAddingNewExercise) {
                exerciseEditSheet(exercise: nil)
            }
            .sheet(isPresented: $isShowingWorkoutPicker) {
                workoutPickerSheet()
            }
            .onChange(of: isAddingNewExercise) {
                showingRestPicker = false
                showingDurationPicker = false
                showingDuration2Picker = false
                showingTimeBeforeNextPicker = false
            }
            .onChange(of: selectedExercise) {
                showingRestPicker = false
                showingDurationPicker = false
                showingDuration2Picker = false
                showingTimeBeforeNextPicker = false
            }
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                if #available(iOS 26.0, *) {
                    Button(action: {
                        isAddingNewExercise = true
                        newExerciseName = ""
                        newExerciseSets = 5
                        newExerciseRestTime = 60
                        newExerciseIsTimeBased = false
                        newExerciseReps = 8
                        newExerciseDuration = 30
                        newExerciseWeight = 50.0
                        newExerciseTimeBeforeNext = 120.0
                        newExerciseIsDistanceBased = false
                        newExerciseDistance = 200
                        
                        isSuperset = false
                        newExercise2Name = ""
                        newExercise2IsTimeBased = false
                        newExercise2Reps = 8
                        newExercise2Duration = 30
                        newExercise2Weight = 50.0
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
                        isAddingNewExercise = true
                        newExerciseName = ""
                        newExerciseSets = 5
                        newExerciseRestTime = 60
                        newExerciseIsTimeBased = false
                        newExerciseReps = 8
                        newExerciseDuration = 30
                        newExerciseWeight = 50.0
                        newExerciseTimeBeforeNext = 120.0
                        newExerciseIsDistanceBased = false
                        newExerciseDistance = 200
                        
                        isSuperset = false
                        newExercise2Name = ""
                        newExercise2IsTimeBased = false
                        newExercise2Reps = 8
                        newExercise2Duration = 30
                        newExercise2Weight = 50.0
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
    private func exerciseRow() -> some View {
        List(selection: $selectedExerciseIDs) {
            ForEach(sortedExercises, id: \.id) { exercise in
                if let partner = partner(for: exercise), partner.isTheSuperset ?? false {
                    displayExercise(for: exercise)
                        .tag(exercise.id)
                        .opacity(((exercise.isTimeBased ? exercise.sets * 2 : exercise.sets) == exercise.currentSet - 1) ? 0.5 : 1)
                        .listRowSeparator(.hidden)
                    displayExercise(for: partner, isSuperset: true)
                        .tag(partner.id)
                        .opacity(((exercise.isTimeBased ? exercise.sets * 2 : exercise.sets) == exercise.currentSet - 1) ? 0.5 : 1)
                        .listRowSeparator(.hidden)
                } else if exercise.supersetPartnerID == nil {
                    displayExercise(for: exercise)
                        .tag(exercise.id)
                        .opacity(((exercise.isTimeBased ? exercise.sets * 2 : exercise.sets) == exercise.currentSet - 1) ? 0.5 : 1)
                        .listRowSeparator(.hidden)
                }
            }
            .onMove(perform: moveExercise)
        }
    }
    
    @ViewBuilder
    private func displayExercise(for exercise: Exercise, isSuperset: Bool? = false) -> some View {
        Group {
            if let partner = partner(for: exercise), partner.isTheSuperset ?? false {
                if editMode?.wrappedValue.isEditing == true {
                    Button(action: {
                        selectedExercise = exercise
                    }) {
                        HStack {
                            displayExercises(exercise: exercise)
                            displayExercises(exercise: partner, isSuperset: true)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    HStack {
                        displayExercises(exercise: exercise)
                        displayExercises(exercise: partner, isSuperset: true)
                    }
                    .onTapGesture {
                        withAnimation {
                            expandedExerciseID = (expandedExerciseID == exercise.id) ? nil : exercise.id
                        }
                    }
                    
                    if expandedExerciseID == exercise.id {
                        ProgressBarView(
                            totalSets: exercise.sets,
                            currentSet: Binding(
                                get: { exercise.currentSet },
                                set: { exercise.currentSet = $0 }
                            ),
                            restDuration: exercise.restTime,
                            timeBeforeNextExercise: exercise.timeBeforeNext,
                            isTimerRunning: Binding(
                                get: { isTimerRunning[exercise.id] ?? false },
                                set: { isTimerRunning[exercise.id] = $0 }
                            ),
                            elapsed: Binding(
                                get: { exercise.elapsed },
                                set: { exercise.elapsed = $0 }
                            ),
                            isTimeBased: exercise.isTimeBased,
                            duration: exercise.duration ?? 30.0,
                            isCalledFromTimer: false
                        )
                        .transition(.opacity)
                    }
                }
            } else if exercise.supersetPartnerID == nil {
                if editMode?.wrappedValue.isEditing == true {
                    Button(action: {
                        selectedExercise = exercise
                    }) {
                        displayExercises(exercise: exercise)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    displayExercises(exercise: exercise, isSuperset: isSuperset)
                        .onTapGesture {
                            withAnimation {
                                expandedExerciseID = (expandedExerciseID == exercise.id) ? nil : exercise.id
                            }
                        }
                    
                    if expandedExerciseID == exercise.id {
                        ProgressBarView(
                            totalSets: exercise.sets,
                            currentSet: Binding(
                                get: { exercise.currentSet },
                                set: { exercise.currentSet = $0 }
                            ),
                            restDuration: exercise.restTime,
                            timeBeforeNextExercise: exercise.timeBeforeNext,
                            isTimerRunning: Binding(
                                get: { isTimerRunning[exercise.id] ?? false },
                                set: { isTimerRunning[exercise.id] = $0 }
                            ),
                            elapsed: Binding(
                                get: { exercise.elapsed },
                                set: { exercise.elapsed = $0 }
                            ),
                            isTimeBased: exercise.isTimeBased,
                            duration: exercise.duration ?? 30.0,
                            isCalledFromTimer: false
                        )
                        .transition(.opacity)
                    }
                }
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteExercise(exercise)
            } label: {
                Label("delete".localized(comment: "Delete"), systemImage: "trash")
            }
        }
    }
    
    @ViewBuilder
    private func displayExercises(exercise: Exercise, isSuperset: Bool? = false) -> some View {
        let alignment: HorizontalAlignment = isSuperset == true ? .trailing : .leading
        HStack {
            VStack(alignment: alignment) {
                Text(exercise.name)
                    .font(.headline)
                
                if exercise.isTimeBased {
                    Text("duration_x_sec".localized(with: Int(exercise.duration ?? 0), comment: "Duration: x sec"))
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                } else {
                    if exercise.isDistanceBased ?? false {
                        if let distance = exercise.distance, distance != 0 {
                            Text("distance_x".localized(with: distance, distanceUnit.symbol, comment: "Distance: x m"))
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    }
                }
                
                if let weight = exercise.weight, weight != 0, !exercise.isDistanceBased! {
                    Text("weight_x".localized(with: weight, weightUnit.symbol, comment: "Weight: x kg"))
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                if !isSuperset! {
                    Text("sets_x".localized(with: exercise.sets, comment: "Sets: x"))
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                if !exercise.isTimeBased && !exercise.isDistanceBased! {
                    Text("reps_x".localized(with: exercise.reps ?? 0, comment: "Reps: x"))
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                if !isSuperset! && exercise.sets > 1 {
                    Text("rest_x_sec".localized(with: Int(exercise.restTime), comment: "Rest: x sec"))
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                } else {
                    Spacer()
                }
            }
            if !isSuperset! {
                Spacer()
            }
        }
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private func exerciseEditSheet(exercise: Exercise?) -> some View {
        NavigationStack {
            if let exercise = exercise { // edit exercise
                if let partner = partner(for: exercise) { // superset
                    exerciseEditForm(exercise1: exercise, exercise2: partner)
                        .navigationTitle("edit_superset".localized(comment: "Edit Superset"))
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("", systemImage: "checkmark") {
                                    try? modelContext.save()
                                    selectedExercise = nil
                                    focusedField = nil
                                }
                            }
                            ToolbarItem(placement: .cancellationAction) {
                                Button("", systemImage: "xmark") {
                                    selectedExercise = nil
                                    focusedField = nil
                                }
                            }
                        }
                } else { // set
                    exerciseEditForm(exercise1: exercise)
                        .navigationTitle("edit_exercise".localized(comment: "Edit Exercise"))
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("", systemImage: "checkmark") {
                                    if isSuperset {
                                        let partner = Exercise(
                                            name: newExercise2Name,
                                            weight: newExercise2IsTimeBased ? nil : newExercise2Weight,
                                            sets: 0,
                                            reps: newExercise2IsTimeBased ? nil : newExercise2Reps,
                                            duration: newExercise2IsTimeBased ? newExercise2Duration : nil,
                                            restTime: 0.0,
                                            isTimeBased: newExercise2IsTimeBased,
                                            orderIndex: exercise.orderIndex,
                                            timeBeforeNext: 0.0,
                                            isTheSuperset: true
                                        )
                                        partner.supersetPartnerID = exercise.id
                                        exercise.supersetPartnerID = partner.id
                                        workout.exercises!.append(partner)
                                        partner.workout = workout
                                        modelContext.insert(partner)
                                        workout.exercises!.sort { $0.orderIndex < $1.orderIndex }
                                    }
                                    try? modelContext.save()
                                    selectedExercise = nil
                                    focusedField = nil
                                }
                            }
                            ToolbarItem(placement: .cancellationAction) {
                                Button("", systemImage: "xmark") {
                                    selectedExercise = nil
                                    focusedField = nil
                                }
                            }
                        }
                }
            } else { // new exercise
                exerciseEditForm(exercise1: nil)
                    .navigationTitle("new_exercise".localized(comment: "New Exercise"))
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("", systemImage: "checkmark") {
                                let orderIndex: Int = (workout.exercises!.map { $0.orderIndex }.max() ?? 0) + 1
                                if isSuperset {
                                    let exercise1 = Exercise(
                                        name: newExerciseName,
                                        weight: newExerciseIsTimeBased ? nil : newExerciseWeight,
                                        sets: newExerciseSets,
                                        reps: newExerciseIsTimeBased ? nil : newExerciseReps,
                                        duration: newExerciseIsTimeBased ? newExerciseDuration : nil,
                                        restTime: newExerciseRestTime,
                                        isTimeBased: newExerciseIsTimeBased,
                                        orderIndex: orderIndex,
                                        timeBeforeNext: newExerciseTimeBeforeNext
                                    )
                                    let exercise2 = Exercise(
                                        name: newExercise2Name,
                                        weight: newExercise2IsTimeBased ? nil : newExercise2Weight,
                                        sets: 0,
                                        reps: newExercise2IsTimeBased ? nil : newExercise2Reps,
                                        duration: newExercise2IsTimeBased ? newExercise2Duration : nil,
                                        restTime: 0.0,
                                        isTimeBased: newExercise2IsTimeBased,
                                        orderIndex: orderIndex,
                                        timeBeforeNext: 0.0,
                                        isTheSuperset: true
                                    )
                                    exercise1.supersetPartnerID = exercise2.id
                                    exercise2.supersetPartnerID = exercise1.id
                                    workout.exercises!.append(exercise1)
                                    workout.exercises!.append(exercise2)
                                    exercise1.workout = workout
                                    exercise2.workout = workout
                                    modelContext.insert(exercise1)
                                    modelContext.insert(exercise2)
                                } else {
                                    let exercise = Exercise(
                                        name: newExerciseName,
                                        weight: newExerciseIsTimeBased ? nil : newExerciseWeight,
                                        sets: newExerciseSets,
                                        reps: newExerciseIsTimeBased ? nil : newExerciseReps,
                                        duration: newExerciseIsTimeBased ? newExerciseDuration : nil,
                                        restTime: newExerciseRestTime,
                                        isTimeBased: newExerciseIsTimeBased,
                                        orderIndex: orderIndex,
                                        timeBeforeNext: newExerciseTimeBeforeNext,
                                        isDistanceBased: newExerciseIsDistanceBased,
                                        distance: newExerciseDistance
                                    )
                                    workout.exercises!.append(exercise)
                                    exercise.workout = workout
                                    modelContext.insert(exercise)
                                }
                                try? modelContext.save()
                                selectedExercise = nil
                                isAddingNewExercise = false
                                focusedField = nil
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("", systemImage: "xmark") {
                                selectedExercise = nil
                                isAddingNewExercise = false
                                focusedField = nil
                            }
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private func exerciseEditForm(exercise1: Exercise? = nil, exercise2: Exercise? = nil) -> some View {
        Form {
            Section {
                Toggle("superset".localized(comment: "Superset"), isOn: Binding(
                    get: { exercise2 != nil || isSuperset },
                    set: { newValue in
                        isSuperset = newValue
                        if newValue {
                            if exercise1 != nil {
                                exercise1!.isDistanceBased = false
                            } else {
                                newExerciseIsDistanceBased = false
                            }
                        }
                        
                        if !newValue, let exercise = exercise1, exercise.supersetPartnerID != nil {
                            removeFromSuperset(exercise: exercise)
                        }
                        if !newValue && (focusedField == .supersetName || focusedField == .supersetWeight) {
                            focusedField = .exerciseWeight
                        }
                    }
                ))
                
                TextField("exercise_name".localized(comment: "Exercise name"), text: exercise1 == nil ? $newExerciseName : Binding(
                    get: { exercise1!.name },
                    set: { exercise1!.name = $0 }
                ))
                .focused($focusedField, equals: .exerciseName)
                
                Stepper(
                    "sets_x".localized(with: exercise1 == nil ? newExerciseSets : exercise1!.sets, comment: "Sets:"),
                    value: exercise1 == nil ? $newExerciseSets : Binding(
                        get: { exercise1!.sets },
                        set: { exercise1!.sets = $0 }
                    ),
                    in: 1...20
                )
                
                Button(action: {
                    withAnimation {
                        showingRestPicker.toggle()
                        showingDurationPicker = false
                        showingDuration2Picker = false
                        showingTimeBeforeNextPicker = false
                    }
                }) {
                    HStack {
                        HStack(spacing: 4) {
                            Text("rest_duration".localized(comment: "Rest duration"))
                            Text("  \(Int(exercise1 == nil ? newExerciseRestTime : exercise1!.restTime))s ")
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                            Image(systemName: showingRestPicker ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                        .fixedSize()
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if showingRestPicker {
                    Picker("rest_duration".localized(comment: "Rest duration"), selection: Binding(
                        get: { exercise1 == nil ? newExerciseRestTime : exercise1!.restTime },
                        set: { newValue in
                            if exercise1 == nil {
                                newExerciseRestTime = newValue
                            } else {
                                exercise1!.restTime = newValue
                            }
                        }
                    )) {
                        ForEach(Array(stride(from: 5.0, through: 300.0, by: 5.0)), id: \.self) { duration in
                            Text("\(Int(duration)) seconds".localized(comment: "(xxx) seconds")).tag(duration)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Toggle("time_based".localized(comment: "Time-based"), isOn: Binding(
                    get: { exercise1 == nil ? newExerciseIsTimeBased : exercise1!.isTimeBased },
                    set: { newValue in
                        withAnimation {
                            if exercise1 == nil {
                                newExerciseIsTimeBased = newValue
                                if newValue {
                                    newExerciseDuration = 30.0
                                } else {
                                    newExerciseReps = 8
                                }
                            } else {
                                exercise1!.isTimeBased = newValue
                                if newValue {
                                    exercise1!.duration = 30.0
                                } else {
                                    exercise1!.reps = 8
                                }
                            }
                        }
                    }
                ))
                
                if exercise1 == nil ? newExerciseIsTimeBased : exercise1!.isTimeBased {
                    Button(action: {
                        withAnimation {
                            showingDurationPicker.toggle()
                            showingDuration2Picker = false
                            showingRestPicker = false
                            showingTimeBeforeNextPicker = false
                        }
                    }) {
                        HStack {
                            Text("exercise_duration".localized(comment: "Exercise duration"))
                            Text(" \(Int((exercise1 == nil ? newExerciseDuration : exercise1!.duration) ?? 30.0))s")
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                            Image(systemName: showingDurationPicker ? "chevron.up" : "chevron.down")
                                .font(.caption)
                            Spacer()
                        }
                        .fixedSize()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    if showingDurationPicker {
                        Picker("exercise_duration".localized(comment: "Exercise duration"), selection: Binding(
                            get: { (exercise1 == nil ? newExerciseDuration : exercise1!.duration) ?? 30.0 },
                            set: { newValue in
                                if exercise1 == nil {
                                    newExerciseDuration = newValue
                                } else {
                                    exercise1!.duration = newValue
                                }
                            }
                        )) {
                            ForEach(Array(stride(from: 5.0, through: 600.0, by: 5.0)), id: \.self) { duration in
                                Text("\(Int(duration)) seconds".localized(comment: "(xxx) seconds")).tag(duration)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    
                    HStack {
                        Text("weight".localized(comment: "Weight:"))
                        TextFieldWithUnitDouble(
                            value: Binding(
                                get: { exercise1?.weight ?? newExerciseWeight },
                                set: { newValue in
                                    if exercise1 != nil {
                                        exercise1!.weight = newValue
                                    } else {
                                        newExerciseWeight = newValue
                                    }
                                }
                            ),
                            unit: Binding(
                                get: { weightUnit },
                                set: { _ in }
                            )
                        )
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .exerciseWeight)
                    }
                } else {
                    if !isSuperset {
                        Toggle("distance_based".localized(comment: "Distance-based"), isOn: Binding(
                            get: { (exercise1 == nil ? newExerciseIsDistanceBased : exercise1!.isDistanceBased) ?? false },
                            set: { newValue in
                                withAnimation {
                                    if exercise1 == nil {
                                        newExerciseIsDistanceBased = newValue
                                    } else {
                                        exercise1!.isDistanceBased = newValue
                                    }
                                }
                            }
                        ))
                    }
                    
                    if exercise1 == nil ? newExerciseIsDistanceBased : exercise1!.isDistanceBased! {
                        HStack {
                            Text("distance".localized(comment: "Distance:"))
                            TextFieldWithUnitInt(
                                value: Binding(
                                    get: { exercise1?.distance ?? newExerciseDistance },
                                    set: { newValue in
                                        if exercise1 != nil {
                                            exercise1!.distance = newValue
                                        } else {
                                            newExerciseDistance = newValue
                                        }
                                    }
                                ),
                                unit: Binding(
                                    get: { distanceUnit },
                                    set: { _ in }
                                )
                            )
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .exerciseWeight)
                        }
                    } else {
                        Stepper(
                            "reps_x".localized(with: exercise1 == nil ? newExerciseReps : exercise1!.reps ?? 8, comment: "Reps:"),
                            value: exercise1 == nil ? $newExerciseReps : Binding(
                                get: { exercise1!.reps ?? 10 },
                                set: { exercise1!.reps = $0 }
                            ),
                            in: 1...50
                        )
                        
                        HStack {
                            Text("weight".localized(comment: "Weight:"))
                            TextFieldWithUnitDouble(
                                value: Binding(
                                    get: { exercise1?.weight ?? newExerciseWeight },
                                    set: { newValue in
                                        if exercise1 != nil {
                                            exercise1!.weight = newValue
                                        } else {
                                            newExerciseWeight = newValue
                                        }
                                    }
                                ),
                                unit: Binding(
                                    get: { weightUnit },
                                    set: { _ in }
                                )
                            )
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .exerciseWeight)
                        }
                    }
                }
                
                Button(action: {
                    withAnimation {
                        showingTimeBeforeNextPicker.toggle()
                        showingRestPicker = false
                        showingDurationPicker = false
                        showingDuration2Picker = false
                    }
                }) {
                    HStack {
                        Text("time_before_next".localized(comment: "Time before next exercise"))
                        Text(" \(Int(exercise1 == nil ? newExerciseTimeBeforeNext : exercise1!.timeBeforeNext))s")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Image(systemName: showingTimeBeforeNextPicker ? "chevron.up" : "chevron.down")
                            .font(.caption)
                        Spacer()
                    }
                    .fixedSize()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if showingTimeBeforeNextPicker {
                    Picker("time_before_next".localized(comment: "Time before next exercise"), selection: Binding(
                        get: { exercise1 == nil ? newExerciseTimeBeforeNext : exercise1!.timeBeforeNext },
                        set: { newValue in
                            if exercise1 == nil {
                                newExerciseTimeBeforeNext = newValue
                            } else {
                                exercise1!.timeBeforeNext = newValue
                            }
                        }
                    )) {
                        ForEach(Array(stride(from: 5.0, through: 300.0, by: 5.0)), id: \.self) { duration in
                            Text("\(Int(duration)) seconds".localized(comment: "(xxx) seconds")).tag(duration)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            } /* Section */
            
            if isSuperset || exercise2 != nil {
                Section {
                    TextField("exercise_name".localized(comment: "Exercise name"), text: exercise2 == nil ? $newExercise2Name : Binding(
                        get: { exercise2!.name },
                        set: { exercise2!.name = $0 }
                    ))
                    .focused($focusedField, equals: .supersetName)
                    
                    Toggle("time_based".localized(comment: "Time-based"), isOn: Binding(
                        get: { exercise2 == nil ? newExercise2IsTimeBased : exercise2!.isTimeBased },
                        set: { newValue in
                            withAnimation {
                                if exercise2 == nil {
                                    newExercise2IsTimeBased = newValue
                                } else {
                                    exercise2!.isTimeBased = newValue
                                }
                            }
                        }
                    ))
                    
                    if exercise2 == nil ? newExercise2IsTimeBased : exercise2!.isTimeBased {
                        Button(action: {
                            withAnimation {
                                showingDuration2Picker.toggle()
                                showingDurationPicker = false
                                showingRestPicker = false
                                showingTimeBeforeNextPicker = false
                            }
                        }) {
                            HStack {
                                Text("exercise_duration".localized(comment: "Exercise duration"))
                                Text(" \(Int((exercise2 == nil ? newExercise2Duration : exercise2!.duration) ?? 30.0))s")
                                    .font(.subheadline)
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                Image(systemName: showingDuration2Picker ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                Spacer()
                            }
                            .fixedSize()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if showingDuration2Picker {
                            Picker("exercise_duration".localized(comment: "Exercise duration"), selection: Binding(
                                get: { (exercise2 == nil ? newExercise2Duration : exercise2!.duration) ?? 30.0 },
                                set: { newValue in
                                    if exercise2 == nil {
                                        newExercise2Duration = newValue
                                    } else {
                                        exercise2!.duration = newValue
                                    }
                                }
                            )) {
                                ForEach(Array(stride(from: 5.0, through: 600.0, by: 5.0)), id: \.self) { duration in
                                    Text("\(Int(duration)) seconds".localized(comment: "(xxx) seconds)")).tag(duration)
                                }
                            }
                            .pickerStyle(.wheel)
                        }
                    } else {
                        Stepper(
                            "reps_x".localized(with: exercise2 == nil ? newExercise2Reps : exercise2!.reps ?? 10, comment: "Reps:"),
                            value: exercise2 == nil ? $newExercise2Reps : Binding(
                                get: { exercise2!.reps ?? 10 },
                                set: { exercise2!.reps = $0 }
                            ),
                            in: 1...50
                        )
                        
                        HStack {
                            Text("weight".localized(comment: "Weight:"))
                            TextFieldWithUnitDouble(
                                value: Binding(
                                    get: { exercise2?.weight ?? newExercise2Weight },
                                    set: { newValue in
                                        if exercise2 != nil {
                                            exercise2!.weight = newValue
                                        } else {
                                            newExercise2Weight = newValue
                                        }
                                    }
                                ),
                                unit: Binding(
                                    get: { weightUnit },
                                    set: { _ in }
                                )
                            )
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .supersetWeight)
                        }
                    }
                } /* Section */
            } /* if isSuperset */
        } /* Form */
        .withTextFieldToolbarDoneWithChevrons(isKeyboardShowing: $isKeyboardShowing, isSupersetToggleOn: $isSuperset, focusedField: $focusedField)
    }
    
    @ViewBuilder
    private func leadingToolbarItems() -> some View {
        if editMode?.wrappedValue.isEditing == true {
            Menu {
                if selectedExerciseIDs.isEmpty {
                    Button(action: {
                        selectedExerciseIDs = Set(workout.exercises!.map { $0.id })
                    }) {
                        Label("select_all".localized(comment: "Select all"), systemImage: "checkmark.circle.fill")
                    }
                } else {
                    Button("copy".localized(comment: "Copy"), systemImage: "document.on.document") {
                        isShowingWorkoutPicker = true
                    }
                    Button("delete".localized(comment: "Delete"), systemImage: "trash", role: .destructive) {
                        deleteSelectedExercises()
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
    }
    
    @ViewBuilder
    private func workoutPickerSheet() -> some View {
        NavigationStack {
            let allWorkouts: [Workout] = workout.week?.mesocycle?.weeks!.flatMap { $0.workouts! } ?? []
            let targetWorkouts: [Workout] = allWorkouts
                .filter { $0.id != workout.id }
                .sorted {
                    guard let weekNumber1 = $0.week?.number,
                          let weekNumber2 = $1.week?.number else {
                        return $0.date < $1.date
                    }
                    if weekNumber1 != weekNumber2 {
                        return weekNumber1 < weekNumber2
                    } else {
                        return $0.date < $1.date
                    }
                }
            
            List(targetWorkouts) { targetWorkout in
                Button(action: {
                    copyExercises(to: targetWorkout)
                    isShowingWorkoutPicker = false
                }) {
                    VStack(alignment: .leading) {
                        Text(targetWorkout.name)
                            .font(.headline)
                        Text("week_x".localized(with: targetWorkout.week?.number ?? 0, comment: "Week x"))
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
            }
            .navigationTitle("copy_to_workout".localized(comment: "Copy to Workout"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        isShowingWorkoutPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func copyExercises(to targetWorkout: Workout) {
        let selectedExercises: [Exercise] = workout.exercises!
            .filter { selectedExerciseIDs.contains($0.id) }
            .sorted { $0.orderIndex < $1.orderIndex }
        
        let maxOrderIndex: Int = targetWorkout.exercises!.map { $0.orderIndex }.max() ?? 0
        var newOrderIndex = maxOrderIndex + 1
        var processedPartnerIDs = Set<UUID>()
        
        for exercise in selectedExercises {
            if processedPartnerIDs.contains(exercise.id) {
                continue
            }
            
            if let partner = partner(for: exercise) {
                let mainExercise = exercise.isTheSuperset ?? false ? partner : exercise
                let supersetExercise = exercise.isTheSuperset ?? false ? exercise : partner
                
                processedPartnerIDs.insert(mainExercise.id)
                processedPartnerIDs.insert(supersetExercise.id)
                
                let newExercise1 = Exercise(
                    name: mainExercise.name,
                    weight: mainExercise.weight,
                    sets: mainExercise.sets,
                    reps: mainExercise.reps,
                    duration: mainExercise.duration,
                    restTime: mainExercise.restTime,
                    isTimeBased: mainExercise.isTimeBased,
                    orderIndex: newOrderIndex,
                    timeBeforeNext: mainExercise.timeBeforeNext,
                    isDistanceBased: mainExercise.isDistanceBased,
                    distance: mainExercise.distance
                )
                let newExercise2 = Exercise(
                    name: supersetExercise.name,
                    weight: supersetExercise.weight,
                    sets: supersetExercise.sets,
                    reps: supersetExercise.reps,
                    duration: supersetExercise.duration,
                    restTime: supersetExercise.restTime,
                    isTimeBased: supersetExercise.isTimeBased,
                    orderIndex: newOrderIndex,
                    timeBeforeNext: supersetExercise.timeBeforeNext,
                    isTheSuperset: true,
                    isDistanceBased: supersetExercise.isDistanceBased,
                    distance: supersetExercise.distance
                )
                newExercise1.supersetPartnerID = newExercise2.id
                newExercise2.supersetPartnerID = newExercise1.id
                
                targetWorkout.exercises!.append(newExercise1)
                targetWorkout.exercises!.append(newExercise2)
                newExercise1.workout = targetWorkout
                newExercise2.workout = targetWorkout
                
                modelContext.insert(newExercise1)
                modelContext.insert(newExercise2)
            } else {
                let newExercise: Exercise = Exercise(
                    name: exercise.name,
                    weight: exercise.weight,
                    sets: exercise.sets,
                    reps: exercise.reps,
                    duration: exercise.duration,
                    restTime: exercise.restTime,
                    isTimeBased: exercise.isTimeBased,
                    orderIndex: newOrderIndex,
                    timeBeforeNext: exercise.timeBeforeNext,
                    isDistanceBased: exercise.isDistanceBased,
                    distance: exercise.distance
                )
                targetWorkout.exercises!.append(newExercise)
                newExercise.workout = targetWorkout
                modelContext.insert(newExercise)
            }
            
            newOrderIndex += 1
        }
        
        try? modelContext.save()
        selectedExerciseIDs.removeAll()
    }
    
    private func deleteExercise(_ exercise: Exercise) {
        if let partner = partner(for: exercise) {
            workout.exercises?.removeAll { $0.id == partner.id }
            modelContext.delete(partner)
        }
        workout.exercises?.removeAll { $0.id == exercise.id }
        modelContext.delete(exercise)
    }
    
    private func deleteSelectedExercises() {
        let exercisesToDelete: [Exercise] = workout.exercises!.filter { selectedExerciseIDs.contains($0.id) }
        for exercise in exercisesToDelete {
            modelContext.delete(exercise)
        }
        selectedExerciseIDs.removeAll()
        try? modelContext.save()
    }
    
    private func moveExercise(from source: IndexSet, to destination: Int) {
        var exercises = sortedExercises
        exercises.move(fromOffsets: source, toOffset: destination)
        
        for (index, exercise) in exercises.enumerated() {
            exercise.orderIndex = index
            if let partner = partner(for: exercise) {
                partner.orderIndex = index
            }
        }
        
        try? modelContext.save()
    }
    
    private func partner(for exercise: Exercise) -> Exercise? {
        guard let partnerID = exercise.supersetPartnerID else { return nil }
        return workout.exercises?.first { $0.id == partnerID }
    }
    
    private func isSuperset(exercise: Exercise) -> Bool {
        return exercise.supersetPartnerID != nil
    }
    
    private func removeFromSuperset(exercise: Exercise) {
        guard let partnerID = exercise.supersetPartnerID,
              let partner = workout.exercises?.first(where: { $0.id == partnerID }) else {
            return
        }
        partner.supersetPartnerID = nil
        partner.isTheSuperset = false
        exercise.supersetPartnerID = nil
        exercise.isTheSuperset = false
        workout.exercises?.removeAll { $0.id == partnerID }
        modelContext.delete(partner)
    }
}
