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

    var weekNumber: Int
    var creationDate: Double

    @Relationship(deleteRule: .cascade) var workouts: [Workout]

    init(weekNumber: Int, workouts: [Workout]) {
        self.id = UUID()
        self.weekNumber = weekNumber
        self.creationDate = Date().timeIntervalSince1970
        self.workouts = workouts
    }
}
