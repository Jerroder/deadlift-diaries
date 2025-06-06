//
//  Week.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation

class Week: Identifiable, ObservableObject {
    let id = UUID()
    var weekNumber: Int
    @Published var workouts: [Workout]

    init(weekNumber: Int, workouts: [Workout]) {
        self.weekNumber = weekNumber
        self.workouts = workouts
    }
}
