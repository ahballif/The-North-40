//
//  WeekCalendarView.swift
//  The North 40
//
//  Created by Addison Ballif on 12/12/23.
//

import SwiftUI
import CoreData

fileprivate let numberOfDays = 5


struct WeekCalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    
    @State private var selectedDay = Date()
    
    //@State private var showingInfoEvents = UserDefaults.standard.bool(forKey: "showingInfoEvents")
    @State private var showingInfoEvents = true
    @State private var showingBackgroundEvents = true
    
    @State private var showingSearchSheet = false
    
    
    var body: some View {
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
                    Spacer()
                    Button {
                        showingSearchSheet.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }.sheet(isPresented: $showingSearchSheet) {SearchSheet()}
                    
                    
                }.padding(.horizontal)
                
                Text("Weekly Planner")
                    .font(.title2)
            }
            HStack {
                Text("\(selectedDay.dayOfWeek()) - \((Calendar.current.date(byAdding: .day, value: numberOfDays-1, to: selectedDay) ?? selectedDay).dayOfWeek())")
                
                Spacer()
                
                DatePicker("Selected Day", selection: $selectedDay, displayedComponents: .date)
                    .labelsHidden()
                
                
                Button {
                    selectedDay = Calendar.current.date(byAdding: .day, value: -7, to: selectedDay) ?? selectedDay
                } label: {
                    Image(systemName: "chevron.left.2")
                }
                Button {
                    selectedDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDay) ?? selectedDay
                } label: {
                    Image(systemName: "chevron.left")
                }
                Button {
                    selectedDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDay) ?? selectedDay
                } label: {
                    Image(systemName: "chevron.right")
                }
                Button {
                    selectedDay = Calendar.current.date(byAdding: .day, value: 7, to: selectedDay) ?? selectedDay
                } label: {
                    Image(systemName: "chevron.right.2")
                }
                
                
                
                Button("Today") {
                    selectedDay = Date()
                    
                }
            }
            .padding(.horizontal)
            
            VStack {
                HStack {
                    ForEach(0..<numberOfDays, id: \.self) { dayIdx in
                        VStack(alignment: .center) {
                            let thisDay: Date = (Calendar.current.date(byAdding: .day, value: dayIdx, to: selectedDay) ?? selectedDay)
                            Text("\(thisDay.dayOfWeek()) \(thisDay.get(.day))")
                        }.frame(maxWidth: .infinity)
                            
                    }
                }.padding(.leading, 30)
                
                AllDayListWeek(filter: selectedDay)
                WeeklyPlanner(filter: selectedDay, showingInfoEvents: $showingInfoEvents, showingBackgroundEvents: $showingBackgroundEvents)
                    .environment(\.managedObjectContext, viewContext)
                
                
            }
            
        }.highPriorityGesture(DragGesture(minimumDistance: 25, coordinateSpace: .global)
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


struct WeeklyPlanner: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    
    @FetchRequest var fetchedEvents: FetchedResults<N40Event>
    
    @State private var showingEditEventSheet = false
    @State private var selectedEditEvent: N40Event? = nil
    @State private var clickedOnTime = Date()
    
    
    @State private var hourHeight = UserDefaults.standard.double(forKey: "hourHeight")
    public static let minimumEventHeight = 25.0
    
    private var filteredDay: Date
    
    @Binding var showingRadarEvents: Bool
    @Binding var showingBackgroundEvents: Bool
    
    @GestureState var press = false
    
    var body: some View {
        
        //The main timeline
        ScrollViewReader {value in
            ScrollView {
                ZStack {
                    
                    //Hour Lines
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<24) { hour in
                            HStack {
                                Text("\(((hour+11) % 12)+1)")
                                    .font(.caption)
                                    .frame(width: 20, alignment: .trailing)
                                Color.gray
                                    .frame(height: 1)
                            }
                            .frame(height: hourHeight)
                            .id(hour)
                        }
                        Rectangle()
                            .fill(.clear)
                            .frame(height: hourHeight/2)
                    }
                    
                    HStack(spacing: 0) {
                        ForEach(0..<numberOfDays, id: \.self) {dayIdx in
                            let thisDay: Date = (Calendar.current.date(byAdding: .day, value: dayIdx, to: filteredDay) ?? filteredDay)
                            let dayEvents = fetchedEvents.filter { $0.startDate >= thisDay.startOfDay && $0.startDate < thisDay.endOfDay }
                            ZStack(alignment: .topLeading) {
                                
                                
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
                                                
                                                
                                                clickedOnTime = getSelectedTime(idx: idx, day: thisDay)
                                                selectedEditEvent = nil
                                                showingEditEventSheet.toggle()
                                            }
                                            .frame(height: DailyPlanner.minimumEventHeight)
                                    }
                                    
                                }
                                
                                //Events
                                ZStack{
                                    let radarEvents = dayEvents.filter({ $0.eventType == N40Event.INFORMATION_TYPE })
                                    
                                    EventRenderCalculator.precalculateEventColumns(radarEvents)
                                    
                                    if showingRadarEvents {
                                        ForEach(radarEvents) { event in
                                            eventCell(event, eventsOfSameType: radarEvents, fetchedEventsForDay: dayEvents)
                                        }
                                    }
                                    
                                    let otherEvents = dayEvents.filter({ $0.eventType != N40Event.INFORMATION_TYPE && (showingBackgroundEvents || $0.eventType != N40Event.BACKUP_TYPE)})
                                    
                                    EventRenderCalculator.precalculateEventColumns(otherEvents)
                                    
                                    ForEach(otherEvents) { event in
                                        eventCell(event, eventsOfSameType: otherEvents, fetchedEventsForDay: dayEvents)
                                    }
                                }.padding(.horizontal, 10)
                                //red line
                                if (Date().startOfDay == thisDay.startOfDay) {
                                    Color.red
                                        .frame(height: 1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .offset(x: 0, y: getNowOffset() + hourHeight/2)
                                        .id("now")
                                    
                                    
                                }
                                
                                
                                
                            }
                            //.frame(width: 300)
                            Color.gray
                                .frame(width:1)
                                .frame(maxHeight: .infinity)
                        }
                        //.gesture(magnification)
                        
                        .onAppear {
                            hourHeight = UserDefaults.standard.double(forKey: "hourHeight")
                            let nowMinute = Calendar.current.component(.minute, from: Date())
                            let selectedMinute = Calendar.current.component(.minute, from: filteredDay)
                            if nowMinute == selectedMinute {
                                //value.scrollTo("now")
                            }
                        }
                        
                    }.padding(.leading, 30)
                }
            }.onAppear {
                value.scrollTo(Int(Date().get(.hour)))
            }
        }
        
        
            .sheet(isPresented: $showingEditEventSheet) { [clickedOnTime, selectedEditEvent] in
                NavigationView {
                    if selectedEditEvent == nil {
                        EditEventView(editEvent: nil, chosenStartDate: clickedOnTime)
                    } else {
                        //An event was clicked
                        EditEventView(editEvent: selectedEditEvent)
                    }
                }
            }
            
    }
    
    
    
    init (filter: Date, showingInfoEvents: Binding<Bool>? = nil, showingBackgroundEvents: Binding<Bool>? = nil) {
        
        let scheduledPredicate = NSPredicate(format: "isScheduled == YES")
        let notAllDayPredicate = NSPredicate(format: "allDay == NO")
        
        let todayPredicateA = NSPredicate(format: "startDate >= %@", (Calendar.current.date(byAdding: .day, value: 0, to: filter) ?? filter).startOfDay as NSDate)
        let todayPredicateB = NSPredicate(format: "startDate < %@", (Calendar.current.date(byAdding: .day, value: numberOfDays-1, to: filter) ?? filter).endOfDay as NSDate)
        
        _fetchedEvents = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [todayPredicateA, todayPredicateB, scheduledPredicate, notAllDayPredicate]))
        
        
        self.filteredDay = filter
        
        
        self._showingRadarEvents = showingInfoEvents ?? Binding.constant(true)
        self._showingBackgroundEvents = showingBackgroundEvents ?? Binding.constant(true)
        
    }
    
    func getSelectedTime (idx: Int, day: Date) -> Date {
        
        var dateComponents = DateComponents()
        dateComponents.year = Calendar.current.component(.year, from: day)
        dateComponents.month = Calendar.current.component(.month, from: day)
        dateComponents.day = Calendar.current.component(.day, from: day)
        dateComponents.hour = Int(Double(idx)*DailyPlanner.minimumEventHeight/hourHeight)
        dateComponents.minute = (idx % Int(hourHeight/DailyPlanner.minimumEventHeight))*Int(60*DailyPlanner.minimumEventHeight/hourHeight)

        // Create date from components
        let userCalendar = Calendar(identifier: .gregorian) // since the components above (like year 1980) are for Gregorian
        let someDateTime: Date = userCalendar.date(from: dateComponents)!
        
        return someDateTime
    }
    
    
    func eventCell(_ event: N40Event, eventsOfSameType: [N40Event], fetchedEventsForDay: [N40Event]) -> some View {
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
        
        if UserDefaults.standard.bool(forKey: "showEventsInGoalColor") {
            if event.getAttachedGoals.count > 0 {
                colorHex = event.getAttachedGoals.first!.color
            } else {
                if UserDefaults.standard.bool(forKey: "showNoGoalEventsGray") {
                    colorHex = "#b9baa2" // a grayish color if it's not assigned to a goal
                } else {
                    colorHex = event.color
                }
            }
        } else {
            colorHex = event.color
        }
        
        let numberOfColumns = event.getHighestEventIdx + 1
        
        return GeometryReader {geometry in
            VStack {
                ZStack {
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
                    
                    //If this is an information event, don't show the title if theres another non-information event at the same time.
                    if !(event.eventType == N40Event.INFORMATION_TYPE && fetchedEventsForDay.filter{ $0.startDate == event.startDate && $0.eventType != N40Event.INFORMATION_TYPE}.count > 0) {
                        
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
                                if (event.isRecurringEventLast(viewContext: viewContext)) {
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
            //.padding(.horizontal, 10)
            .frame(height: height, alignment: .top)
            .frame(width: (geometry.size.width)/CGFloat(numberOfColumns), alignment: .leading)
            //.padding(.trailing, 5)
            .offset(x: (CGFloat(event.renderIdx ?? 0)*(geometry.size.width)/CGFloat(numberOfColumns)), y: offset + hourHeight/2)
            .onTapGesture {
                selectedEditEvent = event
                showingEditEventSheet.toggle()
            }
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
            
            if UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_CalendarView") {
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

struct AllDayListWeek: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    
    @FetchRequest var fetchedAllDays: FetchedResults<N40Event>
    @FetchRequest var fetchedGoalsDueToday: FetchedResults<N40Goal>
    @FetchRequest var fetchedBirthdayBoys: FetchedResults<N40Person>
    
    @State private var showingEditEventSheet = false
    
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
    
    
    var body: some View {
        HStack {
            ForEach(0..<numberOfDays, id: \.self) { dayIdx in
                VStack(alignment: .leading) {
                    let thisDay: Date = (Calendar.current.date(byAdding: .day, value: dayIdx, to: filteredDay) ?? filteredDay)
                    let allDayEvents = fetchedAllDays.filter { $0.startDate >= thisDay.startOfDay && $0.startDate < thisDay.endOfDay }
                    let goalsDueToday = fetchedGoalsDueToday.filter {$0.deadline >= thisDay.startOfDay && $0.deadline <= thisDay.endOfDay}
                    let birthdayBoysToday = fetchedBirthdayBoys.filter {isBirthdayToday(birthdayBoy: $0, today: thisDay)}
                    
                    if (allDayEvents.filter({ $0.eventType != N40Event.TODO_TYPE || UserDefaults.standard.bool(forKey: "showAllDayTodos")}).count + goalsDueToday.count ) > 3 { //+ fetchedBirthdayBoys.count
                        ScrollView {
                            ForEach(allDayEvents) { eachEvent in
                                if eachEvent.eventType != N40Event.TODO_TYPE || UserDefaults.standard.bool(forKey: "showAllDayTodos") {
                                    allDayEvent(eachEvent)
                                }
                            }
                            ForEach(goalsDueToday) { eachGoal in
                                dueGoal(eachGoal)
                            }
                            //                    ForEach(fetchedBirthdayBoys) { eachBirthdayBoy in
                            //                        birthdayBoyCell(eachBirthdayBoy)
                            //                    }
                        }.frame(height: 3*allEventHeight)
                    } else {
                        VStack {
                            ForEach(allDayEvents) { eachEvent in
                                if eachEvent.eventType != N40Event.TODO_TYPE || UserDefaults.standard.bool(forKey: "showAllDayTodos") {
                                    allDayEvent(eachEvent)
                                }
                            }
                            ForEach(goalsDueToday) { eachGoal in
                                dueGoal(eachGoal)
                            }
                            ForEach(birthdayBoysToday) { eachBirthdayBoy in
                                birthdayBoyCell(eachBirthdayBoy)
                            }
                            
                        }
                    }
                }.frame(maxWidth: .infinity)
                    
            }
        }.padding(.leading, 30)
            .onAppear{
                print(fetchedGoalsDueToday)
            }
            .sheet(isPresented: $showingDetailSheet) { [detailShowing, selectedEvent, selectedBirthdayBoy, selectedGoal] in
                NavigationView {
                    if detailShowing == DetailOptions.event {
                        EditEventView(editEvent: selectedEvent)
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
                }
            }
    }
    
    init (filter: Date) {
        let beginningOfWeek = filter.startOfDay as NSDate
        let endOfWeek = (Calendar.current.date(byAdding: .day, value: numberOfDays-1, to: filter) ?? filter).endOfDay as NSDate
        
        let todayPredicateA = NSPredicate(format: "startDate >= %@", beginningOfWeek)
        let todayPredicateB = NSPredicate(format: "startDate < %@", endOfWeek)
        let scheduledPredicate = NSPredicate(format: "isScheduled == YES")
        
        let allDayPredicate = NSPredicate(format: "allDay == YES")
        
        
        _fetchedAllDays = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [todayPredicateA, todayPredicateB, scheduledPredicate, allDayPredicate]))
        
        let dueDatePredicateA = NSPredicate(format: "deadline >= %@", beginningOfWeek)
        let dueDatePredicateB = NSPredicate(format: "deadline <= %@", endOfWeek)
        let hasDeadlinePredicate = NSPredicate(format: "hasDeadline == YES")
        
        _fetchedGoalsDueToday = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.name, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [dueDatePredicateA, dueDatePredicateB, hasDeadlinePredicate]))
        
        
        //Birthdays
        var birthdayMonthPredicate = NSPredicate(format: "birthdayMonth == %i", Int16((beginningOfWeek as Date).get(.month)))
        var birthdayDayPredicate = NSPredicate(format: "birthdayDay == %i", Int16(filter.get(.day))) //dummy predicate to initialize the variable as a non-optional
        let hasBirthdayPredicate = NSPredicate(format: "hasBirthday == YES")
        
        let months = Array(Set([Int16((beginningOfWeek as Date).get(.month)), Int16((endOfWeek as Date).get(.month))]))
        if months.count > 1 {
            //We are spanning two months; redo the predicates
            birthdayMonthPredicate = NSCompoundPredicate(type: .or, subpredicates: [NSPredicate(format: "birthdayMonth == %i", months[0]), NSPredicate(format: "birthdayMonth == %i", months[1])])
            var predicates: [NSPredicate] = []
            for i in 0...numberOfDays-1 {
                let day = (Calendar.current.date(byAdding: .day, value: i, to: filter) ?? filter)
                predicates.append(NSPredicate(format: "birthdayDay == %i", Int16(day.get(.day))))
            }
            birthdayDayPredicate = NSCompoundPredicate(type: .or, subpredicates: predicates)
        } else {
            //just see if the days is within the range
            birthdayDayPredicate = NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "birthdayDay >= %i", Int16((beginningOfWeek as Date).get(.day))), NSPredicate(format: "birthdayDay <= %i", Int16((endOfWeek as Date).get(.day)))])
        }
        
        
        
        _fetchedBirthdayBoys = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.firstName, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [birthdayDayPredicate, birthdayMonthPredicate, hasBirthdayPredicate]))
        
        
        self.filteredDay = filter
    }
    
    func isBirthdayToday(birthdayBoy: N40Person, today: Date) -> Bool {
        return birthdayBoy.birthday.get(.month) == today.get(.month) && birthdayBoy.birthday.get(.day) == today.get(.day)
    }
    
    func allDayEvent(_ event: N40Event) -> some View {
        //all events is used for wrapping around other events.
        
        //get color for event cell
        var colorHex = "#FF7051" //default redish color
        
        if UserDefaults.standard.bool(forKey: "showEventsInGoalColor") {
            if event.getAttachedGoals.count > 0 {
                colorHex = event.getAttachedGoals.first!.color
            } else {
                if UserDefaults.standard.bool(forKey: "showNoGoalEventsGray") {
                    colorHex = "#b9baa2" // a grayish color if it's not assigned to a goal
                } else {
                    colorHex = event.color
                }
            }
        } else {
            colorHex = event.color
        }

        return VStack{
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
                                if (event.isRecurringEventLast(viewContext: viewContext)) {
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
            .onTapGesture {
                detailShowing = DetailOptions.event
                selectedEvent = event
                selectedGoal = nil
                selectedBirthdayBoy = nil
                showingDetailSheet = true
            }
            
        
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
        

                        Text("Goal: \(goal.name) - \(goal.deadline.dateOnlyToString())").bold()
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
                selectedEvent = nil
                selectedGoal = goal
                selectedBirthdayBoy = nil
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
                selectedEvent = nil
                selectedGoal = nil
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



