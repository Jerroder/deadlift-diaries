//
//  DateExtension.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-09-25.
//

import Foundation

extension Date {
    func formattedRelative() -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInTomorrow(self) {
            return "Tomorrow"
        } else {
            return self.formatted(.dateTime.day().month())
        }
    }
}
