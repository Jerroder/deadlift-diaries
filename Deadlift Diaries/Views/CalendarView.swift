//
//  CalendarView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-13.
//

import SwiftData
import SwiftUI

enum AddExerciseMode {
    case normal(order: Int)
    case superset(with: WorkoutExercise)
    case edit(WorkoutExercise)
}

struct ScheduledWorkoutCard: View {
    let scheduledWorkout: ScheduledWorkout
    
    private var workoutTemplate: WorkoutTemplate? {
        scheduledWorkout.workoutTemplate
    }
    
    private var exercises: [WorkoutExercise] {
        (scheduledWorkout.exercises ?? []).sorted {
            if $0.order != $1.order {
                return $0.order < $1.order
            }
            
            return ($0.supersetPosition?.rawValue ?? 0) < ($1.supersetPosition?.rawValue ?? 0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(workoutTemplate?.name ?? "workout".localized(comment: "Workout"))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let notes = workoutTemplate?.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            
            if !exercises.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(exercises) { workoutExercise in
                        WorkoutExerciseRow(workoutExercise: workoutExercise)
                    }
                }
                .padding(.leading, 16)
            }
        }
    }
    
    struct WorkoutExerciseRow: View {
        let workoutExercise: WorkoutExercise
        
        private var exerciseName: String {
            workoutExercise.exercise?.name ?? "unknown_exercise".localized(comment: "Unknown Exercise")
        }
        
        var body: some View {
            HStack(alignment: .top, spacing: 16) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 1)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(exerciseName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(targetDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
                
                Spacer()
            }
        }
        
        private var targetDescription: String {
            let target = formattedTargetValue(for: workoutExercise)
            
            if let weight = workoutExercise.targetWeight {
                return "\(workoutExercise.targetSets) x \(target) @ \(weight.formatted()) kg"
            }
            
            return "\(workoutExercise.targetSets) x \(target)"
        }
    }
}

struct CreateExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let existingExercise: Exercise?
    let initialName: String
    let onCreate: (Exercise) -> Void
    
    @State private var name: String
    @State private var isTimeBased: Bool
    @State private var isDistanceBased: Bool
    @State private var notes: String
    
    @FocusState private var focusedField: FocusableField?
    
    private var isEditing: Bool {
        existingExercise != nil
    }
    
    init(existingExercise: Exercise? = nil, initialName: String = "", onCreate: @escaping (Exercise) -> Void) {
        self.existingExercise = existingExercise
        self.initialName = initialName
        self.onCreate = onCreate
        _name = State(initialValue: existingExercise?.name ?? initialName)
        _isTimeBased = State(initialValue: existingExercise?.isTimeBased ?? false)
        _isDistanceBased = State(initialValue: existingExercise?.isDistanceBased ?? false)
        _notes = State(initialValue: existingExercise?.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("exercise".localized(comment: "Exercise")) {
                    TextField("name".localized(comment: "Name"), text: $name)
                        .focused($focusedField, equals: .exerciseName)
                    
                    Toggle("time_based".localized(comment: "Time-based"), isOn: $isTimeBased)
                        .onChange(of: isTimeBased) { _, value in
                            if value {
                                isDistanceBased = false
                            }
                        }
                    
                    Toggle("distance_based".localized(comment: "Distance-based"), isOn: $isDistanceBased)
                        .onChange(of: isDistanceBased) { _, value in
                            if value {
                                isTimeBased = false
                            }
                        }
                    
                    TextField("notes".localized(comment: "Notes"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .notes)
                }
            }
            .withTextFieldToolbarDoneWithChevrons(
                fields: [.exerciseName, .notes],
                focusedField: $focusedField
            )
            .navigationTitle(isEditing ? "edit_exercise".localized(comment: "Edit Exercise") : "new_exercise".localized(comment: "New Exercise"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("", systemImage: "xmark") {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        createExercise()
                    }
                    .tint(.accentColor)
                    .disabled(
                        name
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    )
                }
            }
        }
    }
    
    private func createExercise() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            return
        }
        
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existingExercise {
            existingExercise.name = trimmedName
            existingExercise.isTimeBased = isTimeBased
            existingExercise.isDistanceBased = isDistanceBased
            existingExercise.notes = trimmedNotes
            
            do {
                try modelContext.save()
                onCreate(existingExercise)
                dismiss()
            } catch {
                print("Failed to update exercise: \(error)")
            }
            
            return
        }
        
        let exercise = Exercise(
            name: trimmedName,
            isTimeBased: isTimeBased,
            isDistanceBased: isDistanceBased,
            notes: trimmedNotes
        )
        
        modelContext.insert(exercise)
        
        do {
            try modelContext.save()
            onCreate(exercise)
            dismiss()
        } catch {
            print("Failed to save exercise: \(error)")
        }
    }
}

