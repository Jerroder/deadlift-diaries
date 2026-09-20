//
//  SetProgressView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-18.
//

import SwiftUI

struct RestBox: View {
    let restDuration: Double
    let startDate: Date?
    let isActive: Bool
    let isCompleted: Bool
    
    private let restColor = Color(red: 0xFF / 255, green: 0xBC / 255, blue: 0x8E / 255)
    
    var body: some View {
        TimelineView(.animation) { context in
            GeometryReader { geo in
                let progress: Double = {
                    if isCompleted {
                        return 1
                    }
                    
                    guard isActive, let startDate else {
                        return 0
                    }
                    
                    let elapsed = context.date.timeIntervalSince(startDate)
                    return min(max(elapsed / restDuration, 0), 1)
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
    @State private var restSeconds: Int = 60
    
    @State private var restStartDate: Date?
    @State private var restTask: Task<Void, Never>?
    
    private var sets: [PerformedSet] {
        (exercise.sets ?? []).sorted { $0.setNumber < $1.setNumber }
    }
    
    private var restDuration: Int {
        exercise.sourceExercise?.restSeconds ?? 60
    }
    
    private var completedRestIndex: Int {
        sets.firstIndex(where: { !$0.completed }) ?? sets.count
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
                                startDate: restStartDate,
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
                    Text("Rest \(restSeconds)s")
                    
                    Button("Skip rest") {
                        finishRest()
                    }
                    .buttonStyle(.glass)
                } else if completedRestIndex < sets.count {
                    Button("Start rest") {
                        startRest()
                    }
                    .buttonStyle(.glassProminent)
                }
            } else {
                if isResting {
                    Text("Rest \(restSeconds)s")
                    
                    Button("Skip rest") {
                        finishRest()
                    }
                } else if completedRestIndex < sets.count {
                    Button("Start rest") {
                        startRest()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear {
            completeCurrentSet()
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
        restSeconds = restDuration
        restStartDate = Date()
        
        let duration = restDuration
        let clock = ContinuousClock()
        let start = clock.now
        
        restTask = Task { @MainActor in
            while !Task.isCancelled {
                let elapsed = start.duration(to: clock.now)
                
                let elapsedSeconds = Double(elapsed.components.seconds) +
                Double(elapsed.components.attoseconds) / 1_000_000_000_000_000_000
                
                restSeconds = max(0, Int(ceil(Double(duration) - elapsedSeconds)))
                
                if elapsedSeconds >= Double(duration) {
                    finishRest()
                    break
                }
                
                try? await clock.sleep(for: .milliseconds(250))
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
