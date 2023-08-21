//
//  InformationProcessing.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

import Foundation

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
public func getContactInfos(phoneNumberString: String) -> [[String]] {
    var outlist: [String] = []
    
    //remove empty values
    phoneNumberString.components(separatedBy: ",").forEach { pn in
        if (pn != "") { outlist.append(pn) }
    }
    
    var phoneNumbers: [String] = []
    var emailAddresses: [String] = []
    var socialMedias: [String] = []
    var unknowns: [String] = []
    
    outlist.forEach { contact in
        if (contact.prefix(1) == "P") {
            var passContact = contact
            passContact.remove(at: passContact.startIndex)
            phoneNumbers.append(passContact) }
        else if (contact.prefix(1) == "E") {
            var passContact = contact
            passContact.remove(at: passContact.startIndex)
            emailAddresses.append(passContact) }
        else if (contact.prefix(1) == "S") {
            var passContact = contact
            passContact.remove(at: passContact.startIndex)
            socialMedias.append(passContact) }
        else {
            unknowns.append(contact)
            print("Item type unknown: ",contact)
        }
    }
    
    return [phoneNumbers, emailAddresses, socialMedias, unknowns]
    
    
}

public func storeContactInfos(phoneNumbers: [String], emailAddresses: [String], socialMedias: [String]) -> String {
    var sum = ""
    phoneNumbers.forEach { pn in
        sum += ",P" + formatPhoneNumber(inputString: pn)
    }
    emailAddresses.forEach { em in
        sum += ",E" + em    }
    socialMedias.forEach { sm in
        sum += ",S" + sm
        
    }
    return sum
}
