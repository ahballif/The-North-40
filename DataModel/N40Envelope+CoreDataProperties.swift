//
//  N40Envelope+CoreDataProperties.swift
//  The North 40
//
//  Created by Addison Ballif on 9/2/23.
//
//

import Foundation
import CoreData


extension N40Envelope {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<N40Envelope> {
        return NSFetchRequest<N40Envelope>(entityName: "N40Envelope")
    }

    @NSManaged public var currentBalance: Double
    @NSManaged public var lastCalculation: Date
    @NSManaged public var name: String
    
    @NSManaged public var transactions: NSSet?

    
    public var getTransactions: [N40Transaction] {
        //returns an array of the timeline events attached to the group
        let set = transactions as? Set<N40Transaction> ?? []
        return set.sorted {
            $0.date > $1.date //returns oldest last
        }
    }
    
    
}

// MARK: Generated accessors for transactions
extension N40Envelope {

    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: N40Transaction)

    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: N40Transaction)

    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)

    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)

}

extension N40Envelope : Identifiable {

}
