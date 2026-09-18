import SwiftUI
import SwiftData

struct SetRow: View {
    @Bindable var set: PerformedSet
    
    var body: some View {
        HStack {
            Toggle("", isOn: $set.completed)
                .labelsHidden()
            
            TextField("kg", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
            
            TextField("reps", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
        }
    }
}

struct ExerciseCard: View {
    @Bindable var exercise: PerformedExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.exerciseName)
                .font(.headline)
            
            Text("\(exercise.targetSets) x \(exercise.targetReps)" +
                 (exercise.targetWeight != nil ? " @ \(exercise.targetWeight!) kg" : "")
            )
            .foregroundStyle(.secondary)
            
            SetProgressView(exercise: exercise)
        }
        .padding(.vertical)
    }
}

struct WorkoutSessionView: View {
    @Bindable var session: WorkoutSession
    
    var body: some View {
        List {
            ForEach(session.exercises?.sorted { $0.orderIndex < $1.orderIndex } ?? []) { exercise in
                ExerciseCard(exercise: exercise)
            }
        }
        .navigationTitle("Workout")
    }
}

struct ExerciseView: View {
    let scheduledWorkout: ScheduledWorkout
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var workoutSession: WorkoutSession?
    
    var body: some View {
        Group {
            if let workoutSession {
                WorkoutSessionView(session: workoutSession)
            } else {
                ProgressView()
            }
        }
        .task {
            startWorkout()
        }
    }
    
    private func startWorkout() {
        // Prevent creating duplicates when SwiftUI redraws
        guard workoutSession == nil else {
            return
        }
        
        guard let template = scheduledWorkout.workoutTemplate else {
            return
        }
        
        let session = WorkoutSession(scheduledWorkout: scheduledWorkout)
        
        createPerformedExercises(from: template, session: session)
        
        modelContext.insert(session)
        workoutSession = session
    }
    
    private func createPerformedExercises(from template: WorkoutTemplate, session: WorkoutSession) {
        let exercises = template.exercises?.sorted { $0.order < $1.order } ?? []
        
        for (index, exercise) in exercises.enumerated() {
            let performedExercise = PerformedExercise(from: exercise, orderIndex: index)
            
            performedExercise.sourceExercise = exercise
            performedExercise.workoutSession = session
            session.exercises?.append(performedExercise)
        }
    }
}
