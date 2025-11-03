//
//  SoundPickerSheet.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-09-29.
//

import AudioToolbox
import SwiftUI

struct SettingsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    let mesocycles: [Mesocycle]?
    
    @State private var showingShareSheet = false
    @State private var isShowingDocumentPicker = false
    
    @AppStorage("isICouldEnabled") private var isICouldEnabled = false
    @AppStorage("selectedSoundID") private var selectedSoundID: Int = 1075
    @AppStorage("sendNotification") private var sendNotification: Bool = false
    @AppStorage("isContinuousModeEnabled") private var isContinuousModeEnabled: Bool = false
    @AppStorage("autoResetTimer") private var autoResetTimer: Bool = false
    
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
                    Toggle("do_not_stop_timer".localized(comment: "Do not stop timer between sets and rest"), isOn: $isContinuousModeEnabled)
                        .padding([.leading, .trailing])
                    Toggle("automatically_reset_timer".localized(comment: "Automatically reset timer at the end of an exercise"), isOn: $autoResetTimer)
                        .padding([.leading, .trailing])
                    Toggle("send_notification".localized(comment: "When the app is in the background, send a notification when the timer ends"), isOn: $sendNotification)
                        .padding([.leading, .trailing])
                }
                
                Section {
                    if let mesocycles = mesocycles, !mesocycles.isEmpty {
                        Button("export".localized(comment: "Export")) {
                            saveAndShareJSON(mesocycles)
                            showingShareSheet = true
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    if mesocycles != nil {
                        Button("import".localized(comment: "Import")) {
                            isShowingDocumentPicker = true
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
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
                DocumentPicker { mesocycles in
                    for mesocycle in mesocycles {
                        modelContext.insert(mesocycle)
                    }
                    try? modelContext.save()
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
                        isPresented = false
                    }
                }
            }
        }
    }
}
