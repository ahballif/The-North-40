//
//  GoalListView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

import SwiftUI

struct GoalListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    private var updater: RefreshView = RefreshView()
    
    @State private var showingEditGoalSheet = false
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.priorityIndex, ascending: false)], predicate: NSPredicate(format: "isCompleted == NO"), animation: .default)
    private var fetchedUnfinishedGoals: FetchedResults<N40Goal>
    
    @State private var goalsArray: [N40Goal] = []
    
    @State private var isTiered = true
    
    var body: some View {
        
        NavigationView {
            ZStack {
                
                List {
                    ForEach(fetchedUnfinishedGoals) { goal in
                        if !isTiered {
                            GoalBoard(goal).environmentObject(updater)
                        } else {
                            if goal.getEndGoals.count == 0 {
                                GoalBoard(goal).environmentObject(updater)
                                ForEach(goal.getSubGoals, id: \.self) {subGoal in
                                    if !subGoal.isCompleted {
                                        GoalBoard(subGoal)
                                            .environmentObject(updater)
                                            .padding(.leading, 25.0)
                                    }
                                }
                            }
                        }
                    }.onMove(perform: move)
                }.scrollContentBackground(.hidden)
                    .listStyle(.plain)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if !isTiered {
                            EditButton()
                        }
                        NavigationLink(destination: CompletedGoalsList().environmentObject(updater)) {
                            
                            Label("Completed", systemImage: "graduationcap.fill")
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            redistributePriorityIndices()
                            isTiered.toggle()
                        } label: {
                            if isTiered {
                                Image(systemName: "list.number")
                            } else {
                                Image(systemName: "list.bullet.indent")
                            }
                        }
                    }
                }
                
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        Button(action: {showingEditGoalSheet.toggle()}) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .clipShape(Circle())
                                .frame(minWidth: 50, maxWidth: 50)
                                .padding(30)
                        }
                        .sheet(isPresented: $showingEditGoalSheet) {
                            EditGoalView(editGoal: nil)
                            
                        }
                    }
                }
                
                
            }
            .navigationTitle(Text("Goals"))
            .navigationBarTitleDisplayMode(.inline)
                
        }.onAppear {
            goalsArray = fetchedUnfinishedGoals.reversed().sorted {
                $0.priorityIndex > $1.priorityIndex
            }
            redistributePriorityIndices()
        }
        
        
    }
    
    
    
    
    func move(from source: IndexSet, to destination: Int) {
        goalsArray.move(fromOffsets: source, toOffset: destination)
        redistributePriorityIndices()
        
    }
    
    
    
    private func redistributePriorityIndices () {
        var nextPriorityIndex = goalsArray.count - 1
        goalsArray.forEach {goal in
            goal.priorityIndex = Int16(nextPriorityIndex)
            nextPriorityIndex -= 1
        }
        
        do {
            try viewContext.save()
        }
        catch {
            // Handle Error
            print("Error info: \(error)")
        }
        updater.updater.toggle()
    }
    
    
}

struct GoalBoard: View {
    @EnvironmentObject var updater: RefreshView
    
    
    @State private var goal: N40Goal
    
    private let headerHeight = 50.0
    
    @State private var collapsed = true
    
    init(_ goal: N40Goal) {
        self.goal = goal
    }
    
