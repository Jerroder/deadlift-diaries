//
//  OverviewView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2026-09-26.
//

/* A hierarchical read of the programs: TrainingBlock -> WorkoutTemplate -> WorkoutExercise */

import SwiftData
import SwiftUI

struct OverviewView: View {
    @Query(sort: \TrainingBlock.orderIndex)
    private var trainingBlocks: [TrainingBlock]
    
    @Query(sort: \WorkoutTemplate.name)
    private var allWorkoutTemplates: [WorkoutTemplate]
    
    @State private var showCreateTrainingBlockSheet: Bool = false
    @State private var trainingBlockToEdit: TrainingBlock?
    
    private var unassignedTemplates: [WorkoutTemplate] {
        allWorkoutTemplates.filter { $0.trainingBlock == nil }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if trainingBlocks.isEmpty && unassignedTemplates.isEmpty {
                    emptyView
                } else {
                    List {
                        ForEach(trainingBlocks) { block in
                            Section {
                                ForEach(sortedTemplates(in: block)) { template in
                                    workoutRow(template)
                                }
                            } header: {
                                blockHeader(block)
                            }
                        }
                        
                        if !unassignedTemplates.isEmpty {
                            Section {
                                ForEach(sortedTemplates(unassignedTemplates)) { template in
                                    workoutRow(template)
                                }
                            } header: {
                                Text("no_program".localized(comment: "No Program"))
                            }
                        }
                    }
                }
            }
            .navigationTitle("overview".localized(comment: "Overview"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateTrainingBlockSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateTrainingBlockSheet) {
            CreateTrainingBlockView { _ in }
        }
        .sheet(item: $trainingBlockToEdit) { block in
            CreateTrainingBlockView(existingBlock: block) { _ in }
        }
    }
    
    // MARK: - Program Header
    
