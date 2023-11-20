//
//  ExportImportData.swift
//  The North 40
//
//  Created by Addison Ballif on 9/30/23.
//

import Foundation
import CoreData

struct Exporter {
    private static func encodeN40Person(person: N40Person) -> String {
        var outputString = "N40Person\n"
        outputString += "address: \(person.address.trimmed())\n"
        outputString += "birthday: \(person.birthday)\n"
        outputString += "birthdayDay: \(person.birthdayDay)\n"
        outputString += "birthdayMonth: \(person.birthdayMonth)\n"
        outputString += "email1: \(person.email1.trimmed())\n"
        outputString += "email2: \(person.email2.trimmed())\n"
        outputString += "firstName: \(person.firstName.trimmed())\n"
        outputString += "hasBirthday: \(person.hasBirthday)\n"
        outputString += "isArchived: \(person.isArchived)\n"
        outputString += "lastName: \(person.lastName.trimmed())\n"
        outputString += "notes: \(person.notes.newLineEncoded())\n"
        outputString += "phoneNumber1: \(person.phoneNumber1.trimmed())\n"
        outputString += "phoneNumber2: \(person.phoneNumber2.trimmed())\n"
        outputString += "socialMedia1: \(person.socialMedia1.trimmed())\n"
        outputString += "socialMedia2: \(person.socialMedia2.trimmed())\n"
        outputString += "title: \(person.title.trimmed().trimmed())\n"
//        if person.photo != nil {
//            outputString += "photo: \(String(data: person.photo!, encoding: .utf16) ?? "no-photo")\n"
//        }
        
        //No relationship data because people are going to be decoded first.
        
        return outputString
    }
    private static func encodeN40Goal(goal: N40Goal) -> String {
        var outputString = "N40Goal\n"
        outputString += "color: \(goal.color)\n"
        outputString += "dateCompleted: \(goal.dateCompleted)\n"
        outputString += "deadline: \(goal.deadline)\n"
        outputString += "hasDeadline: \(goal.hasDeadline)\n"
        outputString += "information: \(goal.information.newLineEncoded())\n"
        outputString += "isCompleted: \(goal.isCompleted)\n"
        outputString += "name: \(goal.name.trimmed())\n"
        outputString += "priorityIndex: \(goal.priorityIndex)\n"
        
        //Only entities that have been created so far are people (and goals)
        // Those are the only entity relationships that can be decoded at this point, so the only worth saving.
        for person in goal.getAttachedPeople {
            outputString += "attachedPeople: \(person.firstName.trimmed())-nm-\(person.lastName.trimmed())\n"
        }
        for endGoal in goal.getEndGoals {
            outputString += "endGoals: \(endGoal.name.trimmed())\n"
        }
        //We don't need to encode sub goals because of the nature of inverse relationships.
        
        
        return outputString
    }
    private static func encodeN40Event(event: N40Event) -> String {
        var outputString = "N40Event\n"
        outputString += "allDay: \(event.allDay)\n"
        outputString += "bucketlist: \(event.bucketlist)\n"
        outputString += "color: \(event.color)\n"
        outputString += "contactMethod: \(event.contactMethod)\n"
        outputString += "duration: \(event.duration)\n"
        outputString += "eventType: \(event.eventType)\n"
        outputString += "information: \(event.information.newLineEncoded())\n"
        outputString += "isScheduled: \(event.isScheduled)\n"
        outputString += "location: \(event.location.trimmed())\n"
        outputString += "name: \(event.name.trimmed())\n"
        outputString += "recurringTag: \(event.recurringTag)\n"
        outputString += "startDate: \(event.startDate)\n"
        outputString += "status: \(event.status)\n"
        outputString += "summary: \(event.summary.newLineEncoded())\n"
        
        //Created entities so far are people and goals. No need to save the other relationships yet.
        for person in event.getAttachedPeople {
            outputString += "attachedPeople: \(person.firstName.trimmed())-nm-\(person.lastName.trimmed())\n"
        }
        for goal in event.getAttachedGoals {
            outputString += "attachedGoals: \(goal.name.trimmed())\n"
        }
        
        return outputString
    }
    private static func encodeN40Envelope(envelope: N40Envelope) -> String {
        var outputString = "N40Envelope\n"
        outputString += "currentBalance: \(envelope.currentBalance)\n"
        outputString += "lastCalculation: \(envelope.lastCalculation)\n"
        outputString += "name: \(envelope.name.trimmed())\n"
        
        //transactions are not yet created, so no need to save that relationship data
        
        return outputString
    }
    private static func encodeN40Group(group: N40Group) -> String {
        var outputString = "N40Group\n"
        outputString += "information: \(group.information.newLineEncoded())\n"
        outputString += "name: \(group.name.trimmed())\n"
        outputString += "priorityIndex: \(group.priorityIndex)\n"
        
        for person in group.getPeople {
            outputString += "people: \(person.firstName.trimmed())-nm-\(person.lastName.trimmed())\n"
        }
        for goal in group.getGoals {
            outputString += "goals: \(goal.name.trimmed())\n"
        }
        
        
        return outputString
    }
    private static func encodeN40Note(note: N40Note) -> String {
        var outputString = "N40Note\n"
        outputString += "archived: \(note.archived)\n"
        outputString += "date: \(note.date)\n"
        outputString += "information: \(note.information.newLineEncoded())\n"
        outputString += "title: \(note.title.trimmed())\n"
        
        for person in note.getAttachedPeople {
            outputString += "attachedPeople: \(person.firstName.trimmed())-nm-\(person.lastName.trimmed())\n"
        }
        for goal in note.getAttachedGoals {
            outputString += "attachedGoals: \(goal.name.trimmed())\n"
        }
        
        
        return outputString
    }
    private static func encodeN40Transaction(transaction: N40Transaction) -> String {
        var outputString = "N40Transaction\n"
        outputString += "amount: \(transaction.amount)\n"
        outputString += "date: \(transaction.date)\n"
        outputString += "isIncome: \(transaction.isIncome)\n"
        outputString += "isPartOfEnvelopeTransfer: \(transaction.isPartOfEnvelopeTransfer)\n"
        outputString += "name: \(transaction.name.trimmed())\n"
        outputString += "notes: \(transaction.notes.newLineEncoded())\n"
        outputString += "recurringTag: \(transaction.recurringTag)\n"
        
        if transaction.getEnvelope() != nil {
            outputString += "envelope: \(transaction.getEnvelope()!.name.trimmed())\n"
        }
        if transaction.event != nil {
            outputString += "event: \(transaction.event!.name.trimmed())-event-\(transaction.event!.startDate)\n"
        }
        
        return outputString
    }
    
    
    
