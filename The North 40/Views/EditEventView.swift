//
//  EditEventView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/17/23.
//

import SwiftUI
import CoreData

struct EditEventView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @State public var editEvent: N40Event?
    
    
    private let repeatOptions = ["No Repeat", "Every Day", "Every Week", "Every Two Weeks", "Monthly (Day of Month)", "Monthly (Week of Month)"]
    
    
    @State private var eventTitle = ""
    @State private var location = ""
    
    @State private var information = ""
    
    @State public var isScheduled: Bool = true
    @State public var chosenStartDate: Date = Date()
    @State private var chosenEndDate = Date()
    @State private var duration = 0
    @State private var allDay: Bool = false
    
    @State private var contactMethod = ["In Person", "person.2.fill"]
    @State public var eventType: [String] = ["Non-Reportable","calendar.day.timeline.leading"]
    
    @State private var status = 0
    @State private var summary = ""
    private let circleDiameter = 30.0
    private let statusLabels = ["Unreported", "Skipped", "Attempted", "Happened"]
    
    @State private var attachedPeople: [N40Person] = []
    @State private var showingAttachPeopleSheet = false
    
    @State private var attachedGoals: [N40Goal] = []
    @State private var showingAttachGoalSheet = false
    
    @State private var selectedColor = Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))
    
    @State private var isAlreadyRepeating = false
    @State private var repeatOptionSelected = "No Repeat"
    @State private var numberOfRepeats = 3 // in months
    @State private var isShowingEditAllConfirm: Bool = false
    
    @State private var isShowingSaveAsCopyConfirm: Bool = false
    
    //for the delete button
    @State private var isPresentingConfirm: Bool = false
    @State private var isPresentingRecurringDeleteConfirm: Bool = false
    
    // used to pass in a person or goal (for example if event created from person or goal)
    public var attachingGoal: N40Goal? = nil
    public var attachingPerson: N40Person? = nil
    
    var body: some View {
        VStack {
            
            if (editEvent == nil) {
                
                HStack{
                    Button("Cancel") {dismiss()}
                    Spacer()
                    Text(("Create New " + (eventType != ["To-Do", "checklist"] ? "Event" : "To-Do")))
                    Spacer()
                    Button("Done") {
                        saveEvent()
                        dismiss()
                    }
                }
            
            }
            
            ScrollView {
                
                HStack {
                    if (eventType == N40Event.EVENT_TYPE_OPTIONS[3]) {
                        //Button to check off the to-do
                        Button(action: {
                            if status == 0 {
                                status = 3
                            } else {
                                status = 0
                            }
                        }) {
                            Image(systemName: (status == 0) ? "square" : "checkmark.square")
                        }.buttonStyle(PlainButtonStyle())
                    }
                    //Title of the event
                    TextField("Event Title", text: $eventTitle).font(.title2)
                    
                }
                
                if (eventType == N40Event.EVENT_TYPE_OPTIONS[0]) && chosenStartDate < Date() {
                    //If it's a reportable event and it's in the past:
                    
                    VStack {
                        //This is the view where you can report on the event.
                        HStack {
                            Text("Status: \(statusLabels[status])")
                            Spacer()
                            if status == N40Event.UNREPORTED {
                                Image(systemName: "questionmark.circle.fill")
                                    .resizable()
                                    .foregroundColor(Color.orange)
                                    .frame(width: circleDiameter, height:circleDiameter)
                            } else {
                                Button {
                                    status = N40Event.UNREPORTED
                                } label: {
                                    Image(systemName: "questionmark.circle.fill")
                                        .resizable()
                                        .frame(width: circleDiameter, height:circleDiameter)
                                }
                            }
                            
                            if status == N40Event.SKIPPED {
                                Image(systemName: "slash.circle.fill")
                                    .resizable()
                                    .foregroundColor(Color.red)
                                    .frame(width: circleDiameter, height:circleDiameter)
                            } else {
                                Button {
                                    status = N40Event.SKIPPED
                                } label: {
                                    Image(systemName: "slash.circle.fill")
                                        .resizable()
                                        .frame(width: circleDiameter, height:circleDiameter)
                                }
                            }
                            
                            if status == N40Event.ATTEMPTED {
                                Image(systemName: "xmark.circle.fill")
                                    .resizable()
                                    .foregroundColor(Color.red)
                                    .frame(width: circleDiameter, height:circleDiameter)
                            } else {
                                Button {
                                    status = N40Event.ATTEMPTED
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .resizable()
                                        .frame(width: circleDiameter, height:circleDiameter)
                                }
                            }
                            
                            if status == N40Event.HAPPENED {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .foregroundColor(Color.green)
                                    .frame(width: circleDiameter, height:circleDiameter)
                            } else {
                                Button {
                                    status = N40Event.HAPPENED
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .resizable()
                                        .frame(width: circleDiameter, height:circleDiameter)
                                }
                            }
                            
                            
                            
                        }
                        
                        HStack {
                            Text("Summary: ")
                            Spacer()
                        }
                        TextEditor(text: $summary)
                            .padding(.horizontal)
                            .shadow(color: .gray, radius: 5)
                            .frame(minHeight: 100)
                        
                        
                    }
                    
                }
                
                
                VStack {
                    
                    //Choosing date and time
                    Toggle("Schedule Event", isOn: $isScheduled)
                    
                    DatePicker(selection: $chosenStartDate) {
                        Text("From: ")
                    }.disabled(!isScheduled)
                        .onChange(of: chosenStartDate, perform: { (value) in
                            chosenEndDate = Calendar.current.date(byAdding: .minute, value: duration, to: chosenStartDate) ?? chosenStartDate                                        })

                    DatePicker(selection: $chosenEndDate) {
                        Text("To: ")
                    }.disabled(!isScheduled)
                        .onChange(of: chosenEndDate, perform: { _ in
                            duration = getMinutesDifferenceFromTwoDates(start: chosenStartDate, end: chosenEndDate)
                        })

                    HStack {
                        Text("All Day: ")
                        Toggle("All Day: ", isOn: $allDay)
                            .labelsHidden()
                            .disabled(!isScheduled)
                        Spacer()
                        
                        Button("Set to Now") {
                            chosenStartDate = Date()
                            chosenEndDate = Calendar.current.date(byAdding: .minute, value: duration, to: chosenStartDate) ?? chosenStartDate
                        }.disabled(!isScheduled)
                        
                    }
                    
                    HStack {
                        
                        Text("Duration: \(duration) min")
                        Spacer()
                        Stepper("", value: $duration, in: 0...1440, step: 5, onEditingChanged: {_ in
                            chosenEndDate = Calendar.current.date(byAdding: .minute, value: duration, to: chosenStartDate) ?? chosenStartDate
                        })
                            
                    }
                    
                }
                VStack {
                    HStack {
                        Picker("Contact Method: ", selection: $contactMethod) {
                            ForEach(N40Event.contactOptions, id: \.self) {
                                Label($0[0], systemImage: $0[1])
                            }
                        }
                        Spacer()
                    }
                    
                    HStack {
                        TextField("Location:", text: $location)
                        Spacer()
                        if (location != "") {
                            Button(action: {
                                guard let address = URL(string: "https://www.google.com/maps/place/\(location.replacingOccurrences(of: " ", with: "+"))") else { return }
                                UIApplication.shared.open(address)
                            }) {
                                Label("", systemImage: "map.fill")
                            }
                        }
                    }
                    
                    
                    HStack {
                        Picker("Event Type: ", selection: $eventType) {
                            ForEach(N40Event.EVENT_TYPE_OPTIONS, id: \.self) {
                                Label($0[0], systemImage: $0[1])
                            }
                        }
                        Spacer()
                        Text("Color: ")
                        ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                            .labelsHidden()
                        
                    }
                    
                    VStack {
                        VStack {
                            HStack {
                                Text("Repeat event: ")
                                if (!isAlreadyRepeating) {
                                    Picker("", selection: $repeatOptionSelected) {
                                        ForEach(repeatOptions, id: \.self) { option in
                                            Text(option)
                                        }
                                    }.disabled(!isScheduled)
                                    
                                    Spacer()
                                    
                                    
                                } else {
                                    Text("This is a repeating event. ")
                                    
                                    Spacer()
                                }
                            }
                            if (!isAlreadyRepeating) {
                                HStack {
                                    Text("For \(numberOfRepeats) Months")
                                    Stepper("", value: $numberOfRepeats, in: 1...12)
                                        .disabled(!isScheduled)
                                    
                                }
                            }
                        }.padding()
                    }.border(.gray)
                    
                    
                    VStack {
                        HStack {
                            Text("Event Description: ")
                            Spacer()
                        }
                        TextEditor(text: $information)
                            .padding(.horizontal)
                            .shadow(color: .gray, radius: 5)
                            .frame(minHeight: 100)
                        
                        
                    }
                }
                
                VStack {
                    HStack{
                        Text("Attached People:")
                            .font(.title3)
                        Spacer()
                    }
                    
                    ForEach(attachedPeople) { person in
                        HStack {
                            Text("\(person.firstName) \(person.lastName)")
                            Spacer()
                            Button {
                                removePerson(removedPerson: person)
                            } label: {
                                Image(systemName: "multiply")
                            }
                        }.padding()
                    }
                    
                    Button(action: {
                        showingAttachPeopleSheet.toggle()
                    }) {
                        Label("Attach Person", systemImage: "plus").padding()
                    }.sheet(isPresented: $showingAttachPeopleSheet) {
                        SelectPeopleView(editEventView: self)
                    }
                    
                        
                    
                }
                
                VStack {
                    HStack{
                        Text("Attached Goals:")
                            .font(.title3)
                        Spacer()
                    }
                    
                    ForEach(attachedGoals) { goal in
                        HStack {
                            Text(goal.name)
                            Spacer()
                            Button {
                                removeGoal(removedGoal: goal)
                            } label: {
                                Image(systemName: "multiply")
                            }
                        }.padding()
                    }
                    
                    Button(action: {
                        showingAttachGoalSheet.toggle()
                    }) {
                        Label("Attach Goal", systemImage: "plus").padding()
                    }.sheet(isPresented: $showingAttachGoalSheet) {
                        SelectGoalView(editEventView: self)
                    }
                    
                        
                    
                }
                
                
            }
            
        }.padding()
            .onAppear {
                populateFields()
            }
            .toolbar {
                if (editEvent != nil) {
                    
                    ToolbarItemGroup {
                        
                        
                        Button {
                            isShowingSaveAsCopyConfirm = true
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }.confirmationDialog("Save Changes As New Copy?", isPresented: $isShowingSaveAsCopyConfirm) {
                            Button("Save Changes As New Copy") {
                                saveEvent(saveAsCopy: true)
                                
                                dismiss()
                            }
                        }
                        
                        if (editEvent!.recurringTag != "") {
                            
                            Button {
                                isPresentingRecurringDeleteConfirm = true
                            } label: {
                                Image(systemName: "trash")
                            }.confirmationDialog("Delete this event?",
                                                 isPresented: $isPresentingRecurringDeleteConfirm) {
                                Button("Just this event", role: .destructive) {
                                    
                                    deleteEvent()
                                    
                                    dismiss()
                                    
                                }
                                Button("Delete all upcoming events", role: .destructive) {
                                    
                                    deleteAllRecurringEvents()
                                    
                                    dismiss()
                                }
                            } message: {
                                Text("Delete this event and all following?")
                            }
                            
                            Button("Update") {
                                isShowingEditAllConfirm = true
                            }.confirmationDialog("Save To All Occurances?", isPresented: $isShowingEditAllConfirm) {
                                Button("Just this one") {
                                    saveEvent()
                                    
                                    dismiss()
                                }
                                Button("Change all upcoming") {
                                    saveAllRecurringEvents()
                                    
                                    dismiss()
                                }
                            } message: {
                                Text("Affect all upcoming occurances?")
                            }
                            
                            
                        } else {
                            Button {
                                isPresentingConfirm = true
                            } label: {
                                Image(systemName: "trash")
                            }.confirmationDialog("Delete this event?",
                                                 isPresented: $isPresentingConfirm) {
                                Button("Delete", role: .destructive) {
                                    deleteEvent()
                                    
                                    dismiss()
                                    
                                }
                            } message: {
                                Text("Delete This Event?")
                            }
                            
                            Button("Update") {
                                saveEvent()
                                dismiss()
                            }
                            
                            
                        }
                        
                        
                    }
                    
                }
            }
        
            
        
        
    }
    
    public func attachPerson(addPerson: N40Person) {
        //attaches a person to the attachedPeople array. (Used by the SelectPeopleView
        attachedPeople.append(addPerson)
    }
    
    public func removePerson(removedPerson: N40Person) {
        //removes a person from the attachedPeople array. (Used by the button on each list item)
        let idx = attachedPeople.firstIndex(of: removedPerson) ?? -1
        if idx != -1 {
            attachedPeople.remove(at: idx)
            
            editEvent?.removeFromAttachedPeople(removedPerson)
            
        }
    }
    
    public func attachGoal (addGoal: N40Goal)  {
        //attaches a goal to the attachedGoal array.
        attachedGoals.append(addGoal)
    }
    public func removeGoal (removedGoal: N40Goal) {
        let idx = attachedGoals.firstIndex(of: removedGoal) ?? -1
        if idx != -1 {
            attachedGoals.remove(at: idx)
            
            editEvent?.removeFromAttachedGoals(removedGoal)
        }
    }
    
    private func populateFields() {
        if editEvent != nil {
            eventTitle = editEvent?.name ?? ""
            location = editEvent?.location ?? ""
            
            information = editEvent?.information ?? ""
            
            isScheduled = editEvent?.isScheduled ?? true
            allDay = editEvent?.allDay ?? false
            
            chosenStartDate = editEvent!.startDate
            
            duration = Int(editEvent?.duration ?? 0)
            contactMethod = N40Event.contactOptions[Int(editEvent?.contactMethod ?? 0)]
            eventType = N40Event.EVENT_TYPE_OPTIONS[Int(editEvent?.eventType ?? 1)]
            
            status = Int(editEvent?.status ?? 0)
            summary = editEvent?.summary ?? ""
            
            
            editEvent?.attachedPeople?.forEach {person in
                attachedPeople.append(person as! N40Person)
            }
            editEvent?.attachedGoals?.forEach {goal in
                attachedGoals.append(goal as! N40Goal)
            }
            
            
            if editEvent!.recurringTag != "" {
                isAlreadyRepeating = true
            }
        } else {
            //This is for if you create an event from a timeline view.
            if attachingGoal != nil {
                attachedGoals.append(attachingGoal!)
            }
            if attachingPerson != nil {
                attachedPeople.append(attachingPerson!)
            }
            
        }
        if UserDefaults.standard.bool(forKey: "randomEventColor") {
            if editEvent != nil {
                selectedColor = Color(hex: editEvent?.color ?? "#FF7051") ?? Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 0.5)
            } else {
                selectedColor = Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 1.0)
            }
        } else {
            selectedColor = Color(hex: editEvent?.color ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))
        }
        
        
        chosenEndDate = Calendar.current.date(byAdding: .minute, value: duration, to: chosenStartDate) ?? chosenStartDate
        
    }
    
    private func saveEvent (saveAsCopy: Bool = false) {
        withAnimation {
            
            var newEvent = editEvent ?? N40Event(context: viewContext)
            if saveAsCopy {
                //If duplicate is set to true, remove the reference to the old editEvent so that it creates a new one.
                newEvent = N40Event(context: viewContext)
            }
            
            newEvent.name = self.eventTitle
            
            if (self.eventTitle == "") {
    
                var defaultName = "Do Something"
                
                if editEvent == nil {
                    if attachedPeople.count > 0 {
                        defaultName = attachedPeople[0].firstName + " " + attachedPeople[0].lastName
                        for eachPerson in attachedPeople {
                            if eachPerson != attachedPeople[0] {
                                defaultName += ", " + eachPerson.firstName + " " + eachPerson.lastName
                            }
                        }
                    } else if attachedGoals.count > 0 {
                        defaultName = attachedGoals[0].name
                        for eachGoal in attachedGoals {
                            if eachGoal != attachedGoals[0] {
                                defaultName += ", " + eachGoal.name
                            }
                        }
                    }
                }
                
                newEvent.name = defaultName
            }
            
            newEvent.startDate = self.chosenStartDate
            newEvent.isScheduled = self.isScheduled
            newEvent.duration = Int16(self.duration)
            newEvent.allDay = self.allDay
            
            newEvent.location = self.location
            newEvent.information = self.information
            
            newEvent.status = Int16(self.status)
            newEvent.summary = self.summary
            
            //finds the index representing the correct contact method and event type
            newEvent.contactMethod = Int16(N40Event.contactOptions.firstIndex(of: contactMethod) ?? 0)
            newEvent.eventType = Int16(N40Event.EVENT_TYPE_OPTIONS.firstIndex(of: eventType) ?? 1) //Make 1 the default for now
    
            
            newEvent.color = selectedColor.toHex() ?? "#FF7051"
            
            if editEvent != nil {
                //We need to remove all the people and goals before we reattach any.
                let alreadyAttachedPeople = editEvent?.getAttachedPeople ?? []
                let alreadyAttachedGoals = editEvent?.getAttachedGoals ?? []
                
                alreadyAttachedPeople.forEach {person in
                    newEvent.removeFromAttachedPeople(person)
                }
                alreadyAttachedGoals.forEach {goal in
                    newEvent.removeFromAttachedGoals(goal)
                }
                
            }
            //Now add back only the ones that are selected.
            attachedPeople.forEach {person in
                newEvent.addToAttachedPeople(person)
            }
            attachedGoals.forEach {goal in
                newEvent.addToAttachedGoals(goal)
            }
            
            
            
            
            //Making recurring events
            if repeatOptionSelected != repeatOptions[0] {
                let recurringTag = UUID().uuidString
                newEvent.recurringTag = recurringTag
                if repeatOptionSelected == "Every Day" {
                    //Repeat Daily
                    for i in 1...30*numberOfRepeats {
                        duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i, to: newEvent.startDate)!)
                    }
                    
                } else if repeatOptionSelected == "Every Week" {
                    //Repeat Weekly
                    for i in 1...Int(Double(numberOfRepeats)/12.0*52.0) {
                        duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i*7, to: newEvent.startDate)!)
                    }
                    
                } else if repeatOptionSelected == "Every Two Weeks" {
                    for i in 1...Int(Double(numberOfRepeats)/12.0*52.0/2.0) {
                        duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i*14, to: newEvent.startDate)!)
                    }
                } else if repeatOptionSelected == "Monthly (Day of Month)" {
                    //Repeat Monthly
                    for i in 1...numberOfRepeats {
                        duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .month, value: i, to: newEvent.startDate)!)
                    }
                } else if repeatOptionSelected == "Monthly (Week of Month)" {
                    // Repeat monthly keeping the day of week
                    var repeatsMade = 1 // the first is the original event.
                    
                    var repeatDate = newEvent.startDate
                    var lastCreatedDate = newEvent.startDate
                    
                    while repeatsMade < numberOfRepeats {
                        
                        
                        //While the next date is in the same month as the last created date
                        while Calendar.current.component(.month, from: lastCreatedDate) == Calendar.current.component(.month, from: repeatDate) {
                            //add a week to the next date until it crosses over to the next month
                            repeatDate = Calendar.current.date(byAdding: .day, value: 7, to: repeatDate) ?? repeatDate
                        }
                        //Now the repeat date should be in the next month,
                        // ex. if doing first sunday of the month, it should be the next first sunday
                        
                        duplicateN40Event(originalEvent: newEvent, newStartDate: repeatDate)
                        lastCreatedDate = repeatDate
                        repeatsMade += 1
                    }
                    
                }
                
            }
            
                        
            // To save the new entity to the persistent store, call
            // save on the context
            do {
                try viewContext.save()
            }
            catch {
                // Handle Error
                print("Error info: \(error)")
                
            }
            
        }
        
    }
    
    private func deleteEvent() {
        if (editEvent != nil) {
            viewContext.delete(editEvent!)
            
            do {
                try viewContext.save()
            }
            catch {
                // Handle Error
                print("Error info: \(error)")
            }
        } else {
            print("Cannot delete event because it has not been created yet. ")
        }
    }
    
    private func deleteAllRecurringEvents() {
        if editEvent != nil {
            let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
            
            let isScheduledPredicate = NSPredicate(format: "isScheduled = %d", true)
            let isFuturePredicate = NSPredicate(format: "startDate >= %@", ((editEvent?.startDate ?? Date()) as CVarArg)) //will include this event
            let sameTagPredicate = NSPredicate(format: "recurringTag == %@", (editEvent!.recurringTag))
            
            let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [isScheduledPredicate, isFuturePredicate, sameTagPredicate])
            fetchRequest.predicate = compoundPredicate
            
            do {
                // Peform Fetch Request
                let fetchedEvents = try viewContext.fetch(fetchRequest)
                
                fetchedEvents.forEach { recurringEvent in
                    viewContext.delete(recurringEvent)
                }
                
                // To save the entities to the persistent store, call
                // save on the context
                do {
                    try viewContext.save()
                }
                catch {
                    // Handle Error
                    print("Error info: \(error)")
                    
                }
                
                
            } catch let error as NSError {
                print("Couldn't fetch other recurring events. \(error), \(error.userInfo)")
            }
        } else {
            print("Cannot delete recurring events because they have not been created yet. ")
        }
    }
    
    private func saveAllRecurringEvents() {
        if editEvent != nil {
            let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
            
            let isScheduledPredicate = NSPredicate(format: "isScheduled = %d", true)
            let isFuturePredicate = NSPredicate(format: "startDate >= %@", ((editEvent?.startDate ?? Date()) as CVarArg)) //will include this event
            let sameTagPredicate = NSPredicate(format: "recurringTag == %@", (editEvent!.recurringTag))
            
            let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [isScheduledPredicate, isFuturePredicate, sameTagPredicate])
            fetchRequest.predicate = compoundPredicate
            
            do {
                // Peform Fetch Request
                let fetchedEvents = try viewContext.fetch(fetchRequest)
                
                fetchedEvents.forEach { recurringEvent in
                    
                    withAnimation {
                        
                        recurringEvent.name = self.eventTitle
                        if (self.eventTitle == "") {
                            //This is where we would add up the attached people to figure out an event title name.
                            
                            //placeholder:
                            recurringEvent.name = "Do Something"
                        }
                        
                        recurringEvent.duration = Int16(self.duration)
                        
                        //only saves time info
                        let hour = Calendar.current.component(.hour, from: chosenStartDate)
                        let minute = Calendar.current.component(.minute, from: chosenStartDate)
                        recurringEvent.startDate = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: recurringEvent.startDate) ?? recurringEvent.startDate
                        
                        recurringEvent.allDay = self.allDay
                        
                        recurringEvent.location = self.location
                        recurringEvent.information = self.information
                        
                        //wont save status
                        //or summary
                        
                        //finds the index representing the correct contact method and event type
                        recurringEvent.contactMethod = Int16(N40Event.contactOptions.firstIndex(of: contactMethod) ?? 0)
                        recurringEvent.eventType = Int16(N40Event.EVENT_TYPE_OPTIONS.firstIndex(of: eventType) ?? 1) //Make 1 the default for now
                        
                        
                        recurringEvent.color = selectedColor.toHex() ?? "#FF7051"
                        
                        
                        //We need to remove all the people and goals before we reattach any.
                        let alreadyAttachedPeople = editEvent?.getAttachedPeople ?? []
                        let alreadyAttachedGoals = editEvent?.getAttachedGoals ?? []
                        
                        alreadyAttachedPeople.forEach {person in
                            recurringEvent.removeFromAttachedPeople(person)
                        }
                        alreadyAttachedGoals.forEach {goal in
                            recurringEvent.removeFromAttachedGoals(goal)
                        }
                        
                        
                        //Now add back only the ones that are selected.
                        attachedPeople.forEach {person in
                            recurringEvent.addToAttachedPeople(person)
                        }
                        attachedGoals.forEach {goal in
                            recurringEvent.addToAttachedGoals(goal)
                        }
                    }
                }
                
                // To save the entities to the persistent store, call
                // save on the context
                do {
                    try viewContext.save()
                }
                catch {
                    // Handle Error
                    print("Error info: \(error)")
                    
                }
                
                
            } catch let error as NSError {
                print("Couldn't fetch other recurring events. \(error), \(error.userInfo)")
            }
        } else {
            print("Cannot save updates to the other recurring events because they have not been created yet. ")
        }
    }
    
    private func duplicateN40Event(originalEvent: N40Event, newStartDate: Date) {
        
        let newEvent = N40Event(context: viewContext)
        newEvent.name = originalEvent.name
        newEvent.isScheduled = originalEvent.isScheduled
        newEvent.startDate = newStartDate // This one is different
        newEvent.duration = originalEvent.duration
        newEvent.location = originalEvent.location
        newEvent.information = originalEvent.information
        newEvent.status = 0 // This one is different
        newEvent.summary = "" // also this one
        newEvent.contactMethod = originalEvent.contactMethod
        newEvent.allDay = originalEvent.allDay
        newEvent.eventType = originalEvent.eventType
        newEvent.color = originalEvent.color
        newEvent.recurringTag = originalEvent.recurringTag
        originalEvent.getAttachedPeople.forEach {person in
            newEvent.addToAttachedPeople(person)
        }
        originalEvent.getAttachedGoals.forEach {goal in
            newEvent.addToAttachedGoals(goal)
        }
        
        do {
            try viewContext.save()
        }
        catch {
            // Handle Error
            print("Error info: \(error)")
            
        }
        
    }
    
    
    
        
}


