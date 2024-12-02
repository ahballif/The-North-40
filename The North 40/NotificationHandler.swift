//
//  NotificationHandler.swift
//  The North 40
//
//  Created by Addison Ballif on 12/1/24.
//

import Foundation
import UserNotifications
import CoreData


class NotificationHandler {
    static let instance = NotificationHandler() // A singleton
    
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (success, error) in
            if let error = error {
                print("ERROR: \(error)")
            }
        }
    }
    
    func updateNotification(event: N40Event, pretime: Int16 = 0, viewContext: NSManagedObjectContext) {
        // remember to save core data after running this function
        
        
        requestAuthorization()
        
        // first check to see if it's already scheduled
        if event.notificationID != "" {
            //remove the previous notification
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [event.notificationID])
            event.notificationID = ""
        }
        
        let content = UNMutableNotificationContent()
        content.title = event.name
        content.subtitle = event.information
        content.sound = .default
        // update badge count here //content.badge =
        
        // time
        let triggerDate = Calendar.current.date(byAdding: .minute, value: -1*Int(pretime), to: event.startDate) ?? event.startDate
        var components = triggerDate.get(.minute, .hour, .day, .month, .year)
        if event.allDay {
            components.minute = 0
            components.hour = 0
        }
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let notificationID = UUID().uuidString
        
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        
        // add these features to the N40Event
        event.notificationID = notificationID
        event.notificationTime = pretime
        
        // save those details
        do {
            try viewContext.save()
        }
        catch {
            // Handle Error
            print("Error info: \(error)")
        }
        
    }
    
    
    func deletePendingNotification(event: N40Event) {
        
        requestAuthorization()
        
        if event.notificationID != "" {
            //remove the previous notification
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [event.notificationID])
            event.notificationID = ""
        }
        
    }
}
