import SwiftUI
import SwiftData

enum WorkoutSessionRow: Identifiable {
    case exercise(PerformedExercise)
    case superset(first: PerformedExercise, second: PerformedExercise)
    
    var id: UUID {
        switch self {
        case .exercise(let exercise):
            return exercise.id
            
        case .superset(let first, _):
            return first.supersetID ?? first.id
        }
    }
    
    var orderIndex: Int {
        switch self {
        case .exercise(let exercise):
            return exercise.orderIndex
            
        case .superset(let first, _):
            return first.orderIndex
        }
    }
}

struct ExerciseCard: View {
    @Bindable var exercise: PerformedExercise
    let isExpanded: Bool
    let alignment: HorizontalAlignment
    let isLastExercise: Bool
    
    @Environment(\.editMode) private var editMode
    @Environment(\.modelContext) private var modelContext
    
    @State private var showHistory = false
    @State private var showEditSheet = false
    
    private let weightUnit: Unit = isMetricSystem() ? Unit(symbol: "kg") : Unit(symbol: "lbs")
    
    // The Exercise this session's exercise came from. Used to show its progress history.
    private var linkedExercise: Exercise? {
        exercise.sourceExercise?.exercise
    }
    
    private var targetText: String {
        if linkedExercise?.isTimeBased == true {
            return "duration_x_sec".localized(with: exercise.targetReps, comment: "Duration: x sec")
        } else if linkedExercise?.isDistanceBased == true {
            return "distance_x".localized(with: exercise.targetDistance, distanceUnit().symbol, comment: "Distance: x m")
        } else {
            return "reps_x".localized(with: exercise.targetReps, comment: "Reps: x")
        }
    }
    
    var body: some View {
        if editMode?.wrappedValue.isEditing == true {
            exerciseDetails()
                .contentShape(Rectangle())
                .onTapGesture {
                    if exercise.sourceExercise != nil {
                        showEditSheet = true
                    }
                }
                .sheet(isPresented: $showEditSheet) {
                    if let sourceExercise = exercise.sourceExercise {
                        AddExerciseView(
                            mode: .edit(sourceExercise),
                            onAdd: { updated in
                                exercise.syncTargets(from: updated, modelContext: modelContext)
                                updated.propagateToFollowingWorkouts(deleted: false, modelContext: modelContext)
                                try? modelContext.save()
                            },
                            onRemoveFromSuperset: sourceExercise.isInSuperset ? {
                                sourceExercise.removeFromSuperset(modelContext: modelContext)
                                try? modelContext.save()
                            } : nil
                        )
                    }
                }
        } else {
            exerciseDetails()
            
            if isExpanded {
                SetProgressView(exercise: exercise, isLastExercise: isLastExercise)
                    .contentShape(Rectangle())
                    .onTapGesture { }
            }
        }
    }
    
    @ViewBuilder
    private func exerciseDetails() -> some View {
        VStack(alignment: alignment) {
            HStack(spacing: 6) {
                Text(exercise.exerciseName)
                    .font(.headline)
                
                if let linkedExercise, editMode?.wrappedValue.isEditing != true {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showHistory) {
                        NavigationStack {
                            ExerciseHistoryView(
                                exercise: linkedExercise,
                                trainingBlock: exercise.sourceExercise?.scheduledWorkout?.workoutTemplate?.trainingBlock
                            )
                                .toolbar {
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button("", systemImage: "checkmark") {
                                            showHistory = false
                                        }
                                    }
                                }
                        }
                    }
                }
            }
            
            if let weight = exercise.targetWeight, weight != 0 {
                Text("weight_x".localized(with: weight, weightUnit.symbol, comment: "Weight: x kg"))
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            
            if alignment == .leading { // meaning not the superset
                Text("sets_x".localized(with: exercise.targetSets, comment: "Sets: x"))
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            
            Text(targetText)
                .font(.subheadline)
                .foregroundColor(Color(UIColor.secondaryLabel))
            
            if let rest = exercise.sourceExercise?.restSeconds, alignment == .leading {
                Text("rest_x_sec".localized(with: rest, comment: "Rest: x sec"))
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }
}

struct SupersetCard: View {
    let first: PerformedExercise
    let second: PerformedExercise
    let isLastExercise: Bool
    
    @Binding var expandedExerciseID: UUID?
    
    @Environment(\.editMode) private var editMode
    
    private var isExpanded: Bool {
        expandedExerciseID == first.id ||
        expandedExerciseID == second.id
    }
    
    var body: some View {
        if editMode?.wrappedValue.isEditing == true {
            exerciseDetails()
        } else {
            exerciseDetails()
            
            if isExpanded {
                SetProgressView(exercise: first, isLastExercise: isLastExercise)
                    .contentShape(Rectangle())
                    .onTapGesture { }
            }
        }
    }
    
    @ViewBuilder
    private func exerciseDetails() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                ExerciseCard(exercise: first, isExpanded: false, alignment: .leading, isLastExercise: isLastExercise)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                
                ExerciseCard(exercise: second, isExpanded: false, alignment: .trailing, isLastExercise: isLastExercise)
                .frame(maxWidth: .infinity, alignment: .topTrailing)
            }
            .contentShape(Rectangle())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            toggleExpansion()
        }
    }
    
    private func toggleExpansion() {
        withAnimation {
            if isExpanded {
                expandedExerciseID = nil
            } else {
                expandedExerciseID = first.id
            }
        }
    }
}


struct WorkoutSessionView: View {
    @Bindable var session: WorkoutSession
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    
    @State private var expandedExerciseID: UUID?
    @State private var showAddExerciseSheet: Bool = false
    
