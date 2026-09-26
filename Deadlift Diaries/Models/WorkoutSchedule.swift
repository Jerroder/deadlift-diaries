//
//  WorkoutSchedule.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-14.
//

/* Workout "push A"
 Every Monday
 From Sept 21 -> Nov 30 */

import Foundation
import SwiftData

@Model
final class WorkoutSchedule {
    var id: UUID = UUID()

    var startDate: Date = Date()
    var endDate: Date?

    var weekday: Int = 0

    var workoutTemplate: WorkoutTemplate?

    init(startDate: Date, endDate: Date? = nil, weekday: Int, workoutTemplate: WorkoutTemplate) {
        self.startDate = startDate
        self.endDate = endDate
        self.weekday = weekday
        self.workoutTemplate = workoutTemplate
    }
}
