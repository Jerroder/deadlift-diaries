//
//  Week.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation
import SwiftData

@Model
final class Week {
    @Attribute(.unique) var id: UUID
    
    var number: Int
    var startDate: Date
    var mesocycle: Mesocycle?
    
    @Relationship(deleteRule: .cascade) var workouts: [Workout]
    
    init(number: Int, startDate: Date) {
        self.id = UUID()
        self.number = number
        self.startDate = startDate
        self.workouts = []
    }
}
