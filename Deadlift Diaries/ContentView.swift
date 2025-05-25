//
//  ContentView.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-05-24.
//

import SwiftUI
import SwiftData

struct ProgramView: View {
    @State private var textFields: [String] = []

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    ForEach(textFields.indices, id: \.self) { index in
                        ZStack {
                            RoundedRectangle(cornerRadius: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Corner Radius@*/10.0/*@END_MENU_TOKEN@*/)
                                .fill(Color(UIColor.secondarySystemBackground))
                            VStack {
                                TextField("Program name", text: $textFields[index])
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground).cornerRadius(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=Corner Radius@*/10.0/*@END_MENU_TOKEN@*/))
                                    .font(.headline)
                                Text("sdfsdfsdfsdf")
                                    .padding()
                            }.frame(maxWidth: .infinity)
                        }
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
                trailing: Button(action: addString) {
                    Image(systemName: "plus")
                }
            )
        }
    }

    private func addString() {
        withAnimation {
            textFields.append("")
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
