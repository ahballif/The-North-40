//
//  TimelineView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/26/23.
//

import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var updater: RefreshView
    @Environment(\.colorScheme) var colorScheme
    
    @FetchRequest var events: FetchedResults<N40Event>
    
    @State var selectedPerson: N40Person?
    @State var selectedGoal: N40Goal?
    
    
    init (goal: N40Goal) {
        _events = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: false)], predicate: NSPredicate(format: "(ANY attachedGoals == %@)", goal), animation: .default)
        _selectedPerson = State(initialValue: nil)
        _selectedGoal = State(initialValue: goal)
    }
    
    init (person: N40Person) {
        _events = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: false)], predicate: NSPredicate(format: "(ANY attachedPeople == %@)", person), animation: .default)
        _selectedPerson = State(initialValue: person)
        _selectedGoal = State(initialValue: nil)
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(((colorScheme == .dark) ? .black : .white))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            ScrollViewReader {value in
                ScrollView {
                    VStack {
                        
                        //unschedule first
                        ForEach(events.filter { !$0.isScheduled && $0.eventType != N40Event.BACKUP_TYPE}) { eachEvent in
                            eventDisplayBoxView(myEvent: eachEvent).environmentObject(updater)
                            
                        }
                        
                        let timelineObjects = getTimelineObjects()
                        
                        //need to add tag for now line as well as updater for events
                        ForEach(timelineObjects, id: \.uniqueID) { object in
                            object.environmentObject(updater)
                                .if(object.type == TimelineType.nowLine) { view in
                                    view.id("nowLine")
                                    
                                }
                        }
                        
                        
                    }
                    .onAppear {
                        value.scrollTo("nowLine")
                    }
                }
            }
        }.padding(.horizontal, 10)
    }
    
    func getTimelineObjects () -> [TimelineObject] {
        let allScheduledEvents: [N40Event] = events.filter {  $0.isScheduled && $0.eventType != N40Event.BACKUP_TYPE }.sorted {$0.startDate > $1.startDate}
        var returnedTimelineObjects: [TimelineObject] = []
        
        //first add event in timeline objects
        for eachEvent in allScheduledEvents {
            returnedTimelineObjects.append(TimelineObject(date: eachEvent.startDate, type: TimelineType.event, event: eachEvent))
        }
        
        //next add notes, birthdays, duedates, etc.
        if selectedGoal != nil {
            //add due date and sub-goals
            if selectedGoal!.hasDeadline {
                returnedTimelineObjects.append(TimelineObject(date: selectedGoal!.deadline, type: TimelineType.dueDate, goal: selectedGoal))
            }
            for eachSubGoal in selectedGoal!.getSubGoals {
                returnedTimelineObjects.append(TimelineObject(date: eachSubGoal.deadline, type: TimelineType.subGoalDueDate, goal: eachSubGoal))
            }
            
            
            //add attached notes
            for eachNote in selectedGoal!.getAttachedNotes {
                returnedTimelineObjects.append(TimelineObject(date: eachNote.date, type: TimelineType.note, note: eachNote))
            }
        }
        if selectedPerson != nil {
            //add birthday
            if selectedPerson!.hasBirthday {
                var nextBirthday = Calendar.current.date(bySetting: .year, value: Date().get(.year), of: selectedPerson!.birthday) ?? selectedPerson!.birthday
                if (selectedPerson!.birthday.get(.month) == Date().get(.month) && selectedPerson!.birthday.get(.day) < Date().get(.day)) || (selectedPerson!.birthday.get(.month) < Date().get(.month)) {
                    //if it's earlier in the year, then we need to add another year.
                    nextBirthday = Calendar.current.date(byAdding: .year, value: 1, to: nextBirthday) ?? nextBirthday
                }
                returnedTimelineObjects.append(TimelineObject(date: nextBirthday, type: TimelineType.birthday, person: selectedPerson!))
            }
            
            //add attached notes
            for eachNote in selectedPerson!.getAttachedNotes {
                returnedTimelineObjects.append(TimelineObject(date: eachNote.date, type: TimelineType.note, note: eachNote))
            }
        }
        
        //add the now line
        returnedTimelineObjects.append(TimelineObject(date: Date(), type: TimelineType.nowLine))
        
        //add the months and years
        returnedTimelineObjects = returnedTimelineObjects.sorted { $0.date > $1.date} //sort the list
        var linesToAdd: [TimelineObject] = [] //These need to be added after iterating through
        for i in 0..<returnedTimelineObjects.count {
            
            if i < (returnedTimelineObjects.count-1) {
                //if it's not the last one, see if we should insert a line or divider.
            
                
                if (returnedTimelineObjects[i].date.get(.month) != returnedTimelineObjects[i+1].date.get(.month)) {
                    //Draw a line to delineate month
                    linesToAdd.append(TimelineObject(date: returnedTimelineObjects[i].date, type: TimelineType.month))
                }
                if (returnedTimelineObjects[i].date.get(.year) != returnedTimelineObjects[i+1].date.get(.year)) {
                    //Draw a line to delineate month
                    linesToAdd.append(TimelineObject(date: returnedTimelineObjects[i].date, type: TimelineType.year))
                }
                
            } else {
                //comparisons if its the last in the loop
                
                if (returnedTimelineObjects[i].date.get(.month) != Date().get(.month)) {
                    //Draw a line to delineate month
                    linesToAdd.append(TimelineObject(date: returnedTimelineObjects[i].date, type: TimelineType.month))
                }
                if (returnedTimelineObjects[i].date.get(.year) != Date().get(.year)) {
                    //Draw a line to delineate month
                    linesToAdd.append(TimelineObject(date: returnedTimelineObjects[i].date, type: TimelineType.year))
                }
            }
        }
        returnedTimelineObjects += linesToAdd
        
        return returnedTimelineObjects.sorted {$0.date > $1.date}
    }
}

