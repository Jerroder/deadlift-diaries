//
//  ContentView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

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
    ContentView()
}
