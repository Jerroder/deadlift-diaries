//
//  SetProgressView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-18.
//

import SwiftUI

struct RestBox: View {
    let totalDuration: Double
    let remaining: Duration
    let isActive: Bool
    let isCompleted: Bool
    var color: Color = Color(red: 0xFF / 255, green: 0xBC / 255, blue: 0x8E / 255)
    
    var body: some View {
        TimelineView(.animation) { _ in
            GeometryReader { geo in
                let progress: Double = {
                    if isCompleted {
                        return 1
                    }
                    
                    guard isActive else {
                        return 0
                    }
                    
                    let components = remaining.components
                    let remainingSeconds = Double(components.seconds) +
                    Double(components.attoseconds) / 1_000_000_000_000_000_000
                    
                    return min(max(1 - remainingSeconds / totalDuration, 0), 1)
                }()
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
        }
    }
}

struct SetProgressView: View {
    @Bindable var exercise: PerformedExercise
    
    @State private var currentSetIndex: Int = 0
    
    @AppStorage("sendNotification") private var sendNotification: Bool = false
    @AppStorage("selectedSoundID") private var selectedSoundID: Int = 1075
    @AppStorage("autoStartSetAfterRest") private var autoStartSetAfterRest: Bool = false
    @AppStorage("autoStartRestAfterSet") private var autoStartRestAfterSet: Bool = false
    
    private let liveActivityManager = TimerLiveActivityManager.shared
    @State private var restSessionID = UUID()
    
    private var workoutTimer = RestTimerManager.shared
    
    private var sets: [PerformedSet] {
        (exercise.sets ?? []).sorted { $0.setNumber < $1.setNumber }
    }
    
    private var isTimeBased: Bool {
        exercise.sourceExercise?.exercise?.isTimeBased ?? false
    }
    
    // The target duration (in seconds) of a single time-based set, e.g. a 60 second plank.
    private var setDuration: Int {
        exercise.targetReps
    }
    
    private var restDuration: Int {
        exercise.sourceExercise?.restSeconds ?? 60
    }
    
    private var completedRestIndex: Int {
        sets.firstIndex(where: { !$0.completed }) ?? sets.count
    }
    
    private var currentSetCompleted: Bool {
        guard sets.indices.contains(currentSetIndex) else {
            return true
        }
        
        return sets[currentSetIndex].completed
    }
    
    private var isCurrentExerciseResting: Bool {
        workoutTimer.isActive && workoutTimer.phase == .rest && workoutTimer.exerciseID == exercise.id
    }
    
    private var isCurrentExerciseSetTiming: Bool {
        workoutTimer.isActive && workoutTimer.phase == .workingSet && workoutTimer.exerciseID == exercise.id
    }
    
    private var isCurrentExerciseTiming: Bool {
        isCurrentExerciseResting || isCurrentExerciseSetTiming
    }
    
    private var restSeconds: Int {
        if completedRestIndex == sets.count {
            return 0
        }
        
        if isCurrentExerciseResting {
            return Int(workoutTimer.remaining.components.seconds)
        }
        
        return restDuration
    }
    
    // The value shown under the progress bar: whichever timer is relevant right now.
    private var displaySeconds: Int {
        if isCurrentExerciseTiming {
            return Int(workoutTimer.remaining.components.seconds)
        }
        
        if completedRestIndex >= sets.count {
            return 0
        }
        
        if isTimeBased && !currentSetCompleted {
            return setDuration
        }
        
        return restDuration
    }
    
    private var displayTimeString: String {
        formattedSeconds(displaySeconds)
    }
    
    private var restoredSetIndex: Int {
        if isTimeBased && completedRestIndex < sets.count {
            return completedRestIndex
        }
        
        return max(0, completedRestIndex - 1)
    }
    
    private func formattedSeconds(_ seconds: Int) -> String {
        let totalSeconds = max(0, seconds)
        
        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        }
        
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let segmentCount = sets.count * 2 - 1
                let spacing: CGFloat = 6
                let totalSpacing = CGFloat(segmentCount - 1) * spacing
                let segmentWidth = (geo.size.width - totalSpacing) / CGFloat(segmentCount)
                
