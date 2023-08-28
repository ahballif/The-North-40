//
//  N40Note+CoreDataProperties.swift
//  The North 40
//
//  Created by Addison Ballif on 8/28/23.
//
//

import Foundation
import CoreData


extension N40Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<N40Note> {
        return NSFetchRequest<N40Note>(entityName: "N40Note")
    }

    @NSManaged public var title: String
    @NSManaged public var information: String
    @NSManaged public var date: Date
    
    @NSManaged public var attachedPeople: NSSet?
    @NSManaged public var attachedGoals: NSSet?

}

// MARK: Generated accessors for attachedPeople
extension N40Note {

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
extension N40Note {

    @objc(addAttachedGoalsObject:)
    @NSManaged public func addToAttachedGoals(_ value: N40Goal)

    @objc(removeAttachedGoalsObject:)
    @NSManaged public func removeFromAttachedGoals(_ value: N40Goal)

    @objc(addAttachedGoals:)
    @NSManaged public func addToAttachedGoals(_ values: NSSet)

    @objc(removeAttachedGoals:)
    @NSManaged public func removeFromAttachedGoals(_ values: NSSet)

}

extension N40Note : Identifiable {

}
