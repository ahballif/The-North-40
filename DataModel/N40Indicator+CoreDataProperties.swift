//
//  N40Indicator+CoreDataProperties.swift
//  The North 40
//
//  Created by Addison Ballif on 5/27/24.
//
//

import Foundation
import CoreData


extension N40Indicator {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<N40Indicator> {
        return NSFetchRequest<N40Indicator>(entityName: "N40Indicator")
    }

    @NSManaged public var name: String
    @NSManaged public var targetDate: Date
    @NSManaged public var target: Int16
    @NSManaged public var achieved: Int16
    @NSManaged public var dataString: String
    @NSManaged public var color: String
    
    @NSManaged public var attachedGoals: NSSet?
    @NSManaged public var attachedPeople: NSSet?

}

// MARK: Generated accessors for attachedGoals
extension N40Indicator {

    @objc(addAttachedGoalsObject:)
    @NSManaged public func addToAttachedGoals(_ value: N40Goal)

    @objc(removeAttachedGoalsObject:)
    @NSManaged public func removeFromAttachedGoals(_ value: N40Goal)

    @objc(addAttachedGoals:)
    @NSManaged public func addToAttachedGoals(_ values: NSSet)

    @objc(removeAttachedGoals:)
    @NSManaged public func removeFromAttachedGoals(_ values: NSSet)

}

// MARK: Generated accessors for attachedPeople
extension N40Indicator {

    @objc(addAttachedPeopleObject:)
    @NSManaged public func addToAttachedPeople(_ value: N40Person)

    @objc(removeAttachedPeopleObject:)
    @NSManaged public func removeFromAttachedPeople(_ value: N40Person)

    @objc(addAttachedPeople:)
    @NSManaged public func addToAttachedPeople(_ values: NSSet)

    @objc(removeAttachedPeople:)
    @NSManaged public func removeFromAttachedPeople(_ values: NSSet)

}

extension N40Indicator : Identifiable {

}
