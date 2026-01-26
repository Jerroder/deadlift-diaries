//
//  TimerActivityAttributes.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-01-26.
//

import Foundation
import ActivityKit

struct TimerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: TimeInterval
        var totalDuration: TimeInterval
        var currentSet: Int
        var totalSets: Int
        var isResting: Bool
        var isRunning: Bool
        var startTime: Date?
    }

    var timerType: String // "rest" or "exercise" or "beforeNext"
}
