//
//  InformationProcessing.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

// THIS FILE IS NOT BEING USED RIGHT NOW. 

import Foundation


public struct ContactInfo {
    let id = UUID()
    
    public static let PHONE_NUMBER = 0
    public static let EMAIL = 1
    public static let SOCIAL_MEDIA = 2
    public static let OTHER = 3
    
    public var contactType: Int // One of the three above
    public var info: String
    
    init(contactType: Int, info: String) {
        self.contactType = contactType
        self.info = info
    }
}

// ----------- for formatting phone numbers
public func formatPhoneNumber(inputString: String) -> String {
    var pn = inputString.filter("0123456789".contains)
    if (pn.count == 10) {
        let pnIn = pn.split(separator: "")
        pn = "("+pnIn[0]+pnIn[1]+pnIn[2]+") "
        pn += pnIn[3]+pnIn[4]+pnIn[5]+"-"
        pn += pnIn[6]+pnIn[7]+pnIn[8]+pnIn[9]
    }
    return pn
}

// ------ converts an array of phone numbers to a cvs phone nunmber string for storing in core data
public func getContactInfos(phoneNumberString: String) -> [ContactInfo] {
    var outlist: [String] = []
    
    //remove empty values
    phoneNumberString.components(separatedBy: ",").forEach { pn in
        if (pn != "") { outlist.append(pn) }
    }
    
    var contactInfos: [ContactInfo] = []
    
    outlist.forEach { contact in
        if (contact.prefix(1) == "P") {
            var passContact = contact
            passContact.remove(at: passContact.startIndex)
            contactInfos.append(ContactInfo(contactType: ContactInfo.PHONE_NUMBER, info: passContact))
        } else if (contact.prefix(1) == "E") {
            var passContact = contact
            passContact.remove(at: passContact.startIndex)
            contactInfos.append(ContactInfo(contactType: ContactInfo.EMAIL, info: passContact))
        } else if (contact.prefix(1) == "S") {
            var passContact = contact
            passContact.remove(at: passContact.startIndex)
            contactInfos.append(ContactInfo(contactType: ContactInfo.SOCIAL_MEDIA, info: passContact))
        } else {
            contactInfos.append(ContactInfo(contactType: ContactInfo.OTHER, info: contact))
            print("Item type unknown: ",contact)
        }
    }
    
    return contactInfos
    
    
}

public func storeContactInfos(contactInfos: [ContactInfo]) -> String {
    
    var sum = ""
    
    contactInfos.forEach { contact in
        if contact.contactType == ContactInfo.PHONE_NUMBER {
            sum += ",P" + formatPhoneNumber(inputString: contact.info)
        } else if contact.contactType == ContactInfo.EMAIL {
            sum += ",E" + formatPhoneNumber(inputString: contact.info)
        } else if contact.contactType == ContactInfo.SOCIAL_MEDIA {
            sum += ",S" + formatPhoneNumber(inputString: contact.info)
        } else {
            sum += "," + formatPhoneNumber(inputString: contact.info)
        }
    }
    
    return sum
}



