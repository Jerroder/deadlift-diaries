//
//  ContentView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            ProgramView().tabItem {
                Image(systemName: "calendar")
                Text("Programs")
            }

            TimerView().tabItem {
                Image(systemName: "timer")
                Text("Timer")
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ProgramList.self, configurations: config)
    ContentView()
        .modelContainer(container)
}
