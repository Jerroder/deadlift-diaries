//
//  Exercise.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//


class Exercise {
    var name: String
    var description: String
    var duration: Double
    var sets: Int
    var reps: Int

    init(name: String, description: String, duration: Double, sets: Int, reps: Int) {
        self.name = name
        self.description = description
        self.duration = duration
        self.sets = sets
        self.reps = reps
    }
}
