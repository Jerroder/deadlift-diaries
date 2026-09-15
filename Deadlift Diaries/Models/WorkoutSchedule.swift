//
//  WorkoutSchedule.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-15.
//

/* Workout "push A"
 Every Monday
 From Sept 21 -> Nov 30 */

import Foundation
import SwiftData

@Model
final class WorkoutSchedule {
    @Attribute(.unique)
    var id: UUID
    
    var startDate: Date
    var endDate: Date?
    
    var weekday: Int
    
    var workoutTemplate: WorkoutTemplate?
    
    init(
        startDate: Date,
        endDate: Date? = nil,
        weekday: Int,
        workoutTemplate: WorkoutTemplate
    ) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.weekday = weekday
        self.workoutTemplate = workoutTemplate
    }
}
