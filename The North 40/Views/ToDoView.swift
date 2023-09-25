//
//  ToDoView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/17/23.
//

import SwiftUI
import CoreData

struct ToDoView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var updater: RefreshView = RefreshView()
    
    @State private var showingEditEventSheet = false
    
    //Only finds events that are to-do type (eventType == 3) and that are not fully completed (status == 3)
    
    @State private var showingInboxSheet = false
    @State private var sortBy = 2
    
    //This fetch request is only used for the badge.
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "eventType == %i", N40Event.TODO_TYPE), NSPredicate(format: "status != %i", N40Event.HAPPENED), NSPredicate(format: "isScheduled == NO")]), animation: .default)
    private var inboxToDos: FetchedResults<N40Event>
    
    var body: some View {
        NavigationView {
            ZStack {
                
                if sortBy == 0 {
                    SortedToDoList(sortBy: 0, showing: SortedToDoList.SCHEDULED_TODOS).environmentObject(updater)
                } else if sortBy == 1 {
                    SortedToDoList(sortBy: 1, showing: SortedToDoList.SCHEDULED_TODOS).environmentObject(updater)
                } else {
                    SortedToDoList(sortBy: 2, showing: SortedToDoList.SCHEDULED_TODOS).environmentObject(updater)
                }
                
                    
                
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
            .navigationTitle(Text("To-Do's Today"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingInboxSheet.toggle()
                    } label: {
                        Image(systemName: "tray")
                            .overlay(Badge(count: inboxToDos.count))
                    }
                    .sheet(isPresented: $showingInboxSheet, onDismiss: {updater.updater.toggle()}) {
                        NavigationView {
                            VStack {
                                Text("Inbox").font(.title2).padding()
                                SortedToDoList(showing: SortedToDoList.UNSCHEDULED_TODOS).environmentObject(updater)
                                Spacer()
                            }
                        }
                    }
                }
                
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        sortBy += 1
                        if sortBy >= 3 {sortBy = 0}
                        updater.updater.toggle()
                    } label: {
                        if sortBy == 0 {
                            Image(systemName: "person.2")
                        } else if sortBy == 1 {
                            Image(systemName: "list.number")
                        } else {
                            Image(systemName: "pencil.and.ruler.fill")
                        }
                    }
                }
            }
                
        }
        
    }
    
}

struct Badge: View {
    let count: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
            Text(String(count))
                .font(.system(size: 12))
                .padding(5)
                .background(Color.red)
                .clipShape(Circle())
                .foregroundColor(.white)
                // custom positioning in the top-right corner
                .alignmentGuide(.top) { $0[.bottom] }
                .alignmentGuide(.trailing) { $0[.trailing] - $0.width * 0.25 }
        }
    }
}

private let todayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mma"
    return formatter
}()

private let lateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, h:mma"
    return formatter
}()





