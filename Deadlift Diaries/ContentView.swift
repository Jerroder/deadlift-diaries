//
//  ContentView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-24.
//

import SwiftUI
import SwiftData

struct ProgramView: View {
    @State private var zStacks: [Int] = []
    @State private var textFieldText: String = "" // @TODO: change to an array

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack() {
                    ForEach(zStacks, id: \.self) { _ in
                        ZStack {
                            TextField("Program name", text: $textFieldText)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground).cornerRadius(10))
                                .font(.headline)
                        }.frame(maxWidth: .infinity)
                    }
                }.frame(maxWidth: .infinity).padding()
            }

            .navigationBarTitle("Programs", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    print("Edit button tapped!")
                }) {
                    Text("Edit")
                },
                trailing: Button(action: addStack) {
                    Image(systemName: "plus")
                }
            )
        }
    }
    
    private func addStack() {
        withAnimation {
            zStacks.append(zStacks.count)
        }
    }
}

struct TimerView: View {
    var body: some View {
        Text("Timer").font(.title)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            ProgramView().tabItem {
                Image(systemName: "calendar")
                Text("Programs")
            }
            
            TimerView().tabItem {
                Image(systemName: "timer")
                Text("Timer")
            }
        }
    }
}

#Preview {
    ContentView()
}
