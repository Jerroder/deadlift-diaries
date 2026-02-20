//
//  TimerWidgetLiveActivity.swift
//  TimerWidget
//
//  Created by Jerroder on 2026-01-26.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

struct TimerWidgetLiveActivity: Widget {
    let orange = Color(red: 0xFF/255, green: 0xBC/255, blue: 0x8E/255)
    let accentColor = Color(red: 0x5D/255, green: 0xA7/255, blue: 0x9B/255)
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerWidgetAttributes.self) { context in
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.isResting ? "Rest Timer" : "Exercise Timer")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell.fill")
                            .font(.caption)
                        Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    if let startTime = context.state.startTime, context.state.isRunning {
                        Text(startTime.addingTimeInterval(context.state.timeRemaining), style: .timer)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(context.state.isResting ? orange : accentColor)
                            .frame(width: 100)
                    } else {
                        Text(formatTime(context.state.timeRemaining))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(context.state.isResting ? orange : accentColor)
                            .frame(width: 100)
                    }
                    
                    ProgressView(value: 1 - (context.state.timeRemaining / context.state.totalDuration))
                        .tint(context.state.isResting ? orange : accentColor)
                        .frame(width: 100)
                }
                .padding(.trailing, 8)
            }
            .padding()
            .activityBackgroundTint(Color(UIColor.systemBackground))
            .activitySystemActionForegroundColor(Color.primary)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell.fill")
                            .font(.caption)
                        Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                            .font(.caption)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let startTime = context.state.startTime, context.state.isRunning {
                        Text(startTime.addingTimeInterval(context.state.timeRemaining), style: .timer)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    } else {
                        Text(formatTime(context.state.timeRemaining))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.isResting ? "Resting" : "Exercise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: 1 - (context.state.timeRemaining / context.state.totalDuration))
                        .tint(context.state.isResting ? orange : accentColor)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(context.state.isResting ? orange : accentColor)
            } compactTrailing: {
                if let startTime = context.state.startTime, context.state.isRunning {
                    Text(startTime.addingTimeInterval(context.state.timeRemaining), style: .timer)
                        .monospacedDigit()
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(context.state.isResting ? orange : accentColor)
                } else {
                    Text(formatTime(context.state.timeRemaining))
                        .monospacedDigit()
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(context.state.isResting ? orange : accentColor)
                }
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(context.state.isResting ? orange : accentColor)
            }
            .keylineTint(context.state.isResting ? orange : accentColor)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let seconds = Int(timeInterval)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        } else {
            return String(format: "%ds", remainingSeconds)
        }
    }
}

extension TimerWidgetAttributes {
    fileprivate static var preview: TimerWidgetAttributes {
        TimerWidgetAttributes(timerType: "rest")
    }
}

extension TimerWidgetAttributes.ContentState {
    fileprivate static var resting: TimerWidgetAttributes.ContentState {
        TimerWidgetAttributes.ContentState(
            timeRemaining: 60,
            totalDuration: 60,
            currentSet: 2,
            totalSets: 5,
            isResting: true,
            isRunning: true,
            startTime: Date()
        )
    }
     
    fileprivate static var exercising: TimerWidgetAttributes.ContentState {
        TimerWidgetAttributes.ContentState(
            timeRemaining: 30,
            totalDuration: 30,
            currentSet: 3,
            totalSets: 5,
            isResting: false,
            isRunning: true,
            startTime: Date()
        )
    }
}

#Preview("Notification", as: .content, using: TimerWidgetAttributes.preview) {
   TimerWidgetLiveActivity()
} contentStates: {
    TimerWidgetAttributes.ContentState.resting
    TimerWidgetAttributes.ContentState.exercising
}
