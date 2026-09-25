//
//  JSONExport.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-10-06.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// MARK: - DTOs

struct TrainingBlockDTO: Codable {
    let id: UUID
    let name: String
    let startDate: Date
    let endDate: Date?
    let orderIndex: Int
    let notes: String
}

struct WorkoutTemplateDTO: Codable {
    let id: UUID
    let name: String
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    let trainingBlockID: UUID?
}

struct WorkoutExerciseDTO: Codable {
    let id: UUID
    let order: Int
    let supersetID: UUID?
    let supersetPosition: SupersetPosition?
    let targetSets: Int
    let targetReps: Int
    let targetDistance: Int
    let targetWeight: Double?
    let restSeconds: Int?
    let timeBeforeNext: Int?
    let notes: String?
    let lineageID: UUID
    let exerciseID: UUID?
    let workoutTemplateID: UUID?
    let scheduledWorkoutID: UUID?
}

struct WorkoutScheduleDTO: Codable {
    let id: UUID
    let startDate: Date
    let endDate: Date?
    let weekday: Int
    let workoutTemplateID: UUID?
}

struct ScheduledWorkoutDTO: Codable {
    let id: UUID
    let scheduledDate: Date
    let notes: String?
    let createdAt: Date
    let workoutTemplateID: UUID?
}

struct ExerciseDTO: Codable {
    let id: UUID
    let name: String
    let isTimeBased: Bool
    let isDistanceBased: Bool
    let notes: String
}

struct WorkoutSessionDTO: Codable {
    let id: UUID
    let startedAt: Date
    let completedAt: Date?
    let scheduledWorkoutID: UUID?
}

struct PerformedExerciseDTO: Codable {
    let id: UUID
    let exerciseName: String
    let targetSets: Int
    let targetReps: Int
    let targetDistance: Int
    let targetWeight: Double?
    let orderIndex: Int
    let supersetID: UUID?
    let supersetPosition: SupersetPosition?
    let elapsed: Double
    let beforeNextCompleted: Bool
    let workoutSessionID: UUID?
    let sourceExerciseID: UUID?
}

struct PerformedSetDTO: Codable {
    let id: UUID
    let setNumber: Int
    let weight: Double?
    let reps: Int?
    let duration: Double?
    let distance: Int?
    let completed: Bool
    let performedExerciseID: UUID?
}

struct ExportData: Codable {
    let trainingBlocks: [TrainingBlockDTO]
    let workoutTemplates: [WorkoutTemplateDTO]
    let workoutExercises: [WorkoutExerciseDTO]
    let workoutSchedules: [WorkoutScheduleDTO]
    let scheduledWorkouts: [ScheduledWorkoutDTO]
    let exercises: [ExerciseDTO]
    let workoutSessions: [WorkoutSessionDTO]
    let performedExercises: [PerformedExerciseDTO]
    let performedSets: [PerformedSetDTO]
}

// MARK: - Export

