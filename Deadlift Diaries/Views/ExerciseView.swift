//
//  ExerciseView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData

struct ExerciseItemView: View {
    @Bindable var exercise: Exercise

    var body: some View {
        Text("Exercise: \(exercise.name), Sets: \(exercise.sets), Reps: \(exercise.reps)")
            .font(.caption)
    }
}
