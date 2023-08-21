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
    
    
    public var editEvent: N40Event?
    public var duplicate = false
    
    private let contactOptions = [["In Person", "person.2.fill"],["Phone Call","phone.fill"],["Text Message","message"],["Social Media", "ellipsis.bubble"],["Email", "envelope"],["Other", "bubble.middle.top"]]
    
    private let eventTypeOptions = [["Reportable", "rectangle.and.pencil.and.ellipsis"], ["Non-Reportable","calendar.day.timeline.leading"], ["Radar Event", "dot.radiowaves.left.and.right"], ["To-Do", "checklist"]]
    
    private let repeatOptions = ["No Repeat", "Every Day", "Every Week", "Every Month"]
    
    
    @State private var eventTitle = ""
    @State private var location = ""
    
    @State private var information = ""
    
    @State public var isScheduled: Bool = true
    @State public var chosenStartDate: Date = Date()
    @State private var chosenEndDate = Date()
    @State private var duration = 0
    @State private var contactMethod = ["In Person", "person.2.fill"]
    @State public var eventType: [String] = ["Non-Reportable","calendar.day.timeline.leading"]
    
    @State private var status = 0
    
    @State private var attachedPeople: [N40Person] = []
    @State private var showingAttachPeopleSheet = false
    
    @State private var selectedColor = Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))
    
    @State private var isAlreadyRepeating = false
    @State private var repeatOptionSelected = "No Repeat"
    @State private var numberOfRepeats = 3 // in months
    @State private var isShowingEditAllConfirm: Bool = false
    
    //for the delete button
    @State private var isPresentingConfirm: Bool = false
    @State private var isPresentingRecurringDeleteConfirm: Bool = false
    
    
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
                    if (eventType == eventTypeOptions[3]) {
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


                    Button("Set to Now") {
                        chosenStartDate = Date()
                        chosenEndDate = Calendar.current.date(byAdding: .minute, value: duration, to: chosenStartDate) ?? chosenStartDate
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
                            ForEach(contactOptions, id: \.self) {
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
                            ForEach(eventTypeOptions, id: \.self) {
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
                                    }
                                    
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
                
                
            }
            
        }.padding()
            .onAppear {
                populateFields()
            }
            .toolbar {
                if (editEvent != nil) {
                    
                    ToolbarItemGroup {
                        Text(("Edit " + (eventType != ["To-Do", "checklist"] ? "Event" : "To-Do")))
                        Spacer()
                        
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
                            
                            Button("Done") {
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
                            
                            Button("Done") {
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
            
            do {
                try viewContext.save()
            }
            catch {
                // Handle Error
                print("Error info: \(error)")
                
            }
            
        }
    }
    
    private func populateFields() {
        if editEvent != nil {
            eventTitle = editEvent?.name ?? ""
            location = editEvent?.location ?? ""
            
            information = editEvent?.information ?? ""
            
            isScheduled = editEvent?.isScheduled ?? true
            
            chosenStartDate = editEvent!.startDate
            
            duration = Int(editEvent?.duration ?? 0)
            contactMethod = contactOptions[Int(editEvent?.contactMethod ?? 0)]
            eventType = eventTypeOptions[Int(editEvent?.eventType ?? 1)]
            
            status = Int(editEvent?.status ?? 0)
            
            editEvent?.attachedPeople?.forEach {person in
                attachedPeople.append(person as! N40Person)
            }
            
            if editEvent!.recurringTag != "" {
                isAlreadyRepeating = true
            }
        }
        
        selectedColor = Color(hex: editEvent?.color ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))
        
        chosenEndDate = Calendar.current.date(byAdding: .minute, value: duration, to: chosenStartDate) ?? chosenStartDate
        
    }
    
    private func saveEvent () {
        withAnimation {
            
            var newEvent = editEvent ?? N40Event(context: viewContext)
            if duplicate {
                //If duplicate is set to true, remove the reference to the old editEvent so that it creates a new one.
                newEvent = N40Event(context: viewContext)
            }
            
            newEvent.name = self.eventTitle
            if (self.eventTitle == "") {
                //This is where we would add up the attached people to figure out an event title name.
                
                //placeholder:
                newEvent.name = "Do Something"
            }
            
            newEvent.startDate = self.chosenStartDate
            newEvent.isScheduled = self.isScheduled
            newEvent.duration = Int16(self.duration)
            
            newEvent.location = self.location
            newEvent.information = self.information
            
            newEvent.status = Int16(self.status)
            
            //finds the index representing the correct contact method and event type
            newEvent.contactMethod = Int16(self.contactOptions.firstIndex(of: contactMethod) ?? 0)
            newEvent.eventType = Int16(self.eventTypeOptions.firstIndex(of: eventType) ?? 1) //Make 1 the default for now
    
            
            newEvent.color = selectedColor.toHex() ?? "#FF7051"
            
            //Making recurring events
            if repeatOptionSelected != repeatOptions[0] {
                let recurringTag = UUID().uuidString
                newEvent.recurringTag = recurringTag
                if repeatOptionSelected == repeatOptions[1] {
                    //Repeat Daily
                    for i in 1...30*numberOfRepeats {
                        duplicateEvent(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i, to: newEvent.startDate)!)
                    }
                    
                } else if repeatOptionSelected == repeatOptions[2] {
                    //Repeat Weekly
                    for i in 1...Int(Double(numberOfRepeats)/12.0*52.0) {
                        duplicateEvent(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i*7, to: newEvent.startDate)!)
                    }
                    
                } else if repeatOptionSelected == repeatOptions[3] {
                    //Repeat Monthly
                    for i in 1...numberOfRepeats {
                        duplicateEvent(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .month, value: i, to: newEvent.startDate)!)
                    }
                }
                
            }
            
            
            attachedPeople.forEach {person in
                newEvent.addToAttachedPeople(person)
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
                        
                        recurringEvent.location = self.location
                        recurringEvent.information = self.information
                        
                        //wont save status
                        
                        //finds the index representing the correct contact method and event type
                        recurringEvent.contactMethod = Int16(self.contactOptions.firstIndex(of: contactMethod) ?? 0)
                        recurringEvent.eventType = Int16(self.eventTypeOptions.firstIndex(of: eventType) ?? 1) //Make 1 the default for now
                        
                        
                        recurringEvent.color = selectedColor.toHex() ?? "#FF7051"
                        
                        
                        attachedPeople.forEach {person in
                            recurringEvent.addToAttachedPeople(person)
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
    
    private func duplicateEvent(originalEvent: N40Event, newStartDate: Date) {
        
        let newEvent = N40Event(context: viewContext)
        newEvent.name = originalEvent.name
        newEvent.isScheduled = originalEvent.isScheduled
        newEvent.startDate = newStartDate // This one is different
        newEvent.duration = originalEvent.duration
        newEvent.location = originalEvent.location
        newEvent.information = originalEvent.information
        newEvent.status = 0 // This one is different
        newEvent.contactMethod = originalEvent.contactMethod
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
        EditEventView(editEvent: nil).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
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

struct SelectPeopleView: View {
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
