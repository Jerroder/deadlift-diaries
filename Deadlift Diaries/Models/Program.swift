//
//  Program.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation

class Program: Identifiable, ObservableObject {
    let id = UUID()
    var name: String
    var description: String
    var duration: TimeInterval?
    @Published var weeks: [Week]

    init(name: String, description: String, duration: TimeInterval? = nil, weeks: [Week]) {
        self.name = name
        self.description = description
        self.duration = duration
        self.weeks = weeks
    }
}
