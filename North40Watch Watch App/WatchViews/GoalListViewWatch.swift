//
//  GoalListViewWatch.swift
//  North40Watch Watch App
//
//  Created by Addison Ballif on 9/4/24.
//

import SwiftUI
import CoreData

struct GoalListViewWatch: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingEditGoalSheet = false // for creating goals
    @State private var showingCompletedGoalsSheet = false
    @State private var showingArchivedGoalsSheet = false
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.priorityIndex, ascending: false)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "isCompleted == NO"), NSPredicate(format: "isArchived == NO")]) )
    private var currentGoals: FetchedResults<N40Goal>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.name, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "isCompleted == NO"), NSPredicate(format: "isArchived == YES")]) )
    private var archivedGoals: FetchedResults<N40Goal>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.dateCompleted, ascending: false)], predicate: NSPredicate(format: "isCompleted == YES"))
    private var completedGoals: FetchedResults<N40Goal>
    
    
    
    
    @State public var isNavigationViewStacked: Bool
    
    init (isNavigationViewStacked: Bool = false) {
        _isNavigationViewStacked = State(initialValue: isNavigationViewStacked)
    }
    
    
    var body: some View {
        NavigationView {
            ZStack {
                
                List {
                    ForEach(currentGoals.sorted(by: {$0.priorityIndex > $1.priorityIndex})) {goal in
                        goalBoard(goal)
                            .padding(.leading, goal.endGoalLayers == 3 ? 60 : goal.endGoalLayers == 2 ? 45 : goal.endGoalLayers == 1 ? 25 : 0)
                            .swipeActions {
                                Button {
                                    goal.isArchived = true
                                    withAnimation {
                                        recalculatePriorityIndices()
                                    }

                                } label: {
                                    Image(systemName: "archivebox")
                                }
                            }
                    }.onMove(perform: move)
                    
                }.scrollContentBackground(.hidden)
                    .listStyle(.plain)
                
                
                
                
            }
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        HStack{
                            Button {
                                showingArchivedGoalsSheet.toggle()
                            } label: {
                                Image(systemName: "archivebox")
                            }.sheet(isPresented: $showingArchivedGoalsSheet) {
                                NavigationStack {
                                    List {
                                        ForEach(archivedGoals.sorted(by: {$0.name.uppercased() < $1.name.uppercased()})) {goal in
                                            goalBoard(goal)
                                                .swipeActions {
                                                    Button {
                                                        goal.isArchived = false
                                                        withAnimation {
                                                            recalculatePriorityIndices()
                                                        }
                                                    } label: {
                                                        Image(systemName: "shippingbox.and.arrow.backward")
                                                    }
                                                }
                                        }
                                    }.scrollContentBackground(.hidden)
                                        .listStyle(.plain)
                                        .navigationTitle(Text("Archived Goals"))
                                        .navigationBarTitleDisplayMode(.inline)
                                    
                                }
                            }
                            Button {
                                showingCompletedGoalsSheet.toggle()
                            } label: {
                                Image(systemName: "graduationcap.fill")
                            }.sheet(isPresented: $showingCompletedGoalsSheet) {
                                NavigationStack {
                                    List {
                                        ForEach(completedGoals) {goal in
                                            goalBoard(goal)
                                        }
                                    }.scrollContentBackground(.hidden)
                                        .listStyle(.plain)
                                        .navigationTitle(Text("Completed"))
                                        .navigationBarTitleDisplayMode(.inline)
                                    
                                }
                            }
                        }
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        HStack {
                            Spacer()
                            Button(action: {showingEditGoalSheet.toggle()}) {
                                Image(systemName: "plus.circle")
                            }
                            .sheet(isPresented: $showingEditGoalSheet) {
                                GoalViewWatch(editGoal: nil)
                                
                            }
                        }
                    }
                    
                }
        }
    }
    
    
    func move(from source: IndexSet, to destination: Int) {
        withAnimation {
            recalculatePriorityIndices(moving: true, source: source, destination: destination)
        }
    }
    
    private func recalculatePriorityIndices(moving: Bool = false, source: IndexSet = IndexSet(), destination: Int = 0) {
        
        var setOfGoals: [N40Goal] = []
        for eachGoal in currentGoals {
            setOfGoals.append(eachGoal)
        }
        setOfGoals = setOfGoals.sorted {$0.priorityIndex > $1.priorityIndex}
        
        if moving {
            setOfGoals.move(fromOffsets: source, toOffset: destination)
        }
        
        var currentPriorityIndex = Int16(setOfGoals.count)
        for goal in setOfGoals {
            //set the priority indices based on goal parent relationship .
            if goal.getEndGoals.count == 0 { //only goes 4 layers deep
                //This is an end goal.
                goal.priorityIndex = currentPriorityIndex
                currentPriorityIndex -= 1
                
                for subGoal in goal.getSubGoals {
                    if setOfGoals.contains(subGoal) {
                        subGoal.priorityIndex = currentPriorityIndex
                        currentPriorityIndex -= 1
                        
                        for subSubGoal in subGoal.getSubGoals {
                            if setOfGoals.contains(subSubGoal) {
                                subSubGoal.priorityIndex = currentPriorityIndex
                                currentPriorityIndex -= 1
                                
                                for subSubSubGoal in subSubGoal.getSubGoals {
                                    if setOfGoals.contains(subSubSubGoal) {
                                        subSubSubGoal.priorityIndex = currentPriorityIndex
                                        currentPriorityIndex -= 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            // Handle Error
            print("Error info: \(error)")
        }
    }
    
    //vision note for vision sheet
    private func getVisionNote () -> N40Note {
        var visionNote: N40Note? = nil
        
        let fetchVisionNote: NSFetchRequest<N40Note> = N40Note.fetchRequest()
        fetchVisionNote.sortDescriptors = [NSSortDescriptor(keyPath: \N40Note.date, ascending: false)]
        fetchVisionNote.predicate = NSPredicate(format: "title == 'Life Vision'")
        
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
            
            newNote.title = "Life Vision"
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
    
    
    private func goalBoard(_ goal: N40Goal) -> some View {
        
        return VStack {
            NavigationLink(destination: GoalViewWatch(editGoal: goal)) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color(hex: goal.color))
                        .opacity(0.65)
                        .frame(height: 50.0)
                    VStack{
                        HStack{
                            //Text(String(goal.priorityIndex))
                            Text(goal.name)
                            Spacer()
                        }
                        HStack{
                            if !goal.isCompleted {
                                if goal.hasDeadline {
                                    Text("By: \(goal.deadline.dateOnlyToString())").font(.caption)
                                    Spacer()
                                }
                            } else {
                                Text("Completed: \(goal.dateCompleted.dateOnlyToString())").font(.caption)
                                Spacer()
                            }
                        }
                    }.padding(.horizontal)
                        .padding(.vertical, 5)
                }
            }
        }
    }
    
}

