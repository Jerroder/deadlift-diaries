//
//  SoundPickerSheet.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-09-29.
//

import AudioToolbox
import SwiftUI

struct SoundPickerSheet: View {
    @Binding var isPresented: Bool
    let mesocycles: [Mesocycle]?
    
    @State private var showingShareSheet = false
    
    @AppStorage("selectedSoundID") private var selectedSoundID: Int = 1075
    
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
                
                if let mesocycles = mesocycles, !mesocycles.isEmpty {
                    Section {
                        Button("Export app data") {
                            saveAndShareJSON(mesocycles)
                            showingShareSheet = true
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingShareSheet) {
                ActivityViewController(activityItems: [FileManager.default.temporaryDirectory.appendingPathComponent("deadliftdiaries_export.json")], applicationActivities: nil)
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
