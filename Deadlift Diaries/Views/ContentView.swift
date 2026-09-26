//
//  ContentView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-24.
//

import SwiftData
import SwiftUI
import UserNotifications

enum FocusableField: Hashable {
    case mesocycleName, workoutName, exerciseName, exerciseWeight, supersetName, supersetWeight
    case notes
    case searchField
}

struct ContentView: View {
    var body: some View {
        TabView {
            CalendarView().tabItem {
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
