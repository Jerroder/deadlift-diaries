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
        .frame(width: 20, height: 20)
    }
}

struct SetProgressView: View {
    @Bindable var exercise: PerformedExercise
    
    @State private var completedSetIndex = 0
    @State private var isResting = false
    @State private var restSeconds = 60
    @State private var completedRestIndex = -1
    
    @State private var restStartDate: Date?
    @State private var restTask: Task<Void, Never>?
    
    private var restDuration: Int {
        exercise.sourceExercise?.restSeconds ?? 60
    }
    
    var body: some View {
        let sets = exercise.sets ?? []
        
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(Array(sets.enumerated()), id: \.element.id) { index, _ in
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(index <= completedSetIndex ? Color.accentColor : Color.accentColor.opacity(0.3))
                        .frame(width: 20, height: 20)
                    
                    if index < sets.count - 1 {
                        RestBox(restDuration: Double(restDuration), startDate: restStartDate,
                                isActive: index == completedSetIndex && isResting,
                                isCompleted: index <= completedRestIndex
                        )
                    }
                }
            }
            
            if isResting {
                Text("Rest \(restSeconds)s")
                
                Button("Skip rest") {
                    finishRest()
                }
            } else if completedSetIndex < sets.count - 1 {
                Button("Start rest") {
                    startRest()
                }
                .buttonStyle(.borderedProminent)
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
    
    private func completeCurrentSet() {
        guard let sets = exercise.sets,
              completedSetIndex < sets.count else {
            return
        }
        
        sets[completedSetIndex].completed = true
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
        
        completedRestIndex = completedSetIndex
        completedSetIndex += 1
        
        completeCurrentSet()
    }
}
