//
//  N40EnvelopeTransfer+CoreDataProperties.swift
//  The North 40
//
//  Created by Addison Ballif on 9/7/23.
//
//

import Foundation
import CoreData


extension N40EnvelopeTransfer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<N40EnvelopeTransfer> {
        return NSFetchRequest<N40EnvelopeTransfer>(entityName: "N40EnvelopeTransfer")
    }

    @NSManaged public var date: Date
    @NSManaged public var name: String
    @NSManaged public var notes: String
    @NSManaged public var recurringTag: String
    @NSManaged public var amount: Double
    
    @NSManaged public var from: N40Transaction?
    @NSManaged public var to: N40Transaction?

}

extension N40EnvelopeTransfer : Identifiable {

}
