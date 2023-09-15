//
//  The_North_40App.swift
//  The North 40
//
//  Created by Addison Ballif on 8/7/23.
//

import SwiftUI
import CoreData

@main
struct The_North_40App: App {
    let persistenceController = PersistenceController.shared

    init() {
        UserDefaults.standard.register(defaults: [
            "hourHeight": 100.0,
            "randomEventColor": true,
            "guessEventColor": true,
            "defaultContactMethod": 0,
            "defaultCalendarEventType": 1,
            "scheduleCompletedTodos_ToDoView": true,
            "scheduleCompletedTodos_CalendarView": false,
            "scheduleCompletedTodos_AgendaView": true,
            "scheduleCompletedTodos_EditEventView": false,
            "scheduleCompletedTodos_TimelineView": true,
            "showingInfoEvents": false
        ])
        
        //THIS IS ONLY FOR ADDING CONTACT METHODS AT THE BEGINNING OF N40Event.CONTACT_OPTIONS
        //IT PRESERVES THE VALUES FOR EACH OF THE ALREADY CREATED EVENTS
        
        //IF YOU USE IT ONLY LET THE APP RUN ONCE BEFORE INSTALLING IT AGAIN WITHOUT THIS CODE
        
//        let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
//
//        do {
//            // Peform Fetch Request
//            let fetchedEvents = try persistenceController.container.viewContext.fetch(fetchRequest)
//
//            fetchedEvents.forEach {event in
//                event.contactMethod += 1
//            }
//
//            // To save the entities to the persistent store, call
//            // save on the context
//            do {
//                try persistenceController.container.viewContext.save()
//            }
//            catch {
//                // Handle Error
//                print("Error info: \(error)")
//
//            }
//
//
//        } catch let error as NSError {
//            print("Couldn't fetch other recurring events. \(error), \(error.userInfo)")
//        }
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
