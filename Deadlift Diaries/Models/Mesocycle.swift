//
//  Mesocycle.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation
import SwiftData

@Model
final class Mesocycle {
    @Attribute(.unique) var id: UUID
    
    var name: String
    var startDate: Date
    var numberOfWeeks: Int
    var orderIndex: Int
    @Relationship(deleteRule: .cascade) var weeks: [Week]
    
    init(name: String, startDate: Date, numberOfWeeks: Int, orderIndex: Int) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.numberOfWeeks = numberOfWeeks
        self.orderIndex = orderIndex
        self.weeks = (0..<numberOfWeeks).map { Week(number: $0 + 1, startDate: Calendar.current.date(byAdding: .day, value: $0 * 7, to: startDate)!) }
    }
}
