//
//  SetProgressView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-18.
//

import SwiftUI

struct RestBox: View {
    let restDuration: Double
    let remaining: Duration
    let isActive: Bool
    let isCompleted: Bool
    
    private let restColor = Color(red: 0xFF / 255, green: 0xBC / 255, blue: 0x8E / 255)
    
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
                    
                    return min(max(1 - remainingSeconds / restDuration, 0), 1)
                }()
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(restColor.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(restColor)
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
    
    private let liveActivityManager = TimerLiveActivityManager.shared
    @State private var restSessionID = UUID()
    
    private var restTimer = RestTimerManager.shared
    
    private var sets: [PerformedSet] {
        (exercise.sets ?? []).sorted { $0.setNumber < $1.setNumber }
    }
    
    private var restDuration: Int {
        exercise.sourceExercise?.restSeconds ?? 60
    }
    
    private var completedRestIndex: Int {
        sets.firstIndex(where: { !$0.completed }) ?? sets.count
    }
    
    private var restSeconds: Int {
        if completedRestIndex == sets.count {
            return 0
        }
        
        if isCurrentExerciseResting {
            return Int(restTimer.remaining.components.seconds)
        }
        
        return restDuration
    }
    
    private var restTimeString: String {
        let totalSeconds = max(0, restSeconds)
        
        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        }
        
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var isCurrentExerciseResting: Bool {
        restTimer.isResting && restTimer.exerciseID == exercise.id
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
                        Button {
                            skipToSet(index)
                        } label: {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(set.completed ? Color.accentColor : Color.accentColor.opacity(0.3))
                                .frame(width: segmentWidth, height: 20)
                        }
                        .buttonStyle(.plain)
                        
                        if index < sets.count - 1 {
                            RestBox(
                                restDuration: Double(restDuration),
                                remaining: isCurrentExerciseResting ? restTimer.remaining : .seconds(restSeconds),
                                isActive: isCurrentExerciseResting &&
                                index == currentSetIndex,
                                isCompleted: index < completedRestIndex - 1
                            )
                            .frame(width: segmentWidth, height: 20)
                        }
                    }
                }
            }
            .frame(height: 20)
            
            Text("remaining_x".localized(with: restTimeString, comment: "Remaining: x"))
                .font(.title)
            
            if #available(iOS 26.0, *) {
                restButton()
                    .buttonStyle(.glassProminent)
            } else {
                restButton()
                    .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            completeCurrentSet()
            currentSetIndex = max(0, completedRestIndex - 1)
        }
    }
    
    @ViewBuilder
    private func restButton() -> some View {
        if isCurrentExerciseResting {
            Button(restTimer.isPaused ? "Resume" : "Pause") {
                if restTimer.isPaused {
                    restTimer.resume(sendNotification: sendNotification)
                } else {
                    restTimer.pause()
                }
            }
        } else {
            Button("Start rest") {
                startRest()
            }
            .disabled(completedRestIndex >= sets.count)
        }
    }
    
    private func skipToSet(_ index: Int) {
        guard sets.indices.contains(index) else {
            return
        }
        
        restTimer.stop()
        
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
    
    private func startRest() {
        restTimer.onFinish = { finishedExerciseID, finishedSetIndex in
            guard finishedExerciseID == exercise.id else {
                return
            }
            
            let nextSetIndex = finishedSetIndex + 1
            
            guard sets.indices.contains(nextSetIndex) else {
                return
            }
            
            sets[nextSetIndex].completed = true
            currentSetIndex = nextSetIndex
        }
        
        restTimer.start(
            exerciseID: exercise.id,
            setIndex: currentSetIndex,
            totalSets: sets.count,
            duration: .seconds(restDuration),
            selectedSoundID: selectedSoundID,
            sendNotification: sendNotification
        )
    }
}
