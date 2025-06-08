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
    var sets: Int
    var reps: Int
    var creationDate: Double

    init(name: String, description: String, sets: Int = 0, reps: Int = 0) {
        self.id = UUID()
        self.name = name
        self.desc = description
        self.sets = sets
        self.reps = reps
        self.creationDate = Date().timeIntervalSince1970
    }
}