    private static func encodePeople(viewContext: NSManagedObjectContext) -> String {
        var outputString = ""
        let fetchRequest: NSFetchRequest<N40Person> = N40Person.fetchRequest()
        do {
            // Peform Fetch Request
            let fetchedPeople = try viewContext.fetch(fetchRequest)
            fetchedPeople.forEach { person in
                outputString += encodeN40Person(person: person) + "\n"
            }
        } catch let error as NSError {
            print("Couldn't fetch people. \(error), \(error.userInfo)")
        }
        return outputString
    }
    private static func encodeGoals(viewContext: NSManagedObjectContext) -> String {
        var outputString = ""
        let fetchRequest: NSFetchRequest<N40Goal> = N40Goal.fetchRequest()
        do {
            // Peform Fetch Request
            let fetchedGoals = try viewContext.fetch(fetchRequest)
            fetchedGoals.forEach { goal in
                outputString += encodeN40Goal(goal: goal) + "\n"
            }
        } catch let error as NSError {
            print("Couldn't fetch goals. \(error), \(error.userInfo)")
        }
        return outputString
    }
    private static func encodeEvents(viewContext: NSManagedObjectContext) -> String {
        var outputString = ""
        let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
        do {
            // Peform Fetch Request
            let fetchedEvents = try viewContext.fetch(fetchRequest)
            fetchedEvents.forEach { event in
                outputString += encodeN40Event(event: event) + "\n"
            }
        } catch let error as NSError {
            print("Couldn't fetch events. \(error), \(error.userInfo)")
        }
        return outputString
    }
    private static func encodeEnvelopes(viewContext: NSManagedObjectContext) -> String {
        var outputString = ""
        let fetchRequest: NSFetchRequest<N40Envelope> = N40Envelope.fetchRequest()
        do {
            // Peform Fetch Request
            let fetchedEnvelopes = try viewContext.fetch(fetchRequest)
            fetchedEnvelopes.forEach { envelope in
                outputString += encodeN40Envelope(envelope: envelope) + "\n"
            }
        } catch let error as NSError {
            print("Couldn't fetch envelopes. \(error), \(error.userInfo)")
        }
        return outputString
    }
    private static func encodeGroups(viewContext: NSManagedObjectContext) -> String {
        var outputString = ""
        let fetchRequest: NSFetchRequest<N40Group> = N40Group.fetchRequest()
        do {
            // Peform Fetch Request
            let fetchedGroups = try viewContext.fetch(fetchRequest)
            fetchedGroups.forEach { group in
                outputString += encodeN40Group(group: group) + "\n"
            }
        } catch let error as NSError {
            print("Couldn't fetch groups. \(error), \(error.userInfo)")
        }
        return outputString
    }
    private static func encodeNotes(viewContext: NSManagedObjectContext) -> String {
        var outputString = ""
        let fetchRequest: NSFetchRequest<N40Note> = N40Note.fetchRequest()
        do {
            // Peform Fetch Request
            let fetchedNotes = try viewContext.fetch(fetchRequest)
            fetchedNotes.forEach { note in
                outputString += encodeN40Note(note: note) + "\n"
            }
        } catch let error as NSError {
            print("Couldn't fetch notes. \(error), \(error.userInfo)")
        }
        return outputString
    }
    private static func encodeTransactions(viewContext: NSManagedObjectContext) -> String {
        var outputString = ""
        let fetchRequest: NSFetchRequest<N40Transaction> = N40Transaction.fetchRequest()
        do {
            // Peform Fetch Request
            let fetchedTransactions = try viewContext.fetch(fetchRequest)
            fetchedTransactions.forEach { transaction in
                outputString += encodeN40Transaction(transaction: transaction) + "\n"
            }
        } catch let error as NSError {
            print("Couldn't fetch transactions. \(error), \(error.userInfo)")
        }
        return outputString
    }
    
    
    
