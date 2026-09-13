// Now your calendar is literally a collection of ScheduledWorkout

import SwiftData
import SwiftUI

enum WorkoutStatus: Codable {
    case planned
    case completed
    case skipped
}

@Model
final class ScheduledWorkout {
    var id: UUID = UUID()

    var date: Date = Date()

    var workout: WorkoutTemplate?

    var trainingBlock: TrainingBlock?

    var notes: String = ""

    var status: WorkoutStatus = WorkoutStatus.planned

    init(
        date: Date,
        workout: WorkoutTemplate? = nil,
        trainingBlock: TrainingBlock? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.workout = workout
        self.trainingBlock = trainingBlock
    }
}
