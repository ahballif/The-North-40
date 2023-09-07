//
//  TimelineView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/26/23.
//

import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var updater: RefreshView
    
    @FetchRequest var events: FetchedResults<N40Event>
    
    
    init (goal: N40Goal) {
        _events = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: false)], predicate: NSPredicate(format: "(ANY attachedGoals == %@)", goal), animation: .default)
    }
    
    init (person: N40Person) {
        _events = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: false)], predicate: NSPredicate(format: "(ANY attachedPeople == %@)", person), animation: .default)
    }
    
    var body: some View {
        ScrollView {
            VStack {
                
                //unschedule first
                ForEach(events.filter { !$0.isScheduled && $0.eventType != N40Event.BACKUP_TYPE}) { eachEvent in
                    eventDisplayBoxView(myEvent: eachEvent).environmentObject(updater)
                }
                //scheduled next
                ForEach(events.filter { ($0.startDate > Date() && $0.isScheduled) && $0.eventType != N40Event.BACKUP_TYPE }) { eachEvent in
                    eventDisplayBoxView(myEvent: eachEvent).environmentObject(updater)
                }
                
                VStack {
                    Rectangle()
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 5)
                    
                }
                
                ForEach(events.filter { ($0.startDate < Date() && $0.isScheduled) && $0.eventType != N40Event.BACKUP_TYPE }) { eachEvent in
                    eventDisplayBoxView(myEvent: eachEvent).environmentObject(updater)
                }
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
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: myEvent.color) ?? DEFAULT_EVENT_COLOR)
                    .opacity(0.5)
                    .frame(height: cellHeight)
                    .frame(maxWidth: .infinity)
                
                
                HStack {
                    
                    if (myEvent.eventType == N40Event.TODO_TYPE) {
                        //Button to check off the to-do
                        Button(action: { completeToDoEvent(toDo: myEvent) }) {
                            Image(systemName: (myEvent.status == 0) ? "square" : "checkmark.square")
                                .disabled((myEvent.status != 0))
                        }.buttonStyle(PlainButtonStyle())
                        
                    }
                    
                    Image(systemName: N40Event.CONTACT_OPTIONS[Int(myEvent.contactMethod)][1])
                    
                    VStack {
                        if (myEvent.isScheduled) {
                            HStack {
                                Text(formatDateToString(date: myEvent.startDate))
                                    .bold()
                                Spacer()
                            }
                        }
                        HStack {
                            if (myEvent.eventType == N40Event.REPORTABLE_TYPE && myEvent.startDate < Date() ) {
                                if myEvent.summary != "" {
                                    Text(myEvent.summary)
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
                HStack {
                    Spacer()
                    if (myEvent.eventType == N40Event.REPORTABLE_TYPE && myEvent.startDate < Date()) {
                        if myEvent.status == N40Event.UNREPORTED {
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
                    }
                    if (myEvent.recurringTag != "") {
                        Image(systemName: "repeat")
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

