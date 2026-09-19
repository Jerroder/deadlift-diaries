//
//  CalendarView.swift
//  Deadlift Diaries
//

import SwiftData
import SwiftUI

struct ScheduledWorkoutCard: View {
    let scheduledWorkout: ScheduledWorkout
    
    private var workoutTemplate: WorkoutTemplate? {
        scheduledWorkout.workoutTemplate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let workoutTemplate {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(workoutTemplate.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if let notes = workoutTemplate.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                
                if let exercises = workoutTemplate.exercises, !exercises.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(exercises.sorted(by: { $0.order < $1.order })) { workoutExercise in
                            WorkoutExerciseRow(workoutExercise: workoutExercise)
                        }
                    }
                    .padding(.leading, 14)
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Workout")
                            .font(.headline)
                        
                        Text("Template unavailable")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    struct WorkoutExerciseRow: View {
        let workoutExercise: WorkoutExercise
        
        private var exerciseName: String {
            workoutExercise.exercise?.name ?? "Unknown Exercise"
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
            if let weight = workoutExercise.targetWeight {
                return "\(workoutExercise.targetSets) x \(workoutExercise.targetReps) @ \(weight.formatted()) kg"
            }
            
            return "\(workoutExercise.targetSets) x \(workoutExercise.targetReps)"
        }
    }
}

struct CreateExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let initialName: String
    let onCreate: (Exercise) -> Void
    
    @State private var name: String
    @State private var isTimeBased = false
    @State private var isDistanceBased = false
    @State private var notes = ""
    
    init(initialName: String = "", onCreate: @escaping (Exercise) -> Void) {
        self.initialName = initialName
        self.onCreate = onCreate
        _name = State(initialValue: initialName)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name", text: $name)
                    
                    Toggle("Time based", isOn: $isTimeBased)
                        .onChange(of: isTimeBased) { _, value in
                            if value {
                                isDistanceBased = false
                            }
                        }
                    
                    Toggle("Distance based", isOn: $isDistanceBased)
                        .onChange(of: isDistanceBased) { _, value in
                            if value {
                                isTimeBased = false
                            }
                        }
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
        
        let exercise = Exercise(
            name: trimmedName,
            isTimeBased: isTimeBased,
            isDistanceBased: isDistanceBased,
            notes: notes.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
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

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let order: Int
    let onAdd: (WorkoutExercise) -> Void
    
    @Query(sort: \Exercise.name)
    private var exercises: [Exercise]
    
    @State private var searchText = ""
    
    @State private var selectedExercise: Exercise?
    
    @State private var sets = 3
    @State private var reps = 8
    @State private var restSeconds = 150
    @State private var weight: Double?
    
    private var filteredExercises: [Exercise] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            return exercises
        }
        
        return exercises.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Exercise
                
                Section("Exercise") {
                    if let selectedExercise {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedExercise.name)
                                    .font(.headline)
                                
                                if selectedExercise.isTimeBased {
                                    Text("Time based")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if selectedExercise.isDistanceBased {
                                    Text("Distance based")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Change") {
                                self.selectedExercise = nil
                            }
                        }
                    } else {
                        TextField("Search exercises", text: $searchText)
                        
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
                                            Text("Time")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        } else if exercise.isDistanceBased {
                                            Text("Distance")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        NavigationLink {
                            CreateExerciseView(initialName: searchText) { exercise in
                                selectedExercise = exercise
                            }
                        } label: {
                            Label("Create New Exercise", systemImage: "plus")
                        }
                    }
                }
                
                // MARK: - Targets
                
                if let selectedExercise {
                    Section("Target") {
                        Stepper(value: $sets, in: 1...20) {
                            HStack {
                                Text("Sets")
                                Spacer()
                                Text("\(sets)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if selectedExercise.isTimeBased {
                            Stepper(value: $reps, in: 1...3600) {
                                HStack {
                                    Text("Duration")
                                    Spacer()
                                    Text(formattedDuration(reps))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else if selectedExercise.isDistanceBased {
                            Text("Distance target can be added here.")
                                .foregroundStyle(.secondary)
                        } else {
                            Stepper(value: $reps, in: 1...100) {
                                HStack {
                                    Text("Reps")
                                    Spacer()
                                    Text("\(reps)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        HStack {
                            Text("Weight")
                            
                            Spacer()
                            
                            TextField("Optional", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            
                            Text("kg")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // MARK: - Rest
                    
                    Section("Rest") {
                        Stepper(value: $restSeconds, in: 0...600, step: 15) {
                            HStack {
                                Text("Rest")
                                Spacer()
                                Text(formattedRest(restSeconds))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Exercise")
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
    }
    
    // MARK: - Add
    
    private func addExercise() {
        guard let exercise = selectedExercise else {
            return
        }
        
        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            order: order,
            targetSets: sets,
            targetReps: reps,
            targetWeight: weight,
            restSeconds: restSeconds
        )
        
        onAdd(workoutExercise)
        dismiss()
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
    
    private func formattedDuration(_ seconds: Int) -> String {
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

struct CreateWorkoutTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Workout
    
    @State private var name = ""
    @State private var notes = ""
    
    // MARK: - Exercises
    
    @State private var workoutExercises: [WorkoutExercise] = []
    @State private var showAddExerciseSheet = false
    
    let onCreate: (WorkoutTemplate) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Workout
                
                Section {
                    TextField("Workout Name", text: $name)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Workout")
                }
                
                // MARK: - Exercises
                
                Section {
                    ForEach(workoutExercises, id: \.id) { workoutExercise in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(workoutExercise.exercise?.name ?? "Unknown Exercise")
                                
                                Text("\(workoutExercise.targetSets) x \(workoutExercise.targetReps)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .onDelete { offsets in
                        workoutExercises.remove(atOffsets: offsets)
                        
                        // Re-number exercises after deletion
                        for (index, exercise) in workoutExercises.enumerated() {
                            exercise.order = index
                        }
                    }
                    
                    Button("Add Exercise", systemImage: "plus") {
                        showAddExerciseSheet = true
                    }
                    
                } header: {
                    Text("Exercises")
                }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            AddExerciseView(order: workoutExercises.count) { workoutExercise in
                workoutExercises.append(workoutExercise)
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
        
        let workoutTemplate = WorkoutTemplate(name: trimmedName, notes: trimmedNotes.isEmpty ? nil : trimmedNotes)
        
        for (index, workoutExercise) in workoutExercises.enumerated() {
            workoutExercise.order = index
            workoutExercise.workoutTemplate = workoutTemplate
            
            modelContext.insert(workoutExercise)
        }
        
        modelContext.insert(workoutTemplate)
        
        do {
            try modelContext.save()
            
            onCreate(workoutTemplate)
            dismiss()
        } catch {
            print("Failed to create workout template: \(error)")
        }
    }
}


struct AddWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Templates
    
    @Query(sort: \WorkoutTemplate.name)
    private var workoutTemplates: [WorkoutTemplate]
    
    @State private var searchText: String = ""
    @State private var selectedTemplate: WorkoutTemplate?
    
    // MARK: - Schedule
    
    @State private var startDate: Date
    @State private var numberOfWeeks: Int = 1
    
    init(startDate: Date = Date()) {
        _startDate = State(initialValue: startDate)
    }
    
    // MARK: - Computed Properties
    
    private var weekday: Int {
        Calendar.current.component(.weekday, from: startDate)
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
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Workout Template
                
                Section("Workout Template") {
                    if let selectedTemplate {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedTemplate.name)
                                    .font(.headline)
                                
                                if let notes = selectedTemplate.notes {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Change") {
                                self.selectedTemplate = nil
                            }
                        }
                    } else {
                        TextField("Search templates", text: $searchText)
                        
                        if filteredTemplates.isEmpty {
                            ContentUnavailableView("No Templates", systemImage: "list.bullet.rectangle",
                                                   description: Text("Create a workout template to get started.")
                            )
                        } else {
                            ForEach(filteredTemplates) { template in
                                Button {
                                    selectedTemplate = template
                                    searchText = ""
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.name)
                                            .foregroundStyle(.primary)
                                        
                                        if let notes = template.notes {
                                            Text(notes)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                }
                            }
                        }
                        
                        NavigationLink {
                            CreateWorkoutTemplateView { template in
                                selectedTemplate = template
                            }
                        } label: {
                            Label("Create New Template", systemImage: "plus")
                        }
                    }
                }
                
                // MARK: - Schedule
                
                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    Stepper(value: $numberOfWeeks, in: 1...52) {
                        HStack {
                            Text("Duration")
                            
                            Spacer()
                            
                            Text("\(numberOfWeeks) \(numberOfWeeks == 1 ? "week" : "weeks")")
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Repeats")
                        
                        Spacer()
                        
                        Text(startDate.formatted(.dateTime.weekday(.wide)))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let endDate = calculatedEndDate {
                        HStack {
                            Text("Ends")
                            
                            Spacer()
                            
                            Text(endDate
                                .formatted(.dateTime.month(.abbreviated).day().year())
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                } header: {
                    Text("Schedule")
                } footer: {
                    Text("The workout will repeat every \(startDate.formatted(.dateTime.weekday(.wide))) " +
                         "for \(numberOfWeeks) \(numberOfWeeks == 1 ? "week" : "weeks")."
                    )
                }
            }
            .navigationTitle("Add Workout")
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

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ScheduledWorkout.scheduledDate)
    private var scheduledWorkouts: [ScheduledWorkout]

    // @FocusState.Binding var focusedField: FocusableField?

    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()

    @State private var showAddWorkoutSheet: Bool = false
    @State private var showingSettingsSheet: Bool = false

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
            .navigationTitle("Calendar")
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
                    Button("Today") {
                        goToToday()
                    }
                    .tint(
                        calendar.isDateInToday(selectedDate) ? nil : .accentColor
                    )
                }
            }
        }
        .sheet(isPresented: $showAddWorkoutSheet) {
            AddWorkoutView(startDate: selectedDate)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsSheet()
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
                        .listRowBackground(RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .secondarySystemBackground)))
                    }
                    .onDelete { offsets in
                        deleteWorkouts(at: offsets, from: workouts)
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private func deleteWorkouts(at offsets: IndexSet, from workouts: [ScheduledWorkout]) {
        for index in offsets {
            modelContext.delete(workouts[index])
        }
        try? modelContext.save()
    }

    private var emptyDayView: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "figure.run")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("Rest Day")
                .font(.headline)

            Text("No workout scheduled")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Add Workout", systemImage: "plus") {
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
