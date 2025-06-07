//
//  Week.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation
import SwiftData

@Model
class Week {
    var id: UUID
    var weekNumber: Int
    var workouts: [Workout]

    init(weekNumber: Int, workouts: [Workout]) {
        self.id = UUID()
        self.weekNumber = weekNumber
        self.workouts = workouts
    }
}
