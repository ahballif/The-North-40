//
//  TimelineView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/26/23.
//

import SwiftUI

struct TimelineView: View {
    
    @State private var events: [N40Event]
    
    init (events: [N40Event]) {
        self.events = events
    }
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(events) { eachEvent in
                    eventDisplayBoxView(myEvent: eachEvent)
                }
            }
        }
    }
}

private struct eventDisplayBoxView: View {
    @Environment(\.managedObjectContext) private var viewContext
    //viewContext used for saving if you check off an item
    
    
    @State var myEvent: N40Event
    
    var body: some View {
        NavigationLink(destination: EditEventView(editEvent: myEvent), label: {
            ZStack {
                HStack {
                    
                    if (myEvent.eventType == N40Event.TODO_TYPE) {
                        //Button to check off the to-do
                        Button(action: { completeToDoEvent(toDo: myEvent) }) {
                            Image(systemName: (myEvent.status == 0) ? "square" : "checkmark.square")
                                .disabled((myEvent.status != 0))
                        }.buttonStyle(PlainButtonStyle())
                        
                    }
                    
                    Image(systemName: N40Event.contactOptions[Int(myEvent.contactMethod)][1])
                    
                    VStack {
                        HStack {
                            Text(formatDateToString(date: myEvent.startDate))
                            Spacer()
                        }
                        HStack {
                            Text(myEvent.name)
                            Spacer()
                        }
                    }
                    
                }
                if (myEvent.recurringTag != "") {
                    HStack {
                        Spacer()
                        Image(systemName: "repeat")
                    }
                }
            }.padding()
        })
        .buttonStyle(.plain)
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: myEvent.color) ?? DEFAULT_EVENT_COLOR).opacity(0.5)
        )
        .padding(.horizontal)
        .padding(.vertical, 1)
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

