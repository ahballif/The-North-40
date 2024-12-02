//
//  MoreSharedFunctions.swift
//  The North 40
//
//  Created by Addison Ballif on 9/3/24.
//

import Foundation
import CoreData

public func duplicateN40Event(originalEvent: N40Event, newStartDate: Date, vc: NSManagedObjectContext) {
    
    let newEvent = N40Event(context: vc)
    newEvent.name = originalEvent.name
    newEvent.isScheduled = originalEvent.isScheduled
    newEvent.startDate = newStartDate // This one is different
    newEvent.duration = originalEvent.duration
    newEvent.location = originalEvent.location
    newEvent.information = originalEvent.information
    newEvent.status = 0 // This one is different
    newEvent.summary = "" // also this one
    newEvent.contactMethod = originalEvent.contactMethod
    newEvent.allDay = originalEvent.allDay
    newEvent.eventType = originalEvent.eventType
    newEvent.color = originalEvent.color
    newEvent.recurringTag = originalEvent.recurringTag
    newEvent.repeatOnCompleteInDays = originalEvent.repeatOnCompleteInDays
    originalEvent.getAttachedPeople.forEach {person in
        newEvent.addToAttachedPeople(person)
    }
    originalEvent.getAttachedGoals.forEach {goal in
        newEvent.addToAttachedGoals(goal)
    }
    
    #if os(iOS)
    if originalEvent.notificationID != "" {
        // If the original doesn't have a notification, this one needs one
        NotificationHandler.instance.updateNotification(event: newEvent, pretime: originalEvent.notificationTime, viewContext: vc)
    }
    #endif
    
    
    
    do {
        try vc.save()
    }
    catch {
        // Handle Error
        print("Error info: \(error)")
        
    }
    
}


func getMinutesDifferenceFromTwoDates(start: Date, end: Date) -> Int
   {

       let diff = Int(end.timeIntervalSince1970 - start.timeIntervalSince1970)
       
       let minutes = (diff) / 60
       return minutes
   }
