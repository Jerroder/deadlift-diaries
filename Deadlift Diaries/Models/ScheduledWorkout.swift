// Now your calendar is literally a collection of ScheduledWorkout

import SwiftData
import SwiftUI

@Model
final class ScheduledWorkout {
    @Attribute(.unique)
    var id: UUID
    
    var scheduledDate: Date
    
    var notes: String?
    
    var createdAt: Date
    
    // The template to use
    var workoutTemplate: WorkoutTemplate?
    
    // If this scheduled workout has been started/completed
    var session: WorkoutSession?
    
    init(
        scheduledDate: Date,
        workoutTemplate: WorkoutTemplate
    ) {
        self.id = UUID()
        self.scheduledDate = scheduledDate
        self.workoutTemplate = workoutTemplate
        self.createdAt = Date()
    }
}
