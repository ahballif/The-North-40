//
//  GoalDetailView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/26/23.
//

import SwiftUI

struct GoalDetailView: View {
    
    public var updater = RefreshView()
    
    @State var selectedGoal: N40Goal
    @State private var selectedView = 0 // for diy tab view
    
    @State private var showingWhatToCreateConfirm = false
    @State private var showingEditGoalSheet = false
    
    @State private var showingEditEventSheet = false
    @State private var editEventEventType = N40Event.NON_REPORTABLE_TYPE
    
    
    var body: some View {
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
                }.background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: selectedGoal.color) ?? .clear)
                        .opacity(0.5)
                )
                
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
                        TimelineView(goal: selectedGoal).environmentObject(updater)
                        
                        //The Add Button
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                
                                Button(action: {showingWhatToCreateConfirm.toggle()}) {
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(Circle())
                                        .frame(minWidth: 50, maxWidth: 50)
                                        .padding(30)
                                }.confirmationDialog("chooseWhatToCreate", isPresented: $showingWhatToCreateConfirm) {
                                    Button {
                                        //New TODO Item
                                        editEventEventType = N40Event.TODO_TYPE
                                        showingEditEventSheet.toggle()
                                    } label: {
                                        let type = N40Event.EVENT_TYPE_OPTIONS[N40Event.TODO_TYPE]
                                        Label(type[0], systemImage: type[1])
                                    }
                                    Button {
                                        //("New Reportable Event")
                                        editEventEventType = N40Event.REPORTABLE_TYPE
                                        showingEditEventSheet.toggle()
                                    } label: {
                                        let type = N40Event.EVENT_TYPE_OPTIONS[N40Event.REPORTABLE_TYPE]
                                        Label(type[0], systemImage: type[1])
                                    }
                                    Button {
                                        //("New Unreportable Event")
                                        editEventEventType = N40Event.NON_REPORTABLE_TYPE
                                        showingEditEventSheet.toggle()
                                    } label: {
                                        let type = N40Event.EVENT_TYPE_OPTIONS[N40Event.NON_REPORTABLE_TYPE]
                                        Label(type[0], systemImage: type[1])
                                    }
                                    Button {
                                        //("New Sub Goal")
                                        showingEditGoalSheet.toggle()
                                    } label: {
                                        Label("New Sub-Goal", systemImage: "flag.checkered.2.crossed")
                                    }
                                } message: {
                                    Text("What would you like to add?")
                                }
                                .sheet(isPresented: $showingEditEventSheet, onDismiss: {updater.updater.toggle()}) {
                                    EditEventView(eventType: N40Event.EVENT_TYPE_OPTIONS[editEventEventType], attachingGoal: selectedGoal)
                                }
                                .sheet(isPresented: $showingEditGoalSheet, onDismiss: {updater.updater.toggle()}) {
                                    EditGoalView(editGoal: nil, parentGoal: selectedGoal)
                                }
                                
                            }
                        }
                    }
                }
                
                
                Spacer()
            }.background(Color(hex: selectedGoal.color)?.opacity(0.25))
            
        
    }
    
    
    
    
}


struct GoalInfoView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var selectedGoal: N40Goal
    
    @State private var isCompleted: Bool = false
    
    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("Description")
                        .bold()
                    Spacer()
                }
                HStack {
                    Text(selectedGoal.information)
                    Spacer()
                }
            }.padding()
            
            if (selectedGoal.hasDeadline) {
                Text("Deadline: \(selectedGoal.deadline.dateOnlyToString())")
            }
            
            if (selectedGoal.getAttachedPeople.count > 0) {
                VStack {
                    HStack{
                        Text("Attached People: ").bold()
                        Spacer()
                    }.padding()
                    ForEach(selectedGoal.getAttachedPeople) {person in
                        HStack {
                            NavigationLink(destination: PersonDetailView(selectedPerson: person)) {
                                Text("\(person.firstName) \(person.lastName)")
                            }.buttonStyle(.plain)
                            Spacer()
                        }.padding(.horizontal)
                            .padding(.vertical, 3)
                    }
                }
            }
            
            //Show Parent Goal
            if ((selectedGoal.endGoals ?? ([] as NSSet)).count > 0) {
                VStack {
                    HStack {
                        Text("End Goals: ").bold()
                        Spacer()
                    }.padding(.horizontal)
                    VStack {
                        ForEach(selectedGoal.getEndGoals) {goal in
                            NavigationLink(destination: GoalDetailView(selectedGoal: goal)) {
                                HStack {
                                    Text(goal.name).lineLimit(0)
                                    Spacer()
                                    if (goal.hasDeadline) {
                                        Text(goal.deadline.dateOnlyToString())
                                    }
                                }
                            }.buttonStyle(.plain)
                                .padding(.horizontal)
                                .padding(.vertical, 3)
                        }
                    }
                }
            }
            
            
            //Show child goals
            if ((selectedGoal.subGoals ?? ([] as NSSet)).count > 0) {
                VStack {
                    HStack {
                        Text("Intermediate Landmark Goals: ").bold()
                        Spacer()
                    }.padding(.horizontal)
                    VStack {
                        ForEach(selectedGoal.getSubGoals) {goal in
                            NavigationLink(destination: GoalDetailView(selectedGoal: goal)) {
                                HStack {
                                    Text(goal.name).lineLimit(0)
                                    Spacer()
                                    if (goal.hasDeadline) {
                                        Text(goal.deadline.dateOnlyToString())
                                    }
                                }
                            }.buttonStyle(.plain)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            
            //Complete Goal HIGH FIVE
            Button {
                completeGoal()
            } label: {
                VStack {
                    if !isCompleted {
                        Image(systemName: "hand.wave")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200.0)
                            
                        Text("(High Five to Complete)")
                    } else {
                        Image(systemName: "hands.sparkles")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200.0)
                            
                        Text("Completed! on \(selectedGoal.dateCompleted.dateOnlyToString())")
                    }
                }
            }.padding()
            
            
            
        }.onAppear {
            isCompleted = selectedGoal.isCompleted
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
    
    private func completeGoal () {
        
        isCompleted.toggle()
        
        selectedGoal.isCompleted = isCompleted
        if isCompleted {
            selectedGoal.dateCompleted = Date()
            selectedGoal.deadline = Date()
        }
        
        do {
            try viewContext.save()
        }
        catch {
            // Handle Error
            print("Error info: \(error)")
        }
        
    }
    
    
}
