//
//  ExerciseHistoryView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-24.
//

import SwiftUI
import SwiftData
import Charts

private struct ExerciseHistoryEntry {
    let date: Date
    let weight: Double?
    let reps: Int?
    let sets: Int
    let duration: Double?
    let distance: Int?
}

struct ExerciseHistoryView: View {
    let exercise: Exercise

    @Query private var allPerformedExercises: [PerformedExercise]

    private var weightUnit: Unit {
        isMetricSystem() ? Unit(symbol: "kg") : Unit(symbol: "lbs")
    }

    private var distanceUnit: Unit {
        isMetricSystem() ? Unit(symbol: "km") : Unit(symbol: "mi")
    }

    // Every PerformedExercise snapshots the exercise's name, which lets history survive
    // even if the WorkoutExercise/template it came from is later removed.
    private var historyEntries: [ExerciseHistoryEntry] {
        allPerformedExercises
            .filter { $0.exerciseName == exercise.name }
            .compactMap { performed -> ExerciseHistoryEntry? in
                guard let date = performed.workoutSession?.startedAt else { return nil }

                let allSets = performed.sets ?? []
                let completedSets = allSets.filter(\.completed)
                let sets = completedSets.isEmpty ? allSets : completedSets

                guard !sets.isEmpty else { return nil }

                let distances = sets.compactMap(\.distance)

                return ExerciseHistoryEntry(
                    date: date,
                    weight: sets.compactMap(\.weight).max(),
                    reps: sets.compactMap(\.reps).max(),
                    sets: sets.count,
                    duration: sets.compactMap(\.duration).max(),
                    distance: distances.isEmpty ? nil : distances.reduce(0, +)
                )
            }
            .sorted { $0.date < $1.date }
    }

    private var hasWeightData: Bool {
        historyEntries.contains { $0.weight != nil }
    }

    private var hasRepsData: Bool {
        !exercise.isTimeBased && !exercise.isDistanceBased && historyEntries.contains { $0.reps != nil }
    }

    private var hasSetsData: Bool {
        historyEntries.contains { $0.sets > 0 }
    }

    private var hasDurationData: Bool {
        exercise.isTimeBased && historyEntries.contains { $0.duration != nil }
    }

    private var hasDistanceData: Bool {
        exercise.isDistanceBased && historyEntries.contains { $0.distance != nil }
    }

    var body: some View {
        ScrollView {
            if !historyEntries.isEmpty {
                VStack(spacing: 24) {
                    if hasWeightData {
                        ProgressChartCard(
                            title: "weight".localized(comment: "Weight"),
                            data: historyEntries.compactMap { entry in
                                guard let weight = entry.weight else { return nil }
                                return ChartDataPoint(date: entry.date, value: weight)
                            },
                            unit: weightUnit.symbol,
                            color: .blue
                        )
                    }

                    if hasRepsData {
                        ProgressChartCard(
                            title: "reps".localized(comment: "Reps"),
                            data: historyEntries.compactMap { entry in
                                guard let reps = entry.reps else { return nil }
                                return ChartDataPoint(date: entry.date, value: Double(reps))
                            },
                            unit: "",
                            color: .green,
                            valueFormat: "%.0f"
                        )
                    }

                    if hasSetsData {
                        ProgressChartCard(
                            title: "sets".localized(comment: "Sets"),
                            data: historyEntries.compactMap { entry in
                                guard entry.sets > 0 else { return nil }
                                return ChartDataPoint(date: entry.date, value: Double(entry.sets))
                            },
                            unit: "",
                            color: .orange,
                            valueFormat: "%.0f"
                        )
                    }

                    if hasDurationData {
                        ProgressChartCard(
                            title: "duration".localized(comment: "Duration"),
                            data: historyEntries.compactMap { entry in
                                guard let duration = entry.duration else { return nil }
                                return ChartDataPoint(date: entry.date, value: duration)
                            },
                            unit: "s",
                            color: .purple,
                            valueFormat: "%.0f"
                        )
                    }

                    if hasDistanceData {
                        ProgressChartCard(
                            title: "distance".localized(comment: "Distance"),
                            data: historyEntries.compactMap { entry in
                                guard let distance = entry.distance else { return nil }
                                return ChartDataPoint(date: entry.date, value: Double(distance))
                            },
                            unit: distanceUnit.symbol,
                            color: .red,
                            valueFormat: "%.0f"
                        )
                    }
                }
                .padding()
            } else {
                VStack {
                    Spacer()
                    Text("no_history".localized(comment: "No history available"))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .navigationTitle(exercise.name)
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct ProgressChartCard: View {
    let title: String
    let data: [ChartDataPoint]
    let unit: String
    let color: Color
    var valueFormat: String = "%.1f"

    private var minValue: Double {
        data.map(\.value).min() ?? 0
    }

    private var maxValue: Double {
        data.map(\.value).max() ?? 0
    }

    private var improvement: Double? {
        guard data.count >= 2,
              let first = data.first?.value,
              let last = data.last?.value,
              first > 0 else { return nil }
        return ((last - first) / first) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                if let improvement = improvement {
                    HStack(spacing: 4) {
                        Image(systemName: improvement >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text("\(abs(improvement), specifier: "%.1f")%")
                            .font(.caption)
                    }
                    .foregroundColor(improvement >= 0 ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(improvement >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
                }
            }

            if data.count >= 2 {
                Chart(data) { point in
                    LineMark(
                        x: .value("date".localized(comment: "Date"), point.date),
                        y: .value(title, point.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("date".localized(comment: "Date"), point.date),
                        y: .value(title, point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.05)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("date".localized(comment: "Date"), point.date),
                        y: .value(title, point.value)
                    )
                    .foregroundStyle(color)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartYScale(domain: (minValue * 0.9)...(maxValue * 1.1))
                .frame(height: 200)
                .clipped()
            } else if data.count == 1 {
                Text("need_2_points".localized(comment: "Need at least 2 data points to show progression"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("current".localized(comment: "Current"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let last = data.last {
                        Text("\(last.value, specifier: valueFormat) \(unit)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("best".localized(comment: "Best"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(maxValue, specifier: valueFormat) \(unit)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}
