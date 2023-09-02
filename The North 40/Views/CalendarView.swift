//
//  CalendarView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

import SwiftUI
import CoreData

public let DEFAULT_EVENT_COLOR = Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))


struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedDay = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                
                VStack {
                    Text("Daily Planner")
                        .font(.title2)
                    HStack {
                        Text(selectedDay.dayOfWeek())
                        
                        DatePicker("Selected Day", selection: $selectedDay, displayedComponents: .date)
                            .labelsHidden()
                        
                        
                        Spacer()
                        
                        Button("Today") {
                            selectedDay = Date()
                            
                        }
                    }
                    .padding(.horizontal)
                    
                    AllDayList(filter: selectedDay)
                        .environment(\.managedObjectContext, viewContext)
                    
                    
                    DailyPlanner(filter: selectedDay)
                        .environment(\.managedObjectContext, viewContext)
                    
                    
                    
                    
                }
                
                
            }
        }
        .gesture(DragGesture(minimumDistance: 15, coordinateSpace: .global)
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

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}

struct AllDayList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    
    @FetchRequest var fetchedAllDays: FetchedResults<N40Event>
    @FetchRequest var fetchedGoalsDueToday: FetchedResults<N40Goal>
    @FetchRequest var fetchedBirthdayBoys: FetchedResults<N40Person>
    
    @State private var showingEditEventSheet = false
    
    private var filteredDay: Date
    
    private let allEventHeight = 25.0
    
    
    var body: some View {
        if (fetchedAllDays.count + fetchedGoalsDueToday.count) > 3 {
            ScrollView {
                ForEach(fetchedAllDays) { eachEvent in
                    allDayEvent(eachEvent)
                }
                ForEach(fetchedGoalsDueToday) { eachGoal in
                    dueGoal(eachGoal)
                }
            }.frame(height: 3*allEventHeight)
        } else {
            VStack {
                ForEach(fetchedAllDays) { eachEvent in
                    allDayEvent(eachEvent)
                }
                ForEach(fetchedGoalsDueToday) { eachGoal in
                    dueGoal(eachGoal)
                }
                ForEach(fetchedBirthdayBoys) { eachBirthdayBoy in
                    birthdayBoyCell(eachBirthdayBoy)
                }
            }
        }
        
    }
    
    init (filter: Date) {
        let todayPredicateA = NSPredicate(format: "startDate >= %@", filter.startOfDay as NSDate)
        let todayPredicateB = NSPredicate(format: "startDate < %@", filter.endOfDay as NSDate)
        let scheduledPredicate = NSPredicate(format: "isScheduled == YES")
        
        let allDayPredicate = NSPredicate(format: "allDay == YES")
        
        
        _fetchedAllDays = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [todayPredicateA, todayPredicateB, scheduledPredicate, allDayPredicate]))
        
        let dueDatePredicateA = NSPredicate(format: "deadline >= %@", filter.startOfDay as NSDate)
        let dueDatePredicateB = NSPredicate(format: "deadline <= %@", filter.endOfDay as NSDate)
        let hasDeadlinePredicate = NSPredicate(format: "hasDeadline == YES")
        
        _fetchedGoalsDueToday = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.name, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [dueDatePredicateA, dueDatePredicateB, hasDeadlinePredicate]))
        
        let birthdayMonthPredicate = NSPredicate(format: "birthdayMonth == %i", Int16(filter.get(.month)))
        let birthdayDayPredicate = NSPredicate(format: "birthdayDay == %i", Int16(filter.get(.day)))
        let hasBirthdayPredicate = NSPredicate(format: "hasBirthday == YES")
        
        _fetchedBirthdayBoys = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.firstName, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [birthdayDayPredicate, birthdayMonthPredicate, hasBirthdayPredicate]))
        
        
        self.filteredDay = filter
    }
    
    func allDayEvent(_ event: N40Event) -> some View {
        //all events is used for wrapping around other events.
        

        return NavigationLink(destination: EditEventView(editEvent: event), label: {
                
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill((Color(hex: event.color) ?? DEFAULT_EVENT_COLOR))
                        .opacity(0.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    
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
                        
                
                    
                    
                    
                    if (event.recurringTag != "") {
                        HStack {
                            Spacer()
                            ZStack {
                                Image(systemName: "repeat")
                                if (isRecurringEventLast(event: event)) {
                                    Image(systemName: "line.diagonal")
                                        .scaleEffect(x: -1.2, y: 1.2)
                                }
                            }
                                
                        }.padding(.horizontal, 8)
                    }
                }
                
            })
            .buttonStyle(.plain)
            .font(.caption)
            .frame(height: allEventHeight)
            
            
        
    }
    
    func dueGoal(_ goal: N40Goal) -> some View {
        //all events is used for wrapping around other events.
        

        return NavigationLink(destination: GoalDetailView(selectedGoal: goal), label: {
                
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray)
                        .opacity(0.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(((colorScheme == .dark) ? .white : .black))
                    
                    HStack {
        

                        Text("Goal: \(goal.name) - \(goal.deadline.dateOnlyToString())").bold()
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                        
                }
                
            })
            .buttonStyle(.plain)
            .font(.caption)
            .frame(height: allEventHeight)
            
            
        
    }
    
    func birthdayBoyCell(_ person: N40Person) -> some View {
        

        return NavigationLink(destination: PersonDetailView(selectedPerson: person), label: {
                
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
                
            })
            .buttonStyle(.plain)
            .font(.caption)
            .frame(height: allEventHeight)
            
            
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
    
    func isRecurringEventLast (event: N40Event) -> Bool {
        var isLast = false
        
        let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
        
        let isScheduledPredicate = NSPredicate(format: "isScheduled = %d", true)
        let isFuturePredicate = NSPredicate(format: "startDate >= %@", (event.startDate as CVarArg)) //will include this event
        let sameTagPredicate = NSPredicate(format: "recurringTag == %@", (event.recurringTag))
        
        let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [isScheduledPredicate, isFuturePredicate, sameTagPredicate])
        fetchRequest.predicate = compoundPredicate
        
        do {
            // Peform Fetch Request
            let fetchedEvents = try viewContext.fetch(fetchRequest)
            
            if fetchedEvents.count == 1 {
                isLast = true
            }
            
        } catch {
            print("couldn't fetch recurring events")
        }
        
        return isLast
        
    }
    
    
}

