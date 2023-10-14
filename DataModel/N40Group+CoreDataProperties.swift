//
//  N40Group+CoreDataProperties.swift
//  The North 40
//
//  Created by Addison Ballif on 8/11/23.
//
//

import Foundation
import CoreData


extension N40Group {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<N40Group> {
        return NSFetchRequest<N40Group>(entityName: "N40Group")
    }

    @NSManaged public var priorityIndex: Int16
    @NSManaged public var name: String
    @NSManaged public var information: String
    
    @NSManaged public var people: NSSet?
    @NSManaged public var goals: NSSet?
    
    public var getPeople: [N40Person] {
        //returns an array of the people in the group
        let set = people as? Set<N40Person> ?? []
        return set.sorted {
            $0.lastName < $1.lastName //sorts alphabetically by last name
        }
    }
    
    public var getGoals: [N40Goal] {
        //returns an array of the goals in the group
        let set = goals as? Set<N40Goal> ?? []
        return set.sorted {
            $0.name < $1.name //sorts alphabetically by name
        }
     }

}

// MARK: Generated accessors for people
extension N40Group {

    @objc(addPeopleObject:)
    @NSManaged public func addToPeople(_ value: N40Person)

    @objc(removePeopleObject:)
    @NSManaged public func removeFromPeople(_ value: N40Person)

    @objc(addPeople:)
    @NSManaged public func addToPeople(_ values: NSSet)

    @objc(removePeople:)
    @NSManaged public func removeFromPeople(_ values: NSSet)

}

// MARK: Generated accessors for goals
extension N40Group {

    @objc(addGoalsObject:)
    @NSManaged public func addToGoals(_ value: N40Goal)

    @objc(removeGoalsObject:)
    @NSManaged public func removeFromGoals(_ value: N40Goal)

    @objc(addGoals:)
    @NSManaged public func addToGoals(_ values: NSSet)

    @objc(removeGoals:)
    @NSManaged public func removeFromGoals(_ values: NSSet)

}

extension N40Group : Identifiable {

}