enum TimelineType {
    case event, dueDate, subGoalDueDate, birthday, month, year, nowLine, note
}

struct TimelineObject: View {
    @EnvironmentObject var updater: RefreshView
    @Environment(\.colorScheme) var colorScheme
    
    let uniqueID = UUID()
    
    public let date: Date
    public let type: TimelineType
    
    private let event: N40Event?
    private let person: N40Person?
    private let goal: N40Goal?
    private let note: N40Note?
    
    @State var showingDetailSheet = false
    
    init(date: Date, type: TimelineType, event: N40Event? = nil, person: N40Person? = nil, goal: N40Goal? = nil, note: N40Note? = nil) {
        self.date = date
        self.type = type
        
        self.event = event
        self.person = person
        self.goal = goal
        self.note = note
    }
    
    var body: some View {
        ZStack {
            if type == TimelineType.nowLine {
                //draw the now line
                HStack {
                    Rectangle()
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 5)
                    Text("NOW")
                        .bold()
                        .foregroundColor(.red)
                    Rectangle()
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 5)
                }.padding(.horizontal, 5)
            } else if type == TimelineType.year {
                //Draw a line to dilineate year
                HStack {
                    Text(String(date.get(.year)))
                    Color.gray
                        .frame(maxWidth: .infinity)
                        .frame(height: 2)
                }.padding(.horizontal, 5)
            } else if type == TimelineType.month {
                //Draw a line to delineate month
                HStack {
                    Text("\(date.getMonthString())")
                    Color.gray
                        .frame(maxWidth: .infinity)
                        .frame(height: 1)
                }.padding(.horizontal, 5)
            } else if type == TimelineType.event {
                //Draw the event box
                if event != nil {
                    eventDisplayBoxView(myEvent: self.event!).environmentObject(updater)
                } else {
                    Text("nil event")
                }
            } else if type == TimelineType.dueDate {
                //Draw the due date
                if goal != nil {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray)
                            .opacity(0.0001)
                        //.frame(height: 30.0)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(((colorScheme == .dark) ? .white : .black), lineWidth: 2)
                                    .opacity(0.5)
                            )
                        
