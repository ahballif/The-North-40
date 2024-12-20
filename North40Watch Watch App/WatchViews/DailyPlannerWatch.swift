//
//  DailyPlannerWatch.swift
//  North40Watch Watch App
//
//  Created by Addison Ballif on 9/3/24.
//

import SwiftUI

public let DEFAULT_EVENT_COLOR = Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))



struct CalendarViewWatch: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedDay = Date()
    
    @State private var showingInfoEvents = true
    @State private var showingBackgroundEvents = true
    
    @State private var showingEditEventSheet = false
    
    var body: some View {
        VStack {
            
            
            DailyPlannerWatch(filter: selectedDay, showingInfoEvents: $showingInfoEvents, showingBackgroundEvents: $showingBackgroundEvents, showingEditEventSheet: $showingEditEventSheet)
            

            
            
            
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
        .toolbar{
            ToolbarItemGroup(placement: .topBarTrailing) {
                HStack {
                    Text(selectedDay.shortDateToString())
                    Button {
                        selectedDay = Date()
                    } label: {
                        Image(systemName: selectedDay.startOfDay == Date().startOfDay ? "clock.fill" : "clock")
                    }
                }
                
            }
            if UserDefaults.standard.bool(forKey: "showAllDayEvents") {
                ToolbarItemGroup(placement: .bottomBar) {
                    AllDayListWatch(filter: selectedDay)
                }
            }
            
            
        }
    }
}

