//
//  CalendarView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

import SwiftUI

public let DEFAULT_EVENT_COLOR = Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))


struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingEditEventSheet = false
    
    @State private var selectedDay = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                
                VStack {
                    Text("Daily Planner")
                        .font(.title)
                    HStack {
                        
                        DatePicker("Selected Day", selection: $selectedDay, displayedComponents: .date)
                            .labelsHidden()
                        Spacer()
                        
                        Button(action: {
                            selectedDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDay) ?? selectedDay
                        }) {
                            Image(systemName: "chevron.left")
                        }
                        Spacer()
                        Button(action: {
                            selectedDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDay) ?? selectedDay
                        }) {
                            Image(systemName: "chevron.right")
                        }
                        
                        Spacer()
                        
                        Button("Today") {
                            selectedDay = Date()
                            
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    DailyPlanner(filter: selectedDay)
                        .environment(\.managedObjectContext, viewContext)
                    
                    
                    
                    
                }
                
                //The Add Button
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
                            EditEventView(editEvent: nil, chosenStartDate: selectedDay)
                        }
                    }
                }
            }
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}



struct DailyPlanner: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest var fetchedEvents: FetchedResults<N40Event>
    
    private let hourHeight = 100.0
    private let minimumEventLength = 25.0
    
    private var filteredDay: Date
        
    
    var body: some View {
        
        //The main timeline
        ScrollView {
            ZStack(alignment: .topLeading) {
                
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
                
                
                ForEach(fetchedEvents) { event in
                    eventCell(event)
                }
                if (filteredDay.startOfDay == Date().startOfDay) {
                    Color.red
                        .frame(height: 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .offset(x: 0, y: getNowOffset() + hourHeight/2)
                    
                    
                }
                
                
                
            }
            
            
        }
        
    }
    
    init (filter: Date) {
        _fetchedEvents = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "startDate >= %@", filter.startOfDay as NSDate), NSPredicate(format: "startDate < %@", filter.endOfDay as NSDate), NSPredicate(format: "isScheduled == YES")]))
        
        self.filteredDay = filter
    }
    
    func eventCell(_ event: N40Event) -> some View {
        
        
        var height = Double(event.duration) / 60 * hourHeight
        if (height < minimumEventLength) {
            height = minimumEventLength
        }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)
        let offset = Double(hour) * (hourHeight) + Double(minute)/60  * hourHeight
        
        
        return NavigationLink(destination: EditEventView(editEvent: event), label: {
            HStack {
                HStack() {
                    if (event.eventType == N40Event.TODO_TYPE) {
                        //Button to check off the to-do
                        Button(action: { completeToDoEvent(toDo: event) }) {
                            Image(systemName: (event.status == 0) ? "square" : "checkmark.square")
                                .disabled((event.status != 0))
                        }.buttonStyle(PlainButtonStyle())
                        
                    }
                    
                    Text(event.startDate.formatted(.dateTime.hour().minute()))
                    Text(event.name).bold()
                    Spacer()
                }
                
            }
        })
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
        .frame(height: height, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: event.color) ?? DEFAULT_EVENT_COLOR).opacity(0.5)
        )
        .padding(.trailing, 30)
        .offset(x: 30, y: offset + hourHeight/2)
        
        
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
                    toDo.startDate = Date() //Set it as completed now.
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
    
    
    // End of day = Start of tomorrow minus 1 second
    // End of week = Start of next week minus 1 second
    // End of month = Start of next month minus 1 second
    
}




