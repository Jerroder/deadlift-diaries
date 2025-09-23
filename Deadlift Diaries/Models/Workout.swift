//
//  Workout.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation
import SwiftData

@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    
    var name: String
    var week: Week?
    var orderIndex: Int
    
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]
    
    init(name: String, orderIndex: Int) {
        self.id = UUID()
        self.name = name
        self.exercises = []
        self.orderIndex = orderIndex
    }
}
