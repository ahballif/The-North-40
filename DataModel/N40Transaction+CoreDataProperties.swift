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
    
    @NSManaged public var envelope: N40Envelope?
    @NSManaged public var event: N40Event?

}

extension N40Transaction : Identifiable {

}
