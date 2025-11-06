//
//  Exercise.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation
import SwiftData

@Model
final class Exercise: Codable  {
    var id: UUID = UUID()
    
    var name: String = ""
    var weight: Double?
    var sets: Int = 5
    var reps: Int?
    var duration: Double?
    var restTime: Double = 30.0
    var isTimeBased: Bool = false
    var orderIndex: Int = 0
    var workout: Workout?
    var elapsed: Double = 0.0
    var currentSet: Int = 1
    var timeBeforeNext: Double = 120.0
    var supersetPartnerID: UUID?
    var isTheSuperset: Bool?
    
    init(name: String, weight: Double? = nil, sets: Int, reps: Int? = nil, duration: Double? = 30.0, restTime: Double, isTimeBased: Bool, orderIndex: Int, timeBeforeNext: Double, supersetPartnerID: UUID? = nil, isTheSuperset: Bool? = false) {
        self.id = UUID()
        self.name = name
        self.weight = weight
        self.sets = sets
        self.reps = reps
        self.duration = duration
        self.restTime = restTime
        self.isTimeBased = isTimeBased
        self.orderIndex = orderIndex
        self.elapsed = 0.0
        self.currentSet = 1
        self.timeBeforeNext = timeBeforeNext
        self.supersetPartnerID = supersetPartnerID
        self.isTheSuperset = isTheSuperset
    }
    
    enum CodingKeys: CodingKey {
        case id, name, weight, sets, reps, duration, restTime, isTimeBased, orderIndex, elapsed, currentSet, timeBeforeNext, supersetPartnerID
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(weight, forKey: .weight)
        try container.encode(sets, forKey: .sets)
        try container.encode(reps, forKey: .reps)
        try container.encode(duration, forKey: .duration)
        try container.encode(restTime, forKey: .restTime)
        try container.encode(isTimeBased, forKey: .isTimeBased)
        try container.encode(orderIndex, forKey: .orderIndex)
        try container.encode(elapsed, forKey: .elapsed)
        try container.encode(currentSet, forKey: .currentSet)
        try container.encode(timeBeforeNext, forKey: .timeBeforeNext)
        try container.encode(supersetPartnerID, forKey: .supersetPartnerID)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        self.sets = try container.decode(Int.self, forKey: .sets)
        self.reps = try container.decodeIfPresent(Int.self, forKey: .reps)
        self.duration = try container.decodeIfPresent(Double.self, forKey: .duration)
        self.restTime = try container.decode(Double.self, forKey: .restTime)
        self.isTimeBased = try container.decode(Bool.self, forKey: .isTimeBased)
        self.orderIndex = try container.decode(Int.self, forKey: .orderIndex)
        self.elapsed = try container.decode(Double.self, forKey: .elapsed)
        self.currentSet = try container.decode(Int.self, forKey: .currentSet)
        self.timeBeforeNext = try container.decode(Double.self, forKey: .timeBeforeNext)
        self.supersetPartnerID = try container.decode(UUID.self, forKey: .supersetPartnerID)
    }
}
