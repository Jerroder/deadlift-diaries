//
//  Program.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation
import SwiftData

@Model
final class Program {
    @Attribute(.unique) var id: UUID

    var name: String
    var desc: String
    var duration: TimeInterval?
    var orderIndex: Int

    @Relationship(deleteRule: .cascade) var weeks: [Week]

    init(name: String, description: String, duration: TimeInterval? = nil, weeks: [Week], orderIndex: Int = Int.max) {
        self.id = UUID()
        self.name = name
        self.desc = description
        self.duration = duration
        self.weeks = weeks
        self.orderIndex = orderIndex
    }
}

@Model
final class ProgramList {
    var programs: [Program]

    init(programs: [Program] = []) {
        self.programs = programs
    }
}
