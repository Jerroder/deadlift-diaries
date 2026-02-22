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
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.isResting ? "Resting" : "Exercise")
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
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if let endTime = context.state.endTime, context.state.isRunning {
                            Text(timerInterval: Date.now...endTime, countsDown: true)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(context.state.isResting ? orange : accentColor)
                                .multilineTextAlignment(.trailing)
                        } else {
                            Text(formatTime(context.state.timeRemaining))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(context.state.isResting ? orange : accentColor)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding([.top, .horizontal])
                .activityBackgroundTint(Color(UIColor.systemBackground))
                .activitySystemActionForegroundColor(Color.primary)
                
                if let endTime = context.state.endTime {
                    if context.state.isRunning {
                        ProgressView(
                            timerInterval: (Date.now - (context.state.totalDuration - context.state.timeRemaining))...endTime,
                            countsDown: false,
                            label: { EmptyView() },
                            currentValueLabel: { EmptyView() }
                        )
                        .progressViewStyle(.linear)
                        .tint(context.state.isResting ? orange : accentColor)
                        .padding(.bottom)
                        .padding(.horizontal, 30)
                    } else {
                        ProgressView(value: 1 - (endTime.timeIntervalSince(Date.now) / context.state.totalDuration))
                            .progressViewStyle(.linear)
                            .tint(context.state.isResting ? orange : accentColor)
                            .padding(.bottom)
                            .padding(.horizontal, 30)
                    }
                }
            }

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text(context.state.isResting ? "Resting" : "Exercise")
                            .font(.headline)
                        HStack(spacing: 4) {
                            Image(systemName: "dumbbell.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let endTime = context.state.endTime, context.state.isRunning {
                        Text(timerInterval: Date.now...endTime, countsDown: true)
                            .font(.title)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundColor(context.state.isResting ? orange : accentColor)
                            .multilineTextAlignment(.trailing)
                            .padding(.horizontal)
                    } else {
                        Text(formatTime(context.state.timeRemaining))
                            .font(.title)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundColor(context.state.isResting ? orange : accentColor)
                            .multilineTextAlignment(.trailing)
                            .padding(.horizontal)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let endTime = context.state.endTime {
                        if context.state.isRunning {
                            ProgressView(
                                timerInterval: (Date.now - (context.state.totalDuration - context.state.timeRemaining))...endTime,
                                countsDown: false,
                                label: { EmptyView() },
                                currentValueLabel: { EmptyView() }
                            )
                            .progressViewStyle(.linear)
                            .tint(context.state.isResting ? orange : accentColor)
                            .padding(.horizontal)
                        } else {
                            ProgressView(value: 1 - (endTime.timeIntervalSince(Date.now) / context.state.totalDuration))
                                .progressViewStyle(.linear)
                                .tint(context.state.isResting ? orange : accentColor)
                                .padding(.horizontal)
                        }
                    }
                }
            } compactLeading: {
                if let endTime = context.state.endTime {
                    if context.state.isRunning {
                        ProgressView(
                            timerInterval: (Date.now - (context.state.totalDuration - context.state.timeRemaining))...endTime,
                            countsDown: true,
                            label: { EmptyView() },
                            currentValueLabel: { EmptyView() }
                        )
                        .progressViewStyle(.circular)
                        .tint(context.state.isResting ? orange : accentColor)
                    } else {
                        ProgressView(value: (endTime.timeIntervalSince(Date.now) / context.state.totalDuration))
                            .progressViewStyle(.circular)
                            .tint(context.state.isResting ? orange : accentColor)
                    }
                } else {
                    Image(systemName: "timer")
                        .foregroundColor(context.state.isResting ? orange : accentColor)
                }
            } compactTrailing: {
                if let endTime = context.state.endTime, context.state.isRunning {
                    Text(timerInterval: Date.now...endTime, countsDown: true)
                        .monospacedDigit()
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(context.state.isResting ? orange : accentColor)
                        .frame(minWidth: 20, idealWidth: 30, maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(formatTime(context.state.timeRemaining))
                        .monospacedDigit()
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(context.state.isResting ? orange : accentColor)
                        .frame(minWidth: 20, idealWidth: 30, maxWidth: .infinity, alignment: .leading)
                }
            } minimal: {
                if let endTime = context.state.endTime {
                    if context.state.isRunning {
                        ProgressView(
                            timerInterval: (Date.now - (context.state.totalDuration - context.state.timeRemaining))...endTime,
                            countsDown: true,
                            label: { EmptyView() },
                            currentValueLabel: { EmptyView() }
                        )
                        .progressViewStyle(.circular)
                        .tint(context.state.isResting ? orange : accentColor)
                    } else {
                        ProgressView(value: (endTime.timeIntervalSince(Date.now) / context.state.totalDuration))
                            .progressViewStyle(.circular)
                            .tint(context.state.isResting ? orange : accentColor)
                    }
                } else {
                    Image(systemName: "timer")
                        .foregroundColor(context.state.isResting ? orange : accentColor)
                }
            }
            .keylineTint(context.state.isResting ? orange : accentColor)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let seconds = Int(timeInterval)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func formatTimeInterval(_ endTime: Date) -> String {
        let remainingTime = endTime.timeIntervalSinceNow
        guard remainingTime > 0 else {
            return "0:00"
        }
        
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
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
            startTime: Date(),
            endTime: Date().addingTimeInterval(60)
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
            startTime: Date(),
            endTime: Date().addingTimeInterval(30)
        )
    }
}
