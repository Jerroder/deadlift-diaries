//
//  Week.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation
import SwiftData

@Model
final class Week: Encodable {
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
}

extension Week: Identifiable {} // Apparently needed because otherwise "Set<Week.ID>()" throws an error
