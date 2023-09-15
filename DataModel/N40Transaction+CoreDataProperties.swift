//
//  N40Transaction+CoreDataProperties.swift
//  The North 40
//
//  Created by Addison Ballif on 9/2/23.
//
//

import Foundation
import CoreData


extension N40Transaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<N40Transaction> {
        return NSFetchRequest<N40Transaction>(entityName: "N40Transaction")
    }

    @NSManaged public var name: String
    @NSManaged public var amount: Double
    @NSManaged public var date: Date
    @NSManaged public var isIncome: Bool
    @NSManaged public var recurringTag: String
    @NSManaged public var notes: String
    
    @NSManaged public var isPartOfEnvelopeTransfer: Bool
    
    @NSManaged public var envelope: NSSet?
    @NSManaged public var event: N40Event?
    

    
    public func getEnvelope() -> N40Envelope? {
        let set = envelope as? Set<N40Envelope> ?? []
        return set.first //assuming only one
    }

    
    
}


// MARK: Generated accessors for envelope
extension N40Transaction {

    @objc(addEnvelopeObject:)
    @NSManaged public func addToEnvelope(_ value: N40Envelope)

    @objc(removeEnvelopeObject:)
    @NSManaged public func removeFromEnvelope(_ value: N40Envelope)

    @objc(addEnvelope:)
    @NSManaged public func addToEnvelope(_ values: NSSet)

    @objc(removeEnvelope:)
    @NSManaged public func removeFromEnvelope(_ values: NSSet)

}

extension N40Transaction : Identifiable {

}
