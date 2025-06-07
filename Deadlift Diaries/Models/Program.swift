//
//  Program.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation
import SwiftData

@Model
class Program {
    var id: UUID
    var name: String
    var desc: String
    var duration: TimeInterval?
    var weeks: [Week]

    init(name: String, description: String, duration: TimeInterval? = nil, weeks: [Week]) {
        self.id = UUID()
        self.name = name
        self.desc = description
        self.duration = duration
        self.weeks = weeks
    }
}