    @ViewBuilder
    private func blockHeader(_ block: TrainingBlock) -> some View {
        HStack {
            Text(block.name)
            
            Spacer()
            
            Button {
                trainingBlockToEdit = block
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
        }
    }
    
    // MARK: - Workout Row
    
    @ViewBuilder
    private func workoutRow(_ template: WorkoutTemplate) -> some View {
        DisclosureGroup {
            let rows = exerciseRows(from: representativeExercises(for: template))
            
            if rows.isEmpty {
                Text("no_exercises".localized(comment: "No exercises"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(rows) { row in
                        switch row {
                        case .single(let exercise):
                            ScheduledWorkoutCard.WorkoutExerciseRow(workoutExercise: exercise)
                            
                        case .superset(let first, let second):
                            OverviewSupersetRow(first: first, second: second)
                        }
                    }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(template.name)
                    .font(.headline)

                Text(scheduleSubtitle(for: template))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Weekdays
    
    private func activeWeekdays(for template: WorkoutTemplate) -> [Int] {
        let schedules = template.workoutTemplates ?? []
        let now = Date()
        
        let active = Set(
            schedules
                .filter { $0.startDate <= now && ($0.endDate.map { $0 >= now } ?? true) }
                .map(\.weekday)
        )
        
        if !active.isEmpty {
            return active.sorted { sortableWeekday($0) < sortableWeekday($1) }
        }
        
        if let mostRecent = schedules.max(by: { $0.startDate < $1.startDate }) {
            return [mostRecent.weekday]
        }
        
        return []
    }
    
    private func scheduleSubtitle(for template: WorkoutTemplate) -> String {
        let weekdays = activeWeekdays(for: template)
        
        guard !weekdays.isEmpty else {
            return "unscheduled".localized(comment: "Unscheduled")
        }
        
        let symbols = Calendar.current.weekdaySymbols
        
        let names = weekdays.compactMap { weekday -> String? in
            guard weekday >= 1, weekday <= symbols.count else {
                return nil
            }
            
            return symbols[weekday - 1]
        }
        
        return names.isEmpty ? "unscheduled".localized(comment: "Unscheduled") : names.joined(separator: ", ")
    }
    
    // MARK: - Sorting
    
    private func sortedTemplates(in block: TrainingBlock) -> [WorkoutTemplate] {
        sortedTemplates(block.workoutTemplates ?? [])
    }
    
    private func sortedTemplates(_ templates: [WorkoutTemplate]) -> [WorkoutTemplate] {
        templates.sorted { lhs, rhs in
            let lhsWeekday = activeWeekdays(for: lhs).first
            let rhsWeekday = activeWeekdays(for: rhs).first
            
            switch (lhsWeekday, rhsWeekday) {
            case let (lhsWeekday?, rhsWeekday?) where lhsWeekday != rhsWeekday:
                return sortableWeekday(lhsWeekday) < sortableWeekday(rhsWeekday)
                
            case (nil, .some):
                return false
                
            case (.some, nil):
                return true
                
            default:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
    }
    
    // Moves Monday to the front of the week, which reads more naturally for a training split.
    private func sortableWeekday(_ weekday: Int) -> Int {
        (weekday + 5) % 7
    }
    
    // MARK: - Exercises
    
    private func representativeExercises(for template: WorkoutTemplate) -> [WorkoutExercise] {
        if let scheduledWorkout = currentScheduledWorkout(for: template) {
            return scheduledWorkout.exercises ?? []
        }
        
        return template.exercises ?? []
    }
    
    private func currentScheduledWorkout(for template: WorkoutTemplate) -> ScheduledWorkout? {
        let today = Calendar.current.startOfDay(for: Date())
        let workouts = template.scheduledWorkouts ?? []
        
        if let upcoming = workouts
            .filter({ $0.scheduledDate >= today })
            .min(by: { $0.scheduledDate < $1.scheduledDate }) {
            return upcoming
        }
        
        return workouts
            .filter({ $0.scheduledDate < today })
            .max(by: { $0.scheduledDate < $1.scheduledDate })
    }
    
    private func exerciseRows(from exercises: [WorkoutExercise]) -> [TemplateExerciseRow] {
        let sorted = exercises.sorted {
            if $0.order != $1.order {
                return $0.order < $1.order
            }
            
            return ($0.supersetPosition?.rawValue ?? 0) < ($1.supersetPosition?.rawValue ?? 0)
        }
        
        var rows: [TemplateExerciseRow] = []
        var index = 0
        
        while index < sorted.count {
            let exercise = sorted[index]
            
            guard let supersetID = exercise.supersetID else {
                rows.append(.single(exercise))
                index += 1
                continue
            }
            
            let supersetExercises = sorted.filter { $0.supersetID == supersetID }
            
            if let first = supersetExercises.first(where: { $0.supersetPosition == .first }),
               let second = supersetExercises.first(where: { $0.supersetPosition == .second }) {
                rows.append(.superset(first: first, second: second))
                
                index += supersetExercises.count
            } else { // Defensive fallback for malformed/incomplete data.
                rows.append(.single(exercise))
                index += 1
            }
        }
        
        return rows
    }
    
    // MARK: - Empty State
    
    private var emptyView: some View {
        ContentUnavailableView(
            "no_programs".localized(comment: "No Programs"),
            systemImage: "square.stack.3d.up",
            description: Text("no_programs_description".localized(comment: "Create a program to see its workouts and exercises here."))
        )
    }
}

private struct OverviewSupersetRow: View {
    let first: WorkoutExercise
    let second: WorkoutExercise

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Rectangle()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 6) {
                exerciseInfo(first)

                HStack(spacing: 4) {
                    Image(systemName: "link")
                    Text("superset".localized(comment: "Superset"))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                exerciseInfo(second)
            }
            .padding(.vertical, 6)

            Spacer()
        }
    }

    @ViewBuilder
    private func exerciseInfo(_ workoutExercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(workoutExercise.exercise?.name ?? "unknown_exercise".localized(comment: "Unknown Exercise"))
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Text(targetDescription(for: workoutExercise))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func targetDescription(for workoutExercise: WorkoutExercise) -> String {
        let target = formattedTargetValue(for: workoutExercise)

        if let weight = workoutExercise.targetWeight {
            return "\(workoutExercise.targetSets) x \(target) @ \(weight.formatted()) kg"
        }

        return "\(workoutExercise.targetSets) x \(target)"
    }
}
