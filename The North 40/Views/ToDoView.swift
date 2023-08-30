//
//  ToDoView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/17/23.
//

import SwiftUI

struct ToDoView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingEditEventSheet = false
    @State private var sortByGoals = true
    //Only finds events that are to-do type (eventType == 3) and that are not fully completed (status == 3)
    

    
    var body: some View {
        NavigationView {
            ZStack {
                
            
                SortedToDoList()
                    
                
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
                            EditEventView(isSheet: true, isScheduled: false, eventType: ["To-Do", "checklist"])
                            //Here I passed in some default values that I know you would want probably want when making a to-do item
                            
                        }
                    }
                }
                
                
            }
            .navigationTitle(Text("All To-Do Items"))
            .navigationBarTitleDisplayMode(.inline)
                
        }
        
    }
    
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, h:mma"
    return formatter
}()


struct ToDoView_Previews: PreviewProvider {
    static var previews: some View {
        ToDoView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}




struct SortedToDoList: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest var scheduledToDos: FetchedResults<N40Event>
    @FetchRequest var unScheduledToDos: FetchedResults<N40Event>
    
    @FetchRequest var allGoals: FetchedResults<N40Goal>
    @FetchRequest var unassignedToDos: FetchedResults<N40Event>
    
    @State public var sortByGoals: Bool = true
    
    var body: some View {
        
        VStack {
            HStack {
                Text("Sort By Goals: ")
                Spacer()
                Toggle("", isOn: $sortByGoals)
            }.padding()
            
            List {
                if (sortByGoals) {
                    ForEach(allGoals) { goal in
                        
                        if goal.getTimelineEvents.count > 0 {
                            Section(header: Text("Goal: \(goal.name)")) {
                                
                                ForEach(unScheduledToDos.filter { $0.isAttachedToGoal(goal: goal) }, id: \.self) { todo in
                                    
                                    HStack {
                                        
                                        //Button to check off the to-do
                                        Button(action: { completeToDoEvent(toDo: todo) }) {
                                            Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                                                .disabled((todo.status != 0))
                                        }.buttonStyle(PlainButtonStyle())
                                        
                                        NavigationLink(destination: EditEventView(editEvent: todo, isSheet: false), label: {
                                            HStack {
                                                Text(todo.name)
                                                
                                                Spacer()
                                                if (todo.isScheduled) {
                                                    if (todo.startDate < Date()) {
                                                        Text(todo.startDate, formatter: itemFormatter)
                                                            .foregroundColor(.red)
                                                    } else {
                                                        Text(todo.startDate, formatter: itemFormatter)
                                                        //Don't change color if it's not overdue
                                                    }
                                                }
                                            }
                                        })
                                    }
                                    
                                    
                                }
                                
                                ForEach(scheduledToDos.filter { $0.isAttachedToGoal(goal: goal) }, id: \.self) { todo in
                                    
                                    HStack {
                                        
                                        //Button to check off the to-do
                                        Button(action: { completeToDoEvent(toDo: todo) }) {
                                            Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                                                .disabled((todo.status != 0))
                                        }.buttonStyle(PlainButtonStyle())
                                        
                                        NavigationLink(destination: EditEventView(editEvent: todo, isSheet: false), label: {
                                            HStack {
                                                Text(todo.name)
                                                
                                                Spacer()
                                                if (todo.isScheduled) {
                                                    if (todo.startDate < Date()) {
                                                        Text(todo.startDate, formatter: itemFormatter)
                                                            .foregroundColor(.red)
                                                    } else {
                                                        Text(todo.startDate, formatter: itemFormatter)
                                                        //Don't change color if it's not overdue
                                                    }
                                                }
                                            }
                                        })
                                    }
                                    
                                    
                                }
                                
                            }
                        }
                    }
                    
                    //Now the ones that aren't attached to goals
                    Section(header: Text("Unassigned To-Do Items")) {
                        ForEach(unassignedToDos) { todo in
                            HStack {
                                
                                //Button to check off the to-do
                                Button(action: { completeToDoEvent(toDo: todo) }) {
                                    Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                                        .disabled((todo.status != 0))
                                }.buttonStyle(PlainButtonStyle())
                                
                                NavigationLink(destination: EditEventView(editEvent: todo, isSheet: false), label: {
                                    HStack {
                                        Text(todo.name)
                                        
                                        Spacer()
                                        if (todo.isScheduled) {
                                            if (todo.startDate < Date()) {
                                                Text(todo.startDate, formatter: itemFormatter)
                                                    .foregroundColor(.red)
                                            } else {
                                                Text(todo.startDate, formatter: itemFormatter)
                                                //Don't change color if it's not overdue
                                            }
                                        }
                                    }
                                })
                            }
                        }
                    }
                } else {
                    Section(header: Text("Unscheduled To-Do Items")) {
                        ForEach(unScheduledToDos) { todo in
                            
                            HStack {
                                
                                //Button to check off the to-do
                                Button(action: { completeToDoEvent(toDo: todo) }) {
                                    Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                                        .disabled((todo.status != 0))
                                }.buttonStyle(PlainButtonStyle())
                                
                                NavigationLink(destination: EditEventView(editEvent: todo, isSheet: false), label: {
                                    HStack {
                                        Text(todo.name)
                                        
                                        Spacer()
                                        if (todo.isScheduled) {
                                            if (todo.startDate < Date()) {
                                                Text(todo.startDate, formatter: itemFormatter)
                                                    .foregroundColor(.red)
                                            } else {
                                                Text(todo.startDate, formatter: itemFormatter)
                                                //Don't change color if it's not overdue
                                            }
                                        }
                                    }
                                })
                            }
                        }.onDelete(perform: self.deleteUnscheduledToDoEvent)
                        
                    }
                    Section(header: Text("Scheduled To-Do Items")) {
                        ForEach(scheduledToDos) { todo in
                            
                            HStack {
                                
                                //Button to check off the to-do
                                Button(action: { completeToDoEvent(toDo: todo) }) {
                                    Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                                        .disabled((todo.status != 0))
                                }.buttonStyle(PlainButtonStyle())
                                
                                NavigationLink(destination: EditEventView(editEvent: todo, isSheet: false), label: {
                                    HStack {
                                        Text(todo.name)
                                        
                                        Spacer()
                                        if (todo.isScheduled) {
                                            if (todo.startDate < Date()) {
                                                Text(todo.startDate, formatter: itemFormatter)
                                                    .foregroundColor(.red)
                                            } else {
                                                Text(todo.startDate, formatter: itemFormatter)
                                                //Don't change color if it's not overdue
                                            }
                                        }
                                    }
                                })
                            }
                        }.onDelete(perform: self.deleteScheduledToDoEvent)
                    }
                }
                
                
            }.scrollContentBackground(.hidden)
                .listStyle(.grouped)
        }
    }
    
