//
//  ContentView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-24.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MesocycleView().tabItem {
                Image(systemName: "calendar")
                Text("cycles".localized(comment: "Cycles"))
            }

            TimerView().tabItem {
                Image(systemName: "timer")
                Text("timer".localized(comment: "Timer"))
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Mesocycle.self, configurations: config)
    ContentView()
        .modelContainer(container)
}
