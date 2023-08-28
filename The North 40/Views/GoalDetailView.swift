//
//  GoalDetailView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/26/23.
//

import SwiftUI

struct GoalDetailView: View {
    
    @State var selectedGoal: N40Goal
    @State private var selectedView = 0 // for diy tab view
    
    @State private var showingEditEventSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                
                ZStack {
                    Text(selectedGoal.name)
                        .font(.title)
                    HStack {
                        Spacer()
                        NavigationLink(destination: EditGoalView(editGoal: selectedGoal)) {
                            Label("", systemImage: "pencil")
                        }
                    }.padding()
                }
                
                HStack {
                    
                    if (selectedView == 0) {
                        Button {
                            selectedView = 0
                        } label: {
                            Text("Info")
                                .frame(maxWidth: .infinity)
                        }
                        .font(.title2)
                        .buttonStyle(.borderedProminent)
                        
                    } else {
                        Button {
                            selectedView = 0
                        } label: {
                            Text("Info")
                                .frame(maxWidth: .infinity)
                        }
                        .font(.title2)
                        .buttonStyle(.bordered)
                    }
                    
                    
                    if (selectedView == 1) {
                        Button {
                            selectedView = 1
                        } label: {
                            Text("Timeline")
                                .frame(maxWidth: .infinity)
                        }
                        .font(.title2)
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            selectedView = 1
                        } label: {
                            Text("Timeline")
                                .frame(maxWidth: .infinity)
                        }
                        .font(.title2)
                        .buttonStyle(.bordered)
                    }
                    
                    
                    
                }
                .padding()
                .frame(maxWidth: .infinity)
                
                
                if (selectedView==0) {
                    GoalInfoView(selectedGoal: selectedGoal)
                } else if (selectedView==1) {
                    ZStack {
                        TimelineView(events: selectedGoal.getTimelineEvents)
                        
                        //The Add Button
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                
                                Button(action: {showingEditEventSheet.toggle()}) {
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(Circle())
                                        .frame(minWidth: 50, maxWidth: 50)
                                        .padding(30)
                                }
                                .sheet(isPresented: $showingEditEventSheet) {
                                    EditEventView(attachingGoal: selectedGoal)
                                }
                            }
                        }
                    }
                }
                
                
                Spacer()
            }
            
        }
    }
}


struct GoalInfoView: View {
    
    @ObservedObject var selectedGoal: N40Goal
    
    
    var body: some View {
        ScrollView {
            Text("Description")
            Text(selectedGoal.information)
            if (selectedGoal.hasDeadline) {
                Text("Deadline: \(dateToString(input: selectedGoal.deadline))")
            }
        }
    }
    
    private func dateToString(input: Date) -> String {
        // Create Date Formatter
        let dateFormatter = DateFormatter()

        // Set Date/Time Style
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        return dateFormatter.string(from: input)
    }
    
    
}
