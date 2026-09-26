//
//  TimerView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftData
import SwiftUI

struct TimerView: View {
    @AppStorage("totalSets") private var totalSets: Int = 5
    @AppStorage("isTimeBased") private var isTimeBased: Bool = false
    @AppStorage("duration") private var duration: Double = 30.0
    @AppStorage("restDuration") private var restDuration: Double = 60.0
    @AppStorage("timeBeforeNext") private var timeBeforeNext: Double = 120.0

    @State private var practiceExercise: Exercise
    @State private var practiceWorkoutExercise: WorkoutExercise
    @State private var performedExercise: PerformedExercise

    @State private var showingSettingsSheet: Bool = false
    @State private var showingRestPicker: Bool = false
    @State private var showingDurationPicker: Bool = false
    @State private var showingTimeBeforeNextPicker: Bool = false

    private var workoutTimer = RestTimerManager.shared

    private var isTimerRunning: Bool {
        workoutTimer.isActive && workoutTimer.exerciseID == performedExercise.id
    }

    init() {
        let totalSets = UserDefaults.standard.object(forKey: "totalSets") as? Int ?? 5
        let isTimeBased = UserDefaults.standard.object(forKey: "isTimeBased") as? Bool ?? false
        let duration = UserDefaults.standard.object(forKey: "duration") as? Double ?? 30.0
        let restDuration = UserDefaults.standard.object(forKey: "restDuration") as? Double ?? 60.0
        let timeBeforeNext = UserDefaults.standard.object(forKey: "timeBeforeNext") as? Double ?? 120.0

        let exercise = Exercise(name: "timer".localized(comment: "Timer"), isTimeBased: isTimeBased)
        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            order: 0,
            targetSets: totalSets,
            targetReps: Int(duration),
            restSeconds: Int(restDuration),
            timeBeforeNext: Int(timeBeforeNext)
        )
        let performed = PerformedExercise(from: workoutExercise, orderIndex: 0)
        performed.sourceExercise = workoutExercise

