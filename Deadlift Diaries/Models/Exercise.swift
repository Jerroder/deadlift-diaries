//
//  Exercise.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-09-25.
//

/* "Bench Press" is an Exercise. Nothing more. */

import SwiftData
import SwiftUI

@Model
final class Exercise {
    var id: UUID = UUID()

    var name: String = ""
    var isTimeBased: Bool = false
    var isDistanceBased: Bool = false

    var notes: String = ""

    @Relationship(inverse: \WorkoutExercise.exercise)
    var workoutExercises: [WorkoutExercise]? = []

    init(
        name: String,
        isTimeBased: Bool = false,
        isDistanceBased: Bool = false,
        notes: String = ""
    ) {
        self.name = name
        self.isTimeBased = isTimeBased
        self.isDistanceBased = isDistanceBased
        self.notes = notes
    }
}

// Extension for migration
extension Exercise {
    static func deduplicateByName(in context: ModelContext) {
        guard let allExercises = try? context.fetch(FetchDescriptor<Exercise>()) else {
            return
        }
        
        var canonicalByName: [String: Exercise] = [:]
        var didMerge = false
        
        for exercise in allExercises {
            let key = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            guard !key.isEmpty else {
                continue
            }
            
            guard let canonical = canonicalByName[key] else {
                canonicalByName[key] = exercise
                continue
            }
            
            for workoutExercise in exercise.workoutExercises ?? [] {
                workoutExercise.exercise = canonical
            }
            
            if canonical.notes.isEmpty {
                canonical.notes = exercise.notes
            }
            
            context.delete(exercise)
            didMerge = true
        }
        
        guard didMerge else {
            return
        }
        
        try? context.save()
    }
}
