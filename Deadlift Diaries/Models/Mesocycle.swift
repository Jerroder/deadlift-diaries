//
//  Mesocycle.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation
import SwiftData

@Model
final class Mesocycle: Codable {
    var id: UUID = UUID()
    
    var name: String = ""
    var startDate: Date = Date()
    var numberOfWeeks: Int = 4
    var orderIndex: Int = 0
    @Relationship(deleteRule: .cascade) var weeks: [Week]?
    @Relationship(deleteRule: .cascade, inverse: \ExerciseTemplate.mesocycle) var templates: [ExerciseTemplate]?
    
    init(name: String, startDate: Date, numberOfWeeks: Int, orderIndex: Int) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.numberOfWeeks = numberOfWeeks
        self.orderIndex = orderIndex
        self.weeks = (0..<numberOfWeeks).map { Week(number: $0 + 1, startDate: Calendar.current.date(byAdding: .day, value: $0 * 7, to: startDate)!) }
    }
    
    enum CodingKeys: CodingKey {
        case id, name, startDate, numberOfWeeks, orderIndex, weeks, templates
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(numberOfWeeks, forKey: .numberOfWeeks)
        try container.encode(orderIndex, forKey: .orderIndex)
        try container.encode(weeks, forKey: .weeks)
        try container.encode(templates, forKey: .templates)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.startDate = try container.decode(Date.self, forKey: .startDate)
        self.numberOfWeeks = try container.decode(Int.self, forKey: .numberOfWeeks)
        self.orderIndex = try container.decode(Int.self, forKey: .orderIndex)
        self.weeks = try container.decode([Week].self, forKey: .weeks)
        self.templates = try container.decodeIfPresent([ExerciseTemplate].self, forKey: .templates)
    }
}
