//
//  FormattedSeconds.swift
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
