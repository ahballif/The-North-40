//
//  CalendarView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

import SwiftUI
import CoreData
import EventKit

public let DEFAULT_EVENT_COLOR = Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))


struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    
    @State private var selectedDay = Date()

    @State private var showingCalendar = !UserDefaults.standard.bool(forKey: "showingAgenda")
    
    
    //@State private var showingInfoEvents = UserDefaults.standard.bool(forKey: "showingInfoEvents")
    @State private var showingInfoEvents = true
    @State private var showingBackgroundEvents = true
    @State private var showingSharedEvents: Bool = UserDefaults.standard.bool(forKey: "showingSharedEvents")
    
    @State private var showingSearchSheet = false
    
    @State private var showingEditEventSheet = false
    
    
    
    var body: some View {
        //NavigationView {
            
            
            VStack {
                ZStack {
                    
                    HStack {
                        Button {
                            showingInfoEvents.toggle()
                            UserDefaults.standard.set(showingInfoEvents, forKey: "showingInfoEvents")
                        } label: {
                            ZStack {
                                Image(systemName: "dot.radiowaves.left.and.right")
                                    
                                if !showingInfoEvents {
                                    Image(systemName: "line.diagonal")
                                        .scaleEffect(x: -1.5, y: 1.5)
                                        .foregroundColor(((colorScheme == .dark) ? .black : .white))
                                    Image(systemName: "line.diagonal")
                                        .scaleEffect(x: -1.2, y: 1.2)
                                }
                            }
                        }
                        Button {
                            showingBackgroundEvents.toggle()
                            UserDefaults.standard.set(showingBackgroundEvents, forKey: "showingBackupEvents")
                        } label: {
                            ZStack {
                                Image(systemName: "backpack")
                                    
                                if !showingBackgroundEvents {
                                    Image(systemName: "line.diagonal")
                                        .scaleEffect(x: -1.5, y: 1.5)
                                        .foregroundColor(((colorScheme == .dark) ? .black : .white))
                                    Image(systemName: "line.diagonal")
                                        .scaleEffect(x: -1.2, y: 1.2)
                                }
                            }
                        }
                        if UserDefaults.standard.string(forKey: "selectedAppCalendars") ?? "" != "" {
                            Button {
                                showingSharedEvents.toggle()
                                UserDefaults.standard.set(showingSharedEvents, forKey: "showingSharedEvents")
                            } label: {
                                ZStack {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                    
                                    if !showingSharedEvents {
                                        Image(systemName: "line.diagonal")
                                            .scaleEffect(x: -1.5, y: 1.5)
                                            .foregroundColor(((colorScheme == .dark) ? .black : .white))
                                        Image(systemName: "line.diagonal")
                                            .scaleEffect(x: -1.2, y: 1.2)
                                    }
                                }
                            }
                        }
                        Spacer()
                        Button {
                            showingSearchSheet.toggle()
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }.sheet(isPresented: $showingSearchSheet) {SearchSheet()}
                        
                        Button {
                            showingCalendar.toggle()
                            UserDefaults.standard.set(!showingCalendar, forKey: "showingAgenda")
                        } label: {
                            if showingCalendar {
                                Image(systemName: "list.bullet.rectangle")
                            } else {
                                Image(systemName: "calendar")
                            }
                        }
                    }.padding(.horizontal)
                    
                    Text("Daily \(showingCalendar ? "Planner" : "Agenda")")
                        .font(.title2)
                }
                HStack {
                    Text(selectedDay.dayOfWeek())
                        .lineLimit(1)
                    
                    VStack{
                        //This if statement is a little weird and I maybe won't keep it but it prevents the date picker from getting in the way of new sheets.
                        if !showingEditEventSheet && !showingSearchSheet {
                            DatePicker("Selected Day", selection: $selectedDay, displayedComponents: .date)
                                .labelsHidden()
                        } else {
                            Text(selectedDay.dateOnlyToString()).padding(.leading, 10)
                        }
                    }.frame(height: 25)
                    
                    Spacer()
                    
                    Button {
                        selectedDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDay) ?? selectedDay
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    Button {
                        selectedDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDay) ?? selectedDay
                    } label: {
                        Image(systemName: "chevron.right")
                    }.padding(.trailing)
                    Button("Today") {
                        selectedDay = Date()
                        
                    }
                }
                .padding(.horizontal)
                
                if showingCalendar {
                    ZStack {
                        DailyPlanner(filter: selectedDay, showingInfoEvents: $showingInfoEvents, showingBackgroundEvents: $showingBackgroundEvents, showingSharedCalendarEvents: $showingSharedEvents, showingEditEventSheet: $showingEditEventSheet)
                            
                        
                        
                        
                        VStack {
                            AllDayList(filter: selectedDay, showingSharedAppEvents: $showingSharedEvents)
                                .environment(\.managedObjectContext, viewContext)
                                .background(((colorScheme == .dark) ? .black : .white))
                            Spacer()
                        }
                        
                    }
                } else {
                    AllDayList(filter: selectedDay)
                    
                    AgendaView(filter: selectedDay)
                    
                    Spacer()
                }
                
            //}
            
        }.gesture(DragGesture(minimumDistance: 25, coordinateSpace: .global)
            .onEnded { value in
                
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height
                
                if abs(horizontalAmount) > abs(verticalAmount) {
                    if (horizontalAmount < 0) {
                        //Left swipe
                        selectedDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDay) ?? selectedDay
                    } else {
                        //right swipe
                        selectedDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDay) ?? selectedDay
                    }
                }
                
            })
        
    }
}