struct DailyPlannerWatch: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest var fetchedEvents: FetchedResults<N40Event>
    
    @Binding var showingEditEventSheet: Bool
    
    
    @State private var hourHeight = UserDefaults.standard.double(forKey: "hourHeight")
    public static let minimumEventHeight = 25.0
    
    
    private var filteredDay: Date
    
    @State private var selectedEditEvent: N40Event? = nil
    @State private var clickedOnTime = Date()
    
    
    
    @State private var dragging = false
    @State private var editModeEvent: N40Event? = nil
    @State private var drawDragMinuteOffset: CGFloat = 0.0
    
    
    
    @Binding var showingBackgroundEvents: Bool
    @Binding var showingRadarEvents: Bool
    
    //might need gesterstate for pressing
    // might need state for dragging
    
    var body: some View {
        
        ScrollViewReader { value in
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
                        
                        ForEach(0..<(24*Int(hourHeight/DailyPlannerWatch.minimumEventHeight)), id: \.self) {idx in
                            Rectangle()
                                .fill(Color.black.opacity(0.0001))
                                .onTapGesture {
                                    
                                    if editModeEvent == nil {
                                        clickedOnTime = getSelectedTime(idx: idx)
                                        selectedEditEvent = nil
                                        showingEditEventSheet.toggle()
                                    }
                                    editModeEvent = nil
                                    
                                }
                                .frame(height: DailyPlannerWatch.minimumEventHeight)
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
                    
                    //now line
                    if (filteredDay.startOfDay == Date().startOfDay) {
                        Color.red
                            .frame(height: 1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .offset(x: 0, y: getNowOffset() + hourHeight/2)
                            .id("now")
                        
                        
                    }
                    
                    
                    
                }
                .onAppear {
                    value.scrollTo(Int(Date().get(.hour)))
                    
                }
                
            }
            .scrollDisabled(editModeEvent != nil)
        }
        .sheet(isPresented: $showingEditEventSheet) { [clickedOnTime, selectedEditEvent] in
            NavigationView {
                
                if selectedEditEvent == nil {
                    EditEventViewWatch(editEvent: nil, chosenStartDate: clickedOnTime, autoFocus: UserDefaults.standard.bool(forKey: "autoFocusOnCalendarNewEvent"))
                        
                } else {
                    //An event was clicked
                    EditEventViewWatch(editEvent: selectedEditEvent)
                        
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
        
        
        self._showingEditEventSheet = showingEditEventSheet
        
        
    }
    
    func getSelectedTime (idx: Int) -> Date {
        
        var dateComponents = DateComponents()
        dateComponents.year = Calendar.current.component(.year, from: filteredDay)
        dateComponents.month = Calendar.current.component(.month, from: filteredDay)
        dateComponents.day = Calendar.current.component(.day, from: filteredDay)
        dateComponents.hour = Int(Double(idx)*DailyPlannerWatch.minimumEventHeight/hourHeight)
        dateComponents.minute = (idx % Int(hourHeight/DailyPlannerWatch.minimumEventHeight))*Int(60*DailyPlannerWatch.minimumEventHeight/hourHeight)

        // Create date from components
        let userCalendar = Calendar(identifier: .gregorian) // since the components above (like year 1980) are for Gregorian
        let someDateTime: Date = userCalendar.date(from: dateComponents)!
        
        return someDateTime
    }
    
    // maybe I will want a scroll to now toggle function
    
    func eventCell(_ event: N40Event, allEvents: [N40Event]) -> some View {
        
        //all events is used for wrapping around other events.
        
        var height = Double(event.duration) / 60 * hourHeight
        if (height < DailyPlannerWatch.minimumEventHeight) {
            height = DailyPlannerWatch.minimumEventHeight
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
                                Button(action: {
                                    completeToDoEvent(toDo: event)
                                }) {
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
                        .offset(y: (DailyPlannerWatch.minimumEventHeight-height)/2)
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
//                let impactMed = UIImpactFeedbackGenerator(style: .heavy)
//                impactMed.impactOccurred()
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
                            let minimumDuration = 60.0/hourHeight*DailyPlannerWatch.minimumEventHeight
//                            let numOfMinutesMoved = Double(Int(moveAmount/hourHeight*60.0/minimumDuration) + (moveAmount<0 ? -1 : 0))*minimumDuration
                            let numOfMinutesMoved = round($0.translation.height/hourHeight*60.0/minimumDuration)*minimumDuration
                            let roundMinutesDifference = Double(event.startDate.get(.minute)) - (Double(event.startDate.get(.minute))/minimumDuration).rounded()*minimumDuration
                            
                            dragging = false
                            drawDragMinuteOffset = 0
                            
                            withAnimation {
                                
                                
                                event.startDate = Calendar.current.date(byAdding: .minute, value: Int(numOfMinutesMoved - roundMinutesDifference), to: event.startDate) ?? event.startDate
                                
                                do {
                                    try viewContext.save()
                                } catch {
                                    // handle error
                                }
                                
                                
                            }
                        })
            }
            
        }
        
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
    
    
    func getNowOffset() -> CGFloat {
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let offset = Double(hour)*hourHeight + Double(minute)/60*hourHeight
        
        return offset
        
        
    }
    
    
}


struct AllDayListWatch: View {
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
    
    var body: some View {
        VStack {
            let allGoalsToday = fetchedGoalsDueToday.sorted(by: {$0.name < $1.name}) + fetchedGoalsFinishedToday.sorted(by: {$0.name < $1.name})
            VStack {
                if getCount()>1 {
                    TabView {
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
                        
                    }.tabViewStyle(.page)
                } else {
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
                }
                    
                    
            }.frame(height: getCount() > 0 ? allEventHeight : 0)
        }.sheet(isPresented: $showingDetailSheet) { [detailShowing, selectedEvent, selectedBirthdayBoy, selectedGoal] in
            NavigationView {
                //ZStack {
                    if detailShowing == DetailOptions.event {
                        EditEventViewWatch(editEvent: selectedEvent)
                        
                    } else if detailShowing == DetailOptions.goal {
                        if selectedGoal != nil {
                            GoalViewWatch(editGoal: selectedGoal!)
                        } else {
                            Text("No Goal Selected")
                        }
                    } else {
                        if selectedBirthdayBoy != nil {
                            PersonViewWatch(editPerson: selectedBirthdayBoy!)
                        } else {
                            Text("No Birthday Boy or Girl Selected")
                        }
                    }
                //}
                
            }.navigationViewStyle(StackNavigationViewStyle())
                
                
        }
    }
    
    func getCount() -> Int {
        return fetchedAllDays.count + fetchedBirthdayBoys.count + fetchedGoalsDueToday.sorted(by: {$0.name < $1.name}).count + fetchedGoalsFinishedToday.sorted(by: {$0.name < $1.name}).count + (holidays[filteredDay.startOfDay] != nil && UserDefaults.standard.bool(forKey: "showHolidays") ? 1 : 0)
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
                        
                        // sharing to EK is not supported for watch version
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
