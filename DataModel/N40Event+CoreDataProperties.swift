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
    @NSManaged public var attachedPeople: NSSet?
    @NSManaged public var attachedGoals: NSSet?
    
    
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
