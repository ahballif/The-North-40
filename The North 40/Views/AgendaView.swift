//
//  AgendaView.swift
//  The North 40
//
//  Created by Addison Ballif on 9/9/23.
//

import SwiftUI
import CoreData

struct AgendaView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest var fetchedEvents: FetchedResults<N40Event>
    
    @State private var showingEditEventSheet = false
    @State private var selectedEditEvent: N40Event? = nil
    
    private var filteredDay: Date
    
    
    init (filter: Date) {
        let todayPredicateA = NSPredicate(format: "startDate >= %@", filter.startOfDay as NSDate)
        let todayPredicateB = NSPredicate(format: "startDate < %@", filter.endOfDay as NSDate)
        let scheduledPredicate = NSPredicate(format: "isScheduled == YES")
        
        let notAllDayPredicate = NSPredicate(format: "allDay == NO")
        
        _fetchedEvents = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [todayPredicateA, todayPredicateB, scheduledPredicate, notAllDayPredicate]))
        
        self.filteredDay = filter
    }
    
    
    
    var body: some View {
        ZStack {
            ScrollViewReader {value in
                ScrollView {
                    VStack {
                        
                        ForEach(0..<fetchedEvents.count, id: \.self) {i in
                            let event = fetchedEvents[i]
                            
                            
                            let lastHour = i == 0 ? 0 : Calendar.current.component(.hour, from: fetchedEvents[i-1].startDate)
                            let hour = Calendar.current.component(.hour, from: event.startDate)
                            
                            if Date() < event.startDate && filteredDay.startOfDay == Date().startOfDay {
                                //red line for now
                                if i > 0 {
                                    if fetchedEvents[i-1].startDate < Date() && event.startDate > Date() {
                                        Color.red
                                            .frame(height: 1)
                                            .tag("now")
                                    }
                                }
                                
                            }
                            
                            //Gray lines for hours
                            if (hour > lastHour) {
                                
                                HStack {
                                    Text("\(((hour+11) % 12)+1) \(hour < 12 ? "A" : "P")M")
                                        .font(.caption)
                                        //.frame(width: 20, alignment: .trailing)
                                    Color.gray
                                        .frame(height: 1)
                                    
                                }
                            }
                            
                            if Date() > event.startDate && filteredDay.startOfDay == Date().startOfDay {
                                //red line for now
                                if i > 0 {
                                    if fetchedEvents[i-1].startDate < Date() && event.startDate > Date() {
                                        Color.red
                                            .frame(height: 1)
                                            .id("now")
                                    }
                                }
                                
                            }
                            
                            
                            
                            
                            eventCell(event)
                        }
                    }
                }
                .onAppear {
                    if (filteredDay == Date()) {
                        value.scrollTo("now")
                    }
                }
                .onChange(of: filteredDay) {_ in
                    if (filteredDay == Date()) {
                        value.scrollTo("now")
                    } else {
                        value.scrollTo(Calendar.current.component(.hour, from: filteredDay))
                    }
                }
            }
            
            
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {
                        selectedEditEvent = nil
                        showingEditEventSheet.toggle()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(minWidth: 50, maxWidth: 50)
                            .padding(30)
                    }
                    .sheet(isPresented: $showingEditEventSheet) { [selectedEditEvent] in
                        NavigationView {
                            if selectedEditEvent == nil {
                                EditEventView(editEvent: nil)
                            } else {
                                //An event was clicked
                                EditEventView(editEvent: selectedEditEvent)
                            }
                        }
                    }
                }
            }
            
        }
        
    }
    
    func eventCell(_ event: N40Event) -> some View {
        
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
        
        return ZStack {
            
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
                
                VStack {
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
                        Text(event.startDate.formatted(.dateTime.hour().minute()))
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
        }
        .buttonStyle(.plain)
        .font(.caption)
        .padding(.horizontal, 4)
        .padding(.leading, 30)
        .onTapGesture {
            selectedEditEvent = event
            showingEditEventSheet.toggle()
        }
        
    }
    
    
    private func completeToDoEvent (toDo: N40Event) {
        //checks off to do items or unchecks them
        
        if (toDo.status == 0) {
            toDo.status = 2
            
            if UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_AgendaView") && (!UserDefaults.standard.bool(forKey: "onlyScheduleUnscheduledTodos") || !toDo.isScheduled) {
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
