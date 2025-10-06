//
//  Workout.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation
import SwiftData

@Model
final class Workout: Codable {
    @Attribute(.unique) var id: UUID
    
    var name: String
    var week: Week?
    var orderIndex: Int
    var date: Date
    
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]
    
    init(name: String, orderIndex: Int, date: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.exercises = []
        self.orderIndex = orderIndex
        self.date = date
    }
    
    enum CodingKeys: CodingKey {
        case id, name, orderIndex, date, exercises
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(orderIndex, forKey: .orderIndex)
        try container.encode(date, forKey: .date)
        try container.encode(exercises, forKey: .exercises)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.orderIndex = try container.decode(Int.self, forKey: .orderIndex)
        self.date = try container.decode(Date.self, forKey: .date)
        self.exercises = try container.decode([Exercise].self, forKey: .exercises)
    }
}