    private var nextExerciseOrder: Int {
        (session.exercises?.map(\.orderIndex).max() ?? -1) + 1
    }
    
    private var workoutRows: [WorkoutSessionRow] {
        let exercises = (session.exercises ?? [])
            .sorted {
                if $0.orderIndex != $1.orderIndex {
                    return $0.orderIndex < $1.orderIndex
                }
                
                return ($0.supersetPosition?.rawValue ?? 0) < ($1.supersetPosition?.rawValue ?? 0)
            }
        
        var rows: [WorkoutSessionRow] = []
        var index = 0
        
        while index < exercises.count {
            let exercise = exercises[index]
            
            guard let supersetID = exercise.supersetID else {
                rows.append(.exercise(exercise))
                index += 1
                continue
            }
            
            let supersetExercises = exercises.filter {
                $0.supersetID == supersetID
            }
            
            if let first = supersetExercises.first(where: { $0.supersetPosition == .first }),
               let second = supersetExercises.first(where: { $0.supersetPosition == .second }) {
                rows.append(.superset(first: first, second: second))
                
                index += supersetExercises.count
            } else { // Defensive fallback for malformed/incomplete data.
                rows.append(.exercise(exercise))
                index += 1
            }
        }
        
        return rows
    }
    
    var body: some View {
        List {
            ForEach(workoutRows) { row in
                let isLastExercise = row.id == workoutRows.last?.id
                
                switch row {
                case .exercise(let exercise):
                    ExerciseCard(exercise: exercise,
                                 isExpanded: expandedExerciseID == exercise.id, alignment: .leading,
                                 isLastExercise: isLastExercise)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .listRowSeparator(.hidden)
                    .onTapGesture {
                        toggleExercise(exercise)
                    }
                    
                case .superset(let first, let second):
                    SupersetCard(first: first, second: second, isLastExercise: isLastExercise,
                                 expandedExerciseID: $expandedExerciseID)
                        .listRowSeparator(.hidden)
                }
            }
            .onDelete(perform: deleteRow)
            .onMove(perform: moveRow)
        }
        .navigationTitle("workout".localized(comment: "Workout"))
        .listStyle(.plain)
        .toolbar{
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            if editMode?.wrappedValue.isEditing != true {
                if #available(iOS 26.0, *) {
                    Button(action: {
                        showAddExerciseSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22))
                            .padding([.leading, .trailing], 0)
                            .padding([.top, .bottom], 6)
                    }
                    .padding()
                    .buttonStyle(.glassProminent)
                } else {
                    Button(action: {
                        showAddExerciseSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22))
                            .padding([.leading, .trailing], 0)
                            .padding([.top, .bottom], 6)
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)
                    .clipShape(Circle())
                }
            }
        }
        .sheet(isPresented: $showAddExerciseSheet) {
            AddExerciseView(mode: .normal(order: nextExerciseOrder)) { workoutExercise in
                addExerciseToSession(workoutExercise)
            }
        }
    }
    
    private func addExerciseToSession(_ workoutExercise: WorkoutExercise) {
        if let scheduledWorkout = session.scheduledWorkout {
            workoutExercise.scheduledWorkout = scheduledWorkout
            scheduledWorkout.exercises?.append(workoutExercise)
        }
        
        modelContext.insert(workoutExercise)
        
        let performedExercise = PerformedExercise(from: workoutExercise, orderIndex: workoutExercise.order)
        performedExercise.sourceExercise = workoutExercise
        performedExercise.workoutSession = session
        
        modelContext.insert(performedExercise)
        session.exercises?.append(performedExercise)
        
        workoutExercise.propagateToFollowingWorkouts(deleted: false, modelContext: modelContext)
        
        try? modelContext.save()
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
    
    private func deleteRow(at offsets: IndexSet) {
        for index in offsets {
            let row = workoutRows[index]
            
            switch row {
            case .exercise(let exercise):
                deletePerformedExercise(exercise)
                
            case .superset(let first, let second):
                deletePerformedExercise(first)
                deletePerformedExercise(second)
            }
        }
        
        try? modelContext.save()
    }
    
    private func deletePerformedExercise(_ exercise: PerformedExercise) {
        if let sourceExercise = exercise.sourceExercise {
            sourceExercise.propagateToFollowingWorkouts(deleted: true, modelContext: modelContext)
            modelContext.delete(sourceExercise)
        }
        
        modelContext.delete(exercise)
    }
    
    private func moveRow(from source: IndexSet, to destination: Int) {
        var rows = workoutRows
        
        rows.move(fromOffsets: source, toOffset: destination)
        
        for (index, row) in rows.enumerated() {
            switch row {
            case .exercise(let exercise):
                exercise.orderIndex = index
                
            case .superset(let first, let second):
                first.orderIndex = index
                second.orderIndex = index
            }
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
        
        let session = WorkoutSession(scheduledWorkout: scheduledWorkout)
        
        createPerformedExercises(from: scheduledWorkout, session: session)
        
        modelContext.insert(session)
        
        scheduledWorkout.session = session
        workoutSession = session
        try? modelContext.save()
    }
    
    private func createPerformedExercises(from scheduledWorkout: ScheduledWorkout, session: WorkoutSession) {
        let exercises = scheduledWorkout.exercises?.sorted {
            if $0.order != $1.order {
                return $0.order < $1.order
            }
            
            return ($0.supersetPosition?.rawValue ?? 0) < ($1.supersetPosition?.rawValue ?? 0)
        } ?? []
        
        for exercise in exercises {
            let performedExercise = PerformedExercise(from: exercise, orderIndex: exercise.order)
            
            performedExercise.sourceExercise = exercise
            performedExercise.workoutSession = session
            session.exercises?.append(performedExercise)
        }
    }
}
