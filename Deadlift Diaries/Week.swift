//
//  Week.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-26.
//


class Week {
    var weekNumber: Int
    var workouts: [Workout]

    init(weekNumber: Int, workouts: [Workout]) {
        self.weekNumber = weekNumber
        self.workouts = workouts
    }
}
