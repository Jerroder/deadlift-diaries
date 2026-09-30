//
//  TrainingBlock.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-13.
//

/* Metadata to group workouts and exercise inside a propgram */

import Foundation
import SwiftData
import SwiftUI

@Model
final class TrainingBlock {
    // Matches the app's AccentColor, so existing programs (created before
    // colors existed) keep looking the way they always have.
    static let defaultColorHex = "#5DA79B"

    var id: UUID = UUID()

    var name: String = ""
    var startDate: Date = Date()
    var endDate: Date?

    var orderIndex: Int = 0

    var notes: String = ""

    var colorHex: String = TrainingBlock.defaultColorHex

    @Relationship(inverse: \WorkoutTemplate.trainingBlock)
    var workoutTemplates: [WorkoutTemplate]? = []

    var color: Color {
        Color(hex: colorHex)
    }

    init(
        name: String,
        startDate: Date,
        endDate: Date? = nil,
        orderIndex: Int = 0,
        notes: String = "",
        colorHex: String = TrainingBlock.defaultColorHex
    ) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.orderIndex = orderIndex
        self.notes = notes
        self.colorHex = colorHex
    }
}