struct EditEvent_Previews: PreviewProvider {
    static var previews: some View {
        EditEventView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

func getMinutesDifferenceFromTwoDates(start: Date, end: Date) -> Int
   {

       let diff = Int(end.timeIntervalSince1970 - start.timeIntervalSince1970)
       
       let minutes = (diff) / 60
       return minutes
   }



// ********************** SELECT PEOPLE VIEW ***************************
// A sheet that pops up where you can select people to be attached.

fileprivate struct SelectPeopleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)], animation: .default)
    private var fetchedPeople: FetchedResults<N40Person>
    
    var editEventView: EditEventView
    
    var body: some View {
        List(fetchedPeople) {person in
            HStack {
                Text("\(person.firstName) \(person.lastName)")
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                editEventView.attachPerson(addPerson: person)
                dismiss()
            }
            
        }
    }
}

// ********************** SELECT GOAL VIEW ***************************
// A sheet that pops up where you can select people to be attached.

fileprivate struct SelectGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.deadline, ascending: true)], animation: .default)
    private var fetchedGoals: FetchedResults<N40Goal>
    
    var editEventView: EditEventView
    
    var body: some View {
        List(fetchedGoals) {goal in
            HStack {
                Text(goal.name)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                editEventView.attachGoal(addGoal: goal)
                dismiss()
            }
            
        }
    }
}


extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0
        
        let length = hexSanitized.count
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
            
        } else {
            return nil
        }
        
        self.init(red: r, green: g, blue: b, opacity: a)
    }
    
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
