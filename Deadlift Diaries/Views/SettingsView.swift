//
//  SoundPickerSheet.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-09-29.
//

import AudioToolbox
import SwiftUI
import SwiftData

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingShareSheet: Bool = false
    @State private var isShowingDocumentPicker: Bool = false
    
    @Query private var trainingBlocks: [TrainingBlock]
    @Query private var workoutTemplates: [WorkoutTemplate]
    @Query private var workoutExercises: [WorkoutExercise]
    @Query private var workoutSchedules: [WorkoutSchedule]
    @Query private var scheduledWorkouts: [ScheduledWorkout]
    @Query private var exercises: [Exercise]
    @Query private var workoutSessions: [WorkoutSession]
    @Query private var performedExercises: [PerformedExercise]
    @Query private var performedSets: [PerformedSet]
    
    @AppStorage("isICouldEnabled") private var isICouldEnabled: Bool = false
    @AppStorage("selectedSoundID") private var selectedSoundID: Int = 1075
    @AppStorage("sendNotification") private var sendNotification: Bool = false
    @AppStorage("autoStartSetAfterRest") private var autoStartSetAfterRest: Bool = false
    @AppStorage("autoStartRestAfterSet") private var autoStartRestAfterSet: Bool = false
    @AppStorage("autoResetTimer") private var autoResetTimer: Bool = false
    
    private var hasDataToExport: Bool {
        !trainingBlocks.isEmpty
            || !workoutTemplates.isEmpty
            || !workoutExercises.isEmpty
            || !workoutSchedules.isEmpty
            || !scheduledWorkouts.isEmpty
            || !exercises.isEmpty
            || !workoutSessions.isEmpty
            || !performedExercises.isEmpty
            || !performedSets.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                HStack {
                    Text("sound".localized(comment: "Sound"))
                    Picker("sound".localized(comment: "Sound"), selection: $selectedSoundID) {
                        ForEach(SoundOptions.all, id: \.id) { option in
                            Text(option.name).tag(Int(option.id))
                        }
                    }
                    .pickerStyle(.wheel)
                    .onChange(of: selectedSoundID) { _, _ in
                        if selectedSoundID != 0 {
                            AudioServicesPlaySystemSound(UInt32(selectedSoundID))
                        }
                    }
                }
                
                Section {
                    Toggle("enable_icloud_backup".localized(comment: "Enable iCloud backup"), isOn: $isICouldEnabled)
                        .padding([.leading, .trailing])
                }
                
                Section {
                    Toggle("auto_start_set_after_rest".localized(comment: "Automatically start the next set after rest ends"), isOn: $autoStartSetAfterRest)
                        .padding([.leading, .trailing])
                    Toggle("auto_start_rest_after_set".localized(comment: "Automatically start rest after a set ends"), isOn: $autoStartRestAfterSet)
                        .padding([.leading, .trailing])
                    Toggle("automatically_reset_timer".localized(comment: "Automatically reset timer at the end of an exercise"), isOn: $autoResetTimer)
                        .padding([.leading, .trailing])
                    Toggle("send_notification".localized(comment: "When the app is in the background, send a notification when the timer ends"), isOn: $sendNotification)
                        .padding([.leading, .trailing])
                }
                
                Section {
                    if hasDataToExport {
                        Button("export".localized(comment: "Export")) {
                            saveAndShareJSON(
                                trainingBlocks: trainingBlocks,
                                workoutTemplates: workoutTemplates,
                                workoutExercises: workoutExercises,
                                workoutSchedules: workoutSchedules,
                                scheduledWorkouts: scheduledWorkouts,
                                exercises: exercises,
                                workoutSessions: workoutSessions,
                                performedExercises: performedExercises,
                                performedSets: performedSets
                            )
                            showingShareSheet = true
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    Button("import".localized(comment: "Import")) {
                        isShowingDocumentPicker = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .alignmentGuide(.listRowSeparatorLeading) { g in
                    g[.leading]
                }
            }
            .navigationTitle("settings".localized(comment: "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingShareSheet) {
                ActivityViewController(activityItems: [FileManager.default.temporaryDirectory.appendingPathComponent("deadliftdiaries.json")], applicationActivities: nil)
            }
            .sheet(isPresented: $isShowingDocumentPicker) {
                DocumentPicker { exportData in
                    importExportData(exportData, into: modelContext)
                }
            }
            .onChange(of: sendNotification) {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                    if granted {
                        print("Notification permission granted.")
                    } else if let error = error {
                        print("Notification permission error: \(error.localizedDescription)")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        dismiss()
                    }
                }
            }
        }
    }
}
