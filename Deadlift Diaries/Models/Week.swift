//
//  Week.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation
import SwiftData

@Model
final class Week: Codable {
    var id: UUID = UUID()
    
    var number: Int = 1
    var startDate: Date = Date()
    var mesocycle: Mesocycle?
    
    @Relationship(deleteRule: .cascade) var workouts: [Workout]?
    
    init(number: Int, startDate: Date) {
        self.id = UUID()
        self.number = number
        self.startDate = startDate
        self.workouts = []
    }
    
    enum CodingKeys: CodingKey {
        case id, number, startDate, workouts
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(number, forKey: .number)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(workouts, forKey: .workouts)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.number = try container.decode(Int.self, forKey: .number)
        self.startDate = try container.decode(Date.self, forKey: .startDate)
        self.workouts = try container.decode([Workout].self, forKey: .workouts)
    }
}

extension Week: Identifiable {} // Apparently needed because otherwise "Set<Week.ID>()" throws an error
