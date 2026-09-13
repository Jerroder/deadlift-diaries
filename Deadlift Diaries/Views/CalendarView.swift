//
//  CalendarView.swift
//  Deadlift Diaries
//

import SwiftData
import SwiftUI

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ScheduledWorkout.date)
    private var scheduledWorkouts: [ScheduledWorkout]

    @FocusState.Binding var focusedField: FocusableField?

    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()

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
                ForEach(monthDays, id: \.self) { date in
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
                            .fill(workoutColor(for: workout))
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
                            ScheduledWorkoutCard(
                                scheduledWorkout: scheduledWorkout
                            )
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
                // Add workout action
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
                $0.date,
                inSameDayAs: date
            )
        }
    }

    private func workoutColor(
        for scheduledWorkout: ScheduledWorkout
    ) -> Color {
        if let hex = scheduledWorkout.workout?.colorHex {
            return Color(hex: hex)
        }

        return .accentColor
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

            // Keep selection inside the displayed month.
            if !calendar.isDate(
                selectedDate,
                equalTo: newMonth,
                toGranularity: .month
            ) {
                selectedDate = newMonth
            }
        }
    }

    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = Date()
            selectedDate = Date()
        }
    }
}

// MARK: - Scheduled Workout Card

private struct ScheduledWorkoutCard: View {
    let scheduledWorkout: ScheduledWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        scheduledWorkout.workout?.name
                        ?? "Workout"
                    )
                    .font(.headline)

                    if let block = scheduledWorkout.trainingBlock {
                        Text(block.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                statusBadge
            }

            if let exercises = scheduledWorkout.workout?.exercises {
                VStack(spacing: 8) {
                    ForEach(
                        exercises.sorted {
                            $0.orderIndex < $1.orderIndex
                        }
                    ) { exercise in
                        exerciseRow(exercise)
                    }
                }
            }

            Button {
                // Start workout
            } label: {
                Text("Start Workout")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.15))
            )
            .foregroundStyle(statusColor)
    }

    private var statusText: String {
        switch scheduledWorkout.status {
        case .planned:
            return "Planned"
        case .completed:
            return "Completed"
        case .skipped:
            return "Skipped"
        }
    }

    private var statusColor: Color {
        switch scheduledWorkout.status {
        case .planned:
            return .accentColor
        case .completed:
            return .green
        case .skipped:
            return .secondary
        }
    }

    private func exerciseRow(
        _ workoutExercise: WorkoutExercise
    ) -> some View {
        HStack {

            Text(
                workoutExercise.exercise?.name
                ?? "Exercise"
            )
            .font(.subheadline)

            Spacer()

            Text(prescriptionText(workoutExercise))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func prescriptionText(
        _ exercise: WorkoutExercise
    ) -> String {

        if let reps = exercise.reps {
            var text = "\(exercise.sets) × \(reps)"

            if let weight = exercise.weight {
                text += " @ \(formattedWeight(weight))"
            }

            return text
        }

        if let duration = exercise.duration {
            return "\(exercise.sets) × \(Int(duration))s"
        }

        if let distance = exercise.distance {
            return "\(exercise.sets) × \(distance)m"
        }

        return "\(exercise.sets) sets"
    }

    private func formattedWeight(
        _ weight: Double
    ) -> String {
        if weight.rounded() == weight {
            return "\(Int(weight)) kg"
        }

        return String(format: "%.1f kg", weight)
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
