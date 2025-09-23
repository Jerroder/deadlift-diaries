//
//  WeekView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-06-06.
//

import SwiftUI
import SwiftData

struct WeekView: View {
    let mesocycle: Mesocycle
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            ForEach(mesocycle.weeks.sorted { $0.startDate < $1.startDate }, id: \.id) { week in
                NavigationLink {
                    WorkoutView(week: week)
                } label: {
                    VStack(alignment: .leading) {
                        Text("Week \(week.number)")
                            .font(.headline)
                        Text("Start: \(week.startDate.formatted(.dateTime.day().month().year()))")
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle(mesocycle.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("", systemImage: "plus") {
                    let newWeekNumber = (mesocycle.weeks.map { $0.number }.max() ?? 0) + 1
                    let lastWeekStartDate = mesocycle.weeks.sorted { $0.startDate < $1.startDate }.last?.startDate ?? mesocycle.startDate
                    let newWeekStartDate = Calendar.current.date(byAdding: .day, value: 7, to: lastWeekStartDate)!
                    
                    let newWeek = Week(
                        number: newWeekNumber,
                        startDate: newWeekStartDate
                    )
                    mesocycle.weeks.append(newWeek)
                    newWeek.mesocycle = mesocycle
                    modelContext.insert(newWeek)
                }
            }
        }
    }
}