func exportToJSON(
    trainingBlocks: [TrainingBlock],
    workoutTemplates: [WorkoutTemplate],
    workoutExercises: [WorkoutExercise],
    workoutSchedules: [WorkoutSchedule],
    scheduledWorkouts: [ScheduledWorkout],
    exercises: [Exercise],
    workoutSessions: [WorkoutSession],
    performedExercises: [PerformedExercise],
    performedSets: [PerformedSet]
) -> Data? {
    let exportData = ExportData(
        trainingBlocks: trainingBlocks.map { block in
            TrainingBlockDTO(
                id: block.id,
                name: block.name,
                startDate: block.startDate,
                endDate: block.endDate,
                orderIndex: block.orderIndex,
                notes: block.notes
            )
        },
        workoutTemplates: workoutTemplates.map { template in
            WorkoutTemplateDTO(
                id: template.id,
                name: template.name,
                notes: template.notes,
                createdAt: template.createdAt,
                updatedAt: template.updatedAt,
                trainingBlockID: template.trainingBlock?.id
            )
        },
        workoutExercises: workoutExercises.map { exercise in
            WorkoutExerciseDTO(
                id: exercise.id,
                order: exercise.order,
                supersetID: exercise.supersetID,
                supersetPosition: exercise.supersetPosition,
                targetSets: exercise.targetSets,
                targetReps: exercise.targetReps,
                targetDistance: exercise.targetDistance,
                targetWeight: exercise.targetWeight,
                restSeconds: exercise.restSeconds,
                timeBeforeNext: exercise.timeBeforeNext,
                notes: exercise.notes,
                lineageID: exercise.lineageID,
                exerciseID: exercise.exercise?.id,
                workoutTemplateID: exercise.workoutTemplate?.id,
                scheduledWorkoutID: exercise.scheduledWorkout?.id
            )
        },
        workoutSchedules: workoutSchedules.map { schedule in
            WorkoutScheduleDTO(
                id: schedule.id,
                startDate: schedule.startDate,
                endDate: schedule.endDate,
                weekday: schedule.weekday,
                workoutTemplateID: schedule.workoutTemplate?.id
            )
        },
        scheduledWorkouts: scheduledWorkouts.map { workout in
            ScheduledWorkoutDTO(
                id: workout.id,
                scheduledDate: workout.scheduledDate,
                notes: workout.notes,
                createdAt: workout.createdAt,
                workoutTemplateID: workout.workoutTemplate?.id
            )
        },
        exercises: exercises.map { exercise in
            ExerciseDTO(
                id: exercise.id,
                name: exercise.name,
                isTimeBased: exercise.isTimeBased,
                isDistanceBased: exercise.isDistanceBased,
                notes: exercise.notes
            )
        },
        workoutSessions: workoutSessions.map { session in
            WorkoutSessionDTO(
                id: session.id,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                scheduledWorkoutID: session.scheduledWorkout?.id
            )
        },
        performedExercises: performedExercises.map { exercise in
            PerformedExerciseDTO(
                id: exercise.id,
                exerciseName: exercise.exerciseName,
                targetSets: exercise.targetSets,
                targetReps: exercise.targetReps,
                targetDistance: exercise.targetDistance,
                targetWeight: exercise.targetWeight,
                orderIndex: exercise.orderIndex,
                supersetID: exercise.supersetID,
                supersetPosition: exercise.supersetPosition,
                elapsed: exercise.elapsed,
                beforeNextCompleted: exercise.beforeNextCompleted,
                workoutSessionID: exercise.workoutSession?.id,
                sourceExerciseID: exercise.sourceExercise?.id
            )
        },
        performedSets: performedSets.map { set in
            PerformedSetDTO(
                id: set.id,
                setNumber: set.setNumber,
                weight: set.weight,
                reps: set.reps,
                duration: set.duration,
                distance: set.distance,
                completed: set.completed,
                performedExerciseID: set.performedExercise?.id
            )
        }
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = .prettyPrinted
    do {
        return try encoder.encode(exportData)
    } catch {
        print("Error encoding data: \(error)")
        return nil
    }
}

func saveAndShareJSON(
    trainingBlocks: [TrainingBlock],
    workoutTemplates: [WorkoutTemplate],
    workoutExercises: [WorkoutExercise],
    workoutSchedules: [WorkoutSchedule],
    scheduledWorkouts: [ScheduledWorkout],
    exercises: [Exercise],
    workoutSessions: [WorkoutSession],
    performedExercises: [PerformedExercise],
    performedSets: [PerformedSet]
) {
    guard let jsonData = exportToJSON(
        trainingBlocks: trainingBlocks,
        workoutTemplates: workoutTemplates,
        workoutExercises: workoutExercises,
        workoutSchedules: workoutSchedules,
        scheduledWorkouts: scheduledWorkouts,
        exercises: exercises,
        workoutSessions: workoutSessions,
        performedExercises: performedExercises,
        performedSets: performedSets
    ) else { return }

    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("deadliftdiaries.json")

    do {
        try jsonData.write(to: tempURL)
    } catch {
        print("Error saving file: \(error)")
    }
}

// MARK: - Import

func importExportData(_ exportData: ExportData, into modelContext: ModelContext) {
    var exercisesByID: [UUID: Exercise] = [:]
    var trainingBlocksByID: [UUID: TrainingBlock] = [:]
    var workoutTemplatesByID: [UUID: WorkoutTemplate] = [:]
    var scheduledWorkoutsByID: [UUID: ScheduledWorkout] = [:]
    var workoutExercisesByID: [UUID: WorkoutExercise] = [:]
    var workoutSessionsByID: [UUID: WorkoutSession] = [:]
    var performedExercisesByID: [UUID: PerformedExercise] = [:]

    for dto in exportData.exercises {
        let exercise = Exercise(
            name: dto.name,
            isTimeBased: dto.isTimeBased,
            isDistanceBased: dto.isDistanceBased,
            notes: dto.notes
        )
        exercise.id = dto.id
        exercisesByID[dto.id] = exercise
        modelContext.insert(exercise)
    }

    for dto in exportData.trainingBlocks {
        let block = TrainingBlock(
            name: dto.name,
            startDate: dto.startDate,
            endDate: dto.endDate,
            orderIndex: dto.orderIndex,
            notes: dto.notes
        )
        block.id = dto.id
        trainingBlocksByID[dto.id] = block
        modelContext.insert(block)
    }

    for dto in exportData.workoutTemplates {
        let template = WorkoutTemplate(name: dto.name, notes: dto.notes)
        template.id = dto.id
        template.createdAt = dto.createdAt
        template.updatedAt = dto.updatedAt
        template.trainingBlock = dto.trainingBlockID.flatMap { trainingBlocksByID[$0] }
        workoutTemplatesByID[dto.id] = template
        modelContext.insert(template)
    }

    for dto in exportData.scheduledWorkouts {
        guard let workoutTemplate = dto.workoutTemplateID.flatMap({ workoutTemplatesByID[$0] }) else {
            continue
        }

        let workout = ScheduledWorkout(scheduledDate: dto.scheduledDate, workoutTemplate: workoutTemplate)
        workout.id = dto.id
        workout.notes = dto.notes
        workout.createdAt = dto.createdAt
        scheduledWorkoutsByID[dto.id] = workout
        modelContext.insert(workout)
    }

    for dto in exportData.workoutSchedules {
        guard let workoutTemplate = dto.workoutTemplateID.flatMap({ workoutTemplatesByID[$0] }) else {
            continue
        }

        let schedule = WorkoutSchedule(
            startDate: dto.startDate,
            endDate: dto.endDate,
            weekday: dto.weekday,
            workoutTemplate: workoutTemplate
        )
        schedule.id = dto.id
        modelContext.insert(schedule)
    }

    for dto in exportData.workoutExercises {
        guard let exercise = dto.exerciseID.flatMap({ exercisesByID[$0] }) else {
            continue
        }

        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            order: dto.order,
            targetSets: dto.targetSets,
            targetReps: dto.targetReps,
            targetDistance: dto.targetDistance,
            targetWeight: dto.targetWeight,
            restSeconds: dto.restSeconds,
            timeBeforeNext: dto.timeBeforeNext,
            notes: dto.notes,
            supersetID: dto.supersetID,
            supersetPosition: dto.supersetPosition
        )
        workoutExercise.id = dto.id
        workoutExercise.lineageID = dto.lineageID
        workoutExercise.workoutTemplate = dto.workoutTemplateID.flatMap { workoutTemplatesByID[$0] }
        workoutExercise.scheduledWorkout = dto.scheduledWorkoutID.flatMap { scheduledWorkoutsByID[$0] }
        workoutExercisesByID[dto.id] = workoutExercise
        modelContext.insert(workoutExercise)
    }

    for dto in exportData.workoutSessions {
        let scheduledWorkout = dto.scheduledWorkoutID.flatMap { scheduledWorkoutsByID[$0] }
        let session = WorkoutSession(scheduledWorkout: scheduledWorkout)
        session.id = dto.id
        session.startedAt = dto.startedAt
        session.completedAt = dto.completedAt
        workoutSessionsByID[dto.id] = session
        modelContext.insert(session)

        scheduledWorkout?.session = session
    }

    for dto in exportData.performedExercises {
        let performedExercise = PerformedExercise(
            exerciseName: dto.exerciseName,
            targetSets: dto.targetSets,
            targetReps: dto.targetReps,
            targetDistance: dto.targetDistance,
            targetWeight: dto.targetWeight,
            orderIndex: dto.orderIndex,
            supersetID: dto.supersetID,
            supersetPosition: dto.supersetPosition,
            elapsed: dto.elapsed,
            beforeNextCompleted: dto.beforeNextCompleted
        )
        performedExercise.id = dto.id
        performedExercise.sourceExercise = dto.sourceExerciseID.flatMap { workoutExercisesByID[$0] }
        performedExercise.workoutSession = dto.workoutSessionID.flatMap { workoutSessionsByID[$0] }
        performedExercisesByID[dto.id] = performedExercise
        modelContext.insert(performedExercise)
    }

    for dto in exportData.performedSets {
        let set = PerformedSet(
            setNumber: dto.setNumber,
            weight: dto.weight,
            reps: dto.reps,
            duration: dto.duration,
            distance: dto.distance
        )
        set.id = dto.id
        set.completed = dto.completed
        set.performedExercise = dto.performedExerciseID.flatMap { performedExercisesByID[$0] }
        modelContext.insert(set)
    }

    try? modelContext.save()
}

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (ExportData) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json], asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: (ExportData) -> Void

        init(onPick: @escaping (ExportData) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                let exportData = try decoder.decode(ExportData.self, from: data)
                onPick(exportData)
            } catch {
                print("Error loading or decoding file: \(error)")
            }
        }
    }
}