        _practiceExercise = State(initialValue: exercise)
        _practiceWorkoutExercise = State(initialValue: workoutExercise)
        _performedExercise = State(initialValue: performed)
    }

    var body: some View {
        NavigationStack {
            Form {
                Stepper("total_sets_x".localized(with: totalSets, comment: "Total Sets: x"), value: $totalSets, in: 1...20)
                    .onChange(of: totalSets) { _, _ in
                        rebuildPerformedExercise()
                    }
                    .disabled(isTimerRunning)

                HStack {
                    Button(action: {
                        withAnimation {
                            showingRestPicker.toggle()
                            showingDurationPicker = false
                            showingTimeBeforeNextPicker = false
                        }
                    }) {
                        HStack {
                            HStack(spacing: 4) {
                                Text("rest_duration".localized(comment: "Rest Duration:"))
                                Text("  \(Int(restDuration))s ")
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
                    .disabled(isTimerRunning)

                    if #available(iOS 26.0, *) {
                        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                            GridRow {
                                Button("30s") { restDuration = 30 }
                                    .disabled(isTimerRunning)
                                Button("60s") { restDuration = 60 }
                                    .disabled(isTimerRunning)
                            }
                            GridRow {
                                Button("90s") { restDuration = 90 }
                                    .disabled(isTimerRunning)
                                Button("120s") { restDuration = 120 }
                                    .disabled(isTimerRunning)
                            }
                        }
                        .buttonStyle(.glass)
                    } else {
                        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                            GridRow {
                                Button("30s") { restDuration = 30 }
                                    .disabled(isTimerRunning)
                                Button("60s") { restDuration = 60 }
                                    .disabled(isTimerRunning)
                            }
                            GridRow {
                                Button("90s") { restDuration = 90 }
                                    .disabled(isTimerRunning)
                                Button("120s") { restDuration = 120 }
                                    .disabled(isTimerRunning)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if showingRestPicker {
                    Picker("rest_duration".localized(comment: "Rest duration"), selection: $restDuration) {
                        ForEach(Array(stride(from: 5.0, through: 300.0, by: 5.0)), id: \.self) { duration in
                            Text("x_seconds".localized(with: Int(duration), comment: "x seconds")).tag(duration)
                        }
                    }
                    .pickerStyle(.wheel)
                    .disabled(isTimerRunning)
                    .onChange(of: restDuration) { _, _ in
                        rebuildPerformedExercise()
                    }
                }

                if isTimeBased {
                    Button(action: {
                        withAnimation {
                            showingDurationPicker.toggle()
                            showingRestPicker = false
                            showingTimeBeforeNextPicker = false
                        }
                    }) {
                        HStack {
                            Text("exercise_duration".localized(comment: "Exercise duration"))
                            Text(" \(Int(duration))s")
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
                    .disabled(isTimerRunning)

                    if showingDurationPicker {
                        Picker("exercise_duration".localized(comment: "Exercise duration"), selection: $duration) {
                            ForEach(Array(stride(from: 5.0, through: 300.0, by: 5.0)), id: \.self) { duration in
                                Text("x_seconds".localized(with: Int(duration), comment: "x seconds")).tag(duration)
                            }
                        }
                        .pickerStyle(.wheel)
                        .disabled(isTimerRunning)
                        .onChange(of: duration) { _, _ in
                            rebuildPerformedExercise()
                        }
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
                        Text(" \(Int(timeBeforeNext))s")
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
                .disabled(isTimerRunning)

                if showingTimeBeforeNextPicker {
                    Picker("time_before_next".localized(comment: "Time before next exercise"), selection: $timeBeforeNext) {
                        ForEach(Array(stride(from: 5.0, through: 300.0, by: 5.0)), id: \.self) { duration in
                            Text("x_seconds".localized(with: Int(duration), comment: "x seconds")).tag(duration)
                        }
                    }
                    .pickerStyle(.wheel)
                    .disabled(isTimerRunning)
                    .onChange(of: timeBeforeNext) { _, _ in
                        rebuildPerformedExercise()
                    }
                }

                ProgressBarView(exercise: performedExercise, isLastExercise: false)
                    .id(performedExercise.id)
            }
            .navigationTitle("timer".localized(comment: "Timer"))
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsSheet()
            }
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
                        if isTimeBased {
                            Button(action: {
                                withAnimation {
                                    isTimeBased.toggle()
                                }
                                practiceExercise.isTimeBased = isTimeBased
                                rebuildPerformedExercise()
                            }) {
                                Label("time_based_exercise".localized(comment: "Time-based exercise"), systemImage: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted")
                            }
                            .buttonStyle(.glassProminent)
                            .disabled(isTimerRunning)
                        } else {
                            Button(action: {
                                withAnimation {
                                    isTimeBased.toggle()
                                }
                                practiceExercise.isTimeBased = isTimeBased
                                rebuildPerformedExercise()
                            }) {
                                Label("time_based_exercise".localized(comment: "Time-based exercise"), systemImage: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted")
                            }
                            .glassEffect()
                            .padding([.leading, .trailing], -4)
                            .disabled(isTimerRunning)
                        }
                    } else {
                        Toggle(isOn: Binding(
                            get: { isTimeBased },
                            set: { newValue in
                                withAnimation {
                                    isTimeBased = newValue
                                }
                                practiceExercise.isTimeBased = newValue
                                rebuildPerformedExercise()
                            }
                        )) {
                            Label("time_based_exercise".localized(comment: "Time-based exercise"), systemImage: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted")
                        }
                        .disabled(isTimerRunning)
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func rebuildPerformedExercise() {
        practiceWorkoutExercise.targetSets = totalSets
        practiceWorkoutExercise.targetReps = Int(duration)
        practiceWorkoutExercise.restSeconds = Int(restDuration)
        practiceWorkoutExercise.timeBeforeNext = Int(timeBeforeNext)

        let performed = PerformedExercise(from: practiceWorkoutExercise, orderIndex: 0)
        performed.sourceExercise = practiceWorkoutExercise
        performedExercise = performed
    }
}
