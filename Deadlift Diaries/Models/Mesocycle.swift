//
//  Mesocycle.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation
import SwiftData

@Model
final class Mesocycle: Encodable {
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
    
    enum CodingKeys: CodingKey {
        case id, name, startDate, numberOfWeeks, orderIndex, weeks
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(numberOfWeeks, forKey: .numberOfWeeks)
        try container.encode(orderIndex, forKey: .orderIndex)
        try container.encode(weeks, forKey: .weeks)
    }
}