    var body: some View {
        return VStack {
            VStack {
                //header
                NavigationLink(destination: GoalDetailView(selectedGoal: goal)) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .foregroundColor(Color(hex: goal.color))
                            .opacity(1.0)
                            .frame(height: headerHeight)
                        
                        HStack {
                            Text(goal.name)
                            Spacer()
                        }.padding()
                    }
                }.buttonStyle(PlainButtonStyle())
                VStack {
                    //detail flap
                    HStack {
                        Button {
                            withAnimation {
                                collapsed.toggle()
                            }
                        } label: {
                            Image(systemName: (collapsed ? "chevron.forward" : "chevron.down"))
                        }.buttonStyle(PlainButtonStyle())
                        if !goal.isCompleted {
                            if goal.hasDeadline {
                                Text("By: \(goal.deadline.dateOnlyToString())")
                            } else {
                                Text("No Deadline")
                            }
                        } else {
                            Text("Completed: \(goal.dateCompleted.dateOnlyToString())")
                        }
                        Spacer()
                    }
                    
                    if !collapsed {
                        //details:
                        
                        if goal.isCompleted && goal.hasDeadline {
                            Text("Deadline was: \(goal.deadline.dateOnlyToString())")
                        }
                        
                        if ((goal.endGoals ?? ([] as NSSet)).count > 0) {
                            VStack {
                                HStack {
                                    Text("End Goals: ").bold()
                                    Spacer()
                                }.padding(.horizontal)
                                VStack {
                                    ForEach(goal.getEndGoals) {eachEndGoal in
                                        HStack {
                                            Text(eachEndGoal.name).lineLimit(0)
                                            Spacer()
                                            if (eachEndGoal.hasDeadline) {
                                                Text(eachEndGoal.deadline.dateOnlyToString())
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.leading, 10)
                                    }
                                }
                            }
                        }
                        if ((goal.subGoals ?? ([] as NSSet)).count > 0) {
                            VStack {
                                HStack {
                                    Text("Intermediate Landmark Goals: ").bold()
                                    Spacer()
                                }.padding(.horizontal)
                                VStack {
                                    ForEach(goal.getSubGoals) {eachSubGoal in
                                        HStack {
                                            Text(eachSubGoal.name).lineLimit(0)
                                            Spacer()
                                            if (eachSubGoal.hasDeadline) {
                                                Text(eachSubGoal.deadline.dateOnlyToString())
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.leading, 10)
                                    }
                                }
                            }
                        }
                        if ((goal.attachedPeople ?? ([] as NSSet)).count > 0) {
                            VStack {
                                HStack {
                                    Text("Attached People: ").bold()
                                    Spacer()
                                }.padding(.horizontal)
                                VStack {
                                    ForEach(goal.getAttachedPeople) {eachPerson in
                                        HStack {
                                            Text((eachPerson.title == "" ? "\(eachPerson.firstName)" : "\(eachPerson.title)") + " \(eachPerson.lastName)").lineLimit(0)
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        .padding(.leading, 10)
                                    }
                                }
                            }
                        }
                        if !goal.isCompleted {
                            VStack {
                                HStack {
                                    Text("Next event: ")
                                    Spacer()
                                    if goal.getNextEventDate != nil {
                                        Text(goal.getNextEventDate!.formatToShortDate())
                                    }
                                }
                                HStack {
                                    Text("\(goal.getFutureEvents.count) plans made. ")
                                    Spacer()
                                }
                                HStack {
                                    Text(String(format: "%.0f", 100.0*goal.getPercentTodosFinished)+"% todo's completed.")
                                    Spacer()
                                }
                                
                            }.padding(.horizontal)
                            
                        }
                        
                        
                    }
                }.padding(.horizontal)
                    .padding(.bottom)
            }.background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: goal.color)!)
                    .opacity(0.5)
            )
        }
    }
    
    
    
    
    
    private func formatDate(dateToFormat: Date) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return dateFormatter.string(from: dateToFormat)
    }
}


struct GoalListView_Previews: PreviewProvider {
    static var previews: some View {
        GoalListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}


fileprivate extension Date {
    
    func formatToShortDate () -> String {
        let dateFormatter = DateFormatter()

        
        dateFormatter.dateFormat = "M/d/YY, h:mm a"
        
        // Convert Date to String
        return dateFormatter.string(from: self)
    }
    
}




// Completed Goals list:


struct CompletedGoalsList: View {
    @EnvironmentObject var updater: RefreshView
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.dateCompleted, ascending: false)], predicate: NSPredicate(format: "isCompleted == YES"), animation: .default)
    private var fetchedCompletedGoals: FetchedResults<N40Goal>
    
    
    var body: some View {
        //Completed Goals list
        VStack {
            HStack {
                Text("Completed").font(.title2)
                Spacer()
            }
            List {
                ForEach(fetchedCompletedGoals) { goal in
                    GoalBoard(goal).environmentObject(updater)
                }
            }.listStyle(.plain)
        }.padding()
    }
}
