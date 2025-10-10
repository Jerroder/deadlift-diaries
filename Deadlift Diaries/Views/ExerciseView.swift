//
//  ExerciseView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData

enum FocusableField: Hashable {
    case exerciseName, exerciseWeight, supersetName, supersetWeight
}

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
    @State private var newExercise2Name: String = ""
    @State private var newExercise2IsTimeBased: Bool = false
    @State private var newExercise2Reps: Int = 8
    @State private var newExercise2Duration: Double = 30.0
    @State private var newExercise2Weight: Double = 50.0
    
    @State private var isKeyboardShowing: Bool = false
    @FocusState private var focusedField: FocusableField?
    
    @State private var isTimerRunning: [UUID: Bool] = [:]
    
    private let unit: Unit = isMetricSystem() ? Unit(symbol: "kg") : Unit(symbol: "lbs")
    
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
                if let partner = partner(for: exercise), partner.orderIndex > exercise.orderIndex {
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
        }
    }
    
    @ViewBuilder
    private func displayExercise(for exercise: Exercise, isSuperset: Bool? = false) -> some View {
        Group {
            if let partner = partner(for: exercise), partner.orderIndex > exercise.orderIndex {
                if editMode?.wrappedValue.isEditing == true {
                    Button(action: {
                        selectedExercise = exercise
                    }) {
                        HStack {
                            displayExercises(exercise: exercise, unit: unit)
                            displayExercises(exercise: partner, unit: unit, isSuperset: true)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    HStack {
                        displayExercises(exercise: exercise, unit: unit)
                        displayExercises(exercise: partner, unit: unit, isSuperset: true)
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
                            duration: exercise.duration ?? 30.0
                        )
                        .transition(.opacity)
                    }
                }
            } else if exercise.supersetPartnerID == nil {
                if editMode?.wrappedValue.isEditing == true {
                    Button(action: {
                        selectedExercise = exercise
                    }) {
                        displayExercises(exercise: exercise, unit: unit)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    displayExercises(exercise: exercise, unit: unit, isSuperset: isSuperset)
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
                            duration: exercise.duration ?? 30.0
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
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    @ViewBuilder
    private func displayExercises(exercise: Exercise, unit: Unit, isSuperset: Bool? = false) -> some View {
        let alignment: HorizontalAlignment = isSuperset == true ? .trailing : .leading
        HStack {
            VStack(alignment: alignment) {
                Text(exercise.name)
                    .font(.headline)
                
                if exercise.isTimeBased {
                    Text("Duration: \(Int(exercise.duration ?? 0)) sec")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                } else {
                    if let weight = exercise.weight, weight != 0 {
                        Text("Weight: \(String(format: "%.1f", weight)) \(unit.symbol)")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
                
                if !isSuperset! {
                    Text("Sets: \(exercise.sets)")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                if !exercise.isTimeBased {
                    Text("Reps: \(exercise.reps ?? 0)")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                if !isSuperset! {
                    Text("Rest: \(Int(exercise.restTime)) sec")
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
                        .navigationTitle("Edit Superset")
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
                        .navigationTitle("Edit Exercise")
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
                                            orderIndex: exercise.orderIndex + 1,
                                            timeBeforeNext: 0.0
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
                    .navigationTitle("New Exercise")
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
                                        orderIndex: orderIndex + 1,
                                        timeBeforeNext: 0.0
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
                                        timeBeforeNext: newExerciseTimeBeforeNext
                                    )
                                    workout.exercises!.append(exercise)
                                    exercise.workout = workout
                                    modelContext.insert(exercise)
                                }
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
                Toggle("Superset", isOn: Binding(
                    get: { exercise2 != nil || isSuperset },
                    set: { newValue in
                        isSuperset = newValue
                        if !newValue, let exercise = exercise1, exercise.supersetPartnerID != nil {
                            removeFromSuperset(exercise: exercise)
                        }
                        if !newValue && (focusedField == .supersetName || focusedField == .supersetWeight) {
                            focusedField = .exerciseWeight
                        }
                    }
                ))
                
                TextField("Exercise name", text: exercise1 == nil ? $newExerciseName : Binding(
                    get: { exercise1!.name },
                    set: { exercise1!.name = $0 }
                ))
                .focused($focusedField, equals: .exerciseName)
                
                Stepper(
                    "Sets: \(exercise1 == nil ? newExerciseSets : exercise1!.sets)",
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
                            Text("Rest duration")
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
                    Picker("Rest duration", selection: Binding(
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
                            Text("\(Int(duration)) seconds").tag(duration)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Toggle("Time based", isOn: Binding(
                    get: { exercise1 == nil ? newExerciseIsTimeBased : exercise1!.isTimeBased },
                    set: { newValue in
                        withAnimation {
                            if exercise1 == nil {
                                newExerciseIsTimeBased = newValue
                            } else {
                                exercise1!.isTimeBased = newValue
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
                            Text("Exercise duration")
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
                        Picker("Exercise duration", selection: Binding(
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
                                Text("\(Int(duration)) seconds").tag(duration)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                } else {
                    Stepper(
                        "Reps: \(exercise1 == nil ? newExerciseReps : exercise1!.reps ?? 10)",
                        value: exercise1 == nil ? $newExerciseReps : Binding(
                            get: { exercise1!.reps ?? 10 },
                            set: { exercise1!.reps = $0 }
                        ),
                        in: 1...50
                    )
                    
                    HStack {
                        Text("Weight:")
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
                                get: { unit },
                                set: { _ in }
                            )
                        )
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .exerciseWeight)
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
                        Text("Time before next exercise")
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
                    Picker("Time before next exercise", selection: Binding(
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
                            Text("\(Int(duration)) seconds").tag(duration)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            } /* Section */
            
            if isSuperset || exercise2 != nil {
                Section {
                    TextField("Exercise name", text: exercise2 == nil ? $newExercise2Name : Binding(
                        get: { exercise2!.name },
                        set: { exercise2!.name = $0 }
                    ))
                    .focused($focusedField, equals: .supersetName)
                    
                    Toggle("Time based", isOn: Binding(
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
                                Text("Exercise duration")
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
                            Picker("Exercise duration", selection: Binding(
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
                                    Text("\(Int(duration)) seconds").tag(duration)
                                }
                            }
                            .pickerStyle(.wheel)
                        }
                    } else {
                        Stepper(
                            "Reps: \(exercise2 == nil ? newExercise2Reps : exercise2!.reps ?? 10)",
                            value: exercise2 == nil ? $newExercise2Reps : Binding(
                                get: { exercise2!.reps ?? 10 },
                                set: { exercise2!.reps = $0 }
                            ),
                            in: 1...50
                        )
                        
                        HStack {
                            Text("Weight:")
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
                                    get: { unit },
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
        .withTextFieldToolbarDoneWithChevrons(isKeyboardShowing: $isKeyboardShowing, isSupersetToggleOn: $isSuperset, focusedField: _focusedField)
    }
    
    @ViewBuilder
    private func leadingToolbarItems() -> some View {
        if editMode?.wrappedValue.isEditing == true {
            Menu {
                if selectedExerciseIDs.isEmpty {
                    Button(action: {
                        selectedExerciseIDs = Set(workout.exercises!.map { $0.id })
                    }) {
                        Label("Select all", systemImage: "checkmark.circle.fill")
                    }
                } else {
                    Button("Copy", systemImage: "document.on.document") {
                        isShowingWorkoutPicker = true
                    }
                    Button("Delete", systemImage: "trash", role: .destructive) {
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
                    Text("Week \(targetWorkout.week?.number ?? 0)")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }
        }
        .navigationTitle("Copy to Workout")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isShowingWorkoutPicker = false
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
        
        for exercise in selectedExercises {
            if let partner = partner(for: exercise) {
                let newExercise1 = Exercise(
                    name: exercise.name,
                    weight: exercise.weight,
                    sets: exercise.sets,
                    reps: exercise.reps,
                    duration: exercise.duration,
                    restTime: exercise.restTime,
                    isTimeBased: exercise.isTimeBased,
                    orderIndex: newOrderIndex,
                    timeBeforeNext: exercise.timeBeforeNext
                )
                let newExercise2 = Exercise(
                    name: partner.name,
                    weight: partner.weight,
                    sets: partner.sets,
                    reps: partner.reps,
                    duration: partner.duration,
                    restTime: partner.restTime,
                    isTimeBased: partner.isTimeBased,
                    orderIndex: newOrderIndex + 1,
                    timeBeforeNext: partner.timeBeforeNext
                )
                newExercise1.supersetPartnerID = newExercise2.id
                newExercise2.supersetPartnerID = newExercise1.id
                
                targetWorkout.exercises!.append(newExercise1)
                targetWorkout.exercises!.append(newExercise2)
                newExercise1.workout = targetWorkout
                newExercise2.workout = targetWorkout
                
                modelContext.insert(newExercise1)
                modelContext.insert(newExercise2)
                
                newOrderIndex += 2
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
                    timeBeforeNext: exercise.timeBeforeNext
                )
                targetWorkout.exercises!.append(newExercise)
                newExercise.workout = targetWorkout
                modelContext.insert(newExercise)
                
                newOrderIndex += 1
            }
        }
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
        exercise.supersetPartnerID = nil
        workout.exercises?.removeAll { $0.id == partnerID }
        modelContext.delete(partner)
    }
}
