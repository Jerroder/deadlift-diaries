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
    let isExpanded: Bool
    
    @Environment(\.editMode) private var editMode
    
    private let weightUnit: Unit = isMetricSystem() ? Unit(symbol: "kg") : Unit(symbol: "lbs")
    
    var body: some View {
        if editMode?.wrappedValue.isEditing == true {
            exerciseDetails()
        } else {
            exerciseDetails()
            
            if isExpanded {
                SetProgressView(exercise: exercise)
            }
        }
    }
    
    @ViewBuilder
    private func exerciseDetails() -> some View {
        VStack(alignment: .leading) {
            Text(exercise.exerciseName)
                .font(.headline)
            
            if let weight = exercise.targetWeight, weight != 0 {
                Text("weight_x".localized(with: weight, weightUnit.symbol, comment: "Weight: x kg"))
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            
            Text("sets_x".localized(with: exercise.targetSets, comment: "Sets: x"))
                .font(.subheadline)
                .foregroundColor(Color(UIColor.secondaryLabel))
            
            Text("reps_x".localized(with: exercise.targetReps, comment: "Reps: x"))
                .font(.subheadline)
                .foregroundColor(Color(UIColor.secondaryLabel))
            
            if let rest = exercise.sourceExercise?.restSeconds {
                Text("rest_x_sec".localized(with: rest, comment: "Rest: x sec"))
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct WorkoutSessionView: View {
    @Bindable var session: WorkoutSession
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var expandedExerciseID: UUID?
    
    private var sortedExercises: [PerformedExercise] {
        (session.exercises ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        List {
            ForEach(sortedExercises) { exercise in
                ExerciseCard(exercise: exercise, isExpanded: expandedExerciseID == exercise.id)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .listRowSeparator(.hidden)
                    .onTapGesture {
                        toggleExercise(exercise)
                    }
            }
            .onDelete(perform: deleteExercise)
            .onMove(perform: moveExercise)
        }
        .navigationTitle("Workout")
        .listStyle(.plain)
        .toolbar{
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }
    
    private func toggleExercise(_ exercise: PerformedExercise) {
        withAnimation {
            if expandedExerciseID == exercise.id {
                expandedExerciseID = nil
            } else {
                expandedExerciseID = exercise.id
            }
        }
    }
    
    private func deleteExercise(at offsets: IndexSet) {
        let exercises = session.exercises?.sorted { $0.orderIndex < $1.orderIndex } ?? []
        
        for index in offsets {
            let exercise = exercises[index]
            modelContext.delete(exercise)
        }
        
        try? modelContext.save()
    }
    
    private func moveExercise(from source: IndexSet, to destination: Int) {
        var exercises = sortedExercises
        
        exercises.move(fromOffsets: source, toOffset: destination)
        
        for (index, exercise) in exercises.enumerated() {
            exercise.orderIndex = index
        }
        
        try? modelContext.save()
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
        guard workoutSession == nil else { return }
        
        if let existingSession = scheduledWorkout.session {
            workoutSession = existingSession
            return
        }
        
        guard let template = scheduledWorkout.workoutTemplate else {
            return
        }
        
        let session = WorkoutSession(scheduledWorkout: scheduledWorkout)
        
        createPerformedExercises(from: template, session: session)
        
        modelContext.insert(session)
        
        scheduledWorkout.session = session
        workoutSession = session
        try? modelContext.save()
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
