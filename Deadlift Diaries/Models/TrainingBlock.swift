//
//  TrainingBlock.swift
//  Deadlift Diaries
//

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