struct AllDayList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    
    @FetchRequest var fetchedAllDays: FetchedResults<N40Event>
    @FetchRequest var fetchedGoalsDueToday: FetchedResults<N40Goal>
    @FetchRequest var fetchedGoalsFinishedToday: FetchedResults<N40Goal>
    @FetchRequest var fetchedBirthdayBoys: FetchedResults<N40Person>
    
    private var holidays: [Date: String]
    
    private var filteredDay: Date
    
    private let allEventHeight = 25.0
    
    @State private var showingDetailSheet = false
    private enum DetailOptions {
        case event, goal, birthdayBoy
    }
    @State private var detailShowing = DetailOptions.event
    @State private var selectedEvent: N40Event? = nil
    @State private var selectedGoal: N40Goal? = nil
    @State private var selectedBirthdayBoy: N40Person? = nil
    
    // stuff for showing in the background
    @State private var sharedCalendarEvents: [EKEvent] = []
    @Binding var showingSharedEvents: Bool
    
    
    var body: some View {
        VStack {
            let allGoalsToday = fetchedGoalsDueToday.sorted(by: {$0.name < $1.name}) + fetchedGoalsFinishedToday.sorted(by: {$0.name < $1.name})
            VStack {
                if (fetchedAllDays.filter({ $0.eventType != N40Event.TODO_TYPE || UserDefaults.standard.bool(forKey: "showAllDayTodos")}).count + allGoalsToday.count + fetchedBirthdayBoys.count + sharedCalendarEvents.count*(showingSharedEvents ? 1 : 0)) > 3 {
                    ScrollView {
                        ForEach(fetchedAllDays) { eachEvent in
                            if eachEvent.eventType != N40Event.TODO_TYPE || UserDefaults.standard.bool(forKey: "showAllDayTodos") {
                                allDayEvent(eachEvent)
                            }
                        }
                        ForEach(allGoalsToday) { eachGoal in
                            dueGoal(eachGoal)
                        }
                        ForEach(fetchedBirthdayBoys) { eachBirthdayBoy in
                            birthdayBoyCell(eachBirthdayBoy)
                        }
                        if holidays[filteredDay.startOfDay] != nil && UserDefaults.standard.bool(forKey: "showHolidays") {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.gray)
                                    .opacity(0.0001)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(((colorScheme == .dark) ? .white : .black), lineWidth: 2)
                                            .opacity(0.5)
                                    )
                                
                                HStack {
                                    Text(holidays[filteredDay.startOfDay]!).bold()
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                            }.font(.caption)
                                .frame(height: allEventHeight)
                        }
                        if showingSharedEvents {
                            ForEach(sharedCalendarEvents, id: \.self) { eachSharedEvent in
                                sharedAllDayEvent(eachSharedEvent)
                            }
                        }
                    }.frame(height: 4*allEventHeight)
                } else {
                    VStack {
                        ForEach(fetchedAllDays) { eachEvent in
                            if eachEvent.eventType != N40Event.TODO_TYPE || UserDefaults.standard.bool(forKey: "showAllDayTodos") {
                                allDayEvent(eachEvent)
                            }
                        }
                        ForEach(allGoalsToday) { eachGoal in
                            dueGoal(eachGoal)
                        }
                        ForEach(fetchedBirthdayBoys) { eachBirthdayBoy in
                            birthdayBoyCell(eachBirthdayBoy)
                        }
                        if holidays[filteredDay.startOfDay] != nil && UserDefaults.standard.bool(forKey: "showHolidays") {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.gray)
                                    .opacity(0.0001)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(((colorScheme == .dark) ? .white : .black), lineWidth: 2)
                                            .opacity(0.5)
                                    )
                                
                                HStack {
                                    Text(holidays[filteredDay.startOfDay]!).bold()
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                            }.font(.caption)
                                .frame(height: allEventHeight)
                        }
                        if showingSharedEvents {
                            ForEach(sharedCalendarEvents, id: \.self) { eachSharedEvent in
                                sharedAllDayEvent(eachSharedEvent)
                            }
                        }
                    }
                }
            }.onChange(of: filteredDay) { newValue in
                updateSharedEvents(dateOfFocus: newValue)
            }
        }.sheet(isPresented: $showingDetailSheet) { [detailShowing, selectedEvent, selectedBirthdayBoy, selectedGoal] in
            NavigationView {
                //ZStack {
                    if detailShowing == DetailOptions.event {
                        EditEventView(editEvent: selectedEvent)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button("Close") {
                                        showingDetailSheet = false
                                    }
                                }
                            }
                    } else if detailShowing == DetailOptions.goal {
                        if selectedGoal != nil {
                            GoalDetailView(selectedGoal: selectedGoal!)
                        } else {
                            Text("No Goal Selected")
                        }
                    } else {
                        if selectedBirthdayBoy != nil {
                            PersonDetailView(selectedPerson: selectedBirthdayBoy!)
                        } else {
                            Text("No Birthday Boy or Girl Selected")
                        }
                    }
                //}
                
            }.navigationViewStyle(StackNavigationViewStyle())
                
                
        }
    }
    
    private func updateSharedEvents(dateOfFocus: Date) {
        
        // update the shared calendar stuff
        if UserDefaults.standard.string(forKey: "selectedAppCalendars") ?? "" != "" {
            let eventStore = EKEventStore()
            eventStore.requestAccess(to: .event) { (granted, error) in
                if granted {
                    
                    let sharedCalendars = stringToCalendarList(eventStore: eventStore)
                    
                    // Now get all the non-all day events in this calendar.
                    
                    let startOfDay = dateOfFocus.startOfDay
                    let endOfDay = dateOfFocus.endOfDay
                    
                    // Create a predicate to fetch events for the specific calendar within the time range
                    let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: sharedCalendars)
                    
                    // Fetch the events
                    sharedCalendarEvents = eventStore.events(matching: predicate).filter { $0.isAllDay }
                    for eachEvent in sharedCalendarEvents {
                        let _ = eachEvent.calendar // for some reason you have to use the calendar field or else it gets forgotten and set to (null)
                    }
                    
                } else {
                    print("Access denied")
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    init (filter: Date, showingSharedAppEvents: Binding<Bool>? = nil) {
        let todayPredicateA = NSPredicate(format: "startDate >= %@", filter.startOfDay as NSDate)
        let todayPredicateB = NSPredicate(format: "startDate < %@", filter.endOfDay as NSDate)
        let scheduledPredicate = NSPredicate(format: "isScheduled == YES")
        
        let allDayPredicate = NSPredicate(format: "allDay == YES")
        
        
        _fetchedAllDays = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [todayPredicateA, todayPredicateB, scheduledPredicate, allDayPredicate]))
        
        let dueDatePredicateA = NSPredicate(format: "deadline >= %@", filter.startOfDay as NSDate)
        let dueDatePredicateB = NSPredicate(format: "deadline <= %@", filter.endOfDay as NSDate)
        let hasDeadlinePredicate = NSPredicate(format: "hasDeadline == YES")
        let isNotCompletedPredicate = NSPredicate(format: "isCompleted == NO")
        
    
        let finishedDatePredicateA = NSPredicate(format: "dateCompleted >= %@", filter.startOfDay as NSDate)
        let finishedDatePredicateB = NSPredicate(format: "dateCompleted <= %@", filter.endOfDay as NSDate)
        let isCompletedPredicate = NSPredicate(format: "isCompleted == YES")
        
        _fetchedGoalsDueToday = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.name, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [dueDatePredicateA, dueDatePredicateB, hasDeadlinePredicate, isNotCompletedPredicate]))
        _fetchedGoalsFinishedToday = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.name, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [finishedDatePredicateA, finishedDatePredicateB, isCompletedPredicate]))
        
        let birthdayMonthPredicate = NSPredicate(format: "birthdayMonth == %i", Int16(filter.get(.month)))
        let birthdayDayPredicate = NSPredicate(format: "birthdayDay == %i", Int16(filter.get(.day)))
        let hasBirthdayPredicate = NSPredicate(format: "hasBirthday == YES")
        let isNotArchivedPredicate = NSPredicate(format: "isArchived == NO")
        
        _fetchedBirthdayBoys = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.firstName, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [birthdayDayPredicate, birthdayMonthPredicate, hasBirthdayPredicate, isNotArchivedPredicate]))
        
        
        self.filteredDay = filter
        
        //populate the holidays dictionary
        var rawHolidays = [Date: String]()
        
        if let fileURL = Bundle.main.url(forResource: "holidays", withExtension: "csv") {
            // we found the file in our bundle!
            if let fileContents = try? String(contentsOf: fileURL) {
                // we loaded the file into a string!
                for rawLine in fileContents.split(separator: "\n") {
                    let line = rawLine.split(separator: ",", omittingEmptySubsequences: false)
                    let dateString = String(line[0])
                    
                    // Create Date Formatter
                    let dateFormatter = DateFormatter()
                    // Set Date Format
                    dateFormatter.dateFormat = "MM/dd/yyyy"
                    
                    // Convert String to Date
                    let date = (dateFormatter.date(from: dateString) ?? Date.distantPast).startOfDay
                    rawHolidays.updateValue(String(line[1]), forKey: date)
                }
            }
        }
        self.holidays = rawHolidays
        
        self._showingSharedEvents = showingSharedAppEvents ?? Binding.constant(true)
        
    }
    
    func allDayEvent(_ event: N40Event) -> some View {
        //all events is used for wrapping around other events.
        
        //get color for event cell
        var colorHex = "#FF7051" //default redish color
        
        if UserDefaults.standard.bool(forKey: "showEventsInGoalColor") && event.getAttachedGoals.count > 0 {
            //draw with the goal color
            colorHex = event.getAttachedGoals.first!.color
        } else if UserDefaults.standard.bool(forKey: "showEventsWithPersonColor") && event.getFirstFavoriteColor() != nil {
            //draw with the person color
            colorHex = event.getFirstFavoriteColor()!
        } else if (UserDefaults.standard.bool(forKey: "showEventsInGoalColor") || UserDefaults.standard.bool(forKey: "showEventsWithPersonColor")) && UserDefaults.standard.bool(forKey: "showNoGoalEventsGray") {
            //draw with the gray color
            colorHex = "#b9baa2"
        } else {
            //draw with the original color
            colorHex = event.color
        }

        return VStack {
                
                ZStack {
                    
                    //Change background rectangle based on event type
                    if event.eventType == N40Event.INFORMATION_TYPE {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray)
                            .opacity(0.0001)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke((Color(hex: colorHex) ?? DEFAULT_EVENT_COLOR), lineWidth: 2)
                                    .opacity(0.5)
                            )
                    } else if event.eventType == N40Event.BACKUP_TYPE {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray)
                            .opacity(0.25)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke((Color(hex: colorHex) ?? DEFAULT_EVENT_COLOR), lineWidth: 2)
                                    .opacity(0.5)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill((Color(hex: colorHex) ?? DEFAULT_EVENT_COLOR))
                            .opacity(0.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                

                    
                    HStack {
                        if (event.eventType == N40Event.TODO_TYPE) {
                            //Button to check off the to-do
                            Button(action: { completeToDoEvent(toDo: event) }) {
                                Image(systemName: (event.status == 0) ? "square" : "checkmark.square")
                                    .disabled((event.status != 0))
                            }.buttonStyle(PlainButtonStyle())
                            
                        }
                        
                        Text(event.name).bold()
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                        
                
                    
                    
                    //reportable icon
                    HStack {
                        Spacer()
                        if (event.eventType == N40Event.REPORTABLE_TYPE) {
                            if event.startDate > Date() {
                                Image(systemName: "circle.dotted")
                                    .resizable()
                                    .frame(width: 20, height:20)
                            } else if event.status == N40Event.UNREPORTED {
                                Image(systemName: "questionmark.circle.fill")
                                    .resizable()
                                    .foregroundColor(Color.orange)
                                    .frame(width: 20, height:20)
                            } else if event.status == N40Event.SKIPPED {
                                Image(systemName: "slash.circle.fill")
                                    .resizable()
                                    .foregroundColor(Color.red)
                                    .frame(width: 20, height:20)
                            } else if event.status == N40Event.ATTEMPTED {
                                Image(systemName: "xmark.circle.fill")
                                    .resizable()
                                    .foregroundColor(Color.red)
                                    .frame(width: 20, height:20)
                            } else if event.status == N40Event.HAPPENED {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .foregroundColor(Color.green)
                                    .frame(width: 20, height:20)
                            }
                        } else if (event.eventType == N40Event.INFORMATION_TYPE) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .resizable()
                                .frame(width: 20, height:20)
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
                        
                            
                    }.padding(.horizontal, 8)

                }
                
            }
            .buttonStyle(.plain)
            .font(.caption)
            .frame(height: allEventHeight)
            .opacity((event.status == N40Event.HAPPENED && event.eventType == N40Event.TODO_TYPE && UserDefaults.standard.bool(forKey: "tintCompletedTodos")) ? 0.3 : 1.0)
            
            .onTapGesture {
                detailShowing = DetailOptions.event
                selectedEvent = event
                showingDetailSheet = true
            }
            
        
    }
    
    func sharedAllDayEvent(_ event: EKEvent) -> some View {
        //all events is used for wrapping around other events.
        
        //get color for event cell
        let eventColor: Color = Color(cgColor: event.calendar.cgColor)
        
        

        return VStack {
                
                ZStack {
                    
                    //Change background rectangle based on event type
                    RoundedRectangle(cornerRadius: 8)
                        .fill(eventColor)
                        .opacity(0.15)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(eventColor, lineWidth: 1)
                                .opacity(0.5)
                        )
                

                    
                    HStack {
                        
                        Spacer()
                        Text(event.title)
                            .bold()
                            .foregroundStyle(eventColor)
                            
                        
                    }
                    .padding(.horizontal, 8)
                        
                }
                
            }
            .buttonStyle(.plain)
            .font(.caption)
            .frame(height: allEventHeight)
            
        
    }
    
    func dueGoal(_ goal: N40Goal) -> some View {
        //all events is used for wrapping around other events.
        

        return VStack {
                
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: goal.color) ?? .gray)
                        .opacity(0.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(((colorScheme == .dark) ? .white : .black))
                    
                    HStack {
        
                        if goal.isCompleted {
                            Text("Goal: \(goal.name) completed \( goal.dateCompleted.dateOnlyToString())").bold()
                        } else {
                            Text("Goal: \(goal.name) due \(goal.deadline.dateOnlyToString())").bold()
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                        
                }
                
            }
            .buttonStyle(.plain)
            .font(.caption)
            .frame(height: allEventHeight)
            .onTapGesture {
                detailShowing = DetailOptions.goal
                selectedGoal = goal
                showingDetailSheet = true
            }
    }
    
    
    func birthdayBoyCell(_ person: N40Person) -> some View {
        

        return VStack {
                
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray)
                        .opacity(0.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(((colorScheme == .dark) ? .white : .black))
                    
                    HStack {
        

                        Text("\(person.firstName)'s Birthday! 🎉").bold()
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                        
                }
                
            }
            .buttonStyle(.plain)
            .font(.caption)
            .frame(height: allEventHeight)
            .onTapGesture {
                detailShowing = DetailOptions.birthdayBoy
                selectedBirthdayBoy = person
                showingDetailSheet = true
            }
            
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
                    
                    
                    //duplicate the event if repeatOnCompleteInDays is greater than 0
                    if toDo.repeatOnCompleteInDays > 0 && toDo.status != N40Event.UNREPORTED && (toDo.eventType == N40Event.TODO_TYPE || toDo.eventType == N40Event.REPORTABLE_TYPE) {
                        for futureOccurance in toDo.getFutureRecurringEvents(viewContext: viewContext) {
                            viewContext.delete(futureOccurance)
                        }
                        duplicateN40Event(originalEvent: toDo, newStartDate: Calendar.current.date(byAdding: .day, value: Int(toDo.repeatOnCompleteInDays), to: toDo.startDate) ?? toDo.startDate, vc: viewContext)
                        
                        // Make that duplicate on calendar if needed
                        if toDo.sharedWithCalendar != "" {
                            EditEventView.makeRecurringEventsOnEK(newEvent: toDo, vc: viewContext)
                        }
                    }
                    
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
    
    
}

