//
//  SetProgressView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-18.
//

import SwiftUI

struct RestBox: View {
    let progress: Double
    
    private let restColor = Color(red: 0xFF / 255, green: 0xBC / 255, blue: 0x8E / 255)
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(restColor.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(restColor)
                    .frame(width: geo.size.width * progress)
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
    @State private var timer: Timer?
    @State private var restProgress: Double = 0
    @State private var completedRestIndex = -1
    
    private let restColor = Color(red: 0xFF / 255, green: 0xBC / 255, blue: 0x8E / 255)
    
    private var restDuration: Int {
        exercise.sourceExercise?.restSeconds ?? 60
    }
    
    var body: some View {
        let sets = exercise.sets ?? []
        
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(Array(sets.enumerated()), id: \.element.id) { index, _ in
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            index <= completedSetIndex
                            ? Color.accentColor
                            : Color.accentColor.opacity(0.3)
                        )
                        .frame(width: 20, height: 20)
                    
                    if index < sets.count - 1 {
                        RestBox(progress: index == completedSetIndex ? restProgress : (index <= completedRestIndex ? 1 : 0))
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
            // First set is already completed
            completeCurrentSet()
        }
        .onDisappear {
            timer?.invalidate()
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
        isResting = true
        restSeconds = exercise.sourceExercise?.restSeconds ?? 60
        restProgress = 0
        
        timer?.invalidate()
        
        let totalRest = Double(restDuration)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if restProgress < 1 {
                restProgress += 0.05 / totalRest
                restSeconds = Int((1 - restProgress) * totalRest)
            } else {
                finishRest()
            }
        }
    }
    
    private func finishRest() {
        timer?.invalidate()
        timer = nil
        
        restProgress = 0
        isResting = false
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            completedRestIndex = completedSetIndex
            completedSetIndex += 1
            completeCurrentSet()
        }
    }
}
