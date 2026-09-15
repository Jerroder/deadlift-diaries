// Now your calendar is literally a collection of ScheduledWorkout

import SwiftData
import SwiftUI

@Model
final class ScheduledWorkout {
    var id: UUID = UUID()
    var scheduledDate: Date = Date()
    var notes: String?
    var createdAt: Date = Date()

    // The template to use
    var workoutTemplate: WorkoutTemplate?

    // If this scheduled workout has been started/completed
    var session: WorkoutSession?

    init(scheduledDate: Date, workoutTemplate: WorkoutTemplate) {
        self.scheduledDate = scheduledDate
        self.workoutTemplate = workoutTemplate
        self.createdAt = Date()
    }
}