enum ExpandableTimeField: Equatable {
    case duration
    case rest
    case countdown
}

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let mode: AddExerciseMode
    let onAdd: (WorkoutExercise) -> Void
    var onRemoveFromSuperset: (() -> Void)? = nil
    
    @Query(sort: \Exercise.name)
    private var exercises: [Exercise]
    
    private let weightUnit: Unit = isMetricSystem() ? Unit(symbol: "kg") : Unit(symbol: "lbs")
    
    @State private var searchText: String = ""
    
    @State private var selectedExercise: Exercise?
    
    @State private var sets: Int = 3
    @State private var reps: Int = 8
    @State private var distance: Int = 0
    @State private var restSeconds: Int
    @State private var timeBeforeNext: Int
    @State private var weight: Double?
    
    @State private var expandedTimeField: ExpandableTimeField?
    
    @State private var exerciseToEdit: Exercise?
    
    @FocusState private var focusedField: FocusableField?
    
    private static let defaultRestSeconds = 120
    private static let defaultTimeBeforeNext = 120
    
    private static let lastUsedRestSecondsKey = "lastUsedRestSeconds"
    private static let lastUsedTimeBeforeNextKey = "lastUsedTimeBeforeNext"
    
    private static var lastUsedRestSeconds: Int {
        let value = UserDefaults.standard.integer(forKey: lastUsedRestSecondsKey)
        return value > 0 ? value : defaultRestSeconds
    }
    
    private static var lastUsedTimeBeforeNext: Int {
        let value = UserDefaults.standard.integer(forKey: lastUsedTimeBeforeNextKey)
        return value > 0 ? value : defaultTimeBeforeNext
    }
    
    init(mode: AddExerciseMode, onAdd: @escaping (WorkoutExercise) -> Void, onRemoveFromSuperset: (() -> Void)? = nil) {
        self.mode = mode
        self.onAdd = onAdd
        self.onRemoveFromSuperset = onRemoveFromSuperset
        
        if case let .edit(workoutExercise) = mode {
            _selectedExercise = State(initialValue: workoutExercise.exercise)
            _sets = State(initialValue: workoutExercise.targetSets)
            _reps = State(initialValue: workoutExercise.targetReps)
            _distance = State(initialValue: workoutExercise.targetDistance)
            _restSeconds = State(initialValue: workoutExercise.restSeconds ?? Self.lastUsedRestSeconds)
            _timeBeforeNext = State(initialValue: workoutExercise.timeBeforeNext ?? Self.lastUsedTimeBeforeNext)
            _weight = State(initialValue: workoutExercise.targetWeight)
        } else {
            _restSeconds = State(initialValue: Self.lastUsedRestSeconds)
            _timeBeforeNext = State(initialValue: Self.lastUsedTimeBeforeNext)
        }
    }
    
    private var filteredExercises: [Exercise] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            return exercises
        }
        
        return exercises.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    private var isNormalMode: Bool {
        switch mode {
        case .normal:
            return true
        case .edit(let workoutExercise):
            // The second exercise in a superset shares its rest/countdown with the
            // main (first) exercise, same as when it was first added, so only the
            // main exercise gets its own sets/rest/countdown.
            return workoutExercise.supersetPosition != .second
        case .superset:
            return false
        }
    }
    
    private var navigationTitleText: String {
        switch mode {
        case .normal:
            return "add_exercise".localized(comment: "Add Exercise")
        case .superset:
            return "add_superset_exercise".localized(comment: "Add Superset Exercise")
        case .edit:
            return "edit_exercise".localized(comment: "Edit Exercise")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Exercise
                
                Section("exercise".localized(comment: "Exercise")) {
                    if let selectedExercise {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedExercise.name)
                                    .font(.headline)
                                
                                if selectedExercise.isTimeBased {
                                    Text("time_based".localized(comment: "Time-based"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if selectedExercise.isDistanceBased {
                                    Text("distance_based".localized(comment: "Distance-based"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button("change".localized(comment: "Change")) {
                                self.selectedExercise = nil
                            }
                        }
                    } else {
                        TextField("search_exercises".localized(comment: "Search exercises"), text: $searchText)
                            .focused($focusedField, equals: .exerciseName)
                        
                        if !filteredExercises.isEmpty {
                            ForEach(filteredExercises) { exercise in
                                Button {
                                    selectedExercise = exercise
                                    searchText = ""
                                } label: {
                                    HStack {
                                        Text(exercise.name)
                                            .foregroundStyle(.primary)
                                        
                                        Spacer()
                                        
                                        if exercise.isTimeBased {
                                            Text("time".localized(comment: "Time"))
                                                .font(.caption)
                                                .foregroundStyle(.primary.opacity(0.7))
                                        } else if exercise.isDistanceBased {
                                            Text("distance_label".localized(comment: "Distance"))
                                                .font(.caption)
                                                .foregroundStyle(.primary.opacity(0.7))
                                        }
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteExercise(exercise)
                                    } label: {
                                        Label("delete".localized(comment: "Delete"), systemImage: "trash")
                                    }
                                    
                                    Button {
                                        exerciseToEdit = exercise
                                    } label: {
                                        Label("edit".localized(comment: "Edit"), systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                        
                        NavigationLink {
                            CreateExerciseView(initialName: searchText) { exercise in
                                selectedExercise = exercise
                            }
                        } label: {
                            Label("create_new_exercise".localized(comment: "Create New Exercise"), systemImage: "plus")
                        }
                    }
                }
                
                // MARK: - Targets
                
                if let selectedExercise {
                    Section("target".localized(comment: "Target")) {
                        if isNormalMode {
                            Stepper(value: $sets, in: 1...20) {
                                HStack {
                                    Text("sets_label".localized(comment: "Sets"))
                                    Spacer()
                                    Text("\(sets)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        if selectedExercise.isTimeBased {
                            Button {
                                toggleTimeField(.duration)
                            } label: {
                                HStack {
                                    HStack(spacing: 4) {
                                        Text("duration".localized(comment: "Duration"))
                                        Text(formattedDuration(reps))
                                            .font(.subheadline)
                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                        Image(systemName: expandedTimeField == .duration ? "chevron.up" : "chevron.down")
                                            .font(.caption)
                                    }
                                    .fixedSize()
                                    
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            if expandedTimeField == .duration {
                                DurationWheelPicker(totalSeconds: $reps)
                            }
                        } else if selectedExercise.isDistanceBased {
                            HStack {
                                Text("distance_label".localized(comment: "Distance"))
                                
                                Spacer()
                                
                                TextField("0", value: $distance, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .exerciseWeight)
                                
                                Text(distanceUnit().symbol)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Stepper(value: $reps, in: 1...100) {
                                HStack {
                                    Text("reps_label".localized(comment: "Reps"))
                                    Spacer()
                                    Text("\(reps)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        HStack {
                            Text("weight_label".localized(comment: "Weight"))
                            
                            Spacer()
                            
                            TextField("optional".localized(comment: "Optional"), value: $weight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .exerciseWeight)
                            
                            Text(weightUnit.symbol)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if isNormalMode {
                        Section("rest_label".localized(comment: "Rest")) {
                            Button {
                                toggleTimeField(.rest)
                            } label: {
                                HStack {
                                    HStack(spacing: 4) {
                                        Text("rest_label".localized(comment: "Rest"))
                                        Text(" \(formattedRest(restSeconds))")
                                            .font(.subheadline)
                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                        Image(systemName: expandedTimeField == .rest ? "chevron.up" : "chevron.down")
                                            .font(.caption)
                                    }
                                    .fixedSize()
                                    
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            if expandedTimeField == .rest {
                                DurationWheelPicker(totalSeconds: $restSeconds)
                            }
                        }
                        
                        Section("before_next_exercise".localized(comment: "Before Next Exercise")) {
                            Button {
                                toggleTimeField(.countdown)
                            } label: {
                                HStack {
                                    HStack(spacing: 4) {
                                        Text("time_before_next".localized(comment: "Time before next exercise"))
                                        Text(" \(formattedRest(timeBeforeNext))")
                                            .font(.subheadline)
                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                        Image(systemName: expandedTimeField == .countdown ? "chevron.up" : "chevron.down")
                                            .font(.caption)
                                    }
                                    .fixedSize()
                                    
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            if expandedTimeField == .countdown {
                                DurationWheelPicker(totalSeconds: $timeBeforeNext)
                            }
                        }
                    }
                }
                
                if let onRemoveFromSuperset {
                    Section {
                        Button(role: .destructive) {
                            onRemoveFromSuperset()
                            dismiss()
                        } label: {
                            Label("remove_from_superset".localized(comment: "Remove from Superset"), systemImage: "link.badge.minus")
                        }
                    }
                }
            }
            .withTextFieldToolbarDone(focusedField: $focusedField)
            .navigationTitle(navigationTitleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        addExercise()
                    }
                    .tint(.accentColor)
                    .disabled(selectedExercise == nil)
                }
            }
        }
        .sheet(item: $exerciseToEdit) { exercise in
            CreateExerciseView(existingExercise: exercise) { _ in }
        }
    }
    
    // MARK: - Delete
    
    private func deleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
        try? modelContext.save()
    }
    
    // MARK: - Add
    
    private func addExercise() {
        guard let exercise = selectedExercise else {
            return
        }
        
        switch mode {
        case .normal(let order):
            let workoutExercise = WorkoutExercise(
                exercise: exercise,
                order: order,
                targetSets: sets,
                targetReps: exercise.isDistanceBased ? 0 : reps,
                targetDistance: exercise.isDistanceBased ? distance : 0,
                targetWeight: weight,
                restSeconds: restSeconds,
                timeBeforeNext: timeBeforeNext
            )
            
            persistLastUsedTimings()
            onAdd(workoutExercise)
            
        case .superset(let baseExercise):
            let workoutExercise = WorkoutExercise(
                exercise: exercise,
                order: baseExercise.order,
                targetSets: baseExercise.targetSets,
                targetReps: exercise.isDistanceBased ? 0 : reps,
                targetDistance: exercise.isDistanceBased ? distance : 0,
                targetWeight: weight,
                restSeconds: baseExercise.restSeconds,
                timeBeforeNext: nil
            )
            
            onAdd(workoutExercise)
            
        case .edit(let workoutExercise):
            workoutExercise.exercise = exercise
            workoutExercise.targetSets = sets
            workoutExercise.targetReps = exercise.isDistanceBased ? 0 : reps
            workoutExercise.targetDistance = exercise.isDistanceBased ? distance : 0
            workoutExercise.targetWeight = weight
            workoutExercise.restSeconds = restSeconds
            workoutExercise.timeBeforeNext = timeBeforeNext
            
            persistLastUsedTimings()
            onAdd(workoutExercise)
        }
        
        dismiss()
    }
    
    private func persistLastUsedTimings() {
        UserDefaults.standard.set(restSeconds, forKey: Self.lastUsedRestSecondsKey)
        UserDefaults.standard.set(timeBeforeNext, forKey: Self.lastUsedTimeBeforeNextKey)
    }
    
    // MARK: - Expandable Time Fields
    
    private func toggleTimeField(_ field: ExpandableTimeField) {
        withAnimation {
            expandedTimeField = expandedTimeField == field ? nil : field
        }
    }
    
    // MARK: - Formatting
    
    private func formattedRest(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }
        
        let minutes = seconds / 60
        let remaining = seconds % 60
        
        if remaining == 0 {
            return "\(minutes)m"
        }
        
        return "\(minutes)m \(remaining)s"
    }
}

struct CreateTrainingBlockView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var existingBlocks: [TrainingBlock]
    
    let existingBlock: TrainingBlock?
    let onCreate: (TrainingBlock) -> Void
    
    @State private var name: String
    @State private var notes: String
    
    @FocusState private var focusedField: FocusableField?
    
    private var isEditing: Bool {
        existingBlock != nil
    }
    
    init(existingBlock: TrainingBlock? = nil, onCreate: @escaping (TrainingBlock) -> Void) {
        self.existingBlock = existingBlock
        self.onCreate = onCreate
        _name = State(initialValue: existingBlock?.name ?? "")
        _notes = State(initialValue: existingBlock?.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("name".localized(comment: "Name"), text: $name)
                        .focused($focusedField, equals: .mesocycleName)
                    
                    TextField("notes".localized(comment: "Notes"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .notes)
                } header: {
                    Text("program".localized(comment: "Program"))
                } footer: {
                    Text("program_name_footer".localized(comment: "Just a name to group templates under, so their exercise history is tracked separately from other programs."))
                }
            }
            .withTextFieldToolbarDoneWithChevrons(
                fields: [.mesocycleName, .notes],
                focusedField: $focusedField
            )
            .navigationTitle(isEditing ? "edit_program".localized(comment: "Edit Program") : "new_program".localized(comment: "New Program"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        createTrainingBlock()
                    }
                    .tint(.accentColor)
                    .disabled(
                        name
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    )
                }
            }
        }
    }
    
    private func createTrainingBlock() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            return
        }
        
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existingBlock {
            existingBlock.name = trimmedName
            existingBlock.notes = trimmedNotes
            
            do {
                try modelContext.save()
                onCreate(existingBlock)
                dismiss()
            } catch {
                print("Failed to update training block: \(error)")
            }
            
            return
        }
        
        if let existing = existingBlocks.first(where: {
            $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame
        }) {
            onCreate(existing)
            dismiss()
            return
        }
        
        let trainingBlock = TrainingBlock(
            name: trimmedName,
            startDate: Date(),
            orderIndex: existingBlocks.count,
            notes: trimmedNotes
        )
        
        modelContext.insert(trainingBlock)
        
        do {
            try modelContext.save()
            onCreate(trainingBlock)
            dismiss()
        } catch {
            print("Failed to save training block: \(error)")
        }
    }
}

enum TemplateExerciseRow: Identifiable {
    case single(WorkoutExercise)
    case superset(first: WorkoutExercise, second: WorkoutExercise)
    
    var id: UUID {
        switch self {
        case .single(let exercise):
            return exercise.id
            
        case .superset(let first, _):
            return first.supersetID ?? first.id
        }
    }
}

private struct SupersetExerciseRow: View {
    let first: WorkoutExercise
    let second: WorkoutExercise
    let onEdit: (WorkoutExercise) -> Void
    let onUnlink: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            exerciseInfo(first, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onEdit(first)
                }
            
            Image(systemName: "link")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            exerciseInfo(second, alignment: .trailing)
                .contentShape(Rectangle())
                .onTapGesture {
                    onEdit(second)
                }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                onUnlink()
            } label: {
                Label("unlink".localized(comment: "Unlink"), systemImage: "link.badge.minus")
            }
            .tint(.orange)
        }
    }
    
    @ViewBuilder
    private func exerciseInfo(_ workoutExercise: WorkoutExercise, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(workoutExercise.exercise?.name ?? "unknown_exercise".localized(comment: "Unknown Exercise"))
            
            Text("\(workoutExercise.targetSets) x \(formattedTargetValue(for: workoutExercise))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }
}

struct CreateWorkoutTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let existingTemplate: WorkoutTemplate?
    
    // MARK: - Workout
    
    @State private var name: String
    @State private var notes: String
    
    // MARK: - Program
    
    @Query(sort: \TrainingBlock.orderIndex)
    private var trainingBlocks: [TrainingBlock]
    
    @State private var selectedTrainingBlock: TrainingBlock?
    @State private var showCreateTrainingBlockSheet: Bool = false
    @State private var trainingBlockToEdit: TrainingBlock?
    @State private var showProgramOptions: Bool = false
    
    // MARK: - Exercises
    
    @State private var workoutExercises: [WorkoutExercise]
    @State private var exercisesToDelete: [WorkoutExercise] = []
    @State private var showAddExerciseSheet: Bool = false
    
    @State private var supersetBaseExercise: WorkoutExercise?
    @State private var exerciseToEdit: WorkoutExercise?
    
    @FocusState private var focusedField: FocusableField?
    
    let onCreate: (WorkoutTemplate) -> Void
    
    private var isEditing: Bool {
        existingTemplate != nil
    }
    
    private let originalExerciseIDs: Set<UUID>
    
    init(existingTemplate: WorkoutTemplate? = nil, onCreate: @escaping (WorkoutTemplate) -> Void) {
        self.existingTemplate = existingTemplate
        self.onCreate = onCreate
        _name = State(initialValue: existingTemplate?.name ?? "")
        _notes = State(initialValue: existingTemplate?.notes ?? "")
        _selectedTrainingBlock = State(initialValue: existingTemplate?.trainingBlock)
        _workoutExercises = State(initialValue: existingTemplate?.exercises ?? [])
        originalExerciseIDs = Set(existingTemplate?.exercises?.map(\.id) ?? [])
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Workout
                
                Section {
                    TextField("workout_name".localized(comment: "Workout Name"), text: $name)
                        .focused($focusedField, equals: .workoutName)
                    
                    TextField("notes".localized(comment: "Notes"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .notes)
                } header: {
                    Text("workout".localized(comment: "Workout"))
                }
                
                // MARK: - Program
                
                Section {
                    if showProgramOptions {
                        Button {
                            withAnimation {
                                selectedTrainingBlock = nil
                                showProgramOptions = false
                            }
                        } label: {
                            HStack {
                                Text("no_program".localized(comment: "No Program"))
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if selectedTrainingBlock == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        ForEach(trainingBlocks) { block in
                            HStack {
                                Button {
                                    withAnimation {
                                        selectedTrainingBlock = block
                                        showProgramOptions = false
                                    }
                                } label: {
                                    HStack {
                                        Text(block.name)
                                            .foregroundStyle(.primary)
                                        
                                        Spacer()
                                        
                                        if selectedTrainingBlock?.id == block.id {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    trainingBlockToEdit = block
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                                .padding(.leading, 8)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteTrainingBlock(block)
                                } label: {
                                    Label("delete".localized(comment: "Delete"), systemImage: "trash")
                                }
                            }
                        }
                        
                        Button {
                            showCreateTrainingBlockSheet = true
                        } label: {
                            Label("create_new_program".localized(comment: "Create New Program"), systemImage: "plus")
                        }
                    } else {
                        Button {
                            withAnimation {
                                showProgramOptions = true
                            }
                        } label: {
                            HStack {
                                Text("program".localized(comment: "Program"))
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Text(selectedTrainingBlock?.name ?? "none".localized(comment: "None"))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                } header: {
                    Text("program".localized(comment: "Program"))
                } footer: {
                    Text("template_program_footer".localized(comment: "Optional. Keeps this template's exercise history separate from other programs."))
                }
                
                // MARK: - Exercises
                
                Section {
                    ForEach(templateExerciseRows) { row in
                        switch row {
                        case .single(let workoutExercise):
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workoutExercise.exercise?.name ?? "unknown_exercise".localized(comment: "Unknown Exercise"))
                                    
                                    Text("\(workoutExercise.targetSets) x \(formattedTargetValue(for: workoutExercise))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    exerciseToEdit = workoutExercise
                                }
                                
                                Spacer()
                                
                                Button {
                                    supersetBaseExercise = workoutExercise
                                } label: {
                                    Image(systemName: "link.badge.plus")
                                }
                                .buttonStyle(.borderless)
                            }
                            .contentShape(Rectangle())
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    delete(row)
                                } label: {
                                    Label("delete".localized(comment: "Delete"), systemImage: "trash")
                                }
                                
                                Button {
                                    exerciseToEdit = workoutExercise
                                } label: {
                                    Label("edit".localized(comment: "Edit"), systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            
                        case .superset(let first, let second):
                            SupersetExerciseRow(first: first, second: second, onEdit: { exercise in
                                exerciseToEdit = exercise
                            }, onUnlink: {
                                unlinkSuperset(first: first, second: second)
                            })
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    delete(row)
                                } label: {
                                    Label("delete".localized(comment: "Delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                    
                    Button("add_exercise".localized(comment: "Add Exercise"), systemImage: "plus") {
                        showAddExerciseSheet = true
                    }
                    
                } header: {
                    Text("exercises".localized(comment: "Exercises"))
                }
            }
            .withTextFieldToolbarDoneWithChevrons(
                fields: [.workoutName, .notes],
                focusedField: $focusedField
            )
            .navigationTitle(isEditing ? "edit_template".localized(comment: "Edit Template") : "new_template".localized(comment: "New Template"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("", systemImage: "xmark") {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        createTemplate()
                    }
                    .disabled(
                        name
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    )
                }
            }
        }
        .sheet(isPresented: $showAddExerciseSheet) {
            AddExerciseView(
                mode: .normal(order: workoutExercises.count)
            ) { workoutExercise in
                workoutExercises.append(workoutExercise)
            }
        }
        .sheet(item: $supersetBaseExercise) { baseExercise in
            AddExerciseView(
                mode: .superset(with: baseExercise)
            ) { workoutExercise in
                addSupersetExercise(workoutExercise, to: baseExercise)
            }
        }
        .sheet(item: $exerciseToEdit) { workoutExercise in
            AddExerciseView(
                mode: .edit(workoutExercise),
                onAdd: { _ in },
                onRemoveFromSuperset: workoutExercise.isInSuperset ? {
                    removeFromSuperset(workoutExercise)
                } : nil
            )
        }
        .sheet(item: $trainingBlockToEdit) { block in
            CreateTrainingBlockView(existingBlock: block) { updated in
                selectedTrainingBlock = updated
            }
        }
        .sheet(isPresented: $showCreateTrainingBlockSheet) {
            CreateTrainingBlockView { trainingBlock in
                selectedTrainingBlock = trainingBlock
            }
        }
    }
    
    // MARK: - Program
    
    private func deleteTrainingBlock(_ block: TrainingBlock) {
        if selectedTrainingBlock?.id == block.id {
            selectedTrainingBlock = nil
        }
        
        modelContext.delete(block)
        try? modelContext.save()
    }
    
    private var templateExerciseRows: [TemplateExerciseRow] {
        let sorted = workoutExercises.sorted {
            if $0.order != $1.order {
                return $0.order < $1.order
            }
            
            return ($0.supersetPosition?.rawValue ?? 0) < ($1.supersetPosition?.rawValue ?? 0)
        }
        
        var rows: [TemplateExerciseRow] = []
        var index = 0
        
        while index < sorted.count {
            let exercise = sorted[index]
            
            guard let supersetID = exercise.supersetID else {
                rows.append(.single(exercise))
                index += 1
                continue
            }
            
            let supersetExercises = sorted.filter { $0.supersetID == supersetID }
            
            if let first = supersetExercises.first(where: { $0.supersetPosition == .first }),
               let second = supersetExercises.first(where: { $0.supersetPosition == .second }) {
                rows.append(.superset(first: first, second: second))
                
                index += supersetExercises.count
            } else { // Defensive fallback for malformed/incomplete data.
                rows.append(.single(exercise))
                index += 1
            }
        }
        
        return rows
    }
    
    private func addSupersetExercise(_ secondExercise: WorkoutExercise, to firstExercise: WorkoutExercise) {
        let supersetID = UUID()
        
        firstExercise.supersetID = supersetID
        firstExercise.supersetPosition = .first
        
        secondExercise.supersetID = supersetID
        secondExercise.supersetPosition = .second
        
        secondExercise.order = firstExercise.order
        
        workoutExercises.append(secondExercise)
    }
    
    private func unlinkSuperset(first: WorkoutExercise, second: WorkoutExercise) {
        first.supersetID = nil
        first.supersetPosition = nil
        
        second.supersetID = nil
        second.supersetPosition = nil
        
        renumberExercises()
    }
    
    // Removes just one exercise from a superset, deleting it and leaving its
    // sibling as a standalone single exercise.
    private func removeFromSuperset(_ exercise: WorkoutExercise) {
        if let supersetID = exercise.supersetID,
           let sibling = workoutExercises.first(where: { $0.supersetID == supersetID && $0.id != exercise.id }) {
            sibling.supersetID = nil
            sibling.supersetPosition = nil
        }
        
        remove(exercise)
        renumberExercises()
    }
    
    private func delete(_ row: TemplateExerciseRow) {
        switch row {
        case .single(let exercise):
            remove(exercise)
            
        case .superset(let first, let second):
            remove(first)
            remove(second)
        }
        
        renumberExercises()
    }
    
    private func remove(_ exercise: WorkoutExercise) {
        if let index = workoutExercises.firstIndex(where: { $0.id == exercise.id }) {
            workoutExercises.remove(at: index)
        }
        
        if originalExerciseIDs.contains(exercise.id) {
            exercisesToDelete.append(exercise)
        }
    }
    
    private func renumberExercises() {
        var order = 0
        
        for row in templateExerciseRows {
            switch row {
            case .single(let exercise):
                exercise.order = order
                order += 1
                
            case .superset(let first, let second):
                first.order = order
                second.order = order
                order += 1
            }
        }
    }
    
    // MARK: - Create
    
    private func createTemplate() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }
        
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let workoutTemplate = existingTemplate ?? WorkoutTemplate(name: trimmedName, notes: trimmedNotes.isEmpty ? nil : trimmedNotes)
        
        workoutTemplate.name = trimmedName
        workoutTemplate.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        workoutTemplate.trainingBlock = selectedTrainingBlock
        workoutTemplate.updatedAt = Date()
        
        for exercise in exercisesToDelete {
            modelContext.delete(exercise)
        }
        
        renumberExercises()
        
        for workoutExercise in workoutExercises {
            workoutExercise.workoutTemplate = workoutTemplate
            
            modelContext.insert(workoutExercise)
        }
        
        if existingTemplate == nil {
            modelContext.insert(workoutTemplate)
        }
        
        do {
            try modelContext.save()
            
            onCreate(workoutTemplate)
            dismiss()
        } catch {
            print("Failed to save workout template: \(error)")
        }
    }
}

struct AddWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Templates
    
    @Query(sort: \WorkoutTemplate.name)
    private var workoutTemplates: [WorkoutTemplate]
    
    @Query(sort: \WorkoutSchedule.startDate, order: .reverse)
    private var workoutSchedules: [WorkoutSchedule]
    
    @State private var searchText: String = ""
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var templateToEdit: WorkoutTemplate?
    
    // MARK: - Schedule
    
    @State private var startDate: Date
    @State private var numberOfWeeks: Int = 1
    
    @FocusState private var focusedField: FocusableField?
    
    init(startDate: Date = Date()) {
        _startDate = State(initialValue: startDate)
    }
    
    // MARK: - Computed Properties
    
    private var weekday: Int {
        Calendar.current.component(.weekday, from: startDate)
    }
    
    // Defaults the duration to whatever was used the last time this same
    // template was scheduled, so recurring workouts don't need re-entering it.
    private func updateNumberOfWeeks(for template: WorkoutTemplate?) {
        guard let template else {
            return
        }
        
        guard let lastSchedule = workoutSchedules.first(where: { $0.workoutTemplate?.id == template.id }) else {
            return
        }
        
        guard let endDate = lastSchedule.endDate else {
            numberOfWeeks = 1
            return
        }
        
        let days = Calendar.current.dateComponents([.day], from: lastSchedule.startDate, to: endDate).day ?? 0
        numberOfWeeks = max(1, (days / 7) + 1)
    }
    
    private var filteredTemplates: [WorkoutTemplate] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            return workoutTemplates
        }
        
        return workoutTemplates.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    private var calculatedEndDate: Date? {
        Calendar.current.date(byAdding: .weekOfYear, value: numberOfWeeks - 1, to: startDate)
    }
    
    private var trainingBlock: TrainingBlock? {
        selectedTemplate?.trainingBlock
    }
    
    private func exerciseNamesSummary(for template: WorkoutTemplate) -> String {
        let exercises = (template.exercises ?? []).sorted {
            if $0.order != $1.order {
                return $0.order < $1.order
            }
            
            return ($0.supersetPosition?.rawValue ?? 0) < ($1.supersetPosition?.rawValue ?? 0)
        }
        
        return exercises
            .map { $0.exercise?.name ?? "unknown_exercise".localized(comment: "Unknown Exercise") }
            .joined(separator: ", ")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Workout Template
                
                Section("workout_template".localized(comment: "Workout Template")) {
                    if let selectedTemplate {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedTemplate.name)
                                    .font(.headline)
                                
                                if let trainingBlock = selectedTemplate.trainingBlock {
                                    Text(trainingBlock.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                if let notes = selectedTemplate.notes {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button("change".localized(comment: "Change")) {
                                self.selectedTemplate = nil
                            }
                        }
                    } else {
                        TextField("search_templates".localized(comment: "Search templates"), text: $searchText)
                            .focused($focusedField, equals: .searchField)
                        
                        if filteredTemplates.isEmpty {
                            ContentUnavailableView("no_templates".localized(comment: "No Templates"), systemImage: "list.bullet.rectangle",
                                                   description: Text("create_template_prompt".localized(comment: "Create a workout template to get started."))
                            )
                        } else {
                            ForEach(filteredTemplates) { template in
                                Button {
                                    selectedTemplate = template
                                    searchText = ""
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                            Text(template.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            
                                            if let trainingBlock = template.trainingBlock {
                                                Text("(\(trainingBlock.name))")
                                                    .font(.caption)
                                                    .foregroundStyle(.primary)
                                            }
                                        }
                                        
                                        let exerciseNames = exerciseNamesSummary(for: template)
                                        
                                        if !exerciseNames.isEmpty {
                                            Text(exerciseNames)
                                                .font(.caption)
                                                .foregroundStyle(.primary.opacity(0.7))
                                                .lineLimit(2)
                                        }
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteTemplate(template)
                                    } label: {
                                        Label("delete".localized(comment: "Delete"), systemImage: "trash")
                                    }
                                    
                                    Button {
                                        templateToEdit = template
                                    } label: {
                                        Label("edit".localized(comment: "Edit"), systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                        
                        NavigationLink {
                            CreateWorkoutTemplateView { template in
                                selectedTemplate = template
                            }
                        } label: {
                            Label("create_new_template".localized(comment: "Create New Template"), systemImage: "plus")
                        }
                    }
                }
                
                // MARK: - Schedule
                
                Section {
                    DatePicker("start_date".localized(comment: "Start Date"), selection: $startDate, displayedComponents: .date)
                    
                    Stepper(value: $numberOfWeeks, in: 1...52) {
                        HStack {
                            Text("duration".localized(comment: "Duration"))
                            
                            Spacer()
                            
                            Text("x_week".localized(with: numberOfWeeks, comment: "x week(s)"))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("repeats".localized(comment: "Repeats"))
                        
                        Spacer()
                        
                        Text(startDate.formatted(.dateTime.weekday(.wide)))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let endDate = calculatedEndDate {
                        HStack {
                            Text("ends".localized(comment: "Ends"))
                            
                            Spacer()
                            
                            Text(endDate
                                .formatted(.dateTime.month(.abbreviated).day().year())
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                } header: {
                    Text("schedule".localized(comment: "Schedule"))
                } footer: {
                    let weekday = startDate.formatted(.dateTime.weekday(.wide))
                    let weeks = "x_week".localized(with: numberOfWeeks, comment: "x week(s)")
                    
                    if let trainingBlock {
                        Text("repeat_footer_program".localized(with: weekday, weeks, trainingBlock.name, comment: "The workout will repeat every x for x. Tied to the x program for history tracking."))
                    } else {
                        Text("repeat_footer".localized(with: weekday, weeks, comment: "The workout will repeat every x for x."))
                    }
                }
            }
            .withTextFieldToolbarDone(focusedField: $focusedField)
            .navigationTitle("add_workout".localized(comment: "Add Workout"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        saveWorkout()
                    }
                    .disabled(selectedTemplate == nil)
                }
            }
        }
        .onChange(of: selectedTemplate) { _, newValue in
            updateNumberOfWeeks(for: newValue)
        }
        .sheet(item: $templateToEdit) { template in
            CreateWorkoutTemplateView(existingTemplate: template) { updated in
                selectedTemplate = updated
            }
        }
    }
    
    // MARK: - Delete
    
    private func deleteTemplate(_ template: WorkoutTemplate) {
        modelContext.delete(template)
        try? modelContext.save()
    }
    
    // MARK: - Save
    
    private func saveWorkout() {
        guard let workoutTemplate = selectedTemplate else {
            return
        }
        
        let calendar = Calendar.current
        
        guard let endDate = calendar.date(byAdding: .day, value: (numberOfWeeks - 1) * 7, to: startDate) else {
            return
        }
        
        let schedule = WorkoutSchedule(startDate: startDate, endDate: endDate,
                                       weekday: weekday, workoutTemplate: workoutTemplate)
        
        modelContext.insert(schedule)
        
        var scheduledDate = startDate
        
        for _ in 0..<numberOfWeeks {
            let scheduledWorkout = ScheduledWorkout(scheduledDate: scheduledDate, workoutTemplate: workoutTemplate)
            
            modelContext.insert(scheduledWorkout)
            
            for templateExercise in workoutTemplate.exercises ?? [] {
                guard let copy = templateExercise.makeCopy(for: scheduledWorkout) else {
                    continue
                }
                
                modelContext.insert(copy)
                scheduledWorkout.exercises?.append(copy)
            }
            
            scheduledDate = calendar.date(byAdding: .day, value: 7, to: scheduledDate)!
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save workout: \(error)")
        }
    }
}

struct EditScheduledWorkoutView: View {
    let scheduledWorkout: ScheduledWorkout
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \WorkoutSchedule.startDate)
    private var workoutSchedules: [WorkoutSchedule]
    
    @State private var showAddExerciseSheet: Bool = false
    @State private var supersetBaseExercise: WorkoutExercise?
    @State private var exerciseToEdit: WorkoutExercise?
    
    @State private var numberOfWeeks: Int = 1
    @State private var hasLoadedNumberOfWeeks: Bool = false
    
    private var exercises: [WorkoutExercise] {
        (scheduledWorkout.exercises ?? []).sorted { $0.order < $1.order }
    }
    
    private var nextOrder: Int {
        (exercises.map(\.order).max() ?? -1) + 1
    }
    
    // The recurring schedule that produced this occurrence, used to let the
    // number of weeks be edited relative to the series' original start date.
    private var matchingSchedule: WorkoutSchedule? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: scheduledWorkout.scheduledDate)
        
        return workoutSchedules
            .filter {
                $0.workoutTemplate?.id == scheduledWorkout.workoutTemplate?.id &&
                $0.weekday == weekday &&
                $0.startDate <= scheduledWorkout.scheduledDate
            }
            .max { $0.startDate < $1.startDate }
    }
    
    private func weeks(for schedule: WorkoutSchedule) -> Int {
        guard let endDate = schedule.endDate else {
            return 1
        }
        
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: schedule.startDate, to: endDate).day ?? 0
        
        return max(1, (days / 7) + 1)
    }
    
    private var exerciseRows: [TemplateExerciseRow] {
        var rows: [TemplateExerciseRow] = []
        var index = 0
        
        while index < exercises.count {
            let exercise = exercises[index]
            
            guard let supersetID = exercise.supersetID else {
                rows.append(.single(exercise))
                index += 1
                continue
            }
            
            let supersetExercises = exercises.filter { $0.supersetID == supersetID }
            
            if let first = supersetExercises.first(where: { $0.supersetPosition == .first }),
               let second = supersetExercises.first(where: { $0.supersetPosition == .second }) {
                rows.append(.superset(first: first, second: second))
                
                index += supersetExercises.count
            } else { // Defensive fallback for malformed/incomplete data.
                rows.append(.single(exercise))
                index += 1
            }
        }
        
        return rows
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let matchingSchedule {
                    Section {
                        Stepper(value: $numberOfWeeks, in: 1...52) {
                            HStack {
                                Text("duration".localized(comment: "Duration"))
                                
                                Spacer()
                                
                                Text("x_week".localized(with: numberOfWeeks, comment: "x week(s)"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("schedule".localized(comment: "Schedule"))
                    } footer: {
                        Text("schedule_weeks_footer".localized(comment: "Changes the number of weeks this workout repeats for, starting from when it first began."))
                    }
                    .onAppear {
                        if !hasLoadedNumberOfWeeks {
                            numberOfWeeks = weeks(for: matchingSchedule)
                            hasLoadedNumberOfWeeks = true
                        }
                    }
                }
                
                Section {
                    ForEach(exerciseRows) { row in
                        switch row {
                        case .single(let workoutExercise):
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workoutExercise.exercise?.name ?? "unknown_exercise".localized(comment: "Unknown Exercise"))
                                    
                                    Text("\(workoutExercise.targetSets) x \(formattedTargetValue(for: workoutExercise))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    exerciseToEdit = workoutExercise
                                }
                                
                                Spacer()
                                
                                Button {
                                    supersetBaseExercise = workoutExercise
                                } label: {
                                    Image(systemName: "link.badge.plus")
                                }
                                .buttonStyle(.borderless)
                            }
                            .contentShape(Rectangle())
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    delete(row)
                                } label: {
                                    Label("delete".localized(comment: "Delete"), systemImage: "trash")
                                }
                                
                                Button {
                                    exerciseToEdit = workoutExercise
                                } label: {
                                    Label("edit".localized(comment: "Edit"), systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            
                        case .superset(let first, let second):
                            SupersetExerciseRow(first: first, second: second, onEdit: { exercise in
                                exerciseToEdit = exercise
                            }, onUnlink: {
                                unlinkSuperset(first: first, second: second)
                            })
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    delete(row)
                                } label: {
                                    Label("delete".localized(comment: "Delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                    
                    Button("add_exercise".localized(comment: "Add Exercise"), systemImage: "plus") {
                        showAddExerciseSheet = true
                    }
                } header: {
                    Text("exercises".localized(comment: "Exercises"))
                } footer: {
                    Text("workout_changes_footer".localized(comment: "Changes here only affect this workout and its following occurrences - the template it was created from stays unchanged."))
                }
            }
            .navigationTitle(scheduledWorkout.workoutTemplate?.name ?? "workout".localized(comment: "Workout"))
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        modelContext.rollback()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        applyNumberOfWeeksChangeIfNeeded()
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showAddExerciseSheet) {
            AddExerciseView(mode: .normal(order: nextOrder)) { workoutExercise in
                addExercise(workoutExercise)
            }
        }
        .sheet(item: $supersetBaseExercise) { baseExercise in
            AddExerciseView(mode: .superset(with: baseExercise)) { workoutExercise in
                addSupersetExercise(workoutExercise, to: baseExercise)
            }
        }
        .sheet(item: $exerciseToEdit) { workoutExercise in
            AddExerciseView(
                mode: .edit(workoutExercise),
                onAdd: { updated in
                    updated.propagateToFollowingWorkouts(deleted: false, modelContext: modelContext)
                    updated.syncOwnPerformedExercise(modelContext: modelContext)
                },
                onRemoveFromSuperset: workoutExercise.isInSuperset ? {
                    workoutExercise.removeFromSuperset(modelContext: modelContext)
                } : nil
            )
        }
    }
    
    // MARK: - Mutations
    
    private func addExercise(_ workoutExercise: WorkoutExercise) {
        workoutExercise.scheduledWorkout = scheduledWorkout
        modelContext.insert(workoutExercise)
        scheduledWorkout.exercises?.append(workoutExercise)
        
        workoutExercise.propagateToFollowingWorkouts(deleted: false, modelContext: modelContext)
        workoutExercise.addToOwnSessionIfNeeded(modelContext: modelContext)
    }
    
    private func addSupersetExercise(_ workoutExercise: WorkoutExercise, to baseExercise: WorkoutExercise) {
        let supersetID = baseExercise.supersetID ?? UUID()
        
        baseExercise.supersetID = supersetID
        baseExercise.supersetPosition = .first
        
        workoutExercise.supersetID = supersetID
        workoutExercise.supersetPosition = .second
        workoutExercise.order = baseExercise.order
        workoutExercise.scheduledWorkout = scheduledWorkout
        
        modelContext.insert(workoutExercise)
        scheduledWorkout.exercises?.append(workoutExercise)
        
        baseExercise.propagateToFollowingWorkouts(deleted: false, modelContext: modelContext)
        workoutExercise.propagateToFollowingWorkouts(deleted: false, modelContext: modelContext)
        
        baseExercise.syncOwnPerformedExercise(modelContext: modelContext)
        workoutExercise.addToOwnSessionIfNeeded(modelContext: modelContext)
    }
    
    private func unlinkSuperset(first: WorkoutExercise, second: WorkoutExercise) {
        first.supersetID = nil
        first.supersetPosition = nil
        
        second.supersetID = nil
        second.supersetPosition = nil
        
        first.propagateToFollowingWorkouts(deleted: false, modelContext: modelContext)
        second.propagateToFollowingWorkouts(deleted: false, modelContext: modelContext)
        
        first.syncOwnPerformedExercise(modelContext: modelContext)
        second.syncOwnPerformedExercise(modelContext: modelContext)
    }
    
    private func delete(_ row: TemplateExerciseRow) {
        switch row {
        case .single(let exercise):
            remove(exercise)
            
        case .superset(let first, let second):
            remove(first)
            remove(second)
        }
    }
    
    private func remove(_ exercise: WorkoutExercise) {
        exercise.propagateToFollowingWorkouts(deleted: true, modelContext: modelContext)
        exercise.removeFromOwnSessionIfNeeded(modelContext: modelContext)
        
        scheduledWorkout.exercises?.removeAll { $0.id == exercise.id }
        modelContext.delete(exercise)
    }
    
    // MARK: - Number of Weeks
    
    // Extends or trims the recurring series so its total length matches
    // numberOfWeeks, always counting from the series' original start date.
    private func applyNumberOfWeeksChangeIfNeeded() {
        guard let schedule = matchingSchedule,
              let workoutTemplate = schedule.workoutTemplate else {
            return
        }
        
        let calendar = Calendar.current
        let oldWeeks = weeks(for: schedule)
        
        guard numberOfWeeks != oldWeeks,
              let newEndDate = calendar.date(byAdding: .day, value: (numberOfWeeks - 1) * 7, to: schedule.startDate) else {
            return
        }
        
        if numberOfWeeks > oldWeeks {
            var date = calendar.date(byAdding: .day, value: oldWeeks * 7, to: schedule.startDate) ?? newEndDate
            
            while date <= newEndDate {
                let alreadyScheduled = (workoutTemplate.scheduledWorkouts ?? []).contains {
                    calendar.isDate($0.scheduledDate, inSameDayAs: date)
                }
                
                if !alreadyScheduled {
                    let newWorkout = ScheduledWorkout(scheduledDate: date, workoutTemplate: workoutTemplate)
                    modelContext.insert(newWorkout)
                    
                    for templateExercise in workoutTemplate.exercises ?? [] {
                        guard let copy = templateExercise.makeCopy(for: newWorkout) else {
                            continue
                        }
                        
                        modelContext.insert(copy)
                        newWorkout.exercises?.append(copy)
                    }
                }
                
                guard let nextDate = calendar.date(byAdding: .day, value: 7, to: date) else {
                    break
                }
                
                date = nextDate
            }
        } else {
            let oldEndDate = schedule.endDate ?? newEndDate
            
            let workoutsToRemove = (workoutTemplate.scheduledWorkouts ?? []).filter {
                $0.scheduledDate > newEndDate &&
                $0.scheduledDate <= oldEndDate &&
                calendar.component(.weekday, from: $0.scheduledDate) == schedule.weekday
            }
            
            for workout in workoutsToRemove {
                modelContext.delete(workout)
            }
        }
        
        schedule.endDate = newEndDate
    }
}

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \ScheduledWorkout.scheduledDate)
    private var scheduledWorkouts: [ScheduledWorkout]
    
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    
    @State private var showAddWorkoutSheet: Bool = false
    @State private var showingSettingsSheet: Bool = false
    @State private var workoutToEdit: ScheduledWorkout?
    
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = true ? 2 : 1 // change true to false to set Sunday as first day of the week
        return calendar
    }
    
    private func workouts(on date: Date) -> [ScheduledWorkout] {
        scheduledWorkouts.filter {
            calendar.isDate($0.scheduledDate, inSameDayAs: date)
        }
    }
    
    private var selectedDayWorkouts: [ScheduledWorkout] {
        workouts(on: selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: - Month header
                
                monthHeader
                
                // MARK: - Calendar
                
                calendarGrid
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                
                Divider()
                
                // MARK: - Selected day
                
                selectedDayView
            }
            .navigationTitle("calendar".localized(comment: "Calendar"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(action: {
                            showingSettingsSheet = true
                        }) {
                            Label("settings".localized(comment: "Settings"), systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26.0, *) {
                        if calendar.isDateInToday(selectedDate) {
                            Button("today".localized(comment: "Today")) {
                                goToToday()
                            }
                        } else {
                            Button("today".localized(comment: "Today")) {
                                goToToday()
                            }
                            .buttonStyle(.glassProminent)
                        }
                    } else {
                        if calendar.isDateInToday(selectedDate) {
                            Button("today".localized(comment: "Today")) {
                                goToToday()
                            }
                        } else {
                            Button("today".localized(comment: "Today")) {
                                goToToday()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddWorkoutSheet) {
            AddWorkoutView(startDate: selectedDate)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsSheet()
        }
        .sheet(item: $workoutToEdit) { scheduledWorkout in
            EditScheduledWorkoutView(scheduledWorkout: scheduledWorkout)
        }
    }
    
    // MARK: - Month Header
    
    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
            }
            
            Spacer()
            
            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
            
            Spacer()
            
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    // MARK: - Calendar Grid
    
    private var calendarGrid: some View {
        VStack(spacing: 8) {
            
            weekdayHeader
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear
                            .frame(height: 48)
                    }
                }
            }
        }
    }
    
    private var weekdayHeader: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(weekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Day Cell
    
    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        
        let isToday = calendar.isDateInToday(date)
        
        let isCurrentMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
        
        let workouts = workouts(on: date)
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = date
                
                // Optional: automatically move to that month
                if !isCurrentMonth {
                    displayedMonth = date
                }
            }
        } label: {
            VStack(spacing: 4) {
                Text(
                    date.formatted(.dateTime.day())
                )
                .font(.body)
                .fontWeight(isToday || isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.white : isCurrentMonth ? Color.primary : Color.secondary.opacity(0.5))
                .frame(width: 42, height: 42)
                .background {
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                    } else if isToday {
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 2)
                    }
                }
                
                HStack(spacing: 3) {
                    ForEach(workouts.prefix(3), id: \.id) { _ in
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Selected Day
    
    private var selectedDayView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(selectedDate.formatted(.dateTime.month(.wide).day().year()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if !selectedDayWorkouts.isEmpty {
                    Button {
                        showAddWorkoutSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 14)
            .padding(.bottom, 12)
            
            let workouts = workouts(on: selectedDate)
            
            if workouts.isEmpty {
                emptyDayView
            } else {
                List {
                    ForEach(workouts) { scheduledWorkout in
                        NavigationLink {
                            ExerciseView(scheduledWorkout: scheduledWorkout)
                        } label: {
                            ScheduledWorkoutCard(scheduledWorkout: scheduledWorkout)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 12, leading: 30, bottom: 16, trailing: 24))
                        .listRowBackground(RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .secondarySystemBackground))
                            .padding(.horizontal, 14))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteWorkout(scheduledWorkout)
                            } label: {
                                Label("delete".localized(comment: "Delete"), systemImage: "trash")
                            }
                            
                            Button {
                                workoutToEdit = scheduledWorkout
                            } label: {
                                Label("edit".localized(comment: "Edit"), systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private func deleteWorkout(_ scheduledWorkout: ScheduledWorkout) {
        modelContext.delete(scheduledWorkout)
        try? modelContext.save()
    }
    
    private var emptyDayView: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: "figure.run")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            Text("rest_day".localized(comment: "Rest Day"))
                .font(.headline)
            
            Text("no_workout_scheduled".localized(comment: "No workout scheduled"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button("add_workout".localized(comment: "Add Workout"), systemImage: "plus") {
                showAddWorkoutSheet = true
            }
            .buttonStyle(.bordered)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Date Helpers
    
    private var monthDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else {
            return []
        }
        
        let monthStart = monthInterval.start
        
        // Number of blank cells before the first day of the month.
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        
        let leadingEmptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 0
        
        // Total number of cells needed to complete the final week.
        let totalDays = leadingEmptyDays + daysInMonth
        let trailingDays = (7 - (totalDays % 7)) % 7
        
        let totalCells = totalDays + trailingDays
        
        var dates: [Date?] = []
        
        // Generate the actual dates surrounding the month.
        for offset in 0..<totalCells {
            let dayOffset = offset - leadingEmptyDays
            
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let startIndex = calendar.firstWeekday - 1
        
        return Array(symbols[startIndex...]) + Array(symbols[..<startIndex])
    }
    
    // MARK: - Navigation
    
    private func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) else {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = newMonth
        }
    }
    
    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = Date()
            selectedDate = Date()
        }
    }
}

// MARK: - Color

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r: Double
        let g: Double
        let b: Double
        
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
            
        default:
            r = 0
            g = 0
            b = 0
        }
        
        self.init(
            red: r,
            green: g,
            blue: b
        )
    }
}
