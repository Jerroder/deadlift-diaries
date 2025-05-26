//
//  Workout.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//


class Workout {
    var name: String
    var description: String
    var duration: Double
    var exercises: [Exercise]

    init(name: String, description: String, duration: Double, exercises: [Exercise]) {
        self.name = name
        self.description = description
        self.duration = duration
        self.exercises = exercises
    }
}
