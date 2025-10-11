//
//  TimerView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI

struct TimerView: View {
    @AppStorage("totalSets") private var totalSets: Int = 5
    @AppStorage("currentSet") private var currentSet: Int = 1
    @AppStorage("isTimeBased") private var isTimeBased: Bool = false
    @AppStorage("duration") private var duration: Double = 30.0
    @AppStorage("restDuration") private var restDuration: Double = 60.0
    @AppStorage("timeBeforeNext") private var timeBeforeNext: Double = 120.0
    @AppStorage("elapsed") private var elapsed: Double = 0.0
    
    @State private var isTimerRunning: Bool = false
    @State private var showingSoundPickerSheet: Bool = false
    @State private var showingRestPicker: Bool = false
    @State private var showingDurationPicker: Bool = false
    @State private var showingTimeBeforeNextPicker: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Stepper("total_sets_x".localized(with: totalSets, comment: "Total Sets: x"), value: $totalSets, in: 1...20)
                    .onChange(of: totalSets) { oldValue, newValue in
                        if currentSet > newValue {
                            currentSet = newValue
                        }
                    }
                
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
                    Picker("rest_duration".localized(comment:"Rest duration"), selection: $restDuration) {
                        ForEach(Array(stride(from: 5.0, through: 300.0, by: 5.0)), id: \.self) { duration in
                            Text("\(Int(duration)) seconds".localized(comment: "(xxx) seconds")).tag(duration)
                        }
                    }
                    .pickerStyle(.wheel)
                    .disabled(isTimerRunning)
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
                            Text("exercise_duration".localized(comment:"Exercise duration"))
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
                        Picker("exercise_duration".localized(comment:"Exercise duration"), selection: $duration) {
                            ForEach(Array(stride(from: 5.0, through: 300.0, by: 5.0)), id: \.self) { duration in
                                Text("\(Int(duration)) seconds".localized(comment: "(xxx) seconds")).tag(duration)
                            }
                        }
                        .pickerStyle(.wheel)
                        .disabled(isTimerRunning)
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
                        Text("time_before_next".localized(comment:"Time before next exercise"))
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
                    Picker("time_before_next".localized(comment:"Time before next exercise"), selection: $timeBeforeNext) {
                        ForEach(Array(stride(from: 5.0, through: 300.0, by: 5.0)), id: \.self) { duration in
                            Text("\(Int(duration)) seconds".localized(comment: "(xxx) seconds")).tag(duration)
                        }
                    }
                    .pickerStyle(.wheel)
                    .disabled(isTimerRunning)
                }
                
                ProgressBarView(
                    totalSets: totalSets,
                    currentSet: $currentSet,
                    restDuration: restDuration,
                    timeBeforeNextExercise: timeBeforeNext,
                    isTimerRunning: $isTimerRunning,
                    elapsed: $elapsed,
                    isTimeBased: isTimeBased,
                    duration: duration
                )
            }
            .navigationTitle("timer".localized(comment: "Timer"))
            .sheet(isPresented: $showingSoundPickerSheet) {
                SettingsSheet(
                    isPresented: $showingSoundPickerSheet,
                    mesocycles: nil
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(action: {
                            showingSoundPickerSheet = true
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
                            }) {
                                Label("time_based_exercise".localized(comment: "Time-based exercise"), systemImage: "gauge.with.needle")
                            }
                            .buttonStyle(.glassProminent)
                        } else {
                            Button(action: {
                                withAnimation {
                                    isTimeBased.toggle()
                                }
                            }) {
                                Label("time_based_exercise".localized(comment: "Time-based exercise"), systemImage: "gauge.with.needle")
                            }
                            .glassEffect()
                            .padding([.leading, .trailing], -4)
                        }
                    } else {
                        Toggle(isOn: Binding(
                            get: { isTimeBased },
                            set: { newValue in
                                withAnimation {
                                    isTimeBased = newValue
                                }
                            }
                        )) {
                            Label("time_based_exercise".localized(comment: "Time-based exercise"), systemImage: "gauge.with.needle")
                        }
                    }
                }
            }
        }
    }
}
