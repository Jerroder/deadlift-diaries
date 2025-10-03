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
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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