struct DailyPlanner: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest var fetchedEvents: FetchedResults<N40Event>
    
    @State private var showingEditEventSheet = false
    @State private var clickedOnTime = Date()
    
    @State private var hourHeight = UserDefaults.standard.double(forKey: "hourHeight")
    public static let minimumEventHeight = 25.0
    
    private var filteredDay: Date
        
    
    var body: some View {
        
        //The main timeline
        ScrollView {
            ZStack(alignment: .topLeading) {
                
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
                    }
                }
                
                //Invisible buttons to add an event
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: hourHeight/2) //offset the buttons by 2 slots
                    
                    
                    ForEach(0..<(24*Int(hourHeight/DailyPlanner.minimumEventHeight))) {idx in
                        Rectangle()
                            .fill(Color.black.opacity(0.0001))
                            .onTapGesture {
                                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                                    impactMed.impactOccurred()
                                
                                clickedOnTime = getSelectedTime(idx: idx)
                                showingEditEventSheet.toggle()
                            }
                            .frame(height: DailyPlanner.minimumEventHeight)
                    }
                    
                }.sheet(isPresented: $showingEditEventSheet) { [clickedOnTime] in
                    EditEventView(editEvent: nil, chosenStartDate: clickedOnTime)
                }
                
                
                ForEach(fetchedEvents) { event in
                    eventCell(event, allEvents: fetchedEvents.reversed())
                }
                if (filteredDay.startOfDay == Date().startOfDay) {
                    Color.red
                        .frame(height: 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .offset(x: 0, y: getNowOffset() + hourHeight/2)
                    
                    
                }
    
                
                
            }
            //.gesture(magnification)
            
        }
        //.scrollPosition(initialAnchor: .center) // Doesn't work yet with current version of swift.
        .onAppear {
            hourHeight = UserDefaults.standard.double(forKey: "hourHeight")
        }
        
    }
    
    @GestureState private var zoomFactor: CGFloat = 1.0
    @State var oldZoomValue = 1.0
    var magnification: some Gesture {
        return MagnificationGesture()
            .updating($zoomFactor) { value, scale, transaction in
                // updating scale with returned value from magnification gesture
                withAnimation {
                    scale = value
                }
            }
            .onChanged { value in

                withAnimation {
                    
                    let newModifier = (value-oldZoomValue) * 100.0
                    
                    hourHeight += newModifier
                    
                    if hourHeight > (DailyPlanner.minimumEventHeight*12) {
                        hourHeight = (DailyPlanner.minimumEventHeight*12) //No smaller than every 5 minute zoom.
                    }
                    if hourHeight < (DailyPlanner.minimumEventHeight*2) {
                        hourHeight = (DailyPlanner.minimumEventHeight*2) // no bigger than every 30 minute zoom.
                    }
                    
                    oldZoomValue = value
                }
            }
            .onEnded { value in
                // do nothing
                
            }
    }
    
    init (filter: Date) {
        let todayPredicateA = NSPredicate(format: "startDate >= %@", filter.startOfDay as NSDate)
        let todayPredicateB = NSPredicate(format: "startDate < %@", filter.endOfDay as NSDate)
        let scheduledPredicate = NSPredicate(format: "isScheduled == YES")
        
        let notAllDayPredicate = NSPredicate(format: "allDay == NO")
        
        _fetchedEvents = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [todayPredicateA, todayPredicateB, scheduledPredicate, notAllDayPredicate]))
        
        self.filteredDay = filter
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
    
    func allEventsAtTime(at: Date, duration: Int, allEvents: [N40Event]) -> [N40Event] {
        //returns an int of how many events are in that location
        var eventsAtTime: [N40Event] = []
        
        let minDuration = (DailyPlanner.minimumEventHeight/hourHeight*60.0)
        let testDuration = Int(duration) > Int(minDuration) ? Int(duration) : Int(minDuration)
        
        
        let startOfInterval = at.zeroSeconds
        var endOfInterval = Calendar.current.date(byAdding: .minute, value: testDuration, to: at.zeroSeconds) ?? startOfInterval
        
        if endOfInterval.timeIntervalSince(startOfInterval) > 0 {
            endOfInterval = Calendar.current.date(byAdding: .second, value: -1, to: endOfInterval) ?? endOfInterval
        } //subtract a second from the end of the interval to make it less confusing.
        
        allEvents.forEach {eachEvent in
            
            let eventTestDuration = Int(eachEvent.duration) > Int(minDuration) ? Int(eachEvent.duration) : Int(minDuration)
            
            let eventStartOfInterval = eachEvent.startDate.zeroSeconds
            var eventEndOfInterval = Calendar.current.date(byAdding: .minute, value: eventTestDuration, to: eventStartOfInterval) ?? eventStartOfInterval
            
            if eventEndOfInterval.timeIntervalSince(eventStartOfInterval) > 0 {
                eventEndOfInterval = Calendar.current.date(byAdding: .second, value: -1, to: eventEndOfInterval) ?? endOfInterval
            } //subtract a second from the end of the interval to make it less confusing.
            
            
            //  considering the ranges are: [x1:x2] and [y1:y2]
            // x1 <= y2 && y1 <= x2
            if ( startOfInterval <= eventEndOfInterval && eventStartOfInterval <= endOfInterval) {
                eventsAtTime.append(eachEvent)
            }
        }
        
        return eventsAtTime
    }

    
    func numberOfEventsAtTime(at: Date, duration: Int, allEvents: [N40Event]) -> Int {
        let allEventsAtTime = allEventsAtTime(at: at, duration: duration, allEvents: allEvents)
        return allEventsAtTime.count
    }
    
    func getLowestUntakenEventIndex (overlappingEvents: [N40Event]) -> Int {
        
        var takenIndices: [Int] = []
        
        //We need to iterate in accending order, so first just get all the indices
        overlappingEvents.forEach {eachEvent in
            takenIndices.append(eachEvent.renderIdx ?? -1)
        }
        takenIndices.sort()
        
        var lowestUntakeIdx = 0
        
        //now we can iterate through them
        takenIndices.forEach {idx in
            if idx == lowestUntakeIdx {
                lowestUntakeIdx += 1
            }
        }
        
        return lowestUntakeIdx
        
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
        
        let allEventsAtThisTime = allEventsAtTime(at: event.startDate, duration: Int(event.duration), allEvents: allEvents)
        
        event.renderIdx = -1 // basically reset it to be recalculated
        event.renderIdx = getLowestUntakenEventIndex(overlappingEvents: allEventsAtThisTime)
        
        return GeometryReader {geometry in
            NavigationLink(destination: EditEventView(editEvent: event), label: {
                
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill((Color(hex: event.color) ?? DEFAULT_EVENT_COLOR))
                        .opacity(0.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    
                    HStack {
                        if (event.eventType == N40Event.TODO_TYPE) {
                            //Button to check off the to-do
                            Button(action: { completeToDoEvent(toDo: event) }) {
                                Image(systemName: (event.status == 0) ? "square" : "checkmark.square")
                                    .disabled((event.status != 0))
                            }.buttonStyle(PlainButtonStyle())
                            
                        }
                        
                        Image(systemName: N40Event.contactOptions[Int(event.contactMethod)][1])
                        
                        Text(event.startDate.formatted(.dateTime.hour().minute()))
                        Text(event.name).bold()
                            .lineLimit(0)
                        Spacer()
                    }
                    .offset(y: (DailyPlanner.minimumEventHeight-height)/2)
                    .padding(.horizontal, 8)
                        
                
                    HStack {
                        Spacer()
                        if (event.eventType == N40Event.REPORTABLE_TYPE && event.startDate < Date()) {
                            if event.status == N40Event.UNREPORTED {
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
                        }
                        if (event.recurringTag != "") {
                            ZStack {
                                Image(systemName: "repeat")
                                if (isRecurringEventLast(event: event)) {
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
            .frame(height: height, alignment: .top)
            .frame(width: (geometry.size.width-40)/CGFloat(allEventsAtThisTime.count), alignment: .leading)
            .padding(.trailing, 30)
            .offset(x: 30 + (CGFloat(event.renderIdx ?? 0)*(geometry.size.width-40)/CGFloat(allEventsAtThisTime.count)), y: offset + hourHeight/2)
            
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
    
    func isRecurringEventLast (event: N40Event) -> Bool {
        var isLast = false
        
        let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
        
        let isScheduledPredicate = NSPredicate(format: "isScheduled = %d", true)
        let isFuturePredicate = NSPredicate(format: "startDate >= %@", (event.startDate as CVarArg)) //will include this event
        let sameTagPredicate = NSPredicate(format: "recurringTag == %@", (event.recurringTag))
        
        let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [isScheduledPredicate, isFuturePredicate, sameTagPredicate])
        fetchRequest.predicate = compoundPredicate
        
        do {
            // Peform Fetch Request
            let fetchedEvents = try viewContext.fetch(fetchRequest)
            
            if fetchedEvents.count == 1 {
                isLast = true
            }
            
        } catch {
            print("couldn't fetch recurring events")
        }
        
        return isLast
        
    }
    
    
}



extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    var startOfWeek: Date {
        Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date!
    }
    
    var endOfWeek: Date {
        var components = DateComponents()
        components.weekOfYear = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfWeek)!
    }
    
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: startOfDay)
        return Calendar.current.date(from: components)!
    }
    
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth)!
    }
    
    
    var zeroSeconds: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return calendar.date(from: dateComponents) ?? self
    }
    
    func dayOfWeek() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self).capitalized
        // or use capitalized(with: locale) if you want
    }
    
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
    
    func dateOnlyToString () -> String {
        // Create Date Formatter
        let dateFormatter = DateFormatter()

        // Set Date Format
        dateFormatter.dateFormat = "MMM d, y"

        // Convert Date to String
        return dateFormatter.string(from: self)
    }
    
    // End of day = Start of tomorrow minus 1 second
    // End of week = Start of next week minus 1 second
    // End of month = Start of next month minus 1 second
    
}




