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
    var desc: String
    var creationDate: Double

    @Relationship(deleteRule: .cascade) var exercises: [Exercise]

    init(name: String, description: String, exercises: [Exercise] = []) {
        self.id = UUID()
        self.name = name
        self.desc = description
        self.creationDate = Date().timeIntervalSince1970
        self.exercises = exercises
    }
}
