//
//  CalendarView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

import SwiftUI

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedDay = Date()
    
    
    var body: some View {
        VStack {
            Text("Daily Planner")
                .font(.title)
            HStack {
                
                DatePicker(selection: $selectedDay, displayedComponents: .date) {
                    Text("Selected Day:")
                }
                Spacer()
                
                Button("Today") {
                    selectedDay = Date()
                }
            }
            .padding()
            
            Spacer()
            
            DailyPlanner(filter: selectedDay)
            
            
            
            
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}



struct DailyPlanner: View {
    
    @FetchRequest var fetchedEvents: FetchedResults<N40Event>
    
    private let hourHeight = 50.0
    private let startHour = 5
    
    var body: some View {
        
        //The main timeline
        ScrollView {
            ZStack(alignment: .topLeading) {
                
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(startHour..<24) { hour in
                        HStack {
                            Text("\(((hour-1) % 12)+1)")
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
                
                Color.red
                    .frame(height: 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(x: 0, y: getNowOffset() + 24)
            }
        }
        
    }
    
    init (filter: Date) {
        _fetchedEvents = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "startDate >= %@", filter.startOfDay as NSDate), NSPredicate(format: "startDate < %@", filter.endOfDay as NSDate)]))
    }
    
    func eventCell(_ event: N40Event) -> some View {
        
        let height = Double(event.duration) / 60 * hourHeight
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)
        let offset = Double(hour-startHour) * (hourHeight) + Double(minute)/60  * hourHeight
        
        
        return VStack(alignment: .leading) {
            Text(event.startDate.formatted(.dateTime.hour().minute()))
            Text(event.name).bold()
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
        .frame(height: height, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.teal).opacity(0.5)
        )
        .padding(.trailing, 30)
        .offset(x: 30, y: offset + 24)
        
    }
    
    func getNowOffset() -> CGFloat {
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let offset = Double(hour-startHour)*hourHeight + Double(minute)/60*hourHeight
        
        return offset
        
        
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




