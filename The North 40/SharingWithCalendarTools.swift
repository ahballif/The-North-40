//
//  SharingWithCalendarTools.swift
//  The North 40
//
//  Created by Addison Ballif on 8/20/24.
//

import Foundation
import EventKit
import SwiftUI
import UIKit
import CoreData

public func confirmDefaultCalendar(viewContext: NSManagedObjectContext, eventStore: EKEventStore) {
    // check to see if there is a North 40 calendar, and if there isn't, make one
    if (eventStore.calendars(for: .event).filter { $0.title == "North 40" }.count == 0) {
        
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        
        // Set the calendar properties
        newCalendar.title = "North 40"
        newCalendar.source = eventStore.defaultCalendarForNewEvents?.source
        newCalendar.cgColor = getCalendarDefaultColor(viewContext: viewContext).toCGColor()
        
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            print("Calendar created successfully.")
        } catch {
            print("Failed to create calendar: \(error.localizedDescription)")
        }
        
    }
}

public func confirmGoalCalendar(goal: N40Goal, viewContext: NSManagedObjectContext, eventStore: EKEventStore) {
    // check to see if there is a North 40 calendar, and if there isn't, make one
    if (eventStore.calendars(for: .event).filter { $0.title == goal.name }.count == 0) {
        
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        
        // Set the calendar properties
        newCalendar.title = goal.name
        newCalendar.source = eventStore.defaultCalendarForNewEvents?.source
        newCalendar.cgColor = (Color(hex: goal.color) ?? getCalendarDefaultColor(viewContext: viewContext)).toCGColor()
        
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            print("Calendar created successfully.")
        } catch {
            print("Failed to create calendar: \(error.localizedDescription)")
        }
        
    }
}

public func confirmPersonCalendar(person: N40Person, viewContext: NSManagedObjectContext, eventStore: EKEventStore) {
    // check to see if there is a North 40 calendar, and if there isn't, make one
    if (eventStore.calendars(for: .event).filter { $0.title == "With \(person.getFullName.trimmingCharacters(in: .whitespacesAndNewlines))" }.count == 0) {
        
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        
        // Set the calendar properties
        newCalendar.title = "With \(person.getFullName.trimmingCharacters(in: .whitespacesAndNewlines))"
        newCalendar.source = eventStore.defaultCalendarForNewEvents?.source
        if person.hasFavoriteColor {
            newCalendar.cgColor = (Color(hex: person.favoriteColor) ?? getCalendarDefaultColor(viewContext: viewContext)).toCGColor()
        }
            
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            print("Calendar created successfully.")
        } catch {
            print("Failed to create calendar: \(error.localizedDescription)")
        }
        
    }
}

fileprivate func getCalendarDefaultColor(viewContext: NSManagedObjectContext) -> Color {
    
    var colorSchemeColor =  Color(red: 3.0/255.0, green: 110.0/255.0, blue: 20.0/255.0) //default value
    
    //if there are no color schemes, add the default one.
    let fetchRequest: NSFetchRequest<N40ColorScheme> = N40ColorScheme.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priorityIndex", ascending: true)]
    
    
    do {
        // Peform Fetch Request
        let fetchedColorSchemes = try viewContext.fetch(fetchRequest)
        
        colorSchemeColor = fetchedColorSchemes.count > 0 ? unpackColorsFromString(colorString: fetchedColorSchemes.first!.colorsString)[1] : colorSchemeColor
        
        
    } catch let error as NSError {
        print("Couldn't fetch color scheme. \(error), \(error.userInfo)")
    }
    
    return colorSchemeColor
}

public func getCalendarByTitle(title: String, eventStore: EKEventStore) -> EKCalendar? {
    let calendars = eventStore.calendars(for: .event)
    return calendars.first { $0.title == title }
}

extension Color {
    func toCGColor() -> CGColor {
        return UIColor(self).cgColor
    }
}