    public static func encodeDatabase(viewContext: NSManagedObjectContext) -> String {
        var outputText = ""
        
        outputText += encodePeople(viewContext: viewContext) + "\n"
        outputText += encodeGoals(viewContext: viewContext) + "\n"
        outputText += encodeEvents(viewContext: viewContext) + "\n"
        outputText += encodeEnvelopes(viewContext: viewContext) + "\n"
        outputText += encodeGroups(viewContext: viewContext) + "\n"
        outputText += encodeNotes(viewContext: viewContext) + "\n"
        outputText += encodeTransactions(viewContext: viewContext)
        
        return outputText
    }
    
    
}

struct Importer {
    
    private static func deleteCurrentDatabase(viewContext: NSManagedObjectContext) {
        //just delete everything
        
        deletePeople(viewContext: viewContext)
        deleteGoals(viewContext: viewContext)
        deleteEvents(viewContext: viewContext)
        deleteEnvelopes(viewContext: viewContext)
        deleteGroups(viewContext: viewContext)
        deleteNotes(viewContext: viewContext)
        deleteTransactions(viewContext: viewContext)
        
        Importer.saveContext(viewContext)
    }
    
    private static func deletePeople (viewContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<N40Person> = N40Person.fetchRequest()
        do {
            let fetchedResults = try viewContext.fetch(fetchRequest)
            for each in fetchedResults {
                viewContext.delete(each)
            }
        } catch { }
    }
    private static func deleteGoals (viewContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<N40Goal> = N40Goal.fetchRequest()
        do {
            let fetchedResults = try viewContext.fetch(fetchRequest)
            for each in fetchedResults {
                viewContext.delete(each)
            }
        } catch { }
    }
    private static func deleteEvents (viewContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
        do {
            let fetchedResults = try viewContext.fetch(fetchRequest)
            for each in fetchedResults {
                viewContext.delete(each)
            }
        } catch { }
    }
    private static func deleteEnvelopes (viewContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<N40Envelope> = N40Envelope.fetchRequest()
        do {
            let fetchedResults = try viewContext.fetch(fetchRequest)
            for each in fetchedResults {
                viewContext.delete(each)
            }
        } catch { }
    }
    private static func deleteGroups (viewContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<N40Group> = N40Group.fetchRequest()
        do {
            let fetchedResults = try viewContext.fetch(fetchRequest)
            for each in fetchedResults {
                viewContext.delete(each)
            }
        } catch { }
    }
    private static func deleteNotes (viewContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<N40Note> = N40Note.fetchRequest()
        do {
            let fetchedResults = try viewContext.fetch(fetchRequest)
            for each in fetchedResults {
                viewContext.delete(each)
            }
        } catch { }
    }
    private static func deleteTransactions (viewContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<N40Transaction> = N40Transaction.fetchRequest()
        do {
            let fetchedResults = try viewContext.fetch(fetchRequest)
            for each in fetchedResults {
                viewContext.delete(each)
            }
        } catch { }
    }
    
    
    private static func saveContext(_ viewContext: NSManagedObjectContext) {
        do {
            try viewContext.save()
        }
        catch {
            // Handle Error
            print("Error info: \(error)")
        }
    }
    