    init () {
        var unscheduledPredicates: [NSPredicate] = [NSPredicate(format: "eventType == %i", 3), NSPredicate(format: "isScheduled == NO")]
        var scheduledPredicates: [NSPredicate] = [NSPredicate(format: "eventType == %i", 3), NSPredicate(format: "isScheduled == YES")]
        
        
        unscheduledPredicates.append(NSPredicate(format: "status != %i", 3))
        scheduledPredicates.append(NSPredicate(format: "status != %i", 3))
        
        
        _scheduledToDos = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)],predicate: NSCompoundPredicate(type: .and, subpredicates: scheduledPredicates), animation: .default)
        _unScheduledToDos = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)],predicate: NSCompoundPredicate(type: .and, subpredicates: unscheduledPredicates), animation: .default)
        
        _allGoals = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.name, ascending: true)], animation: .default)
        _unassignedToDos = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "eventType == %i", 3), NSPredicate(format: "status != %i", 3), NSPredicate(format: "attachedGoals.@count == 0")]), animation: .default)

        
    }
    
    private func completeToDoEvent (toDo: N40Event) {
        //checks off to do items or unchecks them
        
        if (toDo.status == 0) {
            toDo.status = 2
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                //Wait 2 seconds to change from attempted to completed so it doesn't disappear too quickly
                if (toDo.status == 2) {
                    //This means it was checked off but hasn't been finally hidden
                    toDo.status = 3
                    //toDo.startDate = Date() //Set it as completed now. 
                    do {
                        try viewContext.save()
                    } catch {
                        // handle error
                    }
                }
            }
        } else {
            toDo.status = 0
            
            do {
                try viewContext.save()
            } catch {
                // handle error
            }
        }
    }
    
    
    private func deleteUnscheduledToDoEvent(offsets: IndexSet) {
        // deletes list items
        
        withAnimation {
            offsets.map { unScheduledToDos[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // handle error
            }
        }
    }
    private func deleteScheduledToDoEvent(offsets: IndexSet) {
        // deletes list items
        
        withAnimation {
            offsets.map { scheduledToDos[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // handle error
            }
        }
    }
}
