//
//  SoundPickerSheet.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-09-29.
//

import AudioToolbox
import SwiftUI

struct SoundPickerSheet: View {
    @Binding var selectedSoundID: Int
    @Binding var isPresented: Bool
    
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
                        AudioServicesPlaySystemSound(UInt32(selectedSoundID))
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
