//
//  N40ColorScheme+CoreDataProperties.swift
//  The North 40
//
//  Created by Addison Ballif on 4/12/24.
//
//

import Foundation
import CoreData


extension N40ColorScheme {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<N40ColorScheme> {
        return NSFetchRequest<N40ColorScheme>(entityName: "N40ColorScheme")
    }

    @NSManaged public var name: String
    @NSManaged public var colorsString: String
    @NSManaged public var photo: Data?
    @NSManaged public var priorityIndex: Int16
    

}

extension N40ColorScheme : Identifiable {

}
