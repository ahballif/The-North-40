//
//  ToDoView3.swift
//  The North 40
//
//  Created by Addison Ballif on 12/20/23.
//

import SwiftUI

struct ToDoView3: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingEditEventSheet = false
    
    @State private var showingInboxSheet = false
    @State private var showingBucketlist = false //this is determines what is displayed on the inbox sheet.
    
    //either we sort by goals or we don't, and if we don't we sort by date.
    @State private var sortByGoals = UserDefaults.standard.bool(forKey: "todoSortByGoals")
    
    private let numberOfDaysAhead = 30
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "eventType == %i", N40Event.TODO_TYPE), NSPredicate(format: "status != %i", N40Event.HAPPENED)]), animation: .default)
    private var mainTodos: FetchedResults<N40Event> // all undone scheduled todos
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "eventType == %i", N40Event.REPORTABLE_TYPE), NSPredicate(format: "status == %i", N40Event.UNREPORTED)]), animation: .default)
    private var mainReportables: FetchedResults<N40Event> // all undone scheduled reportables
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "eventType == %i", N40Event.TODO_TYPE), NSPredicate(format: "status != %i", N40Event.HAPPENED), NSPredicate(format: "bucketlist == NO"), NSPredicate(format: "isScheduled == NO")]), animation: .default)
    private var inboxTodos: FetchedResults<N40Event> // all unscheduled todos not in the bucketlist
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "eventType == %i", N40Event.TODO_TYPE), NSPredicate(format: "status != %i", N40Event.HAPPENED), NSPredicate(format: "bucketlist == YES"), NSPredicate(format: "isScheduled == NO")]), animation: .default)
    private var bucketlistTodos: FetchedResults<N40Event> // all unscheduled todos in the bucketlist
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.priorityIndex, ascending: false)])
    private var allGoals: FetchedResults<N40Goal>
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                //The main list
                VStack {
                    if sortByGoals { //the two sort by options are different enough to render differently.
                        List {
                            let noGoalTodos = mainTodos.filter { $0.getAttachedGoals.count < 1 && (!$0.isScheduled || $0.startDate < Date().endOfDay)}
                            let noGoalReportables = mainReportables.filter { $0.getAttachedGoals.count < 1 && (!$0.isScheduled || $0.startDate < Date().endOfDay)}
                            let noGoalSet = (UserDefaults.standard.bool(forKey: "reportablesOnTodoList") ? noGoalTodos + noGoalReportables : noGoalTodos).sorted {$0.startDate < $1.startDate}
                            //since unassigned todays are only today or unscheduled, we don't need to filter out repeats in the future.
                            if noGoalSet.count > 0 {
                                Section(header: Text("Unassigned To-Do Items")) {
                                    ForEach(noGoalSet) {eachEvent in
                                        toDoCell(eachEvent)
                                    }
                                }
                            }
                            
                            ForEach(allGoals) {eachGoal in
                                if eachGoal.getEndGoals.count == 0 {
                                    //only display if it's an end goal (sub goals will be under)
                                    let goalSet = eachGoal.getTimelineEvents.filter { ($0.eventType == N40Event.TODO_TYPE && $0.status != N40Event.HAPPENED) || ($0.eventType == N40Event.REPORTABLE_TYPE && UserDefaults.standard.bool(forKey: "reportablesOnTodoList") && $0.eventType == N40Event.UNREPORTED) }.filter{$0.isNextRecurringEvent(vc: viewContext) || $0.startDate < Date()}.sorted {$0.startDate < $1.startDate}
                                    if getTotalAttachedToDos(eachGoal) > 0 {
                                        Section(header: Text(eachGoal.name)) {
                                            ForEach(goalSet) {eachEvent in
                                                toDoCell(eachEvent)
                                            }
                                        }.headerProminence(.increased)
                                        //now sub goals
                                        ForEach(eachGoal.getSubGoals) {eachSubGoal in
                                            //only display if it's an end goal (sub goals will be under)
                                            let subGoalSet = eachSubGoal.getTimelineEvents.filter { ($0.eventType == N40Event.TODO_TYPE && $0.status != N40Event.HAPPENED) || ($0.eventType == N40Event.REPORTABLE_TYPE && UserDefaults.standard.bool(forKey: "reportablesOnTodoList") && $0.eventType == N40Event.UNREPORTED) }.filter{$0.isNextRecurringEvent(vc: viewContext) || $0.startDate < Date()}.sorted {$0.startDate < $1.startDate}
                                            if subGoalSet.count > 0 {
                                                Section(header: Text(eachSubGoal.name)) {
                                                    ForEach(subGoalSet) {eachEvent in
                                                        toDoCell(eachEvent)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                }
                            }
                        }
                        
                    } else { //sort by date
                        List {
                            let fullSet = getFullSetOfToDos()
                            
                            
                            
                            ForEach(fullSet) {eachEvent in
                                let i = fullSet.firstIndex(of: eachEvent) ?? 0

                                if i == 0 {
                                    if eachEvent.startDate < Date().startOfDay {
                                        //draw the overdue title
                                        dateDivider(altText: "Overdue").moveDisabled(true)
                                    } else {
                                        //draw the today divider
                                        dateDivider(Date()).moveDisabled(true)

                                        //draw the message if the first event is not today
                                        if eachEvent.startDate > Date().endOfDay {
                                            HStack {
                                                Image(systemName: "bird")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .padding(5)
                                                VStack{
                                                    Text("You don't have any more To-Do's today. You're on top of it!")
                                                }
                                            }.moveDisabled(true)

                                            dateDivider(eachEvent.startDate).moveDisabled(true)
                                        }


                                    }

                                } else {
                                    let lastEvent = fullSet[i-1]

                                    //draw the message if there are none today
                                    if eachEvent.startDate > Date().endOfDay && lastEvent.startDate < Date().startOfDay {
                                        //draw the today divider
                                        dateDivider(Date()).moveDisabled(true)

                                        Text("You have no To-Do's today, but you do have some overdue To-Do's").moveDisabled(true)
                                    }

                                    //draw the day divider
                                    if eachEvent.startDate.startOfDay > lastEvent.startDate.endOfDay && eachEvent.startDate >= Date().startOfDay {
                                        //(overdue events don't get day dividers)

                                        dateDivider(eachEvent.startDate).moveDisabled(true)
                                    }


                                }


                                toDoCell(eachEvent)
                            }.onMove(perform: move)
                        
                        }.listStyle(.plain)
                    }
                }
                
                //The add button
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
            }.toolbar{
                ToolbarItemGroup(placement: .navigationBarLeading){
                    if !sortByGoals {
                        Button {
                            showingBucketlist = false
                            showingInboxSheet.toggle()
                        } label: {
                            if inboxTodos.count > 0 {
                                Image(systemName: "tray")
                                    .overlay(Badge(count: inboxTodos.count))
                            } else {
                                Image(systemName: "tray")
                            }
                        }
                        Button {
                            showingBucketlist = true
                            showingInboxSheet.toggle()
                        } label: {
                            Image(systemName: "archivebox")
                        }.sheet(isPresented: $showingInboxSheet) { [showingBucketlist] in
                            //The inbox and bucket sheet list
                            NavigationStack{
                                VStack {
                                    if (!showingBucketlist && inboxTodos.count > 0) || (showingBucketlist && bucketlistTodos.count > 0) {
                                        List {
                                            
                                            let noGoalSet = (!showingBucketlist ? inboxTodos : bucketlistTodos).filter { $0.getAttachedGoals.count < 1}.sorted {$0.startDate < $1.startDate}
                                            //since unassigned todays are only today or unscheduled, we don't need to filter out repeats in the future.
                                            if noGoalSet.count > 0 {
                                                Section(header: Text("Unassigned To-Do Items")) {
                                                    ForEach(noGoalSet) {eachEvent in
                                                        toDoCell(eachEvent)
                                                            .swipeActions {
                                                                if showingBucketlist {
                                                                    Button("Unbucket", role: .destructive) {
                                                                        eachEvent.bucketlist = false
                                                                        
                                                                        do {
                                                                            try viewContext.save()
                                                                        } catch {
                                                                            // handle error
                                                                        }
                                                                    }
                                                                    .tint(.cyan)
                                                                } else {
                                                                    Button("Bucket", role: .destructive) {
                                                                        eachEvent.bucketlist = true
                                                                        
                                                                        do {
                                                                            try viewContext.save()
                                                                        } catch {
                                                                            // handle error
                                                                        }
                                                                    }
                                                                    .tint(.cyan)
                                                                }
                                                            }
                                                            .contextMenu {
                                                                //just have both!
                                                                if showingBucketlist {
                                                                    Button("Unbucket") {
                                                                        eachEvent.bucketlist = false
                                                                        
                                                                        do {
                                                                            try viewContext.save()
                                                                        } catch {
                                                                            // handle error
                                                                        }
                                                                    }
                                                                    
                                                                } else {
                                                                    Button("Bucket") {
                                                                        eachEvent.bucketlist = true
                                                                        
                                                                        do {
                                                                            try viewContext.save()
                                                                        } catch {
                                                                            // handle error
                                                                        }
                                                                    }
                                                                    
                                                                }
                                                            }
                                                    }
                                                }
                                            }
                                            
                                            ForEach(allGoals) {eachGoal in
                                                if eachGoal.getEndGoals.count == 0 {
                                                    //only display if it's an end goal (sub goals will be under)
                                                    let goalSet = (!showingBucketlist ? inboxTodos : bucketlistTodos).filter{ $0.isAttachedToGoal(goal: eachGoal) }.sorted {$0.startDate < $1.startDate}
                                                    if getTotalAttachedToDos(eachGoal) > 0 {
                                                        Section(header: Text(eachGoal.name)) {
                                                            ForEach(goalSet) {eachEvent in
                                                                toDoCell(eachEvent)
                                                                    .swipeActions {
                                                                        if showingBucketlist {
                                                                            Button("Unbucket", role: .destructive) {
                                                                                eachEvent.bucketlist = false
                                                                                
                                                                                do {
                                                                                    try viewContext.save()
                                                                                } catch {
                                                                                    // handle error
                                                                                }
                                                                            }
                                                                            .tint(.cyan)
                                                                        } else {
                                                                            Button("Bucket", role: .destructive) {
                                                                                eachEvent.bucketlist = true
                                                                                
                                                                                do {
                                                                                    try viewContext.save()
                                                                                } catch {
                                                                                    // handle error
                                                                                }
                                                                            }
                                                                            .tint(.cyan)
                                                                        }
                                                                    }
                                                                    .contextMenu {
                                                                        //just have both!
                                                                        if showingBucketlist {
                                                                            Button("Unbucket") {
                                                                                eachEvent.bucketlist = false
                                                                                
                                                                                do {
                                                                                    try viewContext.save()
                                                                                } catch {
                                                                                    // handle error
                                                                                }
                                                                            }
                                                                            
                                                                        } else {
                                                                            Button("Bucket") {
                                                                                eachEvent.bucketlist = true
                                                                                
                                                                                do {
                                                                                    try viewContext.save()
                                                                                } catch {
                                                                                    // handle error
                                                                                }
                                                                            }
                                                                            
                                                                        }
                                                                    }
                                                            }
                                                        }.headerProminence(.increased)
                                                        
                                                        //now sub goals
                                                        ForEach(eachGoal.getSubGoals) {eachSubGoal in
                                                            //only display if it's an end goal (sub goals will be under)
                                                            let subGoalSet = (!showingBucketlist ? inboxTodos : bucketlistTodos).filter{ $0.isAttachedToGoal(goal: eachSubGoal) }.sorted {$0.startDate < $1.startDate}
                                                            if subGoalSet.count > 0 {
                                                                Section(header: Text(eachSubGoal.name)) {
                                                                    ForEach(subGoalSet) {eachEvent in
                                                                        toDoCell(eachEvent)
                                                                            .swipeActions {
                                                                                if showingBucketlist {
                                                                                    Button("Unbucket", role: .destructive) {
                                                                                        eachEvent.bucketlist = false
                                                                                        
                                                                                        do {
                                                                                            try viewContext.save()
                                                                                        } catch {
                                                                                            // handle error
                                                                                        }
                                                                                    }
                                                                                    .tint(.cyan)
                                                                                } else {
                                                                                    Button("Bucket", role: .destructive) {
                                                                                        eachEvent.bucketlist = true
                                                                                        
                                                                                        do {
                                                                                            try viewContext.save()
                                                                                        } catch {
                                                                                            // handle error
                                                                                        }
                                                                                    }
                                                                                    .tint(.cyan)
                                                                                }
                                                                            }
                                                                            .contextMenu {
                                                                                //just have both!
                                                                                if showingBucketlist {
                                                                                    Button("Unbucket") {
                                                                                        eachEvent.bucketlist = false
                                                                                        
                                                                                        do {
                                                                                            try viewContext.save()
                                                                                        } catch {
                                                                                            // handle error
                                                                                        }
                                                                                    }
                                                                                    
                                                                                } else {
                                                                                    Button("Bucket") {
                                                                                        eachEvent.bucketlist = true
                                                                                        
                                                                                        do {
                                                                                            try viewContext.save()
                                                                                        } catch {
                                                                                            // handle error
                                                                                        }
                                                                                    }
                                                                                    
                                                                                }
                                                                            }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                            }
                                        }
                                    } else {
                                        Text("You have no To-Do items in your \(showingBucketlist ? "bucketlist" : "inbox").")
                                    }
                                }
                                .toolbar {
                                    Button("Close") {
                                        showingInboxSheet = false
                                    }
                                }
                                .navigationTitle(Text(showingBucketlist ? "Bucketlist" : "Inbox"))
                            }
                        }
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        sortByGoals.toggle()
                        UserDefaults.standard.set(sortByGoals, forKey: "todoSortByGoals")
                    } label: {
                        if sortByGoals {
                            Image(systemName: "calendar.badge.clock")
                        } else {
                            Image(systemName: "pencil.and.ruler.fill")
                        }
                    }
                }
            }
            .navigationTitle(Text("To-Do's"))
            .navigationBarTitleDisplayMode(.inline)
            
            
        }
        
        
    }
    
    func move(from source: IndexSet, to destination: Int) {
        // move the data here
        var fullSet = getFullSetOfToDos()
        
        fullSet.move(fromOffsets: source, toOffset: destination)
        
        if destination > 1  {
            //change the date based on the surrounding dates
            let ogStartDate = fullSet[destination-1].startDate
            fullSet[destination-1].startDate = fullSet[destination - 2].startDate
            if fullSet[destination-1].startDate.startOfDay != ogStartDate.startOfDay {
                fullSet[destination-1].allDay = true
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            // handle error
        }
        
    }
    
    private func getFullSetOfToDos() -> [N40Event] {
        var fullSet: [N40Event] = []
        
        let overDueTodos = mainTodos.filter { $0.startDate < Date().startOfDay && $0.isScheduled }
        let overDueReportables = mainReportables.filter { $0.startDate < Date().startOfDay  && $0.isScheduled }
        let overDueSet = (UserDefaults.standard.bool(forKey: "reportablesOnTodoList") ? overDueTodos + overDueReportables : overDueTodos).sorted {$0.startDate < $1.startDate}
        
        fullSet = fullSet + overDueSet
        
        for i in 0..<numberOfDaysAhead {
            
            let thisDay = Calendar.current.date(byAdding: .day, value: i, to: Date()) ?? Date()
            let todosToday = mainTodos.filter {$0.startDate >= thisDay.startOfDay && $0.startDate < thisDay.endOfDay  && $0.isScheduled }
            let reportablesToday = mainReportables.filter {$0.startDate >= thisDay.startOfDay && $0.startDate < thisDay.endOfDay  && $0.isScheduled }
            let daySet = (UserDefaults.standard.bool(forKey: "reportablesOnTodoList") ? todosToday + reportablesToday : todosToday).sorted {$0.startDate < $1.startDate}
            
            fullSet = fullSet + daySet
        }
        
        return fullSet
    }
    
    private func getTotalAttachedToDos(_ goal: N40Goal) -> Int {
        var total = 0
        total += (!showingBucketlist ? inboxTodos : bucketlistTodos).filter{ $0.isAttachedToGoal(goal: goal) }.count
        for childGoal in goal.getSubGoals {
            total += (!showingBucketlist ? inboxTodos : bucketlistTodos).filter{ $0.isAttachedToGoal(goal: childGoal) }.count
        }
        return total
    }
    
    
    private func toDoCell(_ event: N40Event) -> some View {
        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .if(UserDefaults.standard.bool(forKey: "colorToDoList") && UserDefaults.standard.bool(forKey: "showEventsInGoalColor") && event.getAttachedGoals.count > 0) { view in
                //draw with the goal color
                view.foregroundColor(Color(hex: event.getAttachedGoals.first!.color)?.opacity(0.5))
                }.if(UserDefaults.standard.bool(forKey: "colorToDoList") && !(UserDefaults.standard.bool(forKey: "showEventsInGoalColor") && event.getAttachedGoals.count > 0) && (UserDefaults.standard.bool(forKey: "showEventsWithPersonColor") && event.getFirstFavoriteColor() != nil)) {view in
                    //draw with the person color
                    view.foregroundColor(Color(hex: event.getFirstFavoriteColor()!)?.opacity(0.5))
                }.if(UserDefaults.standard.bool(forKey: "colorToDoList") && !(UserDefaults.standard.bool(forKey: "showEventsInGoalColor") && event.getAttachedGoals.count > 0) && !(UserDefaults.standard.bool(forKey: "showEventsWithPersonColor") && event.getFirstFavoriteColor() != nil) && ((UserDefaults.standard.bool(forKey: "showEventsInGoalColor") || UserDefaults.standard.bool(forKey: "showEventsWithPersonColor")) && UserDefaults.standard.bool(forKey: "showNoGoalEventsGray"))) {view in
                    //draw with the gray color
                    view.foregroundColor(Color(hex: "#b9baa2")?.opacity(0.5))
                }.if(UserDefaults.standard.bool(forKey: "colorToDoList") && !(UserDefaults.standard.bool(forKey: "showEventsInGoalColor") && event.getAttachedGoals.count > 0) && !(UserDefaults.standard.bool(forKey: "showEventsWithPersonColor") && event.getFirstFavoriteColor() != nil) && !((UserDefaults.standard.bool(forKey: "showEventsInGoalColor") || UserDefaults.standard.bool(forKey: "showEventsWithPersonColor")) && UserDefaults.standard.bool(forKey: "showNoGoalEventsGray"))) {view in
                    //draw with the original color
                    view.foregroundColor(Color(hex: event.color)?.opacity(0.5))
                }
                
            HStack {
                
                //Button to check off the to-do (only for ToDo Type)
                if event.eventType == N40Event.TODO_TYPE {
                    Button{
                        completeToDoEvent(toDo: event)
                        
                    } label: {
                        Image(systemName: (event.status == 0) ? "square" : "checkmark.square")
                            .disabled((event.status != 0))
                    }.buttonStyle(PlainButtonStyle())
                } else {
                    //Put a button circle for reportable type
                    if (event.startDate < Date()) {
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
                NavigationLink(destination: EditEventView(editEvent: event), label: {
                    VStack {
                        HStack {
                            Text(event.name)
                            
                            Spacer()
                            if (event.isScheduled) {
                                if (event.startDate < Date()) {
                                    Text(event.startDate, formatter: event.allDay ? lateFormatterDayOnly : lateFormatter)
                                        .foregroundColor(.red)
                                } else {
                                    if !event.allDay { //Don't show the date if it's an all day event.
                                        Text(event.startDate, formatter: todayFormatter)
                                        //Don't change color if it's not overdue
                                    }
                                }
                            }
                            //recurring event icon
                            if (event.recurringTag != "") {
                                ZStack {
                                    Image(systemName: "repeat")
                                    if (event.isRecurringEventLast(viewContext: viewContext) && event.repeatOnCompleteInDays == 0) {
                                        Image(systemName: "line.diagonal")
                                            .scaleEffect(x: -1.2, y: 1.2)
                                    }
                                }
                            }
                        }
                    }
                })
            }
            
        }
    }
    
    private func dateDivider(_ date: Date = Date(), altText: String? = nil) -> some View {
        return VStack {
            HStack {
                Text(altText != nil ? altText! : date.startOfDay == Date().startOfDay ? "Today" : "\(date.dayOfWeek()) \(date.get(.day))")
                    //.padding(.leading)
                    .font(.headline)
                    //.frame(maxWidth: .infinity)
                Color.gray
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .padding(.leading)
                
            }
        }
    }
    
    private func completeToDoEvent (toDo: N40Event) {
        //checks off to do items or unchecks them
        
        if (toDo.status == 0) {
            withAnimation {
                toDo.status = 2
                
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    //Wait 2 seconds to change from attempted to completed so it doesn't disappear too quickly
                    if (toDo.status == 2) {
                        withAnimation {
                            //This means it was checked off but hasn't been finally hidden
                            toDo.status = 3
                            
                            if UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_ToDoView") && (!UserDefaults.standard.bool(forKey: "onlyScheduleUnscheduledTodos") || !toDo.isScheduled) {
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
                            
                            //duplicate the event if repeatOnCompleteInDays is greater than 0
                            if toDo.repeatOnCompleteInDays > 0 && toDo.status != N40Event.UNREPORTED && (toDo.eventType == N40Event.TODO_TYPE || toDo.eventType == N40Event.REPORTABLE_TYPE) {
                                for futureOccurance in toDo.getFutureRecurringEvents(viewContext: viewContext) {
                                    viewContext.delete(futureOccurance)
                                }
                                EditEventView.duplicateN40Event(originalEvent: toDo, newStartDate: Calendar.current.date(byAdding: .day, value: Int(toDo.repeatOnCompleteInDays), to: toDo.startDate) ?? toDo.startDate, vc: viewContext)
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
            do {
                try viewContext.save()
            } catch {
                // handle error
            }
        }
    }
}

fileprivate struct Badge: View {
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