                        Text("Deadline: \(date.dateOnlyToString())").padding()
                        
                    }
                } else {
                    Text("nil goal")
                }
            } else if type == TimelineType.subGoalDueDate {
                if goal != nil {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill((Color(hex: goal!.color) ?? DEFAULT_EVENT_COLOR))
                            .opacity(1.0)
                        //.frame(height: cellHeight)
                            .frame(maxWidth: .infinity)
                        
                        Text("Sub Goal: \(goal!.name)").padding()
                        
                    }.onTapGesture {
                        showingDetailSheet.toggle()
                    }
                } else {
                    Text("nil sub-goal")
                }
            } else if type == TimelineType.birthday {
                if person != nil {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray)
                            .opacity(0.0001)
                        //.frame(height: 30.0)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.pink, lineWidth: 2)
                                    .opacity(0.5)
                            )
                        
                        Text("\(person!.firstName)'s Birthday!🎉").padding()
                    }
                } else {
                    Text("nil birthday boy")
                }
            } else if type == TimelineType.note {
                if note != nil {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray)
                            .opacity(0.25)
                            //.frame(height: 50.0)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(((colorScheme == .dark) ? .white : .black), lineWidth: 2)
                                    .opacity(0.5)
                            )
                        VStack {
                            HStack {
                                Text(note!.title).bold()
                                Spacer()
                            }
                            
                            HStack {
                                Text(note!.information).lineLimit(2)
                                Spacer()
                            }
                        }.padding()
                        
                    }
                    .onTapGesture {
                        showingDetailSheet.toggle()
                    }
                } else {
                    Text("nil note")
                }
            }
        }
            .padding(.horizontal)
            .padding(.vertical, 2)
            .sheet(isPresented: $showingDetailSheet) {
            if goal != nil {
                //show the goal
                NavigationView {
                    GoalDetailView(selectedGoal: goal!)
                }
            } else {
                //show the note
                EditNoteView(editNote: note)
            }
        }
    }
    
}

