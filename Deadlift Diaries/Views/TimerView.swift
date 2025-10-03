//
//  TimerView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import AudioToolbox
import AVFoundation
import SwiftUI

struct TimerView: View {
    @AppStorage("totalSets") private var totalSets: Int = 5
    @AppStorage("currentSet") private var currentSet: Int = 1
    @AppStorage("restDuration") private var restDuration: Double = 60.0
    @AppStorage("elapsed") private var elapsed: Double = 0.0
    @State private var isTimerRunning: Bool = false
    @State private var showingSoundPicker = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Stepper("Total Sets: \(totalSets)", value: $totalSets, in: 1...20)
                    .onChange(of: totalSets) { oldValue, newValue in
                        if currentSet > newValue {
                            currentSet = newValue
                        }
                    }
                HStack {
                    Text("Rest Duration:")
                    
                    Picker("Rest Duration", selection: $restDuration) {
                        ForEach(Array(stride(from: 5.0, through: 300.0, by: 5.0)), id: \.self) { duration in
                            Text("\(Int(duration)) sec").tag(duration)
                        }
                    }
                    .pickerStyle(.wheel)
                    .disabled(isTimerRunning)
                    .frame(height: 150)
                    
                    if #available(iOS 26.0, *) {
                        VStack(spacing: 8) {
                            Button("30s") { restDuration = 30 }
                                .disabled(isTimerRunning)
                            Button("60s") { restDuration = 60 }
                                .disabled(isTimerRunning)
                            Button("90s") { restDuration = 90 }
                                .disabled(isTimerRunning)
                            Button("120s") { restDuration = 120 }
                                .disabled(isTimerRunning)
                        }
                        .buttonStyle(.glass)
                    } else {
                        VStack(spacing: 8) {
                            Button("30s") { restDuration = 30 }
                                .disabled(isTimerRunning)
                            Button("60s") { restDuration = 60 }
                                .disabled(isTimerRunning)
                            Button("90s") { restDuration = 90 }
                                .disabled(isTimerRunning)
                            Button("120s") { restDuration = 120 }
                                .disabled(isTimerRunning)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                
                ProgressBarView(
                    totalSets: totalSets,
                    currentSet: $currentSet,
                    restDuration: restDuration,
                    isTimerRunning: $isTimerRunning,
                    elapsed: $elapsed
                )
            }
            .padding()
            .navigationTitle("Timer")
            .sheet(isPresented: $showingSoundPicker) {
                SoundPickerSheet(
                    isPresented: $showingSoundPicker
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(action: {
                            showingSoundPicker = true
                        }) {
                            Label("settings".localized(comment: "Settings"), systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
    }
}

struct ProgressBarView: View {
    let totalSets: Int
    @Binding var currentSet: Int
    let restDuration: Double
    @Binding var isTimerRunning: Bool
    @Binding var elapsed: Double
    
    @AppStorage("selectedSoundID") private var selectedSoundID: Int = 1075
    
    @State private var restProgress: CGFloat = 0
    @State private var timer: DispatchSourceTimer?
    @State private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    @State private var timeStarted: Double?
    @State private var timeRemaining: Double = 60.0
    
    let orange = Color(red: 0xFF/255, green: 0xBC/255, blue: 0x8E/255)
    let yellow = Color(red: 0xFF/255, green: 0xD6/255, blue: 0x8E/255)
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                let squareWidth = geometry.size.width / CGFloat(2 * self.totalSets - 1)
                HStack(spacing: 4) {
                    ForEach(1..<2*self.totalSets, id: \.self) { index in
                        if index.isMultiple(of: 2) {
                            let restNumber = index / 2
                            if restNumber == self.currentSet && (self.isTimerRunning || self.restProgress > 0) {
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .frame(width: squareWidth, height: 20)
                                        .foregroundColor(.gray)
                                        .cornerRadius(4)
                                    Rectangle()
                                        .frame(width: squareWidth * self.restProgress, height: 20)
                                        .foregroundColor(yellow)
                                        .cornerRadius(4)
                                        .animation(.linear, value: self.restProgress)
                                }
                            } else if restNumber < self.currentSet {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(orange)
                                    .cornerRadius(4)
                            } else {
                                Rectangle()
                                    .frame(width: squareWidth, height: 20)
                                    .foregroundColor(.gray)
                                    .cornerRadius(4)
                            }
                        } else {
                            let setNumber = (index + 1) / 2
                            Rectangle()
                                .frame(width: squareWidth, height: 20)
                                .foregroundColor(setNumber <= self.currentSet ? .accentColor : .gray)
                                .cornerRadius(4)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: 20)
            }
            .frame(height: 20)
            .padding(.horizontal)
            .onAppear {
                if timeRemaining < restDuration {
                    restProgress = 1 - (CGFloat(timeRemaining.rounded(.down)) / CGFloat(restDuration.rounded(.up)))
                } else {
                    restProgress = 0
                }
            }
            
            Text("Remaining: \(Int(timeRemaining.rounded(.down))) sec")
                .font(.title)
            
            if #available(iOS 26.0, *) {
                HStack {
                    Spacer()
                    Button(action: toggleTimer) {
                        Text(isTimerRunning ? "Pause" : "Start")
                    }
                    .disabled(currentSet >= totalSets)
                    .buttonStyle(.glassProminent)
                    Spacer()
                    Button("Reset") {
                        timer?.cancel()
                        isTimerRunning = false
                        currentSet = 1
                        timeRemaining = restDuration
                        restProgress = 0
                        timeStarted = nil
                        elapsed = 0.0
                    }
                    .buttonStyle(.glass)
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    Button(action: toggleTimer) {
                        Text(isTimerRunning ? "Pause" : "Start")
                    }
                    .disabled(currentSet >= totalSets)
                    Spacer()
                    Button("Reset") {
                        timer?.cancel()
                        isTimerRunning = false
                        currentSet = 1
                        timeRemaining = restDuration
                        restProgress = 0
                        timeStarted = nil
                        elapsed = 0.0
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            timeRemaining = max(0, restDuration - elapsed)
        }
    }
    
    private func toggleTimer() {
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
        isTimerRunning.toggle()
    }
    
    private func startTimer() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [self] in
            self.endBackgroundTask()
        }
        
        timeStarted = Date.now.timeIntervalSince1970 * 1000
        
        let queue = DispatchQueue(label: "com.jerroder.deadliftdiaries", qos: .background)
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: .seconds(1))
        timer?.setEventHandler { [self] in
            DispatchQueue.main.async {
                let now = Date.now.timeIntervalSince1970 * 1000
                let elapsed = max(0, now - (timeStarted ?? 0)) / 1000
                let remaining = max(0, restDuration - elapsed - self.elapsed)
                timeRemaining = remaining
                restProgress = 1 - (CGFloat(timeRemaining.rounded(.down)) / CGFloat(restDuration.rounded(.up)))
                
                if timeRemaining <= 0 {
                    isTimerRunning = false
                    stopTimer()
                    if currentSet < totalSets {
                        currentSet += 1
                        timeRemaining = restDuration
                        restProgress = 0
                        self.elapsed = 0.0
                    }
                } else if timeRemaining <= 1 {
                    playSystemSound()
                }
            }
        }
        timer?.resume()
    }
    
    private func stopTimer() {
        let now = Date.now.timeIntervalSince1970 * 1000
        if let timeStarted = timeStarted {
            elapsed += max(0, now - timeStarted) / 1000
            timeRemaining = max(0, restDuration - elapsed)
        }
        timer?.cancel()
        timer = nil
        endBackgroundTask()
    }

    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func playSystemSound() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.ambient, options: .duckOthers)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AudioServicesPlaySystemSound(UInt32(selectedSoundID))
        }
        
        let duration: Double = selectedSoundID == 1328 ? 2.0 : 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            do {
                try audioSession.setActive(false)
            } catch {
                print("Failed to deactivate audio session: \(error)")
            }
        }
    }
}