struct DailyPlanner: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest var fetchedEvents: FetchedResults<N40Event>
    
    @Binding var showingEditEventSheet: Bool
    
    @State private var selectedEditEvent: N40Event? = nil
    @State private var clickedOnTime = Date()
    
    
    @State private var hourHeight = UserDefaults.standard.double(forKey: "hourHeight")
    public static let minimumEventHeight = 25.0 
    
    private var filteredDay: Date
    
    @Binding var showingRadarEvents: Bool
    @Binding var showingBackgroundEvents: Bool
    @Binding var showingSharedCalendarEvents: Bool
    
    @GestureState var press = false
    
    @State private var scrollToNowToggle = false
    
    @State private var dragging = false
    
    @State private var editModeEvent: N40Event? = nil
    @State private var drawDragMinuteOffset: CGFloat = 0.0
    
    // stuff for showing in the background
    @State private var sharedCalendarEvents: [EKEvent] = []
    @State private var sharedEventLocations: [Date: [String]] = [:]
    
    
    var body: some View {
        
        //The main timeline
        ScrollViewReader {value in
            ScrollView {
                
                ZStack(alignment: .topLeading) {
                    
                    //Hour Lines
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<24) { hour in
                            HStack {
                                Text("\(((hour+11) % 12)+1)\(hour < 12 ? "a" : "p")")
                                    .font(.caption)
                                    .frame(width: 30, alignment: .trailing)
                                Color.gray
                                    .frame(height: 1)
                            }
                            .frame(height: hourHeight)
                            .id(hour)
                        }
                    }
                    
                    //Invisible buttons to add an event
                    VStack(alignment: .leading, spacing: 0) {
                        Rectangle()
                            .fill(.clear)
                            .frame(height: hourHeight/2) //offset the buttons by 2 slots
                        
                        
                        ForEach(0..<(24*Int(hourHeight/DailyPlanner.minimumEventHeight)), id: \.self) {idx in
                            Rectangle()
                                .fill(Color.black.opacity(0.0001))
                                .onTapGesture {
                                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                                    impactMed.impactOccurred()
                                    
                                    if editModeEvent == nil {
                                        clickedOnTime = getSelectedTime(idx: idx)
                                        selectedEditEvent = nil
                                        showingEditEventSheet.toggle()
                                    }
                                    editModeEvent = nil
                                    
                                }
                                .frame(height: DailyPlanner.minimumEventHeight)
                        }
                        
                    }
                    
                    if showingSharedCalendarEvents {
                        ForEach(sharedCalendarEvents, id: \.self) { event in
                            sharedCalendarEventCell(event, eventLocations: sharedEventLocations)
                        }
                    }
                    
                    
                        
                    let radarEvents = fetchedEvents.reversed().filter({ $0.eventType == N40Event.INFORMATION_TYPE })
                    
                    EventRenderCalculator.precalculateEventColumns(radarEvents)
                    
                    if showingRadarEvents {
                        ForEach(radarEvents) { event in
                            eventCell(event, allEvents: radarEvents)
                        }
                    }
                    
                    let otherEvents = fetchedEvents.reversed().filter({ $0.eventType != N40Event.INFORMATION_TYPE && (showingBackgroundEvents || $0.eventType != N40Event.BACKUP_TYPE)})
                    
                    EventRenderCalculator.precalculateEventColumns(otherEvents)
                    
                    ForEach(otherEvents) { event in
                        eventCell(event, allEvents: otherEvents)
                    }
                    
                    
                    if (filteredDay.startOfDay == Date().startOfDay) {
                        Color.red
                            .frame(height: 1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .offset(x: 0, y: getNowOffset() + hourHeight/2)
                            .id("now")
                        
                        
                    }
                    
                    
                    
                }
                //.gesture(magnification)
                .onAppear {
                    value.scrollTo(Int(Date().get(.hour)))
                    
                }
                .onChange(of: filteredDay) { newValue in
                    updateSharedEvents(dateOfFocus: newValue)
                }
                
            }.scrollDisabled(editModeEvent != nil)
            
        }
        
            .sheet(isPresented: $showingEditEventSheet) { [clickedOnTime, selectedEditEvent] in
                NavigationView {
                    
                    if selectedEditEvent == nil {
                        EditEventView(editEvent: nil, chosenStartDate: clickedOnTime, autoFocus: UserDefaults.standard.bool(forKey: "autoFocusOnCalendarNewEvent"))
                            //no toolbar item if it's a new event.
                    } else {
                        //An event was clicked
                        EditEventView(editEvent: selectedEditEvent)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button("Close") {
                                        showingEditEventSheet = false
                                    }
                                }
                            }
                    }
                    
                }
            }
            
    }
    
    private func updateSharedEvents(dateOfFocus: Date) {
        // update the shared calendar stuff
        if UserDefaults.standard.string(forKey: "selectedAppCalendars") ?? "" != "" {
            let eventStore = EKEventStore()
            eventStore.requestAccess(to: .event) { (granted, error) in
                if granted {
                    
                    let sharedCalendars = stringToCalendarList(eventStore: eventStore)
                    
                    // Now get all the non-all day events in this calendar.
                    
                    print(filteredDay)
                    let startOfDay = dateOfFocus.startOfDay
                    let endOfDay = dateOfFocus.endOfDay
                    
                    // Create a predicate to fetch events for the specific calendar within the time range
                    let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: sharedCalendars)
                    
                    // Fetch the events
                    sharedCalendarEvents = eventStore.events(matching: predicate).filter { !$0.isAllDay }
                    
                    
                    // Now make location values so events don't overlap on the screen
                    sharedEventLocations = [:]
                    for eachEvent in sharedCalendarEvents {
                        let _ = eachEvent.calendar // for some reason you have to use the calendar field or else it gets forgotten and set to (null)
                        
                        let eventIdentifier: String = eachEvent.title
                        
                        if sharedEventLocations[eachEvent.startDate] == nil {
                            sharedEventLocations.updateValue([eventIdentifier], forKey: eachEvent.startDate)
                        } else {
                            sharedEventLocations[eachEvent.startDate]!.append(eventIdentifier)
                        }
                        
                        //print(sharedEventLocations)
                    }
                    
                } else {
                    print("Access denied")
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    init (filter: Date, showingInfoEvents: Binding<Bool>? = nil, showingBackgroundEvents: Binding<Bool>? = nil, showingSharedCalendarEvents: Binding<Bool>? = nil, showingEditEventSheet: Binding<Bool>) {
        let todayPredicateA = NSPredicate(format: "startDate >= %@", filter.startOfDay as NSDate)
        let todayPredicateB = NSPredicate(format: "startDate < %@", filter.endOfDay as NSDate)
        let scheduledPredicate = NSPredicate(format: "isScheduled == YES")
        
        let notAllDayPredicate = NSPredicate(format: "allDay == NO")
        
        _fetchedEvents = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [todayPredicateA, todayPredicateB, scheduledPredicate, notAllDayPredicate]))
        
        self.filteredDay = filter
        
        
        self._showingRadarEvents = showingInfoEvents ?? Binding.constant(true)
        self._showingBackgroundEvents = showingBackgroundEvents ?? Binding.constant(true)
        self._showingSharedCalendarEvents = showingSharedCalendarEvents ?? Binding.constant(true)
        
        self._showingEditEventSheet = showingEditEventSheet
        
        
    }
    
    func getSelectedTime (idx: Int) -> Date {
        
        var dateComponents = DateComponents()
        dateComponents.year = Calendar.current.component(.year, from: filteredDay)
        dateComponents.month = Calendar.current.component(.month, from: filteredDay)
        dateComponents.day = Calendar.current.component(.day, from: filteredDay)
        dateComponents.hour = Int(Double(idx)*DailyPlanner.minimumEventHeight/hourHeight)
        dateComponents.minute = (idx % Int(hourHeight/DailyPlanner.minimumEventHeight))*Int(60*DailyPlanner.minimumEventHeight/hourHeight)

        // Create date from components
        let userCalendar = Calendar(identifier: .gregorian) // since the components above (like year 1980) are for Gregorian
        let someDateTime: Date = userCalendar.date(from: dateComponents)!
        
        return someDateTime
    }
    
    public func scrollToNow() {
        self.scrollToNowToggle.toggle()
    }
    
    

    
    
    func eventCell(_ event: N40Event, allEvents: [N40Event]) -> some View {
        //all events is used for wrapping around other events.
        
        var height = Double(event.duration) / 60 * hourHeight
        if (height < DailyPlanner.minimumEventHeight) {
            height = DailyPlanner.minimumEventHeight
        }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)
        let offset = Double(hour) * (hourHeight) + Double(minute)/60  * hourHeight
        

        //get color for event cell
        var colorHex = "#FF7051" //default redish color
        
        if UserDefaults.standard.bool(forKey: "showEventsInGoalColor") && event.getAttachedGoals.count > 0 {
            //draw with the goal color
            colorHex = event.getAttachedGoals.first!.color
        } else if UserDefaults.standard.bool(forKey: "showEventsWithPersonColor") && event.getFirstFavoriteColor() != nil {
            //draw with the person color
            colorHex = event.getFirstFavoriteColor()!
        } else if (UserDefaults.standard.bool(forKey: "showEventsInGoalColor") || UserDefaults.standard.bool(forKey: "showEventsWithPersonColor")) && UserDefaults.standard.bool(forKey: "showNoGoalEventsGray") {
            //draw with the gray color
            colorHex = "#b9baa2"
        } else {
            //draw with the original color
            colorHex = event.color
        }
        
        return GeometryReader {geometry in
            //NavigationLink(destination: EditEventView(editEvent: event), label: {
            VStack{
                ZStack {
                    if event.eventType == N40Event.INFORMATION_TYPE {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: colorHex) ?? DEFAULT_EVENT_COLOR)
                            .opacity(editModeEvent == event ? 0.25 : 0.0001)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke((Color(hex: colorHex) ?? DEFAULT_EVENT_COLOR), lineWidth: 2)
                                    .opacity(editModeEvent == event ? 1.0 : 0.5)
                            )
                    } else if event.eventType == N40Event.BACKUP_TYPE {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray)
                            .opacity(editModeEvent == event ? 1.0 : 0.25)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke((Color(hex: colorHex) ?? DEFAULT_EVENT_COLOR), lineWidth: 2)
                                    .opacity(editModeEvent == event ? 1.0 : 0.5)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill((Color(hex: colorHex) ?? DEFAULT_EVENT_COLOR))
                            .opacity(editModeEvent == event ? 1.0 : 0.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    //If this is an information event, don't show the title if theres another non-information event at the same time. 
                    if !(event.eventType == N40Event.INFORMATION_TYPE && fetchedEvents.filter{ $0.startDate == event.startDate && $0.eventType != N40Event.INFORMATION_TYPE}.count > 0) {
                        
                        HStack {
                            if (event.eventType == N40Event.TODO_TYPE) {
                                //Button to check off the to-do
                                Button(action: { completeToDoEvent(toDo: event) }) {
                                    Image(systemName: (event.status == 0) ? "square" : "checkmark.square")
                                        .disabled((event.status != 0))
                                }.buttonStyle(PlainButtonStyle())
                                
                            }
                            if event.contactMethod != 0 {
                                Image(systemName: N40Event.CONTACT_OPTIONS[Int(event.contactMethod)][1])
                            }
                            //Text("\((event.renderIdx ?? -1 )+1)/\(event.renderTotal ?? 0)") //just for testing render
                            Text(event.startDate.formatted(.dateTime.hour().minute()))
                            Text(event.name).bold()
                                .lineLimit(0)
                            Spacer()
                        }
                        .offset(y: (DailyPlanner.minimumEventHeight-height)/2)
                        .padding(.horizontal, 8)
                        
                    }
                
                    HStack {
                        Spacer()
                        if (event.eventType == N40Event.REPORTABLE_TYPE) {
                            if event.startDate > Date() {
                                Image(systemName: "circle.dotted")
                                    .resizable()
                                    .frame(width: 20, height:20)
                            } else if event.status == N40Event.UNREPORTED {
                                Image(systemName: "questionmark.circle.fill")
                                    .resizable()
                                    .foregroundColor(Color.orange)
                                    .frame(width: 20, height:20)
                            } else if event.status == N40Event.SKIPPED {
                                Image(systemName: "slash.circle.fill")
                                    .resizable()
                                    .foregroundColor(Color.red)
                                    .frame(width: 20, height:20)
                            } else if event.status == N40Event.ATTEMPTED {
                                Image(systemName: "xmark.circle.fill")
                                    .resizable()
                                    .foregroundColor(Color.red)
                                    .frame(width: 20, height:20)
                            } else if event.status == N40Event.HAPPENED {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .foregroundColor(Color.green)
                                    .frame(width: 20, height:20)
                            }
                        } else if (event.eventType == N40Event.INFORMATION_TYPE) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .resizable()
                                .frame(width: 20, height:20)
                        }
                        
                        if (event.recurringTag != "") {
                            ZStack {
                                Image(systemName: "repeat")
                                if (event.isRecurringEventLast(viewContext: viewContext) && event.repeatOnCompleteInDays == 0) {
                                    Image(systemName: "line.diagonal")
                                        .scaleEffect(x: -1.2, y: 1.2)
                                }
                            }
                        }
                        
                            
                    }.padding(.horizontal, 8)
                    
                    
                }
                
            }
            .buttonStyle(.plain)
            .font(.caption)
            .padding(.horizontal, 4)
            .frame(height: height, alignment: .top)
            .frame(width: (geometry.size.width-40)/CGFloat(event.numberOfColumns ?? 1), alignment: .leading)
            //.frame(width: (geometry.size.width-40)/CGFloat(getHighestEventIndex(allEvents: allEvents, from: event.startDate, to: Calendar.current.date(byAdding: .minute, value: getTestDuration(duration: Int(event.duration)), to: event.startDate) ?? event.startDate)), alignment: .leading)
            .padding(.trailing, 30)
            .offset(x: 30 + (CGFloat(event.renderIdx ?? 0)*(geometry.size.width-40)/CGFloat(event.numberOfColumns ?? 1)), y: offset + hourHeight/2 + (editModeEvent == event ? drawDragMinuteOffset : 0.0))
            .onTapGesture {
                if editModeEvent == nil {
                    selectedEditEvent = event
                    showingEditEventSheet.toggle()
                }
                editModeEvent = nil
            }
            .opacity((event.status == N40Event.HAPPENED && event.eventType == N40Event.TODO_TYPE && UserDefaults.standard.bool(forKey: "tintCompletedTodos")) ? 0.3 : 1.0)
            .onLongPressGesture {
                let impactMed = UIImpactFeedbackGenerator(style: .heavy)
                impactMed.impactOccurred()
                editModeEvent = event
            }
            .if(editModeEvent == event) { view in
                view.gesture(
                    DragGesture()
                        .onChanged{
                            dragging = true
                            
                            drawDragMinuteOffset = $0.translation.height
                            
                        }
                        .onEnded {
                            
                            //moving within the day
//                            let eventStartPos = Double(event.startDate.timeIntervalSince1970 - event.startDate.startOfDay.timeIntervalSince1970)/3600*hourHeight + hourHeight/2
//                            let moveAmount = $0.location.y - eventStartPos
                            let minimumDuration = 60.0/hourHeight*DailyPlanner.minimumEventHeight
//                            let numOfMinutesMoved = Double(Int(moveAmount/hourHeight*60.0/minimumDuration) + (moveAmount<0 ? -1 : 0))*minimumDuration
                            let numOfMinutesMoved = round($0.translation.height/hourHeight*60.0/minimumDuration)*minimumDuration
                            let roundMinutesDifference = Double(event.startDate.get(.minute)) - (Double(event.startDate.get(.minute))/minimumDuration).rounded()*minimumDuration
                            
                            dragging = false
                            drawDragMinuteOffset = 0
                            
                            withAnimation {
                                
                                
                                event.startDate = Calendar.current.date(byAdding: .minute, value: Int(numOfMinutesMoved - roundMinutesDifference), to: event.startDate) ?? event.startDate
                                
                                if event.notificationID != "" {
                                    //update the time of the notification
                                    NotificationHandler.instance.updateNotification(event: event, pretime: event.notificationTime, viewContext: viewContext)
                                }
                                
                                do {
                                    try viewContext.save()
                                } catch {
                                    // handle error
                                }
                                
                                // update the calendar app copy if needed
                                if event.sharedWithCalendar != "" {
                                    
                                    let eventStore = EKEventStore()
                                    eventStore.requestAccess(to: .event) { (granted, error) in
                                        if granted {
                                            print("Access granted")
                                            
                                            updateEventOnEKStore(event, eventStore: eventStore, viewContext: viewContext)
                                            
                                            
                                        } else {
                                            print("Access denied")
                                            if let error = error {
                                                print("Error: \(error.localizedDescription)")
                                            }
                                        }
                                    }
                                }
                                
                            }
                        })
            }
            
        }
    }
    
    func sharedCalendarEventCell(_ event: EKEvent, eventLocations: [Date:[String]]) -> some View {
        //all events is used for wrapping around other events.
        
        
        // Calculate the difference in seconds and then convert to minutes
        let timeInterval = event.endDate.timeIntervalSince(event.startDate)
        let duration = timeInterval / 60
        
        var height = Double(duration) / 60 * hourHeight
        if (height < DailyPlanner.minimumEventHeight) {
            height = DailyPlanner.minimumEventHeight
        }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)
        let offset = Double(hour) * (hourHeight) + Double(minute)/60  * hourHeight
        
        let eventColor: Color = Color(cgColor: event.calendar.cgColor)
        
        let numColumns: Int = (eventLocations[event.startDate] ?? [""]).count
        let locationInColumn: Int = (eventLocations[event.startDate] ?? [event.title]).firstIndex(of: event.title) ?? 1
        
        return GeometryReader {geometry in
            //NavigationLink(destination: EditEventView(editEvent: event), label: {
            VStack{
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(eventColor)
                        .opacity(0.15)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(eventColor, lineWidth: 1)
                                .opacity(0.5)
                        )
                    //If this is an information event, don't show the title if theres another non-information event at the same time.
                    if !((fetchedEvents.filter{ $0.startDate == event.startDate}.count) > 0) {
                        
                        HStack {
                            Spacer()
                            Text(event.startDate.formatted(.dateTime.hour().minute()))
                                .foregroundStyle(eventColor)
                            Text(event.title)
                                .foregroundStyle(eventColor)
                                .bold()
                                .lineLimit(0)
                        }
                        .offset(y: (DailyPlanner.minimumEventHeight-height)/2)
                        .padding(.horizontal, 8)
                        
                    }
                    
                    
                    
                    
                }
                
            }
            .buttonStyle(.plain)
            .font(.caption)
            .padding(.horizontal, 4)
            .frame(height: height, alignment: .top)
            .frame(width: (geometry.size.width-40)/CGFloat(numColumns), alignment: .leading)
            //.frame(width: (geometry.size.width-40)/CGFloat(getHighestEventIndex(allEvents: allEvents, from: event.startDate, to: Calendar.current.date(byAdding: .minute, value: getTestDuration(duration: Int(event.duration)), to: event.startDate) ?? event.startDate)), alignment: .leading)
            .padding(.trailing, 30)
            .offset(x: 30 + (geometry.size.width-40)/CGFloat(numColumns)*CGFloat(locationInColumn), y: offset + hourHeight/2 )
            
            
        }
    }
    
    
    
    
    
    func getNowOffset() -> CGFloat {
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let offset = Double(hour)*hourHeight + Double(minute)/60*hourHeight
        
        return offset
        
        
    }
    
    private func completeToDoEvent (toDo: N40Event) {
        //checks off to do items or unchecks them
        
        if (toDo.status == 0) {
            toDo.status = 3
            
            if UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_CalendarView") && (!UserDefaults.standard.bool(forKey: "onlyScheduleUnscheduledTodos") || !toDo.isScheduled) {
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
                duplicateN40Event(originalEvent: toDo, newStartDate: Calendar.current.date(byAdding: .day, value: Int(toDo.repeatOnCompleteInDays), to: toDo.startDate) ?? toDo.startDate, vc: viewContext)
                
                // Make that duplicate on calendar if needed
                if toDo.sharedWithCalendar != "" {
                    EditEventView.makeRecurringEventsOnEK(newEvent: toDo, vc: viewContext)
                }
            }
            
        } else {
            toDo.status = 0
            
        }
        
        do {
            try viewContext.save()
        } catch {
            // handle error
        }
    }
    

    
}


