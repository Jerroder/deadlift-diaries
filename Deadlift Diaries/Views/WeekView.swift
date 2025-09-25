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
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        List {
            ForEach(mesocycle.weeks.sorted { $0.startDate < $1.startDate }, id: \.id) { week in
                weekRow(for: week)
            }
            .onDelete(perform: deleteWeeks)
        }
        .navigationTitle(mesocycle.name)
        .navigationBarBackButtonHidden(editMode?.wrappedValue.isEditing == true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                leadingToolbarItems
            }
            ToolbarItemGroup(placement: .primaryAction) {
                trailingToolbarItems
            }
        }
        .environment(\.editMode, Binding(
            get: { editMode?.wrappedValue ?? .inactive },
            set: { editMode?.wrappedValue = $0 }
        ))
    }
    
    @ViewBuilder
    private func weekRow(for week: Week) -> some View {
        let isPast = {
            let endDate = Calendar.current.date(byAdding: .day, value: 6, to: week.startDate)!
            return Calendar.current.startOfDay(for: endDate) < Calendar.current.startOfDay(for: Date())
        }()
        
        NavigationLink {
            WorkoutView(week: week)
        } label: {
            VStack(alignment: .leading) {
                Text("Week \(week.number)")
                    .font(.headline)
                Text("Start: \(week.startDate.formattedRelative())")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            .opacity(isPast ? 0.5 : 1.0)
        }
    }
    
    @ViewBuilder
    private var leadingToolbarItems: some View {
        if editMode?.wrappedValue.isEditing == true {
            Menu {
                Button(action: {
                    print("test")
                }) {
                    Label("info".localized(comment: "Info"), systemImage: "info.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    @ViewBuilder
    private var trailingToolbarItems: some View {
        EditButton()
        
        Button("", systemImage: "plus") {
            let newWeekNumber = (mesocycle.weeks.map { $0.number }.max() ?? 0) + 1
            let lastWeekStartDate = mesocycle.weeks.sorted { $0.startDate < $1.startDate }.last?.startDate ?? mesocycle.startDate
            let newWeekStartDate = Calendar.current.date(byAdding: .day, value: 7, to: lastWeekStartDate)!
            
            let newWeek = Week(number: newWeekNumber, startDate: newWeekStartDate)
            mesocycle.weeks.append(newWeek)
            newWeek.mesocycle = mesocycle
            modelContext.insert(newWeek)
            mesocycle.numberOfWeeks = mesocycle.weeks.count
        }
    }
    
    private func deleteWeeks(offsets: IndexSet) {
        let weeks = mesocycle.weeks.sorted { $0.number < $1.number }
        for index in offsets {
            let week = weeks[index]
            modelContext.delete(week)
        }

        for (index, week) in mesocycle.weeks.sorted(by: { $0.number < $1.number }).enumerated() {
            week.number = index + 1
        }
    }
}
