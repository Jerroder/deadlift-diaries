//
//  TrainingBlock.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-13.
//

/* Metadata to group workouts and exercise inside a propgram */

import Foundation
import SwiftData

@Model
final class TrainingBlock {
    var id: UUID = UUID()

    var name: String = ""
    var startDate: Date = Date()
    var endDate: Date?

    var orderIndex: Int = 0

    var notes: String = ""

    @Relationship(inverse: \WorkoutTemplate.trainingBlock)
    var workoutTemplates: [WorkoutTemplate]? = []

    init(
        name: String,
        startDate: Date,
        endDate: Date? = nil,
        orderIndex: Int = 0,
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.orderIndex = orderIndex
        self.notes = notes
    }
}
