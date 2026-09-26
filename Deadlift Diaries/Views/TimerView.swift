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
    @AppStorage("duration") private var duration: Int = 30
    @AppStorage("restDuration") private var restDuration: Int = 60
    @AppStorage("timeBeforeNext") private var timeBeforeNext: Int = 120

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
        let duration = UserDefaults.standard.object(forKey: "duration") as? Int ?? 30
        let restDuration = UserDefaults.standard.object(forKey: "restDuration") as? Int ?? 60
        let timeBeforeNext = UserDefaults.standard.object(forKey: "timeBeforeNext") as? Int ?? 120

        let exercise = Exercise(name: "timer".localized(comment: "Timer"), isTimeBased: isTimeBased)
        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            order: 0,
            targetSets: totalSets,
            targetReps: duration,
            restSeconds: restDuration,
            timeBeforeNext: timeBeforeNext
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
                                Text("  \(formattedSeconds(restDuration))")
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
                    .onChange(of: isTimerRunning)  { _, newValue in
                        if newValue {
                            withAnimation {
                                showingRestPicker = false
                            }
                        }
                    }

                    if #available(iOS 26.0, *) {
                        Grid(horizontalSpacing: 6, verticalSpacing: 8) {
                            GridRow {
                                Button("00:30") { restDuration = 30 }
                                    .disabled(isTimerRunning)
                                Button("01:00") { restDuration = 60 }
                                    .disabled(isTimerRunning)
                            }
                            GridRow {
                                Button("01:30") { restDuration = 90 }
                                    .disabled(isTimerRunning)
                                Button("02:00") { restDuration = 120 }
                                    .disabled(isTimerRunning)
                            }
                        }
                        .buttonStyle(.glass)
                    } else {
                        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                            GridRow {
                                Button("00:30") { restDuration = 30 }
                                    .disabled(isTimerRunning)
                                Button("01:00") { restDuration = 60 }
                                    .disabled(isTimerRunning)
                            }
                            GridRow {
                                Button("01:30") { restDuration = 90 }
                                    .disabled(isTimerRunning)
                                Button("02:00") { restDuration = 120 }
                                    .disabled(isTimerRunning)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if showingRestPicker {
                    DurationWheelPicker(totalSeconds: $restDuration)
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
                            Text(" \(formattedSeconds(duration))")
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
                    .onChange(of: isTimerRunning) { _, newValue in
                        if newValue {
                            withAnimation {
                                showingDurationPicker = false
                            }
                        }
                    }

                    if showingDurationPicker {
                        DurationWheelPicker(totalSeconds: $duration)
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
                        Text(" \(formattedSeconds(timeBeforeNext))")
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
                .onChange(of: isTimerRunning) { _, newValue in
                    if newValue {
                        withAnimation {
                            showingTimeBeforeNextPicker = false
                        }
                    }
                }

                if showingTimeBeforeNextPicker {
                    DurationWheelPicker(totalSeconds: $timeBeforeNext)
                        .disabled(isTimerRunning)
                        .onChange(of: timeBeforeNext) { _, newValue in
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
        practiceWorkoutExercise.targetReps = duration
        practiceWorkoutExercise.restSeconds = restDuration
        practiceWorkoutExercise.timeBeforeNext = timeBeforeNext

        let performed = PerformedExercise(from: practiceWorkoutExercise, orderIndex: 0)
        performed.sourceExercise = practiceWorkoutExercise
        performedExercise = performed
    }
}
