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
                            EditEventView(isScheduled: false, eventType: ["To-Do", "checklist"])
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
    @FetchRequest var unassignedToGoalToDos: FetchedResults<N40Event>
    
    @FetchRequest var allPeople: FetchedResults<N40Person>
    @FetchRequest var unassignedToPersonToDos: FetchedResults<N40Event>
    
    
    private let sortByOptions = ["Sort By Goals", "Sort By People", "Sort By Scheduled"]
    @State public var sortBySelected: String = "Sort By Goals"
    
    @State private var showingFutureEvents = false
    
    
    
    var body: some View {
        
        VStack {
            HStack {
                Picker("Sort by: ", selection: $sortBySelected) {
                    ForEach(sortByOptions, id: \.self) {
                        Text($0)
                    }
                }
                Spacer()
                Toggle("Show Future Events: ", isOn: $showingFutureEvents)
                
            }.padding()
            
            List {
                if (sortBySelected == sortByOptions[0]) {
                    //Sort by goal
                    
                    
                    //First the ones that aren't attached to goals
                    Section(header: Text("Unassigned To-Do Items")) {
                        ForEach(unassignedToGoalToDos) { todo in
                            
                            if (isFirstWithRecurringTag(recurringToDo: todo, allEventsInGroup: unassignedToGoalToDos.reversed())  || (todo.startDate.startOfDay < Date().endOfDay)) {
                                //check to see if it's not a future occurance of a repeating event.
                                
                                if (!(showingFutureEvents == false && todo.isScheduled && todo.startDate.startOfDay > Date().endOfDay)) {
                                    //now check if it's in the future after today
                                    
                                    HStack {
                                        
                                        //Button to check off the to-do
                                        Button(action: { completeToDoEvent(toDo: todo) }) {
                                            Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                                                .disabled((todo.status != 0))
                                        }.buttonStyle(PlainButtonStyle())
                                        NavigationLink(destination: EditEventView(editEvent: todo), label: {
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
                    // Now a section for each goal that has events. 
                    ForEach(allGoals) { goal in
                        
                        if goal.getTimelineEvents.filter({ $0.eventType == N40Event.TODO_TYPE && $0.status != N40Event.HAPPENED && !(showingFutureEvents == false && $0.isScheduled && $0.startDate.startOfDay > Date().endOfDay)}).count > 0 {
                            Section(header: Text("Goal: \(goal.name)")) {
                                
                                ForEach(unScheduledToDos.filter { $0.isAttachedToGoal(goal: goal) }, id: \.self) { todo in
                                    if (isFirstWithRecurringTag(recurringToDo: todo, allEventsInGroup: unScheduledToDos.filter { $0.isAttachedToGoal(goal: goal) })  || (todo.startDate.startOfDay < Date().endOfDay)) {
                                        
                                        if (!(showingFutureEvents == false && todo.isScheduled && todo.startDate.startOfDay > Date().endOfDay)) {
                                            //now check if it's in the future after today
                                            
                                            HStack {
                                                
                                                //Button to check off the to-do
                                                Button(action: { completeToDoEvent(toDo: todo) }) {
                                                    Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                                                        .disabled((todo.status != 0))
                                                }.buttonStyle(PlainButtonStyle())
                                                
                                                NavigationLink(destination: EditEventView(editEvent: todo), label: {
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
                                
                                ForEach(scheduledToDos.filter { $0.isAttachedToGoal(goal: goal) }, id: \.self) { todo in
                                    
                                    if (isFirstWithRecurringTag(recurringToDo: todo, allEventsInGroup: scheduledToDos.filter { $0.isAttachedToGoal(goal: goal) })  || (todo.startDate.startOfDay < Date().endOfDay)) {
                                        
                                        if (!(showingFutureEvents == false && todo.isScheduled && todo.startDate.startOfDay > Date().endOfDay)) {
                                            //now check if it's in the future after today
                                            
                                            HStack {
                                                
                                                //Button to check off the to-do
                                                Button(action: { completeToDoEvent(toDo: todo) }) {
                                                    Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                                                        .disabled((todo.status != 0))
                                                }.buttonStyle(PlainButtonStyle())
                                                
                                                NavigationLink(destination: EditEventView(editEvent: todo), label: {
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
                        }
                    }
                    
                    
                } else if (sortBySelected == sortByOptions[1]) {
                    //sort by people
                    
                    
                    // First a section for each person
                    ForEach(allPeople) { person in
                        
                        if person.getTimelineEvents.filter({ $0.eventType == N40Event.TODO_TYPE && $0.status != N40Event.HAPPENED && !(showingFutureEvents == false && $0.isScheduled && $0.startDate.startOfDay > Date().endOfDay)}).count > 0 {
                            Section(header: Text((person.title == "" ? "\(person.firstName)" : "\(person.title)") + " \(person.lastName)")) {
                                
                                ForEach(unScheduledToDos.filter { $0.isAttachedToPerson(person: person) }, id: \.self) { todo in
                                    if (isFirstWithRecurringTag(recurringToDo: todo, allEventsInGroup: unScheduledToDos.filter { $0.isAttachedToPerson(person: person) }) || (todo.startDate.startOfDay < Date().endOfDay)) {
                                        
                                        if (!(showingFutureEvents == false && todo.isScheduled && todo.startDate.startOfDay > Date().endOfDay)) {
                                            //now check if it's in the future after today
                                            
                                            HStack {
                                                
                                                //Button to check off the to-do
                                                Button(action: { completeToDoEvent(toDo: todo) }) {
                                                    Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                                                        .disabled((todo.status != 0))
                                                }.buttonStyle(PlainButtonStyle())
                                                
                                                NavigationLink(destination: EditEventView(editEvent: todo), label: {
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
                                
                                ForEach(scheduledToDos.filter { $0.isAttachedToPerson(person: person)}, id: \.self) { todo in
                                    
                                    if (isFirstWithRecurringTag(recurringToDo: todo, allEventsInGroup: scheduledToDos.filter { $0.isAttachedToPerson(person: person) })  || (todo.startDate.startOfDay < Date().endOfDay)) {
                                        
                                        if (!(showingFutureEvents == false && todo.isScheduled && todo.startDate.startOfDay > Date().endOfDay)) {
                                            //now check if it's in the future after today
                                            
                                            HStack {
                                                
                                                //Button to check off the to-do
                                                Button(action: { completeToDoEvent(toDo: todo) }) {
                                                    Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                                                        .disabled((todo.status != 0))
                                                }.buttonStyle(PlainButtonStyle())
                                                
                                                NavigationLink(destination: EditEventView(editEvent: todo), label: {
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
                        }
                    }
                    
                    //Now the ones that aren't attached to people
                    Section(header: Text("Unassigned To-Do Items")) {
                        ForEach(unassignedToPersonToDos) { todo in
                            
                            if (isFirstWithRecurringTag(recurringToDo: todo, allEventsInGroup: unassignedToPersonToDos.reversed())  || (todo.startDate.startOfDay < Date().endOfDay)) {
                                //check to see if it's not a future occurance of a repeating event.
                                
                                if (!(showingFutureEvents == false && todo.isScheduled && todo.startDate.startOfDay > Date().endOfDay)) {
                                    //now check if it's in the future after today
                                    
                                    HStack {
                                        
                                        //Button to check off the to-do
                                        Button(action: { completeToDoEvent(toDo: todo) }) {
                                            Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                                                .disabled((todo.status != 0))
                                        }.buttonStyle(PlainButtonStyle())
                                        NavigationLink(destination: EditEventView(editEvent: todo), label: {
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
                    
                    
                } else {
                    //Sort by unscheduled
                    
                    Section(header: Text("Unscheduled To-Do Items")) {
                        ForEach(unScheduledToDos) { todo in
                            if (isFirstWithRecurringTag(recurringToDo: todo, allEventsInGroup: unScheduledToDos.reversed())  || (todo.startDate.startOfDay < Date().endOfDay)) {
                                
                                if (!(showingFutureEvents == false && todo.isScheduled && todo.startDate.startOfDay > Date().endOfDay)) {
                                    //now check if it's in the future after today
                                    
                                    HStack {
                                        
                                        //Button to check off the to-do
                                        Button(action: { completeToDoEvent(toDo: todo) }) {
                                            Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                                                .disabled((todo.status != 0))
                                        }.buttonStyle(PlainButtonStyle())
                                        
                                        NavigationLink(destination: EditEventView(editEvent: todo), label: {
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
                        }.onDelete(perform: self.deleteUnscheduledToDoEvent)
                        
                    }
                    Section(header: Text("Scheduled To-Do Items")) {
                        ForEach(scheduledToDos) { todo in
                            if (isFirstWithRecurringTag(recurringToDo: todo, allEventsInGroup: scheduledToDos.reversed())  || (todo.startDate.startOfDay < Date().endOfDay)) {
                                
                                if (!(showingFutureEvents == false && todo.isScheduled && todo.startDate.startOfDay > Date().endOfDay)) {
                                    //now check if it's in the future after today
                                    
                                    HStack {
                                        
                                        //Button to check off the to-do
                                        Button(action: { completeToDoEvent(toDo: todo) }) {
                                            Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                                                .disabled((todo.status != 0))
                                        }.buttonStyle(PlainButtonStyle())
                                        
                                        NavigationLink(destination: EditEventView(editEvent: todo), label: {
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
                        }.onDelete(perform: self.deleteScheduledToDoEvent)
                    }
                }
                
                
            }.scrollContentBackground(.hidden)
                .listStyle(.sidebar)
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
        _unassignedToGoalToDos = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "eventType == %i", N40Event.TODO_TYPE), NSPredicate(format: "status != %i", N40Event.HAPPENED), NSPredicate(format: "attachedGoals.@count == 0")]), animation: .default)

        _allPeople = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)], animation: .default)
        _unassignedToPersonToDos = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "eventType == %i", N40Event.TODO_TYPE), NSPredicate(format: "status != %i", N40Event.HAPPENED), NSPredicate(format: "attachedPeople.@count == 0")]), animation: .default)
        
        
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
    
    
    private func isFirstWithRecurringTag (recurringToDo: N40Event, allEventsInGroup: [N40Event]) -> Bool {
        
        // if it's not a recurring event just say its the first one of it's kind
        if recurringToDo.recurringTag != "" {
            for eachEvent in allEventsInGroup {
                if eachEvent.recurringTag == recurringToDo.recurringTag {
                    if recurringToDo.startDate > eachEvent.startDate {
                        return false
                    }
                }
            }
        }
        
        return true
    }
}
