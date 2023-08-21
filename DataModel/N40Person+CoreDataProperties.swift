//
//  Person+CoreDataProperties.swift
//  The North 40
//
//  Created by Addison Ballif on 8/11/23.
//
//

import Foundation
import CoreData


extension N40Person {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<N40Person> {
        return NSFetchRequest<N40Person>(entityName: "N40Person")
    }

    @NSManaged public var firstName: String
    @NSManaged public var lastName: String
    @NSManaged public var address: String
    @NSManaged public var title: String
    @NSManaged public var phoneNumber1: String
    @NSManaged public var phoneNumber2: String
    @NSManaged public var email1: String
    @NSManaged public var email2: String
    @NSManaged public var socialMedia1: String
    @NSManaged public var socialMedia2: String
    
    @NSManaged public var groups: NSSet?
    @NSManaged public var timelineEvents: NSSet?

    
    public var getGroups: [N40Group] {
        //returns an array of the groups attached to the person
        let set = groups as? Set<N40Group> ?? []
        return Array(set)
    }
    
    public var getTimelineEvents: [N40Event] {
        //returns an array of the timeline events attached to the person
        let set = timelineEvents as? Set<N40Event> ?? []
        return set.sorted {
            $0.startDate > $1.startDate //returns oldest last
        }
    }
    
}

// MARK: Generated accessors for groups
extension N40Person {

    @objc(addGroupsObject:)
    @NSManaged public func addToGroups(_ value: N40Group)

    @objc(removeGroupsObject:)
    @NSManaged public func removeFromGroups(_ value: N40Group)

    @objc(addGroups:)
    @NSManaged public func addToGroups(_ values: NSSet)

    @objc(removeGroups:)
    @NSManaged public func removeFromGroups(_ values: NSSet)

}

// MARK: Generated accessors for timelineEvents
extension N40Person {

    @objc(addTimelineEventsObject:)
    @NSManaged public func addToTimelineEvents(_ value: N40Event)

    @objc(removeTimelineEventsObject:)
    @NSManaged public func removeFromTimelineEvents(_ value: N40Event)

    @objc(addTimelineEvents:)
    @NSManaged public func addToTimelineEvents(_ values: NSSet)

    @objc(removeTimelineEvents:)
    @NSManaged public func removeFromTimelineEvents(_ values: NSSet)

}

extension N40Person : Identifiable {

}
