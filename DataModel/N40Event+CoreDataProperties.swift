//
//  Event+CoreDataProperties.swift
//  The North 40
//
//  Created by Addison Ballif on 8/11/23.
//
//

import Foundation
import CoreData


extension N40Event {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<N40Event> {
        return NSFetchRequest<N40Event>(entityName: "N40Event")
    }

    @NSManaged public var startDate: Date
    @NSManaged public var duration: Int16
    @NSManaged public var name: String
    @NSManaged public var information: String
    @NSManaged public var summary: String
    @NSManaged public var status: Int16
    @NSManaged public var eventType: Int16
    @NSManaged public var contactMethod: Int16
    @NSManaged public var location: String
    @NSManaged public var isScheduled: Bool
    @NSManaged public var color: String
    @NSManaged public var recurringTag: String
    @NSManaged public var allDay: Bool
    @NSManaged public var bucketlist: Bool
    @NSManaged public var repeatOnCompleteInDays: Int16
    @NSManaged public var sharedWithCalendar: String
    @NSManaged public var notificationID: String
    @NSManaged public var notificationTime: Int16 // minutes before to post notification
    
    @NSManaged public var attachedPeople: NSSet?
    @NSManaged public var attachedGoals: NSSet?
    @NSManaged public var attachedTransactions: NSSet?
    
    //event types
    public static let REPORTABLE_TYPE = 0
    public static let NON_REPORTABLE_TYPE = 1
    public static let INFORMATION_TYPE = 2
    public static let TODO_TYPE = 3
    public static let BACKUP_TYPE = 4
    
    public static let EVENT_TYPE_OPTIONS = [["Reportable", "rectangle.and.pencil.and.ellipsis"], ["Non-Reportable","calendar.day.timeline.leading"], ["Radar Event", "dot.radiowaves.left.and.right"], ["To-Do", "checklist"], ["Backup", "backpack"]]
    
    public static let CONTACT_OPTIONS = [["None", "scribble"],["In Person", "person.2.fill"],["Phone Call","phone.fill"],["Text Message","message"],["Social Media", "ellipsis.bubble"],["Video Call", "video"],["Email", "envelope"],["Computer", "desktopcomputer"],["TV", "tv"],["Other", "bubble.middle.top"]]
    
    //events status options
    public static let UNREPORTED = 0
    public static let SKIPPED = 1
    public static let ATTEMPTED = 2
    public static let HAPPENED = 3
    
    
    
    
    public var getAttachedPeople: [N40Person] {
        //returns an array of the people attached
        let set = attachedPeople as? Set<N40Person> ?? []
        return set.sorted {
            $0.lastName < $1.lastName //sorts alphabetically by last name
        }
    }
    
    public var getAttachedGoals: [N40Goal] {
        //returns an array of the goals attached
        let set = attachedGoals as? Set<N40Goal> ?? []
        return set.sorted {
            $0.name < $1.name //sorts alphabetically by name
        }
     }
    