func makeNewCalendarEventToEKStore(_ event: N40Event, eventStore: EKEventStore, viewContext: NSManagedObjectContext, calendars: [EKCalendar] = []) {
    // the calendars input allows the user to specify only certain calendars.
    
    let calendarsToAttachTo = calendars == [] ? getEventCalendars(event, viewContext: viewContext, eventStore: eventStore) : calendars
    
    
    for eachCalendar in calendarsToAttachTo {
        // now make a copy of the event on every calendar.
        
        
        // Now make a new one
        let newEKEvent = EKEvent(eventStore: eventStore)
        
        // Set the event details
        newEKEvent.title = event.name
        newEKEvent.startDate = event.startDate
        newEKEvent.endDate = Calendar.current.date(byAdding: .minute, value: Int(event.duration), to: event.startDate) ?? event.startDate
        newEKEvent.notes = event.sharedWithCalendar //  the tag that we use to keep it synced
        newEKEvent.calendar = eachCalendar
        newEKEvent.isAllDay = event.allDay
        
        // save the new event
        do {
            try eventStore.save(newEKEvent, span: .thisEvent, commit: true)
            print("Event saved successfully.")
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
    
    
    
}


func updateEventOnEKStore (_ event: N40Event, eventStore: EKEventStore, viewContext: NSManagedObjectContext, oldEventDate: Date? = nil) {
    
    // It has already been shared, so fetch and update it
    let calendars = getN40RelatedCalendars(viewContext: viewContext, eventStore: eventStore)
    
    
    let predicate = eventStore.predicateForEvents(withStart: Calendar.current.date(byAdding: .day, value: -1, to: oldEventDate ?? event.startDate) ?? event.startDate, end: Calendar.current.date(byAdding: .day, value: 2, to: oldEventDate ?? event.startDate) ?? event.startDate, calendars: calendars)
        
    print(eventStore.events(matching: predicate))
    let fetchedEKEvents = eventStore.events(matching: predicate).filter { eachEvent in
        return eachEvent.notes?.contains(event.sharedWithCalendar) == true
    }
    
    var calendarsAlreadyUpdated: [EKCalendar] = []
    var eventsToDelete: [EKEvent] = []
    let calendarsItShouldBeOn = getEventCalendars(event, viewContext: viewContext, eventStore: eventStore)
    var calendarsItsNotOn = calendarsItShouldBeOn // We'll delete them as we see that they are on there
    
    for fetchedEKEvent in fetchedEKEvents {
        // go through each of them because they might be on different calendars
        
        if calendarsItShouldBeOn.contains(fetchedEKEvent.calendar) {
            // It just needs to be updated
            
            // check off that its on this calendar
            calendarsItsNotOn = calendarsItsNotOn.filter { $0 != fetchedEKEvent.calendar }
            
            // not make sure its updated in the calendar by, (1) checking for duplicates, or (2) just updating it and checking that calendar off as complete
            if calendarsAlreadyUpdated.contains(fetchedEKEvent.calendar) {
                // This calendar was already updated, so this is a duplicate
                
                eventsToDelete.append(fetchedEKEvent)
                
            } else {
                // this calendar hasn't been updated yet so do it
                
                // Set the event details
                fetchedEKEvent.title = event.name
                fetchedEKEvent.startDate = event.startDate
                fetchedEKEvent.endDate = Calendar.current.date(byAdding: .minute, value: Int(event.duration), to: event.startDate) ?? event.startDate
                fetchedEKEvent.notes = event.sharedWithCalendar //  the tag that we use to keep it synced
                fetchedEKEvent.isAllDay = event.allDay
                
                // save the new event
                do {
                    try eventStore.save(fetchedEKEvent, span: .thisEvent, commit: true)
                    print("Event saved successfully.")
                } catch {
                    print("Failed to save event: \(error.localizedDescription)")
                }
                
                // mark that this calendar has already been updated
                calendarsAlreadyUpdated.append(fetchedEKEvent.calendar)
            }
        } else {
            // It needs to be deleted from that calendar
            eventsToDelete.append(fetchedEKEvent)
        }
        
        
    }
    
    // delete the duplicates
    for duplicateEvent in eventsToDelete {
        // delete them
        do {
            try eventStore.remove(duplicateEvent, span: .thisEvent, commit: true)
            print("Event deleted successfully.")
        } catch {
            print("Failed to delete event: \(error.localizedDescription)")
        }
    }
    
    // add events if it wasn't on a calendar it needs to be on
    if calendarsItsNotOn.count > 0 {
        makeNewCalendarEventToEKStore(event, eventStore: eventStore, viewContext: viewContext, calendars: calendarsItsNotOn)
    }
    
    
    
    

}


func getN40RelatedCalendars(viewContext: NSManagedObjectContext, eventStore: EKEventStore) -> [EKCalendar] {
    let calendars: [EKCalendar] = eventStore.calendars(for: .event)
    var n40Names: [String] = ["North 40"]
    
    
    // go through any goals that have share to calendar turned on
    let fetchRequest: NSFetchRequest<N40Goal> = N40Goal.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
    fetchRequest.predicate = NSPredicate(format: "sharedToCalendar == YES")
    
    do {
        // Peform Fetch Request
        let fetchedGoals = try viewContext.fetch(fetchRequest)
        for fetchedGoal in fetchedGoals {
            n40Names.append(fetchedGoal.name)
        }
    } catch let error as NSError {
        print("Couldn't fetch color scheme. \(error), \(error.userInfo)")
    }
    
    // go through any people that have share to calendar turned on
    let fetchRequest2: NSFetchRequest<N40Person> = N40Person.fetchRequest()
    fetchRequest2.sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true)]
    fetchRequest2.predicate = NSPredicate(format: "sharedToCalendar == YES")
    
    do {
        let fetchedPeople = try viewContext.fetch(fetchRequest2)
        for fetchedPerson in fetchedPeople {
            n40Names.append("With \(fetchedPerson.getFullName.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
    } catch let error as NSError {
        print("Couldn't fetch color scheme. \(error), \(error.userInfo)")
    }
    
    
    // now get the calendars for the names
    var n40Calendars: [EKCalendar] = []
    for eachCalendar in calendars {
        if n40Names.contains(eachCalendar.title) {
            n40Calendars.append(eachCalendar)
        }
    }

        
    return n40Calendars
}


fileprivate func getEventCalendars(_ event: N40Event, viewContext: NSManagedObjectContext, eventStore: EKEventStore) -> [EKCalendar] {
    
    var calendarsToAttachTo: [EKCalendar] = []
    
    // First see if it should go on any goal calendars
    for eachGoal in event.getAttachedGoals {
        if eachGoal.sharedToCalendar {
            confirmGoalCalendar(goal: eachGoal, viewContext: viewContext, eventStore: eventStore)
            if let goalCalendar = getCalendarByTitle(title: eachGoal.name, eventStore: eventStore) {
                calendarsToAttachTo.append(goalCalendar)
            }
        }
    }
    
    // Next see if it should be on any people calendars
    for eachPerson in event.getAttachedPeople {
        if eachPerson.sharedToCalendar {
            confirmPersonCalendar(person: eachPerson, viewContext: viewContext, eventStore: eventStore)
            if let personCalendar = getCalendarByTitle(title: "With \(eachPerson.getFullName.trimmingCharacters(in: .whitespacesAndNewlines))", eventStore: eventStore) {
                calendarsToAttachTo.append(personCalendar)
            }
        }
    }
    
    // if there weren't any goal calendars, then do the default one
    if calendarsToAttachTo.isEmpty {
        // get the calendar to put it on
        confirmDefaultCalendar(viewContext: viewContext, eventStore: eventStore)
        if let appCalendar = getCalendarByTitle(title: "North 40", eventStore: eventStore) {
            calendarsToAttachTo.append(appCalendar)
        } else if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
            calendarsToAttachTo.append(defaultCalendar)
        }
    }
    
    return calendarsToAttachTo
    
}
