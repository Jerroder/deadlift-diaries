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
    @State private var isResting: Bool = false
    
    @State private var restStartDate: Date?
    @State private var restTask: Task<Void, Never>?
    
    @State private var isPaused = false
    @State private var restRemaining: Duration = .zero
    
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
        Int(restRemaining.components.seconds)
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
                                remaining: restRemaining,
                                isActive: index == currentSetIndex && isResting,
                                isCompleted: index < completedRestIndex - 1
                            )
                            .frame(width: segmentWidth, height: 20)
                        }
                    }
                }
            }
            .frame(height: 20)
            
            if #available(iOS 26.0, *) {
                if isResting {
                    Text("Rest \(restTimeString)")
                    
                    Button(isPaused ? "Resume" : "Pause") {
                        if isPaused { // Resume
                            isPaused = false
                            runRestTimer()
                        } else { // Pause
                            isPaused = true
                            restTask?.cancel()
                            restTask = nil
                        }
                    }
                    .buttonStyle(.glassProminent)
                } else if completedRestIndex < sets.count {
                    Text("")
                    
                    Button("Start rest") {
                        startRest()
                    }
                    .buttonStyle(.glassProminent)
                }
            } else {
                if isResting {
                    Text("Rest \(restTimeString)")
                    
                    Button(isPaused ? "Resume" : "Pause") {
                        if isPaused { // Resume
                            isPaused = false
                            runRestTimer()
                        } else { // Pause
                            isPaused = true
                            restTask?.cancel()
                            restTask = nil
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else if completedRestIndex < sets.count {
                    Text("")
                    
                    Button("Start rest") {
                        startRest()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear {
            completeCurrentSet()
            currentSetIndex = completedRestIndex - 1
        }
        .onDisappear {
            restTask?.cancel()
            restTask = nil
        }
    }
    
    private func skipToSet(_ index: Int) {
        guard sets.indices.contains(index) else {
            return
        }
        
        restTask?.cancel()
        restTask = nil
        
        withTransaction(Transaction(animation: nil)) {
            isResting = false
            restStartDate = nil
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
        restTask?.cancel()
        
        isResting = true
        isPaused = false
        
        restRemaining = .seconds(restDuration)
        
        runRestTimer()
    }
    
    private func runRestTimer() {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: restRemaining)
        
        restTask = Task { @MainActor in
            while !Task.isCancelled {
                let now = clock.now
                let newRemaining = deadline - now
                
                if newRemaining <= .zero {
                    restRemaining = .zero
                    finishRest()
                    break
                }
                
                restRemaining = newRemaining
                
                do {
                    try await clock.sleep(
                        until: now.advanced(by: .milliseconds(100))
                    )
                } catch {
                    break
                }
            }
        }
    }
    
    private func finishRest() {
        restTask?.cancel()
        restTask = nil
        
        isResting = false
        restStartDate = nil
        
        currentSetIndex += 1
        completeCurrentSet()
    }
}
