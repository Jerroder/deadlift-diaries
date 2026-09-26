//
//  FormattedFunctions.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-26.
//

func formattedSeconds(_ seconds: Int) -> String {
    let totalSeconds = max(0, seconds)
    
    if totalSeconds < 60 {
        return "\(totalSeconds)s"
    }
    
    let minutes = totalSeconds / 60
    let remainingSeconds = totalSeconds % 60
    
    return String(format: "%02d:%02d", minutes, remainingSeconds)
}

func formattedDuration(_ seconds: Int) -> String {
    if seconds < 60 {
        return "\(seconds)s"
    }
    
    let minutes = seconds / 60
    let remaining = seconds % 60
    
    if remaining == 0 {
        return "\(minutes)m"
    }
    
    return "\(minutes)m \(remaining)s"
}

func formattedTargetValue(for workoutExercise: WorkoutExercise) -> String {
    guard let exercise = workoutExercise.exercise else {
        return "\(workoutExercise.targetReps)"
    }
    
    if exercise.isTimeBased {
        return formattedDuration(workoutExercise.targetReps)
    } else if exercise.isDistanceBased {
        return "\(workoutExercise.targetDistance) \(distanceUnit().symbol)"
    } else {
        return "\(workoutExercise.targetReps)"
    }
}