private struct eventDisplayBoxView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var updater: RefreshView
    //viewContext used for saving if you check off an item
    
    
    @State var myEvent: N40Event
    
    private let cellHeight = 50.0
    
    @State private var showingEditViewSheet = false
    
    var body: some View {
        NavigationLink (destination: EditEventView(editEvent: myEvent).onDisappear(perform: {updater.updater.toggle()} )){
            ZStack {
                //Draw the background box different based on event type
                let colorHex = myEvent.color
                if myEvent.eventType == N40Event.INFORMATION_TYPE {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray)
                        .opacity(0.0001)
                        .frame(height: cellHeight)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke((Color(hex: colorHex) ?? DEFAULT_EVENT_COLOR), lineWidth: 2)
                                .opacity(0.5)
                        )
                } else if myEvent.eventType == N40Event.BACKUP_TYPE {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray)
                        .opacity(0.25)
                        .frame(height: cellHeight)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke((Color(hex: colorHex) ?? DEFAULT_EVENT_COLOR), lineWidth: 2)
                                .opacity(0.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill((Color(hex: colorHex) ?? DEFAULT_EVENT_COLOR))
                        .opacity(0.5)
                        .frame(height: cellHeight)
                        .frame(maxWidth: .infinity)
                }
                
                
                HStack {
                    
                    if (myEvent.eventType == N40Event.TODO_TYPE) {
                        //Button to check off the to-do
                        Button(action: { completeToDoEvent(toDo: myEvent) }) {
                            Image(systemName: (myEvent.status == 0) ? "square" : "checkmark.square")
                                .disabled((myEvent.status != 0))
                        }.buttonStyle(PlainButtonStyle())
                        
                    }
                    if myEvent.contactMethod != 0 {
                        Image(systemName: N40Event.CONTACT_OPTIONS[Int(myEvent.contactMethod)][1])
                    }
                    
                    VStack {
                        if (myEvent.isScheduled) {
                            HStack {
                                if myEvent.allDay {
                                    Text(myEvent.startDate.dateOnlyToString())
                                        .bold()
                                } else {
                                    Text(formatDateToString(date: myEvent.startDate))
                                        .bold()
                                }
                                Spacer()
                            }
                        }
                        HStack {
                            if (myEvent.eventType == N40Event.REPORTABLE_TYPE && myEvent.startDate < Date() ) {
                                if myEvent.summary != "" {
                                    Text(myEvent.summary)
                                        .lineLimit(2)
                                } else if myEvent.information != "" {
                                    Text(myEvent.information)
                                        .lineLimit(2)
                                } else {
                                    Text(myEvent.name)
                                        .lineLimit(2)
                                }
                            } else {
                                Text(myEvent.name)
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                    }
                    
                }.padding()
                
                //The reportable circle
                HStack {
                    Spacer()
                    if (myEvent.eventType == N40Event.REPORTABLE_TYPE) {
                        if myEvent.startDate > Date() {
                            Image(systemName: "circle.dotted")
                                .resizable()
                                .frame(width: 20, height:20)
                        } else if myEvent.status == N40Event.UNREPORTED {
                            Image(systemName: "questionmark.circle.fill")
                                .resizable()
                                .foregroundColor(Color.orange)
                                .frame(width: 20, height:20)
                        } else if myEvent.status == N40Event.SKIPPED {
                            Image(systemName: "slash.circle.fill")
                                .resizable()
                                .foregroundColor(Color.red)
                                .frame(width: 20, height:20)
                        } else if myEvent.status == N40Event.ATTEMPTED {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .foregroundColor(Color.red)
                                .frame(width: 20, height:20)
                        } else if myEvent.status == N40Event.HAPPENED {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .foregroundColor(Color.green)
                                .frame(width: 20, height:20)
                        }
                    } else if (myEvent.eventType == N40Event.INFORMATION_TYPE) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .resizable()
                            .frame(width: 20, height:20)
                    }
                    
                    //the repeating event icon
                    if (myEvent.recurringTag != "") {
                        ZStack {
                            Image(systemName: "repeat")
                            if (myEvent.isRecurringEventLast(viewContext: viewContext)) {
                                Image(systemName: "line.diagonal")
                                    .scaleEffect(x: -1.2, y: 1.2)
                            }
                        }
                    }
                    
                        
                }.padding(.horizontal, 8)
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: cellHeight)
            .padding(.horizontal)
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .font(.caption)
        .sheet(isPresented: $showingEditViewSheet) {
            EditEventView(editEvent: myEvent).environmentObject(updater)
        }
    //.offset(x: 30, y: offset + hourHeight/2)
        
    }
    
    
    private func formatDateToString(date: Date) -> String {
        // Create Date Formatter
        let dateFormatter = DateFormatter()

        // Set Date/Time Style
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short

        // Convert Date to String
        return dateFormatter.string(from: date) // April 19, 2023 at 4:42 PM
    }
    
    private func completeToDoEvent (toDo: N40Event) {
        //checks off to do items or unchecks them
        
        if (toDo.status == 0) {
            toDo.status = 2
            
            if UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_TimelineView") {
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
            
            updater.updater.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                //Wait 2 seconds to change from attempted to completed so it doesn't disappear too quickly
                if (toDo.status == 2) {
                    //This means it was checked off but hasn't been finally hidden
                    toDo.status = 3
                    updater.updater.toggle()
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
            updater.updater.toggle()
            do {
                try viewContext.save()
            } catch {
                // handle error
            }
        }
    }
}

extension Date {
    func getMonthString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL"
        let nameOfMonth = dateFormatter.string(from: self)
        
        return nameOfMonth
    }
}
