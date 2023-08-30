//
//  Goal+CoreDataProperties.swift
//  The North 40
//
//  Created by Addison Ballif on 8/11/23.
//
//

import Foundation
import CoreData


extension N40Goal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<N40Goal> {
        return NSFetchRequest<N40Goal>(entityName: "N40Goal")
    }

    @NSManaged public var name: String
    @NSManaged public var deadline: Date
    @NSManaged public var dateCompleted: Date
    @NSManaged public var information: String
    @NSManaged public var address: String
    @NSManaged public var hasDeadline: Bool
    @NSManaged public var isCompleted: Bool
    
    @NSManaged public var subGoals: NSSet?
    @NSManaged public var endGoal: N40Goal?
    
    @NSManaged public var groups: NSSet?
    @NSManaged public var timelineEvents: NSSet?
    @NSManaged public var attachedNotes: NSSet?
    @NSManaged public var attachedPeople: NSSet?
    
    
    public var getGroups: [N40Group] {
        //returns an array of the groups attached to the goal
        let set = groups as? Set<N40Group> ?? []
        return Array(set)
    }
    
    public var getTimelineEvents: [N40Event] {
        //returns an array of the timeline events attached to the group
        let set = timelineEvents as? Set<N40Event> ?? []
        return set.sorted {
            $0.startDate > $1.startDate //returns oldest last
        }
    }
    
    public var getAttachedPeople: [N40Person] {
        //returns an array of the people attached
        let set = attachedPeople as? Set<N40Person> ?? []
        return set.sorted {
            $0.lastName < $1.lastName //sorts alphabetically by last name
        }
    }
    
    public var getUnfinishedTodos: [N40Event] {
        var unfinishedTodos: [N40Event] = []
        
        for event in self.getTimelineEvents {
            if event.eventType == N40Event.TODO_TYPE && event.status != N40Event.HAPPENED {
                unfinishedTodos.append(event)
            }
        }
        return unfinishedTodos.sorted {
            $0.startDate < $1.startDate
        }
    }

}

// MARK: Generated accessors for groups
extension N40Goal {

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
extension N40Goal {

    @objc(addTimelineEventsObject:)
    @NSManaged public func addToTimelineEvents(_ value: N40Event)

    @objc(removeTimelineEventsObject:)
    @NSManaged public func removeFromTimelineEvents(_ value: N40Event)

    @objc(addTimelineEvents:)
    @NSManaged public func addToTimelineEvents(_ values: NSSet)

    @objc(removeTimelineEvents:)
    @NSManaged public func removeFromTimelineEvents(_ values: NSSet)

}

extension N40Goal {

    @objc(addAttachedPeopleObject:)
    @NSManaged public func addToAttachedPeople(_ value: N40Person)

    @objc(removeAttachedPeopleObject:)
    @NSManaged public func removeFromAttachedPeople(_ value: N40Person)

    @objc(addAttachedPeople:)
    @NSManaged public func addToAttachedPeople(_ values: NSSet)

    @objc(removeAttachedPeople:)
    @NSManaged public func removeFromAttachedPeople(_ values: NSSet)

}

extension N40Goal : Identifiable {

}