                HStack(spacing: spacing) {
                    ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                        let isSetTiming = isTimeBased && isCurrentExerciseSetTiming && index == currentSetIndex
                        
                        Button {
                            selectSet(index)
                        } label: {
                            if isSetTiming {
                                RestBox(
                                    totalDuration: Double(setDuration),
                                    remaining: workoutTimer.remaining,
                                    isActive: true,
                                    isCompleted: false,
                                    color: .accentColor
                                )
                                .frame(width: segmentWidth, height: 20)
                            } else {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(set.completed ? Color.accentColor : Color.accentColor.opacity(0.3))
                                    .frame(width: segmentWidth, height: 20)
                            }
                        }
                        .buttonStyle(.plain)
                        .allowsHitTesting(!isSetTiming)
                        
                        if index < sets.count - 1 {
                            let isRestActive = isCurrentExerciseResting && index == currentSetIndex
                            
                            Button {
                                selectRest(after: index)
                            } label: {
                                RestBox(
                                    totalDuration: Double(restDuration),
                                    remaining: isRestActive ? workoutTimer.remaining : .seconds(restSeconds),
                                    isActive: isRestActive,
                                    isCompleted: index < currentSetIndex && set.completed
                                )
                                .frame(width: segmentWidth, height: 20)
                            }
                            .buttonStyle(.plain)
                            .allowsHitTesting(!isRestActive)
                        }
                    }
                }
            }
            .frame(height: 20)
            
            Text("remaining_x".localized(with: displayTimeString, comment: "Remaining: x"))
                .font(.title)
            
            if #available(iOS 26.0, *) {
                actionButton()
                    .buttonStyle(.glassProminent)
            } else {
                actionButton()
                    .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            if !isTimeBased {
                completeCurrentSet()
            }
            
            currentSetIndex = restoredSetIndex
        }
    }
    
    @ViewBuilder
    private func actionButton() -> some View {
        if isCurrentExerciseTiming {
            Button(workoutTimer.isPaused ? "Resume" : "Pause") {
                if workoutTimer.isPaused {
                    workoutTimer.resume(sendNotification: sendNotification)
                } else {
                    workoutTimer.pause()
                }
            }
        } else if isTimeBased && !currentSetCompleted {
            Button("Start") {
                startSet()
            }
        } else {
            Button("Start rest") {
                startRest()
            }
            .disabled(completedRestIndex >= sets.count)
        }
    }
    
    private func selectSet(_ index: Int) {
        guard sets.indices.contains(index) else {
            return
        }
        
        workoutTimer.stop()
        
        withTransaction(Transaction(animation: nil)) {
            currentSetIndex = index
            
            let completedBoundary = isTimeBased ? index : index + 1
            
            for (i, set) in sets.enumerated() {
                set.completed = i < completedBoundary
            }
        }
    }
    
    private func selectRest(after index: Int) {
        guard sets.indices.contains(index) else {
            return
        }
        
        workoutTimer.stop()
        
        withTransaction(Transaction(animation: nil)) {
            currentSetIndex = index
            
            for (i, set) in sets.enumerated() {
                set.completed = i <= index
            }
        }
    }
    
    private func completeCurrentSet() {
        guard sets.indices.contains(currentSetIndex) else {
            return
        }
        
        sets[currentSetIndex].completed = true
    }
    
    // Times the working portion of a time-based set (e.g. a 60 second plank).
    private func startSet() {
        guard sets.indices.contains(currentSetIndex) else {
            return
        }
        
        workoutTimer.onFinish = { finishedExerciseID, finishedSetIndex in
            guard finishedExerciseID == exercise.id else {
                return
            }
            
            guard sets.indices.contains(finishedSetIndex) else {
                return
            }
            
            sets[finishedSetIndex].completed = true
            
            if autoStartRestAfterSet && finishedSetIndex + 1 < sets.count {
                startRest()
            }
        }
        
        workoutTimer.start(
            phase: .workingSet,
            exerciseID: exercise.id,
            setIndex: currentSetIndex,
            totalSets: sets.count,
            duration: .seconds(setDuration),
            selectedSoundID: selectedSoundID,
            sendNotification: sendNotification
        )
    }
    
    private func startRest() {
        workoutTimer.onFinish = { finishedExerciseID, finishedSetIndex in
            guard finishedExerciseID == exercise.id else {
                return
            }
            
            let nextSetIndex = finishedSetIndex + 1
            
            guard sets.indices.contains(nextSetIndex) else {
                return
            }
            
            currentSetIndex = nextSetIndex
            
            if isTimeBased {
                if autoStartSetAfterRest {
                    startSet()
                }
            } else {
                sets[nextSetIndex].completed = true
            }
        }
        
        workoutTimer.start(
            phase: .rest,
            exerciseID: exercise.id,
            setIndex: currentSetIndex,
            totalSets: sets.count,
            duration: .seconds(restDuration),
            selectedSoundID: selectedSoundID,
            sendNotification: sendNotification
        )
    }
}
