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
    @State private var isShowingTemplatePicker: Bool = false
    @State private var selectedExerciseIDs: Set<UUID> = Set<Exercise.ID>()
    @State private var isShowingWorkoutPicker: Bool = false
    @State private var expandedExerciseID: UUID?
    @State private var showingRestPicker: Bool = false
    @State private var showingDurationPicker: Bool = false
    @State private var showingDuration2Picker: Bool = false
    @State private var showingTimeBeforeNextPicker: Bool = false
    @State private var isSuperset: Bool = false
    @State private var selectedTemplate: ExerciseTemplate?
    @State private var templateIDForDetailView: UUID?
    @State private var templateDetailType: TemplateDetailType?
    @State private var showingTemplateRestPicker: Bool = false
    @State private var showingTemplateDurationPicker: Bool = false
    @State private var showingTemplateTimeBeforeNextPicker: Bool = false
    
    enum TemplateDetailType {
        case history, edit
    }
    
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
    
    @Query private var allTemplates: [ExerciseTemplate]
    
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
            .onChange(of: selectedExercise) { oldValue, newValue in
                if let exercise = newValue {
                    isSuperset = exercise.supersetPartnerID != nil
                    
                    if let template = exercise.template {
                        newExerciseName = template.name
                        newExerciseSets = template.defaultSets
                        newExerciseRestTime = template.defaultRestTime
                        newExerciseIsTimeBased = template.isTimeBased
                        newExerciseReps = template.defaultReps ?? 8
                        newExerciseDuration = template.defaultDuration ?? 30
                        newExerciseWeight = template.defaultWeight ?? 50.0
                        newExerciseTimeBeforeNext = template.timeBeforeNext
                        newExerciseIsDistanceBased = template.isDistanceBased
                        newExerciseDistance = template.defaultDistance ?? 200
                    } else {
                        newExerciseName = exercise.name
                        newExerciseSets = exercise.sets
                        newExerciseRestTime = exercise.restTime
                        newExerciseIsTimeBased = exercise.isTimeBased
                        newExerciseReps = exercise.reps ?? 8
                        newExerciseDuration = exercise.duration ?? 30
                        newExerciseWeight = exercise.weight ?? 50.0
                        newExerciseTimeBeforeNext = exercise.timeBeforeNext
                        newExerciseIsDistanceBased = exercise.isDistanceBased ?? false
                        newExerciseDistance = exercise.distance ?? 200
                    }
                }
            }
            .sheet(isPresented: $isShowingTemplatePicker) {
                exerciseTemplatePickerSheet()
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
                        isShowingTemplatePicker = true
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
                        isShowingTemplatePicker = true
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
                        .opacity(((exercise.effectiveIsTimeBased ? exercise.effectiveSets * 2 : exercise.effectiveSets) == exercise.currentSet - 1) ? 0.5 : 1)
                        .listRowSeparator(.hidden)
                    displayExercise(for: partner, isSuperset: true)
                        .tag(partner.id)
                        .opacity(((exercise.effectiveIsTimeBased ? exercise.effectiveSets * 2 : exercise.effectiveSets) == exercise.currentSet - 1) ? 0.5 : 1)
                        .listRowSeparator(.hidden)
                } else if exercise.supersetPartnerID == nil {
                    displayExercise(for: exercise)
                        .tag(exercise.id)
                        .opacity(((exercise.effectiveIsTimeBased ? exercise.effectiveSets * 2 : exercise.effectiveSets) == exercise.currentSet - 1) ? 0.5 : 1)
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
                            totalSets: exercise.effectiveSets,
                            currentSet: Binding(
                                get: { exercise.currentSet },
                                set: { exercise.currentSet = $0 }
                            ),
                            restDuration: exercise.effectiveRestTime,
                            timeBeforeNextExercise: exercise.effectiveTimeBeforeNext,
                            isTimerRunning: Binding(
                                get: { isTimerRunning[exercise.id] ?? false },
                                set: { isTimerRunning[exercise.id] = $0 }
                            ),
                            elapsed: Binding(
                                get: { exercise.elapsed },
                                set: { exercise.elapsed = $0 }
                            ),
                            isTimeBased: exercise.effectiveIsTimeBased,
                            duration: exercise.effectiveDuration ?? 30.0,
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
                            totalSets: exercise.effectiveSets,
                            currentSet: Binding(
                                get: { exercise.currentSet },
                                set: { exercise.currentSet = $0 }
                            ),
                            restDuration: exercise.effectiveRestTime,
                            timeBeforeNextExercise: exercise.effectiveTimeBeforeNext,
                            isTimerRunning: Binding(
                                get: { isTimerRunning[exercise.id] ?? false },
                                set: { isTimerRunning[exercise.id] = $0 }
                            ),
                            elapsed: Binding(
                                get: { exercise.elapsed },
                                set: { exercise.elapsed = $0 }
                            ),
                            isTimeBased: exercise.effectiveIsTimeBased,
                            duration: exercise.effectiveDuration ?? 30.0,
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
                Text(exercise.effectiveName)
                    .font(.headline)
                
                if exercise.effectiveIsTimeBased {
                    Text("duration_x_sec".localized(with: Int(exercise.effectiveDuration ?? 0), comment: "Duration: x sec"))
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                } else {
                    if exercise.effectiveIsDistanceBased {
                        if let distance = exercise.effectiveDistance, distance != 0 {
                            Text("distance_x".localized(with: distance, distanceUnit.symbol, comment: "Distance: x m"))
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    }
                }
                
                if let weight = exercise.effectiveWeight, weight != 0, !exercise.effectiveIsDistanceBased {
                    Text("weight_x".localized(with: weight, weightUnit.symbol, comment: "Weight: x kg"))
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                if !isSuperset! {
                    Text("sets_x".localized(with: exercise.effectiveSets, comment: "Sets: x"))
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                if !exercise.effectiveIsTimeBased, !exercise.effectiveIsDistanceBased {
                    Text("reps_x".localized(with: exercise.effectiveReps ?? 0, comment: "Reps: x"))
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                if !isSuperset! && exercise.effectiveSets > 1 {
                    Text("rest_x_sec".localized(with: Int(exercise.effectiveRestTime), comment: "Rest: x sec"))
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
                                    if !isSuperset {
                                        removeFromSuperset(exercise: exercise)
                                        
                                        if let template = exercise.template, let workout = exercise.workout {
                                            updateTemplateFromExercise(template: template, exercise: exercise, workout: workout)
                                            addToHistory(template: template, exercise: exercise, workout: workout)
                                        }
                                    } else {
                                        if let template = exercise.template, let workout = exercise.workout {
                                            updateTemplateFromExercise(template: template, exercise: exercise, workout: workout)
                                            addToHistory(template: template, exercise: exercise, workout: workout)
                                        }
                                        
                                        if let partnerTemplate = partner.template, let workout = partner.workout {
                                            updateTemplateFromExercise(template: partnerTemplate, exercise: partner, workout: workout)
                                            addToHistory(template: partnerTemplate, exercise: partner, workout: workout)
                                        }
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
                } else { // set
                    exerciseEditForm(exercise1: exercise)
                        .navigationTitle("edit_exercise".localized(comment: "Edit Exercise"))
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("", systemImage: "checkmark") {
                                    if isSuperset {
                                        let template2 = findOrCreateTemplate(
                                            name: newExercise2Name,
                                            weight: newExercise2IsTimeBased ? nil : newExercise2Weight,
                                            sets: 0,
                                            reps: newExercise2IsTimeBased ? nil : newExercise2Reps,
                                            duration: newExercise2IsTimeBased ? newExercise2Duration : nil,
                                            restTime: 0.0,
                                            isTimeBased: newExercise2IsTimeBased,
                                            isDistanceBased: false,
                                            distance: nil,
                                            timeBeforeNext: 0.0,
                                            isSupersetTemplate: true
                                        )
                                        
                                        if let template1 = exercise.template {
                                            template1.supersetPartnerTemplateID = template2.id
                                            template2.supersetPartnerTemplateID = template1.id
                                            template2.isTheSupersetTemplate = true
                                        }
                                        
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
                                        partner.template = template2
                                        exercise.supersetPartnerID = partner.id
                                        workout.exercises!.append(partner)
                                        partner.workout = workout
                                        modelContext.insert(partner)
                                        workout.exercises!.sort { $0.orderIndex < $1.orderIndex }
                                        
                                        updateTemplateFromExercise(template: template2, exercise: partner, workout: workout)
                                    } else if !isSuperset && exercise.supersetPartnerID != nil {
                                        removeFromSuperset(exercise: exercise)
                                    }
                                    
                                    if let template = exercise.template {
                                        updateTemplateFromExercise(template: template, exercise: exercise, workout: workout)
                                        addToHistory(template: template, exercise: exercise, workout: workout)
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
                                    let template1: ExerciseTemplate
                                    let template2: ExerciseTemplate
                                    
                                    if let selectedTemplate = selectedTemplate,
                                       let partnerTemplateID = selectedTemplate.supersetPartnerTemplateID,
                                       let partnerTemplate = allTemplates.first(where: { $0.id == partnerTemplateID }) {
                                        template1 = selectedTemplate
                                        template2 = partnerTemplate
                                    } else {
                                        template1 = findOrCreateTemplate(
                                            name: newExerciseName,
                                            weight: newExerciseIsTimeBased ? nil : newExerciseWeight,
                                            sets: newExerciseSets,
                                            reps: newExerciseIsTimeBased ? nil : newExerciseReps,
                                            duration: newExerciseIsTimeBased ? newExerciseDuration : nil,
                                            restTime: newExerciseRestTime,
                                            isTimeBased: newExerciseIsTimeBased,
                                            isDistanceBased: false,
                                            distance: nil,
                                            timeBeforeNext: newExerciseTimeBeforeNext
                                        )
                                        template2 = findOrCreateTemplate(
                                            name: newExercise2Name,
                                            weight: newExercise2IsTimeBased ? nil : newExercise2Weight,
                                            sets: 0,
                                            reps: newExercise2IsTimeBased ? nil : newExercise2Reps,
                                            duration: newExercise2IsTimeBased ? newExercise2Duration : nil,
                                            restTime: 0.0,
                                            isTimeBased: newExercise2IsTimeBased,
                                            isDistanceBased: false,
                                            distance: nil,
                                            timeBeforeNext: 0.0,
                                            isSupersetTemplate: true
                                        )
                                        
                                        template1.supersetPartnerTemplateID = template2.id
                                        template2.supersetPartnerTemplateID = template1.id
                                        template2.isTheSupersetTemplate = true
                                    }
                                    
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
                                    exercise1.template = template1
                                    exercise2.template = template2
                                    workout.exercises!.append(exercise1)
                                    workout.exercises!.append(exercise2)
                                    exercise1.workout = workout
                                    exercise2.workout = workout
                                    modelContext.insert(exercise1)
                                    modelContext.insert(exercise2)
                                    
                                    updateTemplateFromExercise(template: template1, exercise: exercise1, workout: workout)
                                    updateTemplateFromExercise(template: template2, exercise: exercise2, workout: workout)
                                } else {
                                    let template: ExerciseTemplate
                                    if let selectedTemplate = selectedTemplate {
                                        template = selectedTemplate
                                    } else {
                                        template = findOrCreateTemplate(
                                            name: newExerciseName,
                                            weight: newExerciseIsTimeBased ? nil : newExerciseWeight,
                                            sets: newExerciseSets,
                                            reps: newExerciseIsTimeBased ? nil : newExerciseReps,
                                            duration: newExerciseIsTimeBased ? newExerciseDuration : nil,
                                            restTime: newExerciseRestTime,
                                            isTimeBased: newExerciseIsTimeBased,
                                            isDistanceBased: newExerciseIsDistanceBased,
                                            distance: newExerciseDistance,
                                            timeBeforeNext: newExerciseTimeBeforeNext
                                        )
                                    }
                                    
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
                                    exercise.template = template
                                    workout.exercises!.append(exercise)
                                    exercise.workout = workout
                                    modelContext.insert(exercise)
                                    
                                    updateTemplateFromExercise(template: template, exercise: exercise, workout: workout)
                                    addToHistory(template: template, exercise: exercise, workout: workout)
                                    
                                    selectedTemplate = nil
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
                Toggle("superset".localized(comment: "Superset"), isOn: $isSuperset)
                    .onChange(of: isSuperset) { oldValue, newValue in
                        if newValue {
                            if exercise1 != nil {
                                exercise1!.isDistanceBased = false
                            } else {
                                newExerciseIsDistanceBased = false
                            }
                        }
                        
                        if !newValue && (focusedField == .supersetName || focusedField == .supersetWeight) {
                            focusedField = .exerciseWeight
                        }
                    }
                
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
                                    newExerciseIsDistanceBased = false
                                } else {
                                    newExerciseReps = 8
                                }
                            } else {
                                exercise1!.isTimeBased = newValue
                                if newValue {
                                    exercise1!.duration = 30.0
                                    exercise1!.isDistanceBased = false
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
                    
                    if (exercise1 == nil ? newExerciseIsDistanceBased : exercise1!.isDistanceBased) ?? false {
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
            
            if isSuperset {
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
    private func exerciseTemplatePickerSheet() -> some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        selectedTemplate = nil
                        isShowingTemplatePicker = false
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
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("new_exercise".localized(comment: "New Exercise"))
                                .font(.headline)
                        }
                    }
                }
                
                if !allTemplates.isEmpty {
                    Section("existing_exercises".localized(comment: "Existing Exercises")) {
                        ForEach(allTemplates.filter { !$0.isTheSupersetTemplate }.sorted(by: { $0.name < $1.name })) { template in
                            let partnerTemplate = template.supersetPartnerTemplateID != nil ? allTemplates.first(where: { $0.id == template.supersetPartnerTemplateID }) : nil
                            
                            VStack(spacing: 0) {
                                HStack(spacing: 12) {
                                    Button(action: {
                                        selectedTemplate = template
                                        isShowingTemplatePicker = false
                                        isAddingNewExercise = true
                                        newExerciseName = template.name
                                        newExerciseSets = template.defaultSets
                                        newExerciseRestTime = template.defaultRestTime
                                        newExerciseIsTimeBased = template.isTimeBased
                                        newExerciseReps = template.defaultReps ?? 8
                                        newExerciseDuration = template.defaultDuration ?? 30
                                        newExerciseWeight = template.defaultWeight ?? 50.0
                                        newExerciseTimeBeforeNext = template.timeBeforeNext
                                        newExerciseIsDistanceBased = template.isDistanceBased
                                        newExerciseDistance = template.defaultDistance ?? 200
                                        
                                        if let partner = partnerTemplate {
                                            isSuperset = true
                                            newExercise2Name = partner.name
                                            newExercise2IsTimeBased = partner.isTimeBased
                                            newExercise2Reps = partner.defaultReps ?? 8
                                            newExercise2Duration = partner.defaultDuration ?? 30
                                            newExercise2Weight = partner.defaultWeight ?? 50.0
                                        } else {
                                            isSuperset = false
                                            newExercise2Name = ""
                                            newExercise2IsTimeBased = false
                                            newExercise2Reps = 8
                                            newExercise2Duration = 30
                                            newExercise2Weight = 50.0
                                        }
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(template.name)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                if partnerTemplate != nil {
                                                    Text("(Superset)")
                                                        .font(.caption)
                                                        .foregroundColor(.orange)
                                                }
                                            }
                                            HStack {
                                                if template.isTimeBased {
                                                    Text("duration_x_sec".localized(with: Int(template.defaultDuration ?? 0), comment: "Duration: x sec"))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                } else {
                                                    if let reps = template.defaultReps {
                                                        Text("reps_x".localized(with: reps, comment: "Reps: x"))
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                if let weight = template.defaultWeight {
                                                    Text("weight_x".localized(with: weight, weightUnit.symbol, comment: "Weight: x kg"))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                Text("sets_x".localized(with: template.defaultSets, comment: "Sets: x"))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            if let partner = partnerTemplate {
                                                Divider().padding(.vertical, 4)
                                                Text(partner.name)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                                HStack {
                                                    if partner.isTimeBased {
                                                        Text("duration_x_sec".localized(with: Int(partner.defaultDuration ?? 0), comment: "Duration: x sec"))
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    } else {
                                                        if let reps = partner.defaultReps {
                                                            Text("reps_x".localized(with: reps, comment: "Reps: x"))
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                        }
                                                    }
                                                    if let weight = partner.defaultWeight {
                                                        Text("weight_x".localized(with: weight, weightUnit.symbol, comment: "Weight: x kg"))
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 16) {
                                        Button(action: {
                                            templateIDForDetailView = template.id
                                            templateDetailType = .history
                                        }) {
                                            Image(systemName: "chart.line.uptrend.xyaxis")
                                                .foregroundColor(.blue)
                                                .frame(width: 30, height: 30)
                                        }
                                        .buttonStyle(.borderless)
                                        
                                        Button(action: {
                                            templateIDForDetailView = template.id
                                            templateDetailType = .edit
                                        }) {
                                            Image(systemName: "pencil")
                                                .foregroundColor(.orange)
                                                .frame(width: 30, height: 30)
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteTemplates)
                    }
                }
            }
            .navigationTitle("add_exercise".localized(comment: "Add Exercise"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        isShowingTemplatePicker = false
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { templateIDForDetailView != nil },
                set: { if !$0 { templateIDForDetailView = nil; templateDetailType = nil } }
            )) {
                if let templateID = templateIDForDetailView,
                   let template = allTemplates.first(where: { $0.id == templateID }) {
                    NavigationStack {
                        if templateDetailType == .history {
                            templateHistoryView(template: template)
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("", systemImage: "xmark") {
                                            templateIDForDetailView = nil
                                            templateDetailType = nil
                                        }
                                    }
                                }
                        } else if templateDetailType == .edit {
                            templateEditView(template: template)
                        }
                    }
                }
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
    
    @ViewBuilder
    private func templateHistoryView(template: ExerciseTemplate) -> some View {
        TemplateHistoryViewContent(template: template, weightUnit: weightUnit, distanceUnit: distanceUnit)
    }
    
    @ViewBuilder
    private func templateEditView(template: ExerciseTemplate) -> some View {
        TemplateEditViewContent(
            template: template,
            allTemplates: allTemplates,
            weightUnit: weightUnit,
            distanceUnit: distanceUnit,
            modelContext: modelContext,
            onSave: { updatedTemplate in
                updateAllExercisesFromTemplate(template: updatedTemplate)
                
                if let partnerID = updatedTemplate.supersetPartnerTemplateID,
                   let partnerTemplate = allTemplates.first(where: { $0.id == partnerID }) {
                    updateAllExercisesFromTemplate(template: partnerTemplate)
                }
                
                try? modelContext.save()
                templateIDForDetailView = nil
                templateDetailType = nil
            },
            onCancel: {
                templateIDForDetailView = nil
                templateDetailType = nil
            }
        )
    }
    
    // MARK: - Helper Functions (placeholder - actual functions are below)
}

struct TemplateEditViewContent: View {
    let template: ExerciseTemplate
    let allTemplates: [ExerciseTemplate]
    let weightUnit: Unit
    let distanceUnit: Unit
    let modelContext: ModelContext
    let onSave: (ExerciseTemplate) -> Void
    let onCancel: () -> Void
    
    @State private var editedName: String = ""
    @State private var editedSets: Int = 5
    @State private var editedRestTime: Double = 60.0
    @State private var editedIsTimeBased: Bool = false
    @State private var editedReps: Int = 8
    @State private var editedDuration: Double = 30.0
    @State private var editedWeight: Double = 50.0
    @State private var editedTimeBeforeNext: Double = 120.0
    @State private var editedIsDistanceBased: Bool = false
    @State private var editedDistance: Int = 200
    
    @State private var isSuperset: Bool = false
    @State private var partnerTemplate: ExerciseTemplate?
    @State private var editedPartnerName: String = ""
    @State private var editedPartnerIsTimeBased: Bool = false
    @State private var editedPartnerReps: Int = 8
    @State private var editedPartnerDuration: Double = 30.0
    @State private var editedPartnerWeight: Double = 50.0
    
    @State private var showingRestPicker: Bool = false
    @State private var showingDurationPicker: Bool = false
    @State private var showingTimeBeforeNextPicker: Bool = false
    
    @State private var isKeyboardShowing: Bool = false
    @FocusState private var focusedField: FocusableField?
    
    var body: some View {
        Form {
            Section {
                Toggle("superset".localized(comment: "Superset"), isOn: $isSuperset)
                
                TextField("exercise_name".localized(comment: "Exercise name"), text: $editedName)
                    .focused($focusedField, equals: .exerciseName)
                
                Stepper("sets_x".localized(with: editedSets, comment: "Sets:"), value: $editedSets, in: 1...20)
                
                Button(action: {
                    withAnimation {
                        showingRestPicker.toggle()
                        showingDurationPicker = false
                        showingTimeBeforeNextPicker = false
                    }
                }) {
                    HStack {
                        HStack(spacing: 4) {
                            Text("rest_duration".localized(comment: "Rest duration"))
                            Text("  \(Int(editedRestTime))s ")
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
                    Picker("rest_duration".localized(comment: "Rest duration"), selection: $editedRestTime) {
                        ForEach(Array(stride(from: 5.0, through: 300.0, by: 5.0)), id: \.self) { duration in
                            Text("\(Int(duration)) seconds".localized(comment: "(xxx) seconds")).tag(duration)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Toggle("time_based".localized(comment: "Time-based"), isOn: Binding(
                    get: { editedIsTimeBased },
                    set: { newValue in
                        withAnimation {
                            editedIsTimeBased = newValue
                        }
                    }
                ))
                
                if editedIsTimeBased {
                    Button(action: {
                        withAnimation {
                            showingDurationPicker.toggle()
                            showingRestPicker = false
                            showingTimeBeforeNextPicker = false
                        }
                    }) {
                        HStack {
                            Text("exercise_duration".localized(comment: "Exercise duration"))
                            Text(" \(Int(editedDuration))s")
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
                        Picker("exercise_duration".localized(comment: "Exercise duration"), selection: $editedDuration) {
                            ForEach(Array(stride(from: 5.0, through: 600.0, by: 5.0)), id: \.self) { duration in
                                Text("\(Int(duration)) seconds".localized(comment: "(xxx) seconds")).tag(duration)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    
                    HStack {
                        Text("weight".localized(comment: "Weight:"))
                        TextFieldWithUnitDouble(
                            value: $editedWeight,
                            unit: Binding(
                                get: { weightUnit },
                                set: { _ in }
                            )
                        )
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .exerciseWeight)
                    }
                } else {
                    Toggle("distance_based".localized(comment: "Distance-based"), isOn: Binding(
                        get: { editedIsDistanceBased },
                        set: { newValue in
                            withAnimation {
                                editedIsDistanceBased = newValue
                            }
                        }
                    ))
                    
                    if editedIsDistanceBased {
                        HStack {
                            Text("distance".localized(comment: "Distance:"))
                            TextFieldWithUnitInt(
                                value: $editedDistance,
                                unit: Binding(
                                    get: { distanceUnit },
                                    set: { _ in }
                                )
                            )
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .exerciseWeight)
                        }
                    } else {
                        Stepper("reps_x".localized(with: editedReps, comment: "Reps:"), value: $editedReps, in: 1...50)
                    }
                    
                    HStack {
                        Text("weight".localized(comment: "Weight:"))
                        TextFieldWithUnitDouble(
                            value: $editedWeight,
                            unit: Binding(
                                get: { weightUnit },
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
                    }
                }) {
                    HStack {
                        Text("time_before_next".localized(comment: "Time before next exercise"))
                        Text(" \(Int(editedTimeBeforeNext))s")
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
                    Picker("time_before_next".localized(comment: "Time before next exercise"), selection: $editedTimeBeforeNext) {
                        ForEach(Array(stride(from: 5.0, through: 300.0, by: 5.0)), id: \.self) { duration in
                            Text("\(Int(duration)) seconds".localized(comment: "(xxx) seconds")).tag(duration)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            
            if isSuperset {
                Section("Superset Partner") {
                    TextField("exercise_name".localized(comment: "Exercise name"), text: $editedPartnerName)
                        .focused($focusedField, equals: .supersetName)
                    
                    Toggle("time_based".localized(comment: "Time-based"), isOn: $editedPartnerIsTimeBased)
                    
                    if editedPartnerIsTimeBased {
                        Stepper("duration_x_sec".localized(with: Int(editedPartnerDuration), comment: "Duration: x sec"), value: $editedPartnerDuration, in: 5...600, step: 5)
                        
                        HStack {
                            Text("weight".localized(comment: "Weight:"))
                            TextFieldWithUnitDouble(
                                value: $editedPartnerWeight,
                                unit: Binding(
                                    get: { weightUnit },
                                    set: { _ in }
                                )
                            )
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .supersetWeight)
                        }
                    } else {
                        Stepper("reps_x".localized(with: editedPartnerReps, comment: "Reps:"), value: $editedPartnerReps, in: 1...50)
                        
                        HStack {
                            Text("weight".localized(comment: "Weight:"))
                            TextFieldWithUnitDouble(
                                value: $editedPartnerWeight,
                                unit: Binding(
                                    get: { weightUnit },
                                    set: { _ in }
                                )
                            )
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .supersetWeight)
                        }
                    }
                }
            }
        }
        .withTextFieldToolbarDoneWithChevrons(isKeyboardShowing: $isKeyboardShowing, isSupersetToggleOn: $isSuperset, focusedField: $focusedField)
        .navigationTitle("edit_template".localized(comment: "Edit Template"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("", systemImage: "checkmark") {
                    saveChanges()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("", systemImage: "xmark") {
                    onCancel()
                }
            }
        }
        .onAppear {
            editedName = template.name
            editedSets = template.defaultSets
            editedRestTime = template.defaultRestTime
            editedIsTimeBased = template.isTimeBased
            editedReps = template.defaultReps ?? 8
            editedDuration = template.defaultDuration ?? 30.0
            editedWeight = template.defaultWeight ?? 50.0
            editedTimeBeforeNext = template.timeBeforeNext
            editedIsDistanceBased = template.isDistanceBased
            editedDistance = template.defaultDistance ?? 200
            
            if let partnerID = template.supersetPartnerTemplateID,
               let partner = allTemplates.first(where: { $0.id == partnerID }) {
                isSuperset = true
                partnerTemplate = partner
                editedPartnerName = partner.name
                editedPartnerIsTimeBased = partner.isTimeBased
                editedPartnerReps = partner.defaultReps ?? 8
                editedPartnerDuration = partner.defaultDuration ?? 30.0
                editedPartnerWeight = partner.defaultWeight ?? 50.0
            }
        }
    }
    
    private func saveChanges() {
        template.name = editedName
        template.defaultSets = editedSets
        template.defaultRestTime = editedRestTime
        template.isTimeBased = editedIsTimeBased
        template.defaultReps = editedIsTimeBased ? nil : editedReps
        template.defaultDuration = editedIsTimeBased ? editedDuration : nil
        template.defaultWeight = editedWeight
        template.timeBeforeNext = editedTimeBeforeNext
        template.isDistanceBased = editedIsDistanceBased
        template.defaultDistance = editedIsDistanceBased ? editedDistance : nil
        
        if isSuperset {
            if let partner = partnerTemplate {
                partner.name = editedPartnerName
                partner.isTimeBased = editedPartnerIsTimeBased
                partner.defaultReps = editedPartnerIsTimeBased ? nil : editedPartnerReps
                partner.defaultDuration = editedPartnerIsTimeBased ? editedPartnerDuration : nil
                partner.defaultWeight = editedPartnerWeight
            } else {
                let newPartner = ExerciseTemplate(
                    name: editedPartnerName,
                    defaultWeight: editedPartnerWeight,
                    defaultSets: 0,
                    defaultReps: editedPartnerIsTimeBased ? nil : editedPartnerReps,
                    defaultDuration: editedPartnerIsTimeBased ? editedPartnerDuration : nil,
                    defaultRestTime: 0.0,
                    isTimeBased: editedPartnerIsTimeBased,
                    isDistanceBased: false,
                    defaultDistance: nil,
                    timeBeforeNext: 0.0,
                    supersetPartnerTemplateID: template.id,
                    isTheSupersetTemplate: true
                )
                modelContext.insert(newPartner)
                template.supersetPartnerTemplateID = newPartner.id
                partnerTemplate = newPartner
            }
        } else {
            if let partnerID = template.supersetPartnerTemplateID,
               let partner = allTemplates.first(where: { $0.id == partnerID }) {
                
                if let partnerExercises = partner.exercises {
                    for exercise in partnerExercises {
                        exercise.template = nil
                    }
                }
                
                if let partnerHistory = partner.history {
                    for historyEntry in partnerHistory {
                        modelContext.delete(historyEntry)
                    }
                }
                
                template.supersetPartnerTemplateID = nil
                modelContext.delete(partner)
            }
        }
        
        onSave(template)
    }
}

// MARK: - ExerciseView Helper Functions (these should be moved inside ExerciseView)
extension ExerciseView {
    func copyExercises(to targetWorkout: Workout) {
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
                
                newExercise1.template = mainExercise.template
                newExercise2.template = supersetExercise.template
                
                targetWorkout.exercises!.append(newExercise1)
                targetWorkout.exercises!.append(newExercise2)
                newExercise1.workout = targetWorkout
                newExercise2.workout = targetWorkout
                
                modelContext.insert(newExercise1)
                modelContext.insert(newExercise2)
                
                if let template = mainExercise.template {
                    addToHistory(template: template, exercise: newExercise1, workout: targetWorkout)
                }
                if let template = supersetExercise.template {
                    addToHistory(template: template, exercise: newExercise2, workout: targetWorkout)
                }
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
                newExercise.template = exercise.template
                targetWorkout.exercises!.append(newExercise)
                newExercise.workout = targetWorkout
                modelContext.insert(newExercise)
                
                if let template = exercise.template {
                    addToHistory(template: template, exercise: newExercise, workout: targetWorkout)
                }
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
        
        if let mainTemplate = exercise.template {
            mainTemplate.supersetPartnerTemplateID = nil
        }
        if let partnerTemplate = partner.template {
            partnerTemplate.supersetPartnerTemplateID = nil
            partnerTemplate.isTheSupersetTemplate = false
        }
        
        partner.supersetPartnerID = nil
        partner.isTheSuperset = false
        exercise.supersetPartnerID = nil
        exercise.isTheSuperset = false
        workout.exercises?.removeAll { $0.id == partnerID }
        modelContext.delete(partner)
    }
    
    private func findOrCreateTemplate(name: String, weight: Double?, sets: Int, reps: Int?, duration: Double?, restTime: Double, isTimeBased: Bool, isDistanceBased: Bool, distance: Int?, timeBeforeNext: Double, isSupersetTemplate: Bool = false) -> ExerciseTemplate {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if let existingTemplate = allTemplates.first(where: { $0.name.lowercased() == normalizedName }) {
            if weight != nil && existingTemplate.defaultWeight == nil {
                existingTemplate.defaultWeight = weight
            }
            if sets > 0 && existingTemplate.defaultSets == 5 {
                existingTemplate.defaultSets = sets
            }
            if reps != nil && existingTemplate.defaultReps == nil {
                existingTemplate.defaultReps = reps
            }
            if duration != nil && existingTemplate.defaultDuration == nil {
                existingTemplate.defaultDuration = duration
            }
            if restTime > 0 && existingTemplate.defaultRestTime == 30.0 {
                existingTemplate.defaultRestTime = restTime
            }
            if timeBeforeNext > 0 && existingTemplate.timeBeforeNext == 120.0 {
                existingTemplate.timeBeforeNext = timeBeforeNext
            }
            return existingTemplate
        }
        
        let template = ExerciseTemplate(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            defaultWeight: weight,
            defaultSets: sets > 0 ? sets : 5,
            defaultReps: reps,
            defaultDuration: duration,
            defaultRestTime: restTime > 0 ? restTime : 30.0,
            isTimeBased: isTimeBased,
            isDistanceBased: isDistanceBased,
            defaultDistance: distance,
            timeBeforeNext: timeBeforeNext > 0 ? timeBeforeNext : 120.0,
            supersetPartnerTemplateID: nil,
            isTheSupersetTemplate: isSupersetTemplate
        )
        modelContext.insert(template)
        return template
    }
    
    private func addToHistory(template: ExerciseTemplate, exercise: Exercise, workout: Workout) {
        let workoutDate = Calendar.current.startOfDay(for: workout.date)
        
        if template.history == nil {
            template.history = []
        }
        
        if let existingHistory = template.history!.first(where: { Calendar.current.isDate($0.date, inSameDayAs: workoutDate) }) {
            if exercise.weight != nil && (existingHistory.weight == nil || exercise.weight! > existingHistory.weight!) {
                existingHistory.weight = exercise.weight
            }
            if exercise.reps != nil && (existingHistory.reps == nil || exercise.reps! > existingHistory.reps!) {
                existingHistory.reps = exercise.reps
            }
            if exercise.sets > existingHistory.sets {
                existingHistory.sets = exercise.sets
            }
            if exercise.duration != nil && (existingHistory.duration == nil || exercise.duration! > existingHistory.duration!) {
                existingHistory.duration = exercise.duration
            }
            if exercise.distance != nil && (existingHistory.distance == nil || exercise.distance! > existingHistory.distance!) {
                existingHistory.distance = exercise.distance
            }
        } else {
            let historyEntry = ExerciseHistory(
                date: workoutDate,
                weight: exercise.weight,
                reps: exercise.reps,
                sets: exercise.sets,
                duration: exercise.duration,
                distance: exercise.distance
            )
            historyEntry.template = template
            template.history!.append(historyEntry)
            modelContext.insert(historyEntry)
        }
    }
    
    private func updateTemplateFromExercise(template: ExerciseTemplate, exercise: Exercise, workout: Workout) {
        template.name = exercise.name
        template.defaultWeight = exercise.weight
        template.defaultSets = exercise.sets
        template.defaultReps = exercise.reps
        template.defaultDuration = exercise.duration
        template.defaultRestTime = exercise.restTime
        template.isTimeBased = exercise.isTimeBased
        template.isDistanceBased = exercise.isDistanceBased ?? false
        template.defaultDistance = exercise.distance
        template.timeBeforeNext = exercise.timeBeforeNext
        
        let currentWorkoutDate = Calendar.current.startOfDay(for: workout.date)
        let templateID = template.id
        
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { ex in
                ex.template?.id == templateID
            }
        )
        
        guard let allExercises = try? modelContext.fetch(descriptor) else { return }
        
        for linkedExercise in allExercises {
            guard let linkedWorkout = linkedExercise.workout else { continue }
            let workoutDate = Calendar.current.startOfDay(for: linkedWorkout.date)
            
            if workoutDate > currentWorkoutDate {
                linkedExercise.name = template.name
                linkedExercise.weight = template.defaultWeight
                linkedExercise.sets = template.defaultSets
                linkedExercise.reps = template.defaultReps
                linkedExercise.duration = template.defaultDuration
                linkedExercise.restTime = template.defaultRestTime
                linkedExercise.isTimeBased = template.isTimeBased
                linkedExercise.isDistanceBased = template.isDistanceBased
                linkedExercise.distance = template.defaultDistance
                linkedExercise.timeBeforeNext = template.timeBeforeNext
                
                if let existingHistory = template.history?.first(where: { Calendar.current.isDate($0.date, inSameDayAs: workoutDate) }) {
                    existingHistory.weight = linkedExercise.weight
                    existingHistory.reps = linkedExercise.reps
                    existingHistory.sets = linkedExercise.sets
                    existingHistory.duration = linkedExercise.duration
                    existingHistory.distance = linkedExercise.distance
                } else {
                    let historyEntry = ExerciseHistory(
                        date: workoutDate,
                        weight: linkedExercise.weight,
                        reps: linkedExercise.reps,
                        sets: linkedExercise.sets,
                        duration: linkedExercise.duration,
                        distance: linkedExercise.distance
                    )
                    historyEntry.template = template
                    if template.history == nil {
                        template.history = []
                    }
                    template.history!.append(historyEntry)
                    modelContext.insert(historyEntry)
                }
            }
        }
    }
    
    private func deleteTemplates(at offsets: IndexSet) {
        let sortedTemplates = allTemplates.filter { !$0.isTheSupersetTemplate }.sorted(by: { $0.name < $1.name })
        
        for index in offsets {
            let template = sortedTemplates[index]
            
            if let partnerTemplateID = template.supersetPartnerTemplateID,
               let partnerTemplate = allTemplates.first(where: { $0.id == partnerTemplateID }) {
                
                if let partnerExercises = partnerTemplate.exercises {
                    for exercise in partnerExercises {
                        exercise.template = nil
                    }
                }
                
                if let partnerHistory = partnerTemplate.history {
                    for historyEntry in partnerHistory {
                        modelContext.delete(historyEntry)
                    }
                }
                
                modelContext.delete(partnerTemplate)
            }
            
            if let exercises = template.exercises {
                for exercise in exercises {
                    exercise.template = nil
                }
            }
            
            if let history = template.history {
                for historyEntry in history {
                    modelContext.delete(historyEntry)
                }
            }
            
            modelContext.delete(template)
        }
        
        try? modelContext.save()
    }
    
    private func updateAllExercisesFromTemplate(template: ExerciseTemplate) {
        let today = Calendar.current.startOfDay(for: Date())
        let templateID = template.id
        
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { ex in
                ex.template?.id == templateID
            }
        )
        
        guard let allExercises = try? modelContext.fetch(descriptor) else { return }
        
        for linkedExercise in allExercises {
            guard let linkedWorkout = linkedExercise.workout else { continue }
            let workoutDate = Calendar.current.startOfDay(for: linkedWorkout.date)
            
            if workoutDate > today {
                linkedExercise.name = template.name
                linkedExercise.weight = template.defaultWeight
                linkedExercise.sets = template.defaultSets
                linkedExercise.reps = template.defaultReps
                linkedExercise.duration = template.defaultDuration
                linkedExercise.restTime = template.defaultRestTime
                linkedExercise.isTimeBased = template.isTimeBased
                linkedExercise.isDistanceBased = template.isDistanceBased
                linkedExercise.distance = template.defaultDistance
                linkedExercise.timeBeforeNext = template.timeBeforeNext
                
                if let existingHistory = template.history?.first(where: { Calendar.current.isDate($0.date, inSameDayAs: workoutDate) }) {
                    existingHistory.weight = linkedExercise.weight
                    existingHistory.reps = linkedExercise.reps
                    existingHistory.sets = linkedExercise.sets
                    existingHistory.duration = linkedExercise.duration
                    existingHistory.distance = linkedExercise.distance
                } else {
                    let historyEntry = ExerciseHistory(
                        date: workoutDate,
                        weight: linkedExercise.weight,
                        reps: linkedExercise.reps,
                        sets: linkedExercise.sets,
                        duration: linkedExercise.duration,
                        distance: linkedExercise.distance
                    )
                    historyEntry.template = template
                    if template.history == nil {
                        template.history = []
                    }
                    template.history!.append(historyEntry)
                    modelContext.insert(historyEntry)
                }
            }
        }
    }
}

struct TemplateHistoryViewContent: View {
    let template: ExerciseTemplate
    let weightUnit: Unit
    let distanceUnit: Unit
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allHistory: [ExerciseHistory]
    
    private var historyEntries: [ExerciseHistory] {
        allHistory.filter { $0.template?.id == template.id }.sorted(by: { $0.date > $1.date })
    }
    
    private var filteredHistoryEntries: [ExerciseHistory] {
        let sortedOldestFirst = historyEntries.sorted(by: { $0.date < $1.date })
        guard !sortedOldestFirst.isEmpty else { return [] }
        
        var filtered: [ExerciseHistory] = [sortedOldestFirst[0]]
        
        for i in 1..<sortedOldestFirst.count {
            let current = sortedOldestFirst[i]
            let previous = sortedOldestFirst[i - 1]
            
            let hasChanges = current.weight != previous.weight ||
                            current.reps != previous.reps ||
                            current.sets != previous.sets ||
                            current.duration != previous.duration ||
                            current.distance != previous.distance
            
            if hasChanges {
                filtered.append(current)
            }
        }
        
        return filtered.reversed()
    }
    
    private func deleteFilteredHistoryEntries(at offsets: IndexSet) {
        let entriesToDelete = offsets.map { filteredHistoryEntries[$0] }
        
        for entry in entriesToDelete {
            modelContext.delete(entry)
        }
        
        try? modelContext.save()
    }
    
    var body: some View {
        List {
            if !filteredHistoryEntries.isEmpty {
                ForEach(filteredHistoryEntries) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.date, style: .date)
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            if let weight = entry.weight {
                                VStack(alignment: .leading) {
                                    Text("weight".localized(comment: "Weight"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(weight, specifier: "%.1f") \(weightUnit.symbol)")
                                        .font(.body)
                                }
                            }
                            
                            if let reps = entry.reps {
                                VStack(alignment: .leading) {
                                    Text("reps".localized(comment: "Reps"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(reps)")
                                        .font(.body)
                                }
                            }
                            
                            if entry.sets > 0 {
                                VStack(alignment: .leading) {
                                    Text("sets".localized(comment: "Sets"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(entry.sets)")
                                        .font(.body)
                                }
                            }
                            
                            if let duration = entry.duration {
                                VStack(alignment: .leading) {
                                    Text("duration".localized(comment: "Duration"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(duration))s")
                                        .font(.body)
                                }
                            }
                            
                            if let distance = entry.distance {
                                VStack(alignment: .leading) {
                                    Text("distance".localized(comment: "Distance"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(distance) \(distanceUnit.symbol)")
                                        .font(.body)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    deleteFilteredHistoryEntries(at: indexSet)
                }
            } else {
                Text("no_history".localized(comment: "No history available"))
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .navigationTitle(template.name)
    }
}
