//
//  Program.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation

class Program {
    let id: UUID
    var name: String
    var description: String
    var duration: TimeInterval
    var weeks: [Week]

    init(name: String, description: String, duration: TimeInterval, weeks: [Week]) {
        self.id = UUID() // Generate a unique identifier
        self.name = name
        self.description = description
        self.duration = duration
        self.weeks = weeks
    }
}
