//
//  Exercise.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation
import SwiftData

@Model
final class Exercise: Encodable  {
    @Attribute(.unique) var id: UUID
    
    var name: String
    var weight: Double?
    var sets: Int
    var reps: Int?
    var duration: Double?
    var restTime: Double
    var isTimeBased: Bool
    var orderIndex: Int
    var workout: Workout?
    var elapsed: Double
    var currentSet: Int
    var timeBeforeNext: Double
    
    init(name: String, weight: Double? = nil, sets: Int, reps: Int? = nil, duration: Double? = 30.0, restTime: Double, isTimeBased: Bool, orderIndex: Int, timeBeforeNext: Double) {
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
    }
    
    enum CodingKeys: CodingKey {
        case id, name, weight, sets, reps, duration, restTime, isTimeBased, orderIndex, elapsed, currentSet, timeBeforeNext
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
    }
}
