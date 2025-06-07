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
    var desc: String
    var duration: Double
    var sets: Int
    var reps: Int

    init(name: String, description: String, duration: Double, sets: Int, reps: Int) {
        self.id = UUID()
        self.name = name
        self.desc = description
        self.duration = duration
        self.sets = sets
        self.reps = reps
    }
}