struct SortedToDoList: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var updater: RefreshView
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)])
    private var allPeople: FetchedResults<N40Person>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.priorityIndex, ascending: false)], predicate: NSPredicate(format: "isCompleted == NO"))
    private var allUnfinishedGoals: FetchedResults<N40Goal>
    
    public var sortBy: Int = 0 //else sort by people
    public static let SORT_BY_GOALS = 0
    public static let SORT_BY_PEOPLE = 1
    public static let SORT_BY_DATE = 2
    
    @State private var showingFutureEvents = false
    
    public var showing: Int = 0
    public static let ALL_TODOS = 0
    public static let SCHEDULED_TODOS = 1
    public static let UNSCHEDULED_TODOS = 2
    public static let TODAY_TODOS = 3
    
    @State private var setOfToDos: [N40Event] = []
    
    public func loadSetOfToDos () {
        
        let fetchToDosRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
        fetchToDosRequest.sortDescriptors = [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)]
        fetchToDosRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "eventType == %i", N40Event.TODO_TYPE), NSPredicate(format: "status != %i", N40Event.HAPPENED)])
        
        do {
            // Peform Fetch Request
            let allToDos = try viewContext.fetch(fetchToDosRequest)
            
            //start with all
            setOfToDos = allToDos.reversed().sorted{ $0.startDate < $1.startDate }
            
            if showing == SortedToDoList.ALL_TODOS {
                //just leave it as is
            } else if showing == SortedToDoList.UNSCHEDULED_TODOS {
                setOfToDos = setOfToDos.filter({ $0.isScheduled == false })
            } else if showing == SortedToDoList.SCHEDULED_TODOS {
                setOfToDos = setOfToDos.filter({ $0.isScheduled == true })
            } else if showing == SortedToDoList.TODAY_TODOS {
                setOfToDos = setOfToDos.filter({ $0.isScheduled && $0.startDate < Date().endOfDay })
            }
            
            //now filter out future events if necessary
            if !showingFutureEvents {
                setOfToDos = setOfToDos.filter { $0.startDate < Date().endOfDay || $0.isScheduled == false }
            }
            
            //see if it's a recurring event that doesn't need to be shown
            setOfToDos = setOfToDos.filter({ isFirstWithRecurringTag(recurringToDo: $0, allEventsInGroup: allToDos.reversed())  || ($0.startDate.startOfDay < Date().endOfDay) })
            
            
            
        } catch {
            print("couldn't fetch")
        }
        
    }
    
    
    
    var body: some View {
        
        VStack {
            
            if setOfToDos.count > 0 {
                List {
                    
                    if (sortBy == 0) {
                        //Sort by goal
                        
                        
                        //First the ones that aren't attached to goals
                        let unassignedSetOfToDos = setOfToDos.filter({ $0.getAttachedGoals.count < 1})
                        if unassignedSetOfToDos.count > 0 {
                            Section(header: Text("Unassigned To-Do Items")) {
                                ForEach(unassignedSetOfToDos) { todo in
                                    ToDoListItem(todo: todo, updateFunction: loadSetOfToDos)
                                }
                            }
                        }
                        // Now a section for each goal that has events.
                        ForEach(allUnfinishedGoals) { goal in
                            let goalSetOfToDos = setOfToDos.filter({ $0.isAttachedToGoal(goal: goal)})
                            
                            if goalSetOfToDos.count > 0 {
                                Section(header: Text("\(goal.name)")) {
                                    ForEach(goalSetOfToDos) { todo in
                                        ToDoListItem(todo: todo, updateFunction: loadSetOfToDos)
                                    }
                                }
                            }
                        }
                        
                        
                        
                    } else if (sortBy == 1) {
                        //sort by people
                        
                        // First a section for each person
                        ForEach(allPeople) { person in
                            let personSetOfToDos = setOfToDos.filter({ $0.isAttachedToPerson(person: person)})
                            
                            if personSetOfToDos.count > 0 {
                                Section(header: Text((person.title == "" ? "\(person.firstName)" : "\(person.title)") + " \(person.lastName)")) {
                                    ForEach(personSetOfToDos) { todo in
                                        ToDoListItem(todo: todo, updateFunction: loadSetOfToDos)
                                    }
                                }
                            }
                        }
                        
                        //Now the ones that aren't attached to people
                        let unassignedSetOfToDos = setOfToDos.filter({ $0.getAttachedPeople.count < 1})
                        if unassignedSetOfToDos.count > 0 {
                            Section(header: Text("Unassigned To-Do Items")) {
                                ForEach(unassignedSetOfToDos) { todo in
                                    ToDoListItem(todo: todo, updateFunction: loadSetOfToDos)
                                }
                            }
                        }
                        
                        
                    } else {
                        ForEach(setOfToDos) {todo in
                            VStack(alignment: .trailing) {
                                ToDoListItem(todo: todo, updateFunction: loadSetOfToDos)
                                ForEach(todo.getAttachedGoals) {eachGoal in
                                    Text(eachGoal.name).font(.caption)
                                }
                            }
                        }
                    }
                    
                }.scrollContentBackground(.hidden)
                    .listStyle(.sidebar)
            } else {
                //show a congrats tab
                if showing == SortedToDoList.UNSCHEDULED_TODOS {
                    Text("You have no unscheduled To-Do Items.")
                } else {
                    Text("You have no to-do items today.")
                }
                Image(systemName: "bird")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                Text("You're on top of it!")
            }
        }.onAppear{
            loadSetOfToDos()
        }.onReceive(updater.$updater) {_ in
            loadSetOfToDos()
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

fileprivate struct ToDoListItem: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State public var todo: N40Event
    
    private var updateFunc: () -> Void
    
    init (todo: N40Event, updateFunction: @escaping () -> Void) {
        self.updateFunc = updateFunction
        self.todo = todo
    }
    
    var body: some View {
        
        HStack {
            
            //Button to check off the to-do
            Button{
                completeToDoEvent(toDo: todo)
                
            } label: {
                Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                    .disabled((todo.status != 0))
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: EditEventView(editEvent: todo), label: {
                HStack {
                    Text(todo.name)
                    
                    Spacer()
                    if (todo.isScheduled) {
                        if (todo.startDate < Date()) {
                            Text(todo.startDate, formatter: lateFormatter)
                                .foregroundColor(.red)
                        } else {
                            Text(todo.startDate, formatter: todayFormatter)
                            //Don't change color if it's not overdue
                        }
                    }
                }
            })
        }
    }
    
    
    private func completeToDoEvent (toDo: N40Event) {
        //checks off to do items or unchecks them
        
        if (toDo.status == 0) {
            withAnimation {
                toDo.status = 2
                
                updateFunc()
                
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    //Wait 2 seconds to change from attempted to completed so it doesn't disappear too quickly
                    if (toDo.status == 2) {
                        //This means it was checked off but hasn't been finally hidden
                        toDo.status = 3
                        updateFunc()
                        
                        if UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_ToDoView") {
                            toDo.startDate = Date()
                            toDo.isScheduled = true
                        }
                        
                        do {
                            try viewContext.save()
                        } catch {
                            // handle error
                        }
                    }
                }
            }
        } else {
            toDo.status = 0
            updateFunc()
            do {
                try viewContext.save()
            } catch {
                // handle error
            }
        }
    }
}
