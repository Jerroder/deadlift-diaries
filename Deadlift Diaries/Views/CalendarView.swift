//
//  CalendarView.swift
//  Deadlift Diaries
//

import SwiftData
import SwiftUI

struct AddWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Workout
    
    @State private var name = ""
    @State private var notes = ""
    
    // MARK: - Schedule
    
    @State private var startDate = Date()
    @State private var numberOfWeeks = 1
    
    private var weekday: Int {
        Calendar.current.component(
            .weekday,
            from: startDate
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Workout
                
                Section {
                    TextField(
                        "Workout Name",
                        text: $name
                    )
                    
                    TextField(
                        "Notes",
                        text: $notes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                } header: {
                    Text("Workout")
                }
                
                // MARK: - Schedule
                
                Section {
                    DatePicker(
                        "Start Date",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    
                    Stepper(
                        value: $numberOfWeeks,
                        in: 1...52
                    ) {
                        HStack {
                            Text("Duration")
                            
                            Spacer()
                            
                            Text(
                                "\(numberOfWeeks) " +
                                "\(numberOfWeeks == 1 ? "week" : "weeks")"
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Repeats")
                        
                        Spacer()
                        
                        Text(
                            startDate.formatted(
                                .dateTime.weekday(.wide)
                            )
                        )
                        .foregroundStyle(.secondary)
                    }
                    
                    if let endDate = calculatedEndDate {
                        HStack {
                            Text("Ends")
                            
                            Spacer()
                            
                            Text(
                                endDate.formatted(
                                    .dateTime
                                        .month(.abbreviated)
                                        .day()
                                        .year()
                                )
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Schedule")
                } footer: {
                    Text(
                        "The workout will repeat every " +
                        "\(startDate.formatted(.dateTime.weekday(.wide))) " +
                        "for \(numberOfWeeks) " +
                        "\(numberOfWeeks == 1 ? "week" : "weeks")."
                    )
                }
                
                // MARK: - Exercises
                
                Section {
                    Button {
                        // Exercise logic will be added later.
                    } label: {
                        Label(
                            "Add Exercise",
                            systemImage: "plus"
                        )
                    }
                } header: {
                    Text("Exercises")
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
                    .disabled(
                        name
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                    )
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var calculatedEndDate: Date? {
        guard numberOfWeeks > 0 else {
            return nil
        }
        
        return Calendar.current.date(
            byAdding: .weekOfYear,
            value: numberOfWeeks - 1,
            to: startDate
        )
    }
    
    // MARK: - Save
    
    private func saveWorkout() {
        let trimmedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        guard !trimmedName.isEmpty else {
            return
        }
        
        let trimmedNotes = notes.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        let calendar = Calendar.current
        
        // The final occurrence is numberOfWeeks - 1
        // weeks after the start date.
        guard let endDate = calendar.date(
            byAdding: .weekOfYear,
            value: numberOfWeeks - 1,
            to: startDate
        ) else {
            return
        }
        
        // 1. Create the reusable workout template.
        
        let workoutTemplate = WorkoutTemplate(
            name: trimmedName,
            notes: trimmedNotes.isEmpty
            ? nil
            : trimmedNotes
        )
        
        // 2. Create the recurring schedule.
        
        let schedule = WorkoutSchedule(
            startDate: startDate,
            endDate: endDate,
            weekday: weekday,
            workoutTemplate: workoutTemplate
        )
        
        // 3. Create each scheduled occurrence.
        
        var scheduledDate = startDate
        
        for _ in 0..<numberOfWeeks {
            let scheduledWorkout = ScheduledWorkout(
                scheduledDate: scheduledDate,
                workoutTemplate: workoutTemplate
            )
            
            modelContext.insert(scheduledWorkout)
            
            guard let nextDate = calendar.date(
                byAdding: .weekOfYear,
                value: 1,
                to: scheduledDate
            ) else {
                break
            }
            
            scheduledDate = nextDate
        }
        
        // 4. Insert the template and schedule.
        
        modelContext.insert(workoutTemplate)
        modelContext.insert(schedule)
        
        // 5. Save everything.
        
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

    @FocusState.Binding var focusedField: FocusableField?

    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    
    @State private var showAddWorkoutSheet: Bool = false

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = true ? 2 : 1 // change true to false to set Sunday as first day of the week
        return calendar
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        goToToday()
                    } label: {
                        Text("Today")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddWorkoutSheet) {
            AddWorkoutView()
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
            
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 4),
                    count: 7
                ),
                spacing: 8
            ) {
                ForEach(
                    Array(monthDays.enumerated()),
                    id: \.offset
                ) { _, date in
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
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible()),
                count: 7
            )
        ) {
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
        let isSelected = calendar.isDate(
            date,
            inSameDayAs: selectedDate
        )
        
        let isToday = calendar.isDateInToday(date)
        
        let workouts = workouts(on: date)
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.day()))
                    .font(.body)
                    .fontWeight(
                        isToday || isSelected
                        ? .semibold
                        : .regular
                    )
                    .foregroundStyle(
                        isSelected
                        ? Color.white
                        : .primary
                    )
                    .frame(width: 42, height: 42)
                    .background {
                        if isSelected {
                            Circle()
                                .fill(Color.accentColor)
                        } else if isToday {
                            Circle()
                                .stroke(
                                    Color.accentColor,
                                    lineWidth: 2
                                )
                        }
                    }
                
                HStack(spacing: 3) {
                    ForEach(
                        workouts.prefix(3),
                        id: \.id
                    ) { workout in
                        Circle()
                            .fill(Color.red)
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

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        selectedDate.formatted(
                            .dateTime.weekday(.wide)
                        )
                    )
                    .font(.title3)
                    .fontWeight(.semibold)

                    Text(
                        selectedDate.formatted(
                            .dateTime.month(.wide).day().year()
                        )
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    // Add workout action
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())
            }
            .padding(.horizontal)
            .padding(.top, 14)
            .padding(.bottom, 12)

            ScrollView {
                let workouts = workouts(on: selectedDate)

                if workouts.isEmpty {
                    emptyDayView
                } else {
                    VStack(spacing: 12) {
                        ForEach(workouts) { scheduledWorkout in
//                            ScheduledWorkoutCard(
//                                scheduledWorkout: scheduledWorkout
//                            )
                            Text(scheduledWorkout.notes ?? "empty")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .frame(maxHeight: .infinity)
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

            Button {
                showAddWorkoutSheet = true
            } label: {
                Label(
                    "Add Workout",
                    systemImage: "plus"
                )
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Date Helpers

    private var monthDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(
            of: .month,
            for: displayedMonth
        ) else {
            return []
        }

        let firstWeekday = calendar.component(
            .weekday,
            from: monthInterval.start
        )

        let daysInMonth = calendar.range(
            of: .day,
            in: .month,
            for: displayedMonth
        )?.count ?? 0

        // Calendar.current's weekday starts at Sunday = 1.
        // We convert this to the number of empty cells before day 1.
        let leadingEmptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7

        var dates: [Date?] = []

        for _ in 0..<leadingEmptyDays {
            dates.append(nil)
        }

        for day in 1...daysInMonth {
            if let date = calendar.date(
                bySetting: .day,
                value: day,
                of: displayedMonth
            ) {
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

    private func workouts(on date: Date) -> [ScheduledWorkout] {
        scheduledWorkouts.filter {
            calendar.isDate(
                $0.scheduledDate,
                inSameDayAs: date
            )
        }
    }

    // MARK: - Navigation

    private func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(
            byAdding: .month,
            value: value,
            to: displayedMonth
        ) else {
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
        let hex = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )

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
