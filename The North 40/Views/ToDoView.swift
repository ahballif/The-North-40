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
    @State private var showingBucketSheet = false
    @State private var sortBy = UserDefaults.standard.bool(forKey: "showTodayTodosFront") ? SortedToDoList.SORT_BY_DATE : SortedToDoList.SORT_BY_GOALS
    
    //This fetch request is only used for the badge.
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "eventType == %i", N40Event.TODO_TYPE), NSPredicate(format: "status != %i", N40Event.HAPPENED), NSPredicate(format: "isScheduled == NO"), NSPredicate(format: "bucketlist == NO")]), animation: .default)
    private var inboxToDos: FetchedResults<N40Event>
    
    var body: some View {
        NavigationView {
            ZStack {
                
                
                let showing = UserDefaults.standard.bool(forKey: "showTodayTodosFront") ? SortedToDoList.SCHEDULED_TODOS : SortedToDoList.ALL_TODOS
                if sortBy == SortedToDoList.SORT_BY_GOALS {
                    SortedToDoList(sortBy: SortedToDoList.SORT_BY_GOALS, showing: showing).environmentObject(updater)
                } else if sortBy == SortedToDoList.SORT_BY_PEOPLE {
                    SortedToDoList(sortBy: SortedToDoList.SORT_BY_PEOPLE, showing: showing).environmentObject(updater)
                } else {
                    SortedToDoList(sortBy: SortedToDoList.SORT_BY_DATE, showing: showing).environmentObject(updater)
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
                if UserDefaults.standard.bool(forKey: "showTodayTodosFront") {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            showingInboxSheet.toggle()
                        } label: {
                            if inboxToDos.count > 0 {
                                Image(systemName: "tray")
                                    .overlay(Badge(count: inboxToDos.count))
                            } else {
                                Image(systemName: "tray")
                            }
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
                        
                        Button {
                            showingBucketSheet.toggle()
                        } label: {
                            Image(systemName: "archivebox")
                        }
                        .sheet(isPresented: $showingBucketSheet, onDismiss: {updater.updater.toggle()}) {
                            NavigationView {
                                VStack {
                                    Text("Bucketlist").font(.title2).padding()
                                    SortedToDoList(showing: SortedToDoList.BUCKET_TODOS).environmentObject(updater)
                                    Spacer()
                                }
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
                
        }.navigationViewStyle(StackNavigationViewStyle())
        
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
private let lateFormatterDayOnly: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
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
    public static let BUCKET_TODOS = 4
    
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
                setOfToDos = setOfToDos.filter({ $0.isScheduled == false && $0.bucketlist == false })
            } else if showing == SortedToDoList.SCHEDULED_TODOS {
                setOfToDos = setOfToDos.filter({ $0.isScheduled == true })
            } else if showing == SortedToDoList.TODAY_TODOS {
                setOfToDos = setOfToDos.filter({ $0.isScheduled && $0.startDate < Date().endOfDay })
            } else if showing == SortedToDoList.BUCKET_TODOS {
                setOfToDos = setOfToDos.filter({ $0.isScheduled == false && $0.bucketlist == true })
            }
            
            //now filter out future events if necessary
            if !showingFutureEvents {
                setOfToDos = setOfToDos.filter { $0.startDate < Date().endOfDay || $0.isScheduled == false }
            }
            
            //see if it's a recurring event that doesn't need to be shown
            setOfToDos = setOfToDos.filter({ isFirstWithRecurringTag(recurringToDo: $0, allEventsInGroup: allToDos.reversed())  || ($0.startDate.startOfDay < Date().endOfDay) })
            
            
            //Add reportable type events if that setting is selected.
            if UserDefaults.standard.bool(forKey: "reportablesOnTodoList") {
                
                let fetchReportablesRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
                fetchReportablesRequest.sortDescriptors = [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)]
                fetchReportablesRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "eventType == %i", N40Event.REPORTABLE_TYPE), NSPredicate(format: "status == %i", N40Event.UNREPORTED)])
                
                do {
                    // Peform Fetch Request
                    let allReportables = try viewContext.fetch(fetchReportablesRequest)
                    
                    //start with all
                    var setOfReportables = allReportables.reversed().sorted{ $0.startDate < $1.startDate }
                    
                    //now filter out future events if necessary
                    if !showingFutureEvents {
                        setOfReportables = setOfReportables.filter { $0.startDate < Date().endOfDay || $0.isScheduled == false }
                    }
                    
                    if showing == SortedToDoList.ALL_TODOS {
                        //just leave it as is
                    } else if showing == SortedToDoList.UNSCHEDULED_TODOS {
                        setOfReportables = []
                    } else if showing == SortedToDoList.SCHEDULED_TODOS {
                        setOfReportables = setOfReportables.filter({ $0.isScheduled == true })
                    } else if showing == SortedToDoList.TODAY_TODOS {
                        setOfReportables = setOfReportables.filter({ $0.isScheduled && $0.startDate < Date().endOfDay })
                    } else if showing == SortedToDoList.BUCKET_TODOS {
                        setOfReportables = []
                    }
                    
                    //Add reportables to setOfToDos
                    setOfToDos.append(contentsOf: setOfReportables)
                    
                    //see if it's a recurring event that doesn't need to be shown
                    setOfToDos = setOfToDos.filter({ isFirstWithRecurringTag(recurringToDo: $0, allEventsInGroup: allToDos.reversed())  || ($0.startDate.startOfDay < Date().endOfDay) })
                    
                    //Sort it so the reportables arent all at the end.
                    setOfToDos = setOfToDos.sorted{ $0.startDate < $1.startDate}
                    
                } catch {
                    print("couldn't fetch")
                }
            }
            
            
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
                                    ToDoListItem(todo: todo, updateFunction: loadSetOfToDos, showing: showing)
                                }
                            }
                        }
                        // Now a section for each goal that has events.
                        ForEach(allUnfinishedGoals) { goal in
                            let goalSetOfToDos = setOfToDos.filter({ $0.isAttachedToGoal(goal: goal)})
                            
                            if goalSetOfToDos.count > 0 {
                                Section(header: Text("\(goal.name)")) {
                                    ForEach(goalSetOfToDos) { todo in
                                        ToDoListItem(todo: todo, updateFunction: loadSetOfToDos, showing: showing)
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
                                        ToDoListItem(todo: todo, updateFunction: loadSetOfToDos, showing: showing)
                                    }
                                }
                            }
                        }
                        
                        //Now the ones that aren't attached to people
                        let unassignedSetOfToDos = setOfToDos.filter({ $0.getAttachedPeople.count < 1})
                        if unassignedSetOfToDos.count > 0 {
                            Section(header: Text("Unassigned To-Do Items")) {
                                ForEach(unassignedSetOfToDos) { todo in
                                    ToDoListItem(todo: todo, updateFunction: loadSetOfToDos, showing: showing)
                                }
                            }
                        }
                        
                        
                    } else {
                        ForEach(setOfToDos) {todo in
                            VStack(alignment: .trailing) {
                                ToDoListItem(todo: todo, updateFunction: loadSetOfToDos, showing: showing)
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
                    
                    Image(systemName: "bird")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                    Text("You're on top of it!")
                } else if showing == SortedToDoList.BUCKET_TODOS {
                    
                    Text("You have no To-Do Items on your bucket list. ")
                    
                    
                } else {
                    Text("You have no more to-do items today.")
                    
                    Image(systemName: "bird")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                    Text("You're on top of it!")
                }
                
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
    
    @State private var showing: Int
    
    private var updateFunc: () -> Void
    
    init (todo: N40Event, updateFunction: @escaping () -> Void, showing: Int = SortedToDoList.TODAY_TODOS) {
        self.updateFunc = updateFunction
        self.todo = todo
        self.showing = showing
    }
    
    var body: some View {
        
        HStack {
            
            //Button to check off the to-do (only for ToDo Type)
            if todo.eventType == N40Event.TODO_TYPE {
                Button{
                    completeToDoEvent(toDo: todo)
                    
                } label: {
                    Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                        .disabled((todo.status != 0))
                }.buttonStyle(PlainButtonStyle())
            } else {
                //Put a button circle for reportable type
                if (todo.startDate < Date()) {
                    Image(systemName: "questionmark.circle.fill")
                        .resizable()
                        .foregroundColor(Color.orange)
                        .frame(width: 20, height:20)
                } else {
                    Image(systemName: "circle.dotted")
                        .resizable()
                        .frame(width: 20, height:20)
                }
            }
            NavigationLink(destination: EditEventView(editEvent: todo), label: {
                HStack {
                    Text(todo.name)
                    
                    Spacer()
                    if (todo.isScheduled) {
                        if (todo.startDate < Date()) {
                            Text(todo.startDate, formatter: todo.allDay ? lateFormatterDayOnly : lateFormatter)
                                .foregroundColor(.red)
                        } else {
                            if !todo.allDay { //Don't show the date if it's an all day event. 
                                Text(todo.startDate, formatter: todayFormatter)
                                //Don't change color if it's not overdue
                            }
                        }
                    }
                }
            })
        }
        .swipeActions {
            if todo.eventType == N40Event.TODO_TYPE {
                if showing == SortedToDoList.UNSCHEDULED_TODOS {
                    Button("Bucket") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation {
                                todo.bucketlist = true
                                
                                do {
                                    try viewContext.save()
                                } catch {
                                    // handle error
                                }
                                
                                updateFunc()
                            }
                        }
                    }
                    .tint(.pink)
                } else if showing == SortedToDoList.BUCKET_TODOS{
                    Button ("Unbucket") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation {
                                todo.bucketlist = false
                                
                                do {
                                    try viewContext.save()
                                } catch {
                                    // handle error
                                }
                                
                                updateFunc()
                            }
                        }
                    }
                    .tint(.pink)
                }
            }
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
                        withAnimation {
                            //This means it was checked off but hasn't been finally hidden
                            toDo.status = 3
                            updateFunc()
                            
                            if UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_ToDoView") {
                                toDo.startDate = Calendar.current.date(byAdding: .minute, value: -1*Int(toDo.duration), to: Date()) ?? Date()
                                toDo.isScheduled = true
                                if UserDefaults.standard.bool(forKey: "roundScheduleCompletedTodos") {
                                    //first make seconds 0
                                    toDo.startDate = Calendar.current.date(bySetting: .second, value: 0, of: toDo.startDate) ?? toDo.startDate
                                    
                                    //then find how much to change the minutes
                                    let minutes: Int = Calendar.current.component(.minute, from: toDo.startDate)
                                    let minuteInterval = Int(25.0/UserDefaults.standard.double(forKey: "hourHeight")*60.0)
                                    
                                    //now round it
                                    let roundedMinutes = Int(minutes / minuteInterval) * minuteInterval
                                    
                                    toDo.startDate = Calendar.current.date(byAdding: .minute, value: Int(roundedMinutes - minutes), to: toDo.startDate) ?? toDo.startDate
                                    
                                }
                            }
                            
                            do {
                                try viewContext.save()
                            } catch {
                                // handle error
                            }
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
