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
    var weight: Int
    var sets: Int
    var reps: Int
    var rest: Int
    var creationDate: Double

    init(name: String = "", weight: Int = 0, sets: Int = 0, reps: Int = 0, rest: Int = 0) {
        self.id = UUID()
        self.name = name
        self.weight = weight
        self.sets = sets
        self.reps = reps
        self.rest = rest
        self.creationDate = Date().timeIntervalSince1970
    }
}