struct SearchSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @State private var searchText: String = ""
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: false)], animation: .default)
    private var allEvents: FetchedResults<N40Event>
    
    @State private var showing = 25
    
    @State private var isPresented = true
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Search from All Events").font(.title2)
                        .padding()
                    Spacer()
                    Button("Close") {
                        dismiss()
                    }.padding()
                }
                ScrollView{
                    VStack{
                        let events = allEvents.filter{ $0.name.lowercased().contains(searchText.lowercased()) && searchText != ""}
                        ForEach(showing < events.count ? events[0..<showing] : events[0..<events.count]) {eachEvent in
                            eventCell(eachEvent)
                        }
                        if showing < events.count {
                            Button {
                                showing += 25
                            } label: {
                                Text("Show More")
                            }
                        }
                    }
                }
                //.searchable(text: $searchText, isPresented: $isPresented) //newer version of xcode
                .searchable(text: $searchText)
                Spacer()
            }
            
        }
    }
    
    func eventCell(_ event: N40Event) -> some View {
        
        return NavigationLink(destination: EditEventView(editEvent: event), label: {
            
            ZStack {
                if event.eventType == N40Event.INFORMATION_TYPE {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray)
                        .opacity(0.0001)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke((Color(hex: event.color) ?? DEFAULT_EVENT_COLOR), lineWidth: 2)
                                .opacity(0.5)
                        )
                } else if event.eventType == N40Event.BACKUP_TYPE {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray)
                        .opacity(0.25)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke((Color(hex: event.color) ?? DEFAULT_EVENT_COLOR), lineWidth: 2)
                                .opacity(0.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill((Color(hex: event.color) ?? DEFAULT_EVENT_COLOR))
                        .opacity(0.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                VStack {
                    HStack {
                        if (event.eventType == N40Event.TODO_TYPE) {
                            //It's not a button here, just a picture
                            Image(systemName: (event.status == 0) ? "square" : "checkmark.square")
                            
                        }
                        if event.contactMethod != 0 {
                            Image(systemName: N40Event.CONTACT_OPTIONS[Int(event.contactMethod)][1])
                        }
                        Text(event.startDate.dateAndTimeToString())
                        Text(event.name).bold()
                            .lineLimit(0)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    if (event.eventType == N40Event.REPORTABLE_TYPE) {
                        if event.startDate > Date() {
                            Image(systemName: "circle.dotted")
                                .resizable()
                                .frame(width: 20, height:20)
                        } else if event.status == N40Event.UNREPORTED {
                            Image(systemName: "questionmark.circle.fill")
                                .resizable()
                                .foregroundColor(Color.orange)
                                .frame(width: 20, height:20)
                        } else if event.status == N40Event.SKIPPED {
                            Image(systemName: "slash.circle.fill")
                                .resizable()
                                .foregroundColor(Color.red)
                                .frame(width: 20, height:20)
                        } else if event.status == N40Event.ATTEMPTED {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .foregroundColor(Color.red)
                                .frame(width: 20, height:20)
                        } else if event.status == N40Event.HAPPENED {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .foregroundColor(Color.green)
                                .frame(width: 20, height:20)
                        }
                    } else if (event.eventType == N40Event.INFORMATION_TYPE) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .resizable()
                            .frame(width: 20, height:20)
                    }
                    
                    if (event.recurringTag != "") {
                        ZStack {
                            Image(systemName: "repeat")
                            if (event.isRecurringEventLast(viewContext: viewContext) && event.repeatOnCompleteInDays == 0) {
                                Image(systemName: "line.diagonal")
                                    .scaleEffect(x: -1.2, y: 1.2)
                            }
                        }
                    }
                    
                    
                }.padding(.horizontal, 8)
                
            }
        })
        .buttonStyle(.plain)
        .font(.caption)
        .padding(.horizontal, 4)
        .padding(.leading, 30)
        
        
    }
    
}






