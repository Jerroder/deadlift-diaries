//
//  ExerciseHistory.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-01-24.
//

import Foundation
import SwiftData

@Model
final class ExerciseHistory: Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var weight: Double?
    var reps: Int?
    var sets: Int = 0
    var duration: Double?
    var distance: Int?
    
    var template: ExerciseTemplate?
    
    init(date: Date = Date(), weight: Double? = nil, reps: Int? = nil, sets: Int = 0, duration: Double? = nil, distance: Int? = nil) {
        self.id = UUID()
        self.date = date
        self.weight = weight
        self.reps = reps
        self.sets = sets
        self.duration = duration
        self.distance = distance
    }
    
    enum CodingKeys: CodingKey {
        case id, date, weight, reps, sets, duration, distance, templateID
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(weight, forKey: .weight)
        try container.encode(reps, forKey: .reps)
        try container.encode(sets, forKey: .sets)
        try container.encode(duration, forKey: .duration)
        try container.encode(distance, forKey: .distance)
        try container.encodeIfPresent(template?.id, forKey: .templateID)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        self.reps = try container.decodeIfPresent(Int.self, forKey: .reps)
        self.sets = try container.decode(Int.self, forKey: .sets)
        self.duration = try container.decodeIfPresent(Double.self, forKey: .duration)
        self.distance = try container.decodeIfPresent(Int.self, forKey: .distance)
    }
}

extension ExerciseHistory: Identifiable {}
