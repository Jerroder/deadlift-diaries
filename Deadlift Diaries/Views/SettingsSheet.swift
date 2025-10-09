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
    @AppStorage("isContinuousModeEnabled") private var isContinuousModeEnabled: Bool = true
    @AppStorage("autoResetTimer") private var autoResetTimer: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                HStack {
                    Text("Sound")
                    Picker("Sound", selection: $selectedSoundID) {
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
                    Toggle("Enable iCloud Sync", isOn: $isICouldEnabled)
                        .padding([.leading, .trailing])
                }
                
                Section {
                    Toggle("Stop timer between sets and rest", isOn: $isContinuousModeEnabled)
                        .padding([.leading, .trailing])
                    Toggle("Automatically reset timer at the end of an exercise", isOn: $autoResetTimer)
                        .padding([.leading, .trailing])
                }
                
                Section {
                    if let mesocycles = mesocycles, !mesocycles.isEmpty {
                        Button("Export") {
                            saveAndShareJSON(mesocycles)
                            showingShareSheet = true
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    if mesocycles != nil {
                        Button("Import") {
                            isShowingDocumentPicker = true
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .alignmentGuide(.listRowSeparatorLeading) { g in
                    g[.leading]
                }
            }
            .navigationTitle("Settings")
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
