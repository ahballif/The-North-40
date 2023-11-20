//
//  Event+CoreDataClass.swift
//  The North 40
//
//  Created by Addison Ballif on 8/11/23.
//
//

import Foundation
import CoreData


public class N40Event: NSManagedObject {

    public var renderIdx: Int? //For showing on the calendar. It will be stored here to allow other events to look at each other.
    public var renderTotal: Int? //Stores the total number of columns at that time for calculating width
}
