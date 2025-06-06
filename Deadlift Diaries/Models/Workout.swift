//
//  Workout.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//

import Foundation

class Workout: Identifiable, ObservableObject {
    let id = UUID()
    var name: String
    var description: String
    @Published var exercises: [Exercise]

    init(name: String, description: String, exercises: [Exercise]) {
        self.name = name
        self.description = description
        self.exercises = exercises
    }
}