    private static func fetchForPerson(firstName: String, lastName: String, viewContext: NSManagedObjectContext) -> N40Person? {
        let fetchRequest: NSFetchRequest<N40Person> = N40Person.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "firstName == %@", firstName), NSPredicate(format: "lastName == %@", lastName)])
        
        var fetchedPerson: N40Person? = nil
        
        do {
            // Peform Fetch Request
            let fetchedPeople = try viewContext.fetch(fetchRequest)
            if fetchedPeople.count > 0 {
                fetchedPerson = fetchedPeople.first
            }
        } catch let error as NSError {
            print("Couldn't fetch people. \(error), \(error.userInfo)")
        }
        
        return fetchedPerson
    }
    private static func fetchForGoal(name: String, viewContext: NSManagedObjectContext) -> N40Goal? {
        let fetchRequest: NSFetchRequest<N40Goal> = N40Goal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        var fetchedGoal: N40Goal? = nil
        
        do {
            // Peform Fetch Request
            let fetchedGoals = try viewContext.fetch(fetchRequest)
            if fetchedGoals.count > 0 {
                fetchedGoal = fetchedGoals.first
            }
        } catch let error as NSError {
            print("Couldn't fetch goals. \(error), \(error.userInfo)")
        }
        
        return fetchedGoal
    }
    private static func fetchForEnvelope(name: String, viewContext: NSManagedObjectContext) -> N40Envelope? {
        let fetchRequest: NSFetchRequest<N40Envelope> = N40Envelope.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        var fetchedEnvelope: N40Envelope? = nil
        
        do {
            // Peform Fetch Request
            let fetchedEnvelopes = try viewContext.fetch(fetchRequest)
            if fetchedEnvelopes.count > 0 {
                fetchedEnvelope = fetchedEnvelopes.first
            }
        } catch let error as NSError {
            print("Couldn't fetch envelope. \(error), \(error.userInfo)")
        }
        
        return fetchedEnvelope
    }
    private static func fetchForEvent(name: String, startDate: Date, viewContext: NSManagedObjectContext) -> N40Event? {
        let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "name == %@", name), NSPredicate(format: "startDate == %@", startDate as NSDate)])
        
        var fetchedEvent: N40Event? = nil
        
        do {
            // Peform Fetch Request
            let fetchedEvents = try viewContext.fetch(fetchRequest)
            if fetchedEvents.count > 0 {
                fetchedEvent = fetchedEvents.first
            }
        } catch let error as NSError {
            print("Couldn't fetch Event. \(error), \(error.userInfo)")
        }
        
        return fetchedEvent
    }

    public static func decodeDatabase(inputData: String, viewContext: NSManagedObjectContext) {
        deleteCurrentDatabase(viewContext: viewContext)
        
        let lines = inputData.components(separatedBy: "\n")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        
        var i = 0
        
        while i < lines.count {
            if lines[i] == "N40Person" {
                //make a new core data entity
                let newPerson = N40Person(context: viewContext)
                
                
                newPerson.address = lines[i+1].deletingPrefix("address: ")
                newPerson.birthday = dateFormatter.date(from: lines[i+2].deletingPrefix("birthday: ")) ?? Date()
                newPerson.birthdayDay = Int16(lines[i+3].deletingPrefix("birthdayDay: ")) ?? 0
                newPerson.birthdayMonth = Int16(lines[i+4].deletingPrefix("birthdayMonth: ")) ?? 0
                newPerson.email1 = lines[i+5].deletingPrefix("email1: ")
                newPerson.email2 = lines[i+6].deletingPrefix("email2: ")
                newPerson.firstName = lines[i+7].deletingPrefix("firstName: ")
                newPerson.hasBirthday = lines[i+8].deletingPrefix("hasBirthday: ") == "true"
                newPerson.isArchived = lines[i+9].deletingPrefix("isArchived: ") == "true"
                newPerson.lastName = lines[i+10].deletingPrefix("lastName: ")
                newPerson.notes = lines[i+11].deletingPrefix("notes: ").newLineDecoded()
                newPerson.phoneNumber1 = lines[i+12].deletingPrefix("phoneNumber1: ")
                newPerson.phoneNumber2 = lines[i+13].deletingPrefix("phoneNumber2: ")
                newPerson.socialMedia1 = lines[i+14].deletingPrefix("socialMedia1: ")
                newPerson.socialMedia2 = lines[i+15].deletingPrefix("socialMedia2: ")
                newPerson.title = lines[i+16].deletingPrefix("title: ")
//                if lines[i+17].contains("photo: ") && lines[i+17].deletingPrefix("photo: ") != "no-photo" {
//                    newPerson.photo = lines[i+17].deletingPrefix("photo: ").data(using: .utf16)
//                    i += 1 //to account for the extra line
//                }
                i += 17
                
            } else if lines[i] == "N40Goal" {
                //make a new core data entity
                let newGoal = N40Goal(context: viewContext)
                
                newGoal.color = lines[i+1].deletingPrefix("color: ")
                newGoal.dateCompleted = dateFormatter.date(from: lines[i+2].deletingPrefix("dateCompleted: ")) ?? Date()
                newGoal.deadline = dateFormatter.date(from: lines[i+3].deletingPrefix("deadline: ")) ?? Date()
                newGoal.hasDeadline = lines[i+4].deletingPrefix("hasDeadline: ") == "true"
                newGoal.information = lines[i+5].deletingPrefix("information: ").newLineDecoded()
                newGoal.isCompleted = lines[i+6].deletingPrefix("isCompleted: ") == "true"
                newGoal.name = lines[i+7].deletingPrefix("name: ")
                newGoal.priorityIndex = Int16(lines[i+8].deletingPrefix("priorityIndex: ")) ?? 0
                
                i += 9
                //now add relationships
                while lines[i].starts(with: "attachedPeople: ") {
                    let fullName = lines[i].deletingPrefix("attachedPeople: ").components(separatedBy: "-nm-")
                    let addedPerson: N40Person? = fetchForPerson(firstName: fullName[0], lastName: fullName[1], viewContext: viewContext)
                    if addedPerson != nil {
                        newGoal.addToAttachedPeople(addedPerson!)
                    }
                    i += 1
                }
                while lines[i].starts(with: "endGoals: ") {
                    let name = lines[i].deletingPrefix("endGoals: ")
                    let addedEndGoal: N40Goal? = fetchForGoal(name: name, viewContext: viewContext)
                    if addedEndGoal != nil {
                        newGoal.addToEndGoals(addedEndGoal!)
                    }
                    i += 1
                }
                    
                    
                    
            } else if lines[i] == "N40Event" {
                //make a new core data entity
                let newEvent = N40Event(context: viewContext)
                
                newEvent.allDay = lines[i+1].deletingPrefix("allDay: ") == "true"
                newEvent.bucketlist = lines[i+2].deletingPrefix("bucketlist: ") == "true"
                newEvent.color = lines[i+3].deletingPrefix("color: ")
                newEvent.contactMethod = Int16(lines[i+4].deletingPrefix("contactMethod: ")) ?? 0
                newEvent.duration = Int16(lines[i+5].deletingPrefix("duration: ")) ?? 0
                newEvent.eventType = Int16(lines[i+6].deletingPrefix("eventType: ")) ?? 0
                newEvent.information = lines[i+7].deletingPrefix("information: ").newLineDecoded()
                newEvent.isScheduled = lines[i+8].deletingPrefix("isScheduled: ") == "true"
                newEvent.location = lines[i+9].deletingPrefix("location: ")
                newEvent.name = lines[i+10].deletingPrefix("name: ")
                newEvent.recurringTag = lines[i+11].deletingPrefix("recurringTag: ")
                newEvent.startDate = dateFormatter.date(from: lines[i+12].deletingPrefix("startDate: ")) ?? Date()
                newEvent.status = Int16(lines[i+13].deletingPrefix("status: ")) ?? 0
                newEvent.summary = lines[i+14].deletingPrefix("summary: ").newLineDecoded()
                
                i += 15
                
                //now add relationships
                while lines[i].starts(with: "attachedPeople: ") {
                    let fullName = lines[i].deletingPrefix("attachedPeople: ").components(separatedBy: "-nm-")
                    let addedPerson: N40Person? = fetchForPerson(firstName: fullName[0], lastName: fullName[1], viewContext: viewContext)
                    if addedPerson != nil {
                        newEvent.addToAttachedPeople(addedPerson!)
                    }
                    i += 1
                }
                while lines[i].starts(with: "attachedGoals: ") {
                    let name = lines[i].deletingPrefix("attachedGoals: ")
                    let addedGoal: N40Goal? = fetchForGoal(name: name, viewContext: viewContext)
                    if addedGoal != nil {
                        newEvent.addToAttachedGoals(addedGoal!)
                    }
                    i += 1
                }
                
            } else if lines[i] == "N40Envelope" {
                //make a new core data entity
                let newEnvelope = N40Envelope(context: viewContext)
                
                newEnvelope.currentBalance = Double(lines[i+1].deletingPrefix("currentBalance: ")) ?? 0.0
                newEnvelope.lastCalculation = dateFormatter.date(from: lines[i+2].deletingPrefix("lastCalculation: ")) ?? Date()
                newEnvelope.name = lines[i+3].deletingPrefix("name: ")
                
                i += 4
                
            } else if lines[i] == "N40Group" {
                //make a new core data entity
                let newGroup = N40Group(context: viewContext)
                
                newGroup.information = lines[i+1].deletingPrefix("information: ").newLineDecoded()
                newGroup.name = lines[i+2].deletingPrefix("name: ")
                newGroup.priorityIndex = Int16(lines[i+3].deletingPrefix("priorityIndex: ")) ?? 0
                
                i += 4
                
                //now add relationships
                while lines[i].starts(with: "people: ") {
                    let fullName = lines[i].deletingPrefix("people: ").components(separatedBy: "-nm-")
                    let addedPerson: N40Person? = fetchForPerson(firstName: fullName[0], lastName: fullName[1], viewContext: viewContext)
                    if addedPerson != nil {
                        newGroup.addToPeople(addedPerson!)
                    }
                    i += 1
                }
                while lines[i].starts(with: "goals: ") {
                    let name = lines[i].deletingPrefix("goals: ")
                    let addedGoal: N40Goal? = fetchForGoal(name: name, viewContext: viewContext)
                    if addedGoal != nil {
                        newGroup.addToGoals(addedGoal!)
                    }
                    i += 1
                }
                
            } else if lines[i] == "N40Note" {
                //make a new core data entity
                let newNote = N40Note(context: viewContext)
                
                newNote.archived = lines[i+1].deletingPrefix("archived: ") == "true"
                newNote.date = dateFormatter.date(from: lines[i+2].deletingPrefix("date: ")) ?? Date()
                newNote.information = lines[i+3].deletingPrefix("information: ").newLineDecoded()
                newNote.title = lines[i+4].deletingPrefix("title: ")
                
                i += 5
                
                //now add relationships
                while lines[i].starts(with: "attachedPeople: ") {
                    let fullName = lines[i].deletingPrefix("attachedPeople: ").components(separatedBy: "-nm-")
                    let addedPerson: N40Person? = fetchForPerson(firstName: fullName[0], lastName: fullName[1], viewContext: viewContext)
                    if addedPerson != nil {
                        newNote.addToAttachedPeople(addedPerson!)
                    }
                    i += 1
                }
                while lines[i].starts(with: "attachedGoals: ") {
                    let name = lines[i].deletingPrefix("attachedGoals: ")
                    let addedGoal: N40Goal? = fetchForGoal(name: name, viewContext: viewContext)
                    if addedGoal != nil {
                        newNote.addToAttachedGoals(addedGoal!)
                    }
                    i += 1
                }
                
            } else if lines[i] == "N40Transaction" {
                //make new core data entity
                let newTransaction = N40Transaction(context: viewContext)
                
                newTransaction.amount = Double(lines[i+1].deletingPrefix("amount: ")) ?? 0.0
                newTransaction.date = dateFormatter.date(from: lines[i+2].deletingPrefix("date: ")) ?? Date()
                newTransaction.isIncome = lines[i+3].deletingPrefix("isIncome: ") == "true"
                newTransaction.isPartOfEnvelopeTransfer = lines[i+4].deletingPrefix("isPartOfEnvelopeTransfer: ") == "true"
                newTransaction.name = lines[i+5].deletingPrefix("name: ")
                newTransaction.notes = lines[i+6].deletingPrefix("notes: ").newLineDecoded()
                newTransaction.recurringTag = lines[i+7].deletingPrefix("recurringTag: ")
                
                i += 8
                
                //now add relationships
                while lines[i].starts(with: "envelope: ") {
                    let envelopeName = lines[i].deletingPrefix("envelope: ")
                    let addedEnvelope: N40Envelope? = fetchForEnvelope(name: envelopeName, viewContext: viewContext)
                    if addedEnvelope != nil {
                        newTransaction.addToEnvelope(addedEnvelope!)
                    }
                    i += 1
                }
                while lines[i].starts(with: "event: ") {
                    let eventComponents = lines[i].deletingPrefix("event: ").components(separatedBy: "-event-")
                    let eventName = eventComponents[0]
                    let eventDate = dateFormatter.date(from: eventComponents[1]) ?? Date()
                    let addedEvent = fetchForEvent(name: eventName, startDate: eventDate, viewContext: viewContext)
                    if addedEvent != nil {
                        newTransaction.event = addedEvent!
                    }
                    i += 1
                }
                
                
                
            } else {
                i += 1 //try the next line.
            }
        }
        
        saveContext(viewContext)
        print("completed")
    }
    
    
}

fileprivate extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    func trimmed() -> String {
        return self.replacingOccurrences(of: "\n", with: " ")
    }
    
    func newLineEncoded() -> String {
        return self.replacingOccurrences(of: "\n", with: "<newline>")
    }
    func newLineDecoded() -> String {
        return self.replacingOccurrences(of: "<newline>", with: "\n")
    }
}
