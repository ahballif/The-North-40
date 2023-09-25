//
//  GoalListView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

import SwiftUI
import CoreData

struct GoalListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    private var listUpdater: RefreshView = RefreshView()
    
    @State private var showingEditGoalSheet = false
    @State private var showingVisionSheet = false
    
    @State private var setOfGoals: [N40Goal] = []
    
    @State private var isTiered = true
    
    
    var body: some View {
        
        NavigationView {
            ZStack {
                
                List {
                    ForEach(setOfGoals) { goal in
                        if !isTiered {
                            GoalBoard(goal).environmentObject(listUpdater)
                        } else {
                            if goal.getEndGoals.count == 0 {
                                GoalBoard(goal).environmentObject(listUpdater)
                                ForEach(goal.getSubGoals, id: \.self) {subGoal in
                                    if !subGoal.isCompleted {
                                        GoalBoard(subGoal)
                                            .environmentObject(listUpdater)
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
                        NavigationLink(destination: CompletedGoalsList().environmentObject(listUpdater)) {
                            
                            Label("Completed", systemImage: "graduationcap.fill")
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            loadSetOfGoals()
                            isTiered.toggle()
                            
                        } label: {
                            if isTiered {
                                Image(systemName: "list.number")
                            } else {
                                Image(systemName: "list.bullet.indent")
                            }
                        }
                        
                        Button {
                            showingVisionSheet.toggle()
                        } label: {
                            Image(systemName: "location.north.circle")
                        }
                        .sheet(isPresented: $showingVisionSheet) {
                            EditNoteView(editNote: getVisionNote())
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
                        .sheet(isPresented: $showingEditGoalSheet, onDismiss: { listUpdater.updater.toggle() }) {
                            EditGoalView(editGoal: nil)
                            
                        }
                    }
                }
                
                
            }
            .navigationTitle(Text("Goals"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadSetOfGoals()
            }
                
        }.onReceive(listUpdater.$updater) {_ in
            loadSetOfGoals()
        }
        
        
    }
    
    private func loadSetOfGoals () {
        let fetchGoalsRequest: NSFetchRequest<N40Goal> = N40Goal.fetchRequest()
        fetchGoalsRequest.sortDescriptors = [NSSortDescriptor(keyPath: \N40Goal.priorityIndex, ascending: false)]
        fetchGoalsRequest.predicate = NSPredicate(format: "isCompleted == NO")
        
        do {
            // Peform Fetch Request
            let allGoals = try viewContext.fetch(fetchGoalsRequest)
            
            setOfGoals = allGoals.reversed().sorted { $0.priorityIndex > $1.priorityIndex }
            
            calculatePriorityIndices()
            
            
        } catch {
            print("couldn't fetch goals")
        }
        
        
    }
    
    private func calculatePriorityIndices () {
        var i = setOfGoals.count - 1
        for goal in setOfGoals {
            goal.priorityIndex = Int16(i)
            i -= 1
        }
        
        do {
            try viewContext.save()
        } catch {
            // Handle Error
            print("Error info: \(error)")
        }
    }
    
    
    func move(from source: IndexSet, to destination: Int) {
        setOfGoals.move(fromOffsets: source, toOffset: destination)
        calculatePriorityIndices()
        loadSetOfGoals()
    }
    
    
    //vision note for vision sheet
    private func getVisionNote () -> N40Note {
        var visionNote: N40Note? = nil
        
        let fetchVisionNote: NSFetchRequest<N40Note> = N40Note.fetchRequest()
        fetchVisionNote.sortDescriptors = [NSSortDescriptor(keyPath: \N40Note.date, ascending: false)]
        fetchVisionNote.predicate = NSPredicate(format: "title == '_Life Vision_'")
        
        do {
            // Peform Fetch Request
            let fetchedVisionNotes = try viewContext.fetch(fetchVisionNote)
            
            if fetchedVisionNotes.count < 1 {
                //we need to make one
            } else if fetchedVisionNotes.count > 1 {
                print("There are multiple vision notes")
                visionNote = fetchedVisionNotes.reversed()[0]
            } else {
                visionNote = fetchedVisionNotes.reversed()[0]
            }
            
            
        } catch {
            print("couldn't fetch vision note")
        }
        
        if visionNote == nil {
            let newNote = N40Note(context: viewContext)
            
            newNote.title = "_Life Vision_"
            newNote.information = "My visions for my life: "
            newNote.date = Date()
            
            do {
                try viewContext.save()
            }
            catch {
                // Handle Error
                print("Error info: \(error)")
            }
            
            visionNote = newNote
        }
        
        return visionNote!
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
                            Button {
                                withAnimation {
                                    collapsed.toggle()
                                }
                            } label: {
                                Image(systemName: (collapsed ? "chevron.forward" : "chevron.down"))
                            }.buttonStyle(PlainButtonStyle())
                            
                            Text(goal.name)
                            Spacer()
                        }.padding()
                    }
                }.buttonStyle(PlainButtonStyle())
                
                
                VStack {
                    //detail flap
                    HStack {
                        if !goal.isCompleted {
                            if goal.hasDeadline {
                                Text("By: \(goal.deadline.dateOnlyToString())")
                                Spacer()
                            }
                        } else {
                            Text("Completed: \(goal.dateCompleted.dateOnlyToString())")
                            Spacer()
                        }
                        
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
            .onDisappear{updater.updater.toggle()}
    }
}