    public func isAttachedToGoal (goal: N40Goal) -> Bool {
        var answer = false
        
        if self.getAttachedGoals.count > 0 {
            for eachGoal in self.getAttachedGoals {
                if eachGoal == goal {
                    answer = true
                }
            }
        }
        return answer
    }
    public func isAttachedToPerson (person: N40Person) -> Bool {
        var answer = false
        
        if self.getAttachedPeople.count > 0 {
            for eachPerson in self.getAttachedPeople {
                if eachPerson == person {
                    answer = true
                }
            }
        }
        return answer
    }
    public func isRecurringEventLast (viewContext: NSManagedObjectContext) -> Bool {
        var isLast = true
        if recurringTag != "" {
            let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
            
            let isScheduledPredicate = NSPredicate(format: "isScheduled = %d", true)
            let isFuturePredicate = NSPredicate(format: "startDate >= %@", (self.startDate as CVarArg)) //will include this event
            let sameTagPredicate = NSPredicate(format: "recurringTag == %@", (self.recurringTag))
            
            let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [isScheduledPredicate, isFuturePredicate, sameTagPredicate])
            fetchRequest.predicate = compoundPredicate
            
            do {
                // Peform Fetch Request
                let fetchedEvents = try viewContext.fetch(fetchRequest)
                
                if fetchedEvents.count != 1 {
                    isLast = false
                }
                
            } catch {
                print("couldn't fetch recurring events")
            }
        }
        return isLast
        
        
        
    }
    
    public func getFutureRecurringEvents (viewContext: NSManagedObjectContext) -> [N40Event] {
        var returningEvents: [N40Event] = []
        if recurringTag != "" {
            let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
            
            let isScheduledPredicate = NSPredicate(format: "isScheduled = %d", true)
            let isFuturePredicate = NSPredicate(format: "startDate > %@", (self.startDate as CVarArg)) //will not include this event
            let sameTagPredicate = NSPredicate(format: "recurringTag == %@", (self.recurringTag))
            
            let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [isScheduledPredicate, isFuturePredicate, sameTagPredicate])
            fetchRequest.predicate = compoundPredicate
            
            do {
                // Peform Fetch Request
                let fetchedEvents = try viewContext.fetch(fetchRequest)
                
                for eachFetchedEvent in fetchedEvents {
                    returningEvents.append(eachFetchedEvent)
                }
                
            } catch {
                print("couldn't fetch recurring events")
            }
        }
        return returningEvents
    }
    
    public func getFirstFavoriteColor () -> String? {
        if getAttachedPeople.count > 0 {
            for person in getAttachedPeople {
                if person.hasFavoriteColor {
                    return person.favoriteColor
                }
            }
        }
        return nil
    }
    
    public func isNextRecurringEvent(vc: NSManagedObjectContext) -> Bool {
        //returns true if it's not a recurring event
        var answer = true
        if recurringTag != "" {
            let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
            
            let isScheduledPredicate = NSPredicate(format: "isScheduled = %d", true)
            let isFuturePredicate = NSPredicate(format: "startDate > %@", (Date() as CVarArg))
            let sameTagPredicate = NSPredicate(format: "recurringTag == %@", (self.recurringTag))
            
            let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [isScheduledPredicate, isFuturePredicate, sameTagPredicate])
            fetchRequest.predicate = compoundPredicate
            
            do {
                // Peform Fetch Request
                let fetchedEvents = try vc.fetch(fetchRequest)
                
                if fetchedEvents.sorted(by: {$0.startDate < $1.startDate}).first != self {
                    answer = false
                } 
                
            } catch {
                print("couldn't fetch recurring events")
            }
        }
        return answer
    }
    

}

// MARK: Generated accessors for attachedPeople
extension N40Event {

    @objc(addAttachedPeopleObject:)
    @NSManaged public func addToAttachedPeople(_ value: N40Person)

    @objc(removeAttachedPeopleObject:)
    @NSManaged public func removeFromAttachedPeople(_ value: N40Person)

    @objc(addAttachedPeople:)
    @NSManaged public func addToAttachedPeople(_ values: NSSet)

    @objc(removeAttachedPeople:)
    @NSManaged public func removeFromAttachedPeople(_ values: NSSet)

}

// MARK: Generated accessors for attachedGoals
extension N40Event {

    @objc(addAttachedGoalsObject:)
    @NSManaged public func addToAttachedGoals(_ value: N40Goal)

    @objc(removeAttachedGoalsObject:)
    @NSManaged public func removeFromAttachedGoals(_ value: N40Goal)

    @objc(addAttachedGoals:)
    @NSManaged public func addToAttachedGoals(_ values: NSSet)

    @objc(removeAttachedGoals:)
    @NSManaged public func removeFromAttachedGoals(_ values: NSSet)

}

extension N40Event : Identifiable {

}
