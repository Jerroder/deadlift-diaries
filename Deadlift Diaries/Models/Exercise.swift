//
//  Exercise.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation
import SwiftData

@Model
final class Exercise  {
    @Attribute(.unique) var id: UUID
    
    var name: String
    var weight: Double?
    var sets: Int
    var reps: Int?
    var duration: Int?
    var restTime: Double
    var isTimeBased: Bool
    var orderIndex: Int
    var workout: Workout?
    var elapsed: Double
    
    init(name: String, weight: Double? = nil, sets: Int, reps: Int? = nil, duration: Int? = nil, restTime: Double, isTimeBased: Bool, orderIndex: Int) {
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
    }
}
