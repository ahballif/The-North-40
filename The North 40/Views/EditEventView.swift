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
    
    
    private let repeatOptions = ["No Repeat", "Every Day", "On Days:", "Every Week", "Every Two Weeks", "Monthly (Day of Month)", "Monthly (Week of Month)", "Yearly"]
    @State private var repeatMonday = true
    @State private var repeatTuesday = true
    @State private var repeatWednesday = true
    @State private var repeatThursday = true
    @State private var repeatFriday = true
    @State private var repeatSaturday = false
    @State private var repeatSunday = false
    
    @State private var eventTitle = ""
    @State private var location = ""
    
    @State private var information = ""
    
    @State public var isScheduled: Bool = true
    @State public var chosenStartDate: Date = Date()
    @State private var chosenEndDate = Date()
    @State private var duration = UserDefaults.standard.integer(forKey: "defaultEventDuration")
    @State private var allDay: Bool = false
    
    @State private var contactMethod = N40Event.CONTACT_OPTIONS[UserDefaults.standard.integer(forKey: "defaultContactMethod")]
    @State public var eventType: [String] = N40Event.EVENT_TYPE_OPTIONS[UserDefaults.standard.integer(forKey: "defaultCalendarEventType")]
    
    @State private var status = 0
    @State private var summary = ""
    private let circleDiameter = 30.0
    private let statusLabels = ["Unreported", "Skipped", "Attempted", "Happened"]
    
    @State private var showingSetToNow = true
    
    @State private var attachedPeople: [N40Person] = []
    @State private var showingAttachPeopleSheet = false
    
    @State private var attachedGoals: [N40Goal] = []
    @State private var showingAttachGoalSheet = false
    
    @State private var selectedColor = Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))
    
    @State private var isAlreadyRepeating = false
    @State private var redoingEventRepeat = false
    @State private var repeatOptionSelected = "No Repeat"
    @State private var numberOfRepeats = 3 // in occurances unless it's in days then its months and if its on specific days its in weeks.
    @State private var isShowingEditAllConfirm: Bool = false
    
    @State private var isShowingSaveAsCopyConfirm: Bool = false
    
    //for the delete button
    @State private var isPresentingConfirm: Bool = false
    @State private var isPresentingRecurringDeleteConfirm: Bool = false
    
    // used to pass in a person or goal (for example if event created from person or goal)
    public var attachingGoal: N40Goal? = nil
    public var attachingPerson: N40Person? = nil
    
    @State private var showingSelectOnCalendarSheet = false
    
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
            ScrollViewReader {value in
                ScrollView {
                    
                    HStack {
                        if (eventType == N40Event.EVENT_TYPE_OPTIONS[3]) {
                            //Button to check off the to-do
                            Button(action: {
                                if status == 0 {
                                    status = 3
                                    
                                    if !isScheduled && UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_EditEventView") {
                                        chosenStartDate = Date()
                                        isScheduled = true
                                        if UserDefaults.standard.bool(forKey: "roundScheduleCompletedTodos") {
                                            //first make seconds 0
                                            chosenStartDate = Calendar.current.date(bySetting: .second, value: 0, of: chosenStartDate) ?? chosenStartDate
                                            
                                            //then find how much to change the minutes
                                            let minutes: Int = Calendar.current.component(.minute, from: chosenStartDate)
                                            let minuteInterval = Int(25.0/UserDefaults.standard.double(forKey: "hourHeight")*60.0)
                                            
                                            //now round it
                                            let roundedMinutes = Int(minutes / minuteInterval) * minuteInterval
                                            
                                            chosenStartDate = Calendar.current.date(byAdding: .minute, value: Int(roundedMinutes - minutes), to: chosenStartDate) ?? chosenStartDate
                                            
                                        }
                                    }
                                    
                                } else {
                                    status = 0
                                }
                                
                                
                            }) {
                                Image(systemName: (status == 0) ? "square" : "checkmark.square")
                            }.buttonStyle(PlainButtonStyle())
                        }
                        //Title of the event
                        TextField("Event Title", text: $eventTitle)
                            .font(.title2)
                            .padding(.vertical,  5)
                            .onSubmit {
                                
                                let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
                                fetchRequest.predicate = NSPredicate(format: "name == %@", eventTitle)
                                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
                                
                                do {
                                    // Peform Fetch Request
                                    let fetchedSimilarEvents = try viewContext.fetch(fetchRequest)
                                    
                                    if fetchedSimilarEvents.count > 0 {
                                        selectedColor = Color(hex: fetchedSimilarEvents[0].color) ?? selectedColor
                                    }
                                    
                                    
                                } catch let error as NSError {
                                    print("Couldn't fetch other recurring events. \(error), \(error.userInfo)")
                                }
                                
                                
                            }
                        
                        
                        
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
                    
                    if information == "" {
                        //If the description is empty put the controls at the top
                        eventDetailControls()
                    }
                    
                    
                    VStack {
                        HStack {
                            Text("Event Description: ")
                            Spacer()
                        }
                        TextEditor(text: $information)
                            .padding(.horizontal)
                            .shadow(color: .gray, radius: 5)
                            .frame(minHeight: 100)
                            .id("descriptionBox")
                            .onChange(of: information) { newValue in
                                
                                value.scrollTo("descriptionBox")
                                
                            }
                        
                    }
                    
                    if information != "" {
                        //but if the desription is not empty, put it first.
                        eventDetailControls()
                    }
                    
                    
                    VStack {
                        HStack{
                            Text("Attached People:")
                                .font(.title3)
                            Spacer()
                        }
                        
                        ForEach(attachedPeople) { person in
                            
                            HStack {
                                NavigationLink(destination: PersonDetailView(selectedPerson: person)) {
                                    Text((person.title == "" ? "\(person.firstName)" : "\(person.title)") + " \(person.lastName)")
                                }.buttonStyle(.plain)
                                
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
                            SelectPeopleView(editEventView: self, selectedPeopleList: attachedPeople)
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
                                NavigationLink(destination: GoalDetailView(selectedGoal: goal)) {
                                    Text(goal.name)
                                    
                                }
                                .buttonStyle(.plain)
                                
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
            }
        }.padding()
            .onAppear {
                populateFields()
            }
            .toolbar {
                if (editEvent != nil) {
                    
                    ToolbarItemGroup {
                        
                        
                        Button {
                            isShowingSaveAsCopyConfirm.toggle()
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }.confirmationDialog("Save Changes As New Copy?", isPresented: $isShowingSaveAsCopyConfirm) {
                            Button("Save Changes As New Copy") {
                                saveEvent(saveAsCopy: true)
                                
                                dismiss()
                            }
                        }
                        
                        if (isAlreadyRepeating) {
                            
                            Button {
                                isPresentingRecurringDeleteConfirm.toggle()
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
                                isShowingEditAllConfirm.toggle()
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
                                isPresentingConfirm.toggle()
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
    
    public func eventDetailControls () -> some View {
        return VStack {
            VStack {
                
                //Choosing date and time
                HStack {
                    Text("Scheduled: ")
                    Toggle("Schedule Event", isOn: $isScheduled)
                        .labelsHidden()
                    Spacer()
                    Text("All Day: ")
                    Toggle("All Day: ", isOn: $allDay)
                        .labelsHidden()
                        .disabled(!isScheduled)
                    
                }
                DatePicker(selection: $chosenStartDate) {
                    Text("From: ")
                }.disabled(!isScheduled)
                    .onChange(of: chosenStartDate, perform: { (value) in
                        chosenEndDate = Calendar.current.date(byAdding: .minute, value: duration, to: chosenStartDate) ?? chosenStartDate
                        allConfirmsFalse()
                    })
                    

                DatePicker(selection: $chosenEndDate) {
                    Text("To: ")
                }.disabled(!isScheduled)
                    .onChange(of: chosenEndDate, perform: { _ in
                        duration = getMinutesDifferenceFromTwoDates(start: chosenStartDate, end: chosenEndDate)
                        if duration < 0 {
                            duration += 60*12
                            chosenEndDate = Calendar.current.date(byAdding: .minute, value: duration, to: chosenStartDate) ?? chosenStartDate
                        }
                        allConfirmsFalse()
                    })
                

                HStack {
                    ZStack {
                        if showingSetToNow {
                            Button("Set to Now") {
                                chosenStartDate = Date()
                                chosenEndDate = Calendar.current.date(byAdding: .minute, value: duration, to: chosenStartDate) ?? chosenStartDate
                                
                                showingSetToNow = false
                            }.disabled(!isScheduled)
                        } else {
                            Button("Round Time") {
                                //first make seconds 0
                                chosenStartDate = Calendar.current.date(bySetting: .second, value: 0, of: chosenStartDate) ?? chosenStartDate
                                
                                //then find how much to change the minutes
                                let minutes: Int = Calendar.current.component(.minute, from: chosenStartDate)
                                let minuteInterval = Int(25.0/UserDefaults.standard.double(forKey: "hourHeight")*60.0)
                                
                                //now round it
                                let roundedMinutes = Int(minutes / minuteInterval) * minuteInterval
                                
                                chosenStartDate = Calendar.current.date(byAdding: .minute, value: Int(roundedMinutes - minutes), to: chosenStartDate) ?? chosenStartDate
                                
                                showingSetToNow = true
                            }
                        }
                    }.onAppear {
                        if Calendar.current.component(.minute, from: chosenStartDate) == Calendar.current.component(.minute, from: Date()) {
                            showingSetToNow = false
                        }
                    }
                    
                    Spacer()
                    Button("Select on Calendar") {
                        showingSelectOnCalendarSheet.toggle()
                    }.buttonStyle(.bordered)
                        .disabled(!isScheduled)
                    .sheet(isPresented: $showingSelectOnCalendarSheet) {
                        SelectOnScheduleView(editEventView: self, filteredDay: chosenStartDate)
                    }
                    
                }
                
                HStack {
                    if duration < 60 {
                        Text("Duration: \(duration) min")
                    } else {
                        Text("Duration: \(Int(duration/60)) h \(String(format: "%02d", duration%60)) min")
                    }
                    Spacer()
                    Stepper("", value: $duration, in: 0...1440, step: 5, onEditingChanged: {_ in
                        chosenEndDate = Calendar.current.date(byAdding: .minute, value: duration, to: chosenStartDate) ?? chosenStartDate
                    })
                        
                }
                
            }
            VStack {
                HStack {
                    Text("Event Medium: ")
                    Spacer()
                    Picker("Contact Method: ", selection: $contactMethod) {
                        ForEach(N40Event.CONTACT_OPTIONS, id: \.self) {
                            Label($0[0], systemImage: $0[1])
                        }
                    }
                    
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
                                Button("Edit the repeat cycle") {
                                    redoingEventRepeat = true
                                    isAlreadyRepeating = false //this will trigger the options to load on the screen
                                }
                                Spacer()
                            }
                        }
                        if (!isAlreadyRepeating && repeatOptionSelected != "No Repeat") {
                            HStack {
                                if repeatOptionSelected == "Every Day" {
                                    Text("For \(numberOfRepeats) Months")
                                } else if repeatOptionSelected == "On Days:" {
                                    Text("For \(numberOfRepeats) Weeks")
                                } else {
                                    Text("For \(numberOfRepeats) Occurrences")
                                }
                                Stepper("", onIncrement: {
                                    numberOfRepeats += 1
                                }, onDecrement: {
                                    if numberOfRepeats >= 1 {
                                        numberOfRepeats -= 1
                                    }
                                })
                                    .disabled(!isScheduled)
                                
                            }
                        }
                        if (!isAlreadyRepeating && repeatOptionSelected == "On Days:") {
                            VStack {
                                HStack {
                                    Text("Monday")
                                    Spacer()
                                    Button {
                                        repeatMonday.toggle()
                                    } label: {
                                        if repeatMonday {
                                            Image(systemName: "checkmark.square.fill")
                                        } else {
                                            Image(systemName: "square")
                                        }
                                    }
                                }
                                HStack {
                                    Text("Tuesday")
                                    Spacer()
                                    Button {
                                        repeatTuesday.toggle()
                                    } label: {
                                        if repeatTuesday {
                                            Image(systemName: "checkmark.square.fill")
                                        } else {
                                            Image(systemName: "square")
                                        }
                                    }
                                }
                                HStack {
                                    Text("Wednesday")
                                    Spacer()
                                    Button {
                                        repeatWednesday.toggle()
                                    } label: {
                                        if repeatWednesday {
                                            Image(systemName: "checkmark.square.fill")
                                        } else {
                                            Image(systemName: "square")
                                        }
                                    }
                                }
                                HStack {
                                    Text("Thursday")
                                    Spacer()
                                    Button {
                                        repeatThursday.toggle()
                                    } label: {
                                        if repeatThursday {
                                            Image(systemName: "checkmark.square.fill")
                                        } else {
                                            Image(systemName: "square")
                                        }
                                    }
                                }
                                HStack {
                                    Text("Friday")
                                    Spacer()
                                    Button {
                                        repeatFriday.toggle()
                                    } label: {
                                        if repeatFriday {
                                            Image(systemName: "checkmark.square.fill")
                                        } else {
                                            Image(systemName: "square")
                                        }
                                    }
                                }
                                HStack {
                                    Text("Saturday")
                                    Spacer()
                                    Button {
                                        repeatSaturday.toggle()
                                    } label: {
                                        if repeatSaturday {
                                            Image(systemName: "checkmark.square.fill")
                                        } else {
                                            Image(systemName: "square")
                                        }
                                    }
                                }
                                HStack {
                                    Text("Sunday")
                                    Spacer()
                                    Button {
                                        repeatSunday.toggle()
                                    } label: {
                                        if repeatSunday {
                                            Image(systemName: "checkmark.square.fill")
                                        } else {
                                            Image(systemName: "square")
                                        }
                                    }
                                }
                            }
                        }
                    }.padding()
                }.border(.gray)
            }
        }
    }
    
    
    
    public func attachPerson(addPerson: N40Person) {
        //attaches a person to the attachedPeople array. (Used by the SelectPeopleView
        if (!attachedPeople.contains(addPerson)) {
            attachedPeople.append(addPerson)
        }
    }
    
    public func removePerson(removedPerson: N40Person) {
        //removes a person from the attachedPeople array. (Used by the button on each list item)
        let idx = attachedPeople.firstIndex(of: removedPerson) ?? -1
        if idx != -1 {
            attachedPeople.remove(at: idx)
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
            contactMethod = N40Event.CONTACT_OPTIONS[Int(editEvent?.contactMethod ?? Int16(UserDefaults.standard.integer(forKey: "defaultContactMethod"))) ]
            eventType = N40Event.EVENT_TYPE_OPTIONS[Int(editEvent?.eventType  ?? Int16(UserDefaults.standard.integer(forKey: "defaultCalendarEventType")))]
            
            status = Int(editEvent?.status ?? 0)
            summary = editEvent?.summary ?? ""
            
            
            attachedPeople = []
            attachedGoals = []
            
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
                selectedColor = Color(hex: editEvent?.color ?? UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 0.5)
            } else {
                selectedColor = Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 1.0)
            }
        } else {
            selectedColor = Color(hex: editEvent?.color ?? UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))
        }
        
        
        chosenEndDate = Calendar.current.date(byAdding: .minute, value: duration, to: chosenStartDate) ?? chosenStartDate
        
    }
    
    private func allConfirmsFalse() {
        isShowingEditAllConfirm = false
        isShowingSaveAsCopyConfirm = false
        isPresentingConfirm = false
        isPresentingRecurringDeleteConfirm = false
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
    
                var defaultName = "Event"
                
                if newEvent.name == "" {
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
            newEvent.contactMethod = Int16(N40Event.CONTACT_OPTIONS.firstIndex(of: contactMethod) ?? 0)
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
            
            
            if saveAsCopy {
                //don't repeat the duplicate (unless a new repeat options was selected)
                newEvent.recurringTag = ""
            } else {
                if redoingEventRepeat {
                    deleteAllRecurringEvents(includeThisEvent: false)
                }
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
                    if numberOfRepeats > 1 {
                        for i in 1...numberOfRepeats-1 {
                            duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i*7, to: newEvent.startDate)!)
                        }
                    }
                } else if repeatOptionSelected == "Every Two Weeks" {
                    if numberOfRepeats > 1 {
                        for i in 1...numberOfRepeats-1 {
                            duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i*14, to: newEvent.startDate)!)
                        }
                    }
                } else if repeatOptionSelected == "Monthly (Day of Month)" {
                    //Repeat Monthly
                    if numberOfRepeats > 1 {
                        for i in 1...numberOfRepeats-1 {
                            duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .month, value: i, to: newEvent.startDate)!)
                        }
                    }
                } else if repeatOptionSelected == "Monthly (Week of Month)" {
                    // Repeat monthly keeping the day of week
                    var repeatsMade = 1 // the first is the original event.
                    
                    var repeatDate = newEvent.startDate
                    var lastCreatedDate = newEvent.startDate
                    
                    //determine the week of month
                    var weekOfMonth = 1
                    var indexWeek = Calendar.current.date(byAdding: .day, value: -7, to: newEvent.startDate)!
                    
                    while Calendar.current.component(.month, from: newEvent.startDate) == Calendar.current.component(.month, from: indexWeek) {
                        
                        weekOfMonth += 1
                        indexWeek = Calendar.current.date(byAdding: .day, value: -7, to: indexWeek)!
                        //subtract a week and see if it's still in the month
                    }
                    //now we know what week of the month the event is in.
                    
                    
                    
                    while repeatsMade < numberOfRepeats {
                        
                        
                        //While the next date is in the same month as the last created date
                        while Calendar.current.component(.month, from: lastCreatedDate) == Calendar.current.component(.month, from: repeatDate) {
                            //add a week to the next date until it crosses over to the next month
                            repeatDate = Calendar.current.date(byAdding: .day, value: 7, to: repeatDate) ?? repeatDate
                        }
                        //Now the repeat date should be in the next month,
                        // ex. if doing first sunday of the month, it should be the next first sunday
                        
                        //now make it the right week of the month
                        repeatDate = Calendar.current.date(byAdding: .day, value: (weekOfMonth-1)*7, to: repeatDate) ?? repeatDate
                        
                        
                        
                        duplicateN40Event(originalEvent: newEvent, newStartDate: repeatDate)
                        lastCreatedDate = repeatDate
                        repeatsMade += 1
                    }
                     
                } else if repeatOptionSelected == "Yearly" {
                    //Repeat Yearly
                    if numberOfRepeats > 1 {
                        for i in 1...numberOfRepeats-1 {
                            duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .year, value: i, to: newEvent.startDate)!)
                        }
                    }
                } else if repeatOptionSelected == "On Days:" {
                    //Repeat Daily
                    let today = newEvent.startDate.dayOfWeek()
                    if (today == "Monday" && repeatMonday) || (today == "Tuesday" && repeatTuesday) || (today == "Wednesday" && repeatWednesday) || (today == "Thursday" && repeatThursday) || (today == "Friday" && repeatFriday) || (today == "Saturday" && repeatSaturday) || (today == "Sunday" && repeatSunday) {
                        //This is the case where we don't add any days.
                        if numberOfRepeats > 1 {
                            for i in 1...numberOfRepeats-1 {
                                duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i*7, to: newEvent.startDate)!)
                            }
                        }
                    }
                    if (today == "Monday" && repeatTuesday) || (today == "Tuesday" && repeatWednesday) || (today == "Wednesday" && repeatThursday) || (today == "Thursday" && repeatFriday) || (today == "Friday" && repeatSaturday) || (today == "Saturday" && repeatSunday) || (today == "Sunday" && repeatMonday) {
                        //This is the case where we add 1 day
                        for i in 0...numberOfRepeats-1 {
                            duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i*7+1, to: newEvent.startDate)!)
                        }
                    }
                    if (today == "Monday" && repeatWednesday) || (today == "Tuesday" && repeatThursday) || (today == "Wednesday" && repeatFriday) || (today == "Thursday" && repeatSaturday) || (today == "Friday" && repeatSunday) || (today == "Saturday" && repeatMonday) || (today == "Sunday" && repeatTuesday) {
                        //This is the case where we add two days
                        for i in 0...numberOfRepeats-1 {
                            duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i*7+2, to: newEvent.startDate)!)
                        }
                    }
                    if (today == "Monday" && repeatThursday) || (today == "Tuesday" && repeatFriday) || (today == "Wednesday" && repeatSaturday) || (today == "Thursday" && repeatSunday) || (today == "Friday" && repeatMonday) || (today == "Saturday" && repeatTuesday) || (today == "Sunday" && repeatWednesday) {
                        //This is the case where we add three days
                        for i in 0...numberOfRepeats-1 {
                            duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i*7+3, to: newEvent.startDate)!)
                        }
                    }
                    if (today == "Monday" && repeatFriday) || (today == "Tuesday" && repeatSaturday) || (today == "Wednesday" && repeatSunday) || (today == "Thursday" && repeatMonday) || (today == "Friday" && repeatTuesday) || (today == "Saturday" && repeatWednesday) || (today == "Sunday" && repeatThursday) {
                        //This is the case where we add four days
                        for i in 0...numberOfRepeats-1 {
                            duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i*7+4, to: newEvent.startDate)!)
                        }
                    }
                    if (today == "Monday" && repeatSaturday) || (today == "Tuesday" && repeatSunday) || (today == "Wednesday" && repeatMonday) || (today == "Thursday" && repeatTuesday) || (today == "Friday" && repeatWednesday) || (today == "Saturday" && repeatThursday) || (today == "Sunday" && repeatFriday) {
                        //This is the case where we add five days
                        for i in 0...numberOfRepeats-1 {
                            duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i*7+5, to: newEvent.startDate)!)
                        }
                    }
                    if (today == "Monday" && repeatSunday) || (today == "Tuesday" && repeatMonday) || (today == "Wednesday" && repeatTuesday) || (today == "Thursday" && repeatWednesday) || (today == "Friday" && repeatThursday) || (today == "Saturday" && repeatFriday) || (today == "Sunday" && repeatSaturday) {
                        //This is the case where we add six days
                        for i in 0...numberOfRepeats-1 {
                            duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i*7+6, to: newEvent.startDate)!)
                        }
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
    
    private func deleteAllRecurringEvents(includeThisEvent: Bool = true) {
        if editEvent != nil {
            let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
            
            let isScheduledPredicate = NSPredicate(format: "isScheduled = %d", true)
            let isFuturePredicate = includeThisEvent ? NSPredicate(format: "startDate >= %@", ((editEvent?.startDate ?? Date()) as CVarArg)) : NSPredicate(format: "startDate > %@", ((editEvent?.startDate ?? Date()) as CVarArg))
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
                        recurringEvent.contactMethod = Int16(N40Event.CONTACT_OPTIONS.firstIndex(of: contactMethod) ?? 0)
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
    
    public func setDate(date: Date) {
        chosenStartDate = date
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
    
    
    let alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W", "X","Y", "Z"]
    let alphabetString = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)], animation: .default)
    private var fetchedPeople: FetchedResults<N40Person>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Group.priorityIndex, ascending: false)], animation: .default)
    private var allGroups: FetchedResults<N40Group>
    
    @State private var sortingAlphabetical = false
    
    var editEventView: EditEventView
    var selectedPeopleList: [N40Person]
    @State private var isArchived = false
    
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Sort all alphabetically: ")
                    Spacer()
                    Toggle("sortAlphabetically", isOn: $sortingAlphabetical).labelsHidden()
                }.padding()
                
                if sortingAlphabetical {
                    
                    List{
                        let noLetterLastNames = fetchedPeople.reversed().filter { $0.lastName.uppercased().filter(alphabetString.contains) == "" && $0.isArchived == isArchived && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}.sorted { $0.lastName < $1.lastName }
                        if noLetterLastNames.count > 0 {
                            Section(header: Text("*")) {
                                ForEach(noLetterLastNames, id: \.self) { person in
                                    if !selectedPeopleList.contains(person) {
                                        personListItem(person: person)
                                    }
                                }
                            }
                        }
                        ForEach(alphabet, id: \.self) { letter in
                            let letterSet = fetchedPeople.reversed().filter { $0.lastName.hasPrefix(letter) && $0.isArchived == isArchived && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}.sorted { $0.lastName < $1.lastName }
                            if (letterSet.count > 0) {
                                Section(header: Text(letter)) {
                                    ForEach(letterSet, id: \.self) { person in
                                        if !selectedPeopleList.contains(person) {
                                            personListItem(person: person)
                                        }
                                    }
                                }
                            }
                        }
                    }.listStyle(.sidebar)
                        .padding(.horizontal, 3)
                    
                } else {
                    
                    List {
                        ForEach(allGroups) {group in
                            let groupSet: [N40Person] = group.getPeople.filter{ $0.isArchived == isArchived && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}
                            if groupSet.count > 0 {
                                Section(header: Text(group.name)) {
                                    //first a button to attach the whole group
                                    Button("Attach Entire Group") {
                                        for eachPerson in groupSet {
                                            editEventView.attachPerson(addPerson: eachPerson)
                                        }
                                        dismiss()
                                    }.foregroundColor(.blue)
                                    
                                    ForEach(groupSet) {person in
                                        if !selectedPeopleList.contains(person) {
                                            personListItem(person: person)
                                        }
                                    }
                                }
                            }
                        }
                        let ungroupedSet = fetchedPeople.reversed().filter { $0.isArchived == isArchived && $0.getGroups.count < 1 && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}.sorted {$0.lastName < $1.lastName}
                        if ungroupedSet.count > 0 {
                            Section(header: Text("Ungrouped People")) {
                                ForEach(ungroupedSet) {person in
                                    if !selectedPeopleList.contains(person) {
                                        personListItem(person: person)
                                    }
                                }
                            }
                        }
                    }.listStyle(.sidebar)
                }
                
            }.searchable(text: $searchText)
        }
    }
    
    
    
    
    private func personListItem (person: N40Person) -> some View {
        return HStack {
            Text((person.title == "" ? "" : "\(person.title) ") + "\(person.firstName) \(person.lastName)")
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editEventView.attachPerson(addPerson: person)
            dismiss()
        }
    }
}

// ********************** SELECT GOAL VIEW ***************************
// A sheet that pops up where you can select people to be attached.

fileprivate struct SelectGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.priorityIndex, ascending: false)], predicate: NSPredicate(format: "isCompleted == NO"), animation: .default)
    private var fetchedGoals: FetchedResults<N40Goal>
    
    var editEventView: EditEventView
    
    var body: some View {
        List(fetchedGoals) {goal in
            if goal.getEndGoals.count == 0 {
                goalBox(goal)
                    .onTapGesture {
                        editEventView.attachGoal(addGoal: goal)
                        dismiss()
                    }
                ForEach(goal.getSubGoals, id: \.self) {subGoal in
                    if !subGoal.isCompleted {
                        goalBox(subGoal)
                            .padding(.leading, 25.0)
                            .onTapGesture {
                                editEventView.attachGoal(addGoal: subGoal)
                                dismiss()
                            }
                    }
                }
            }
            
            
        }
    }
    
    private func goalBox (_ goal: N40Goal) -> some View {
        return VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundColor(Color(hex: goal.color))
                    .opacity(1.0)
                    .frame(height: 50.0)
                HStack {
                    Text(goal.name)
                    Spacer()
                }.padding()
            }
            if goal.hasDeadline {
                HStack {
                    Text("Deadline: \(goal.deadline.dateOnlyToString())")
                    Spacer()
                }.padding()
            }
        }.background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: goal.color)!)
                .opacity(0.5)
        )
    }
    
}


fileprivate extension Date {
    
    func formatToShortDate () -> String {
        let dateFormatter = DateFormatter()

        
        dateFormatter.dateFormat = "M/d/YY, h:mm a"
        
        // Convert Date to String
        return dateFormatter.string(from: self)
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



// SELECT ON SCHEDULE VIEW
// A lot like the daily planner view but all the buttons are just images except the ones that detect what time you click on.
fileprivate struct SelectOnScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    
    public var editEventView: EditEventView? = nil
    @State public var filteredDay: Date = Date()
    
   
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    Spacer()
                    
                }
                HStack {
                    HStack {
                        Text(filteredDay.dayOfWeek())
                        
                        DatePicker("Selected Day", selection: $filteredDay, displayedComponents: .date)
                            .labelsHidden()
                        
                        
                        Spacer()
                        
                        Button("Today") {
                            filteredDay = Date()
                            
                        }
                    }
                }
            }.padding()
            AllDayList(filter: filteredDay)
            scheduleViewCanvas(filter: filteredDay, editEventView: editEventView)
        }.gesture(DragGesture(minimumDistance: 15, coordinateSpace: .global)
            .onEnded { value in
                
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height
                
                if abs(horizontalAmount) > abs(verticalAmount) {
                    if (horizontalAmount < 0) {
                        //Left swipe
                        filteredDay = Calendar.current.date(byAdding: .day, value: 1, to: filteredDay) ?? filteredDay
                    } else {
                        //right swipe
                        filteredDay = Calendar.current.date(byAdding: .day, value: -1, to: filteredDay) ?? filteredDay
                    }
                }
                
            })
    }
}

fileprivate struct scheduleViewCanvas: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @FetchRequest var fetchedEvents: FetchedResults<N40Event>
    
    @State private var clickedOnTime = Date()
    
    public var editEventView: EditEventView? = nil
    
    @State private var hourHeight = UserDefaults.standard.double(forKey: "hourHeight")
    public static let minimumEventHeight = 25.0
    
    
    public var filteredDay: Date
    
    var body: some View {
        
        //The main timeline
        ScrollViewReader { value in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    
                    //Hour Lines
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<24) { hour in
                            HStack {
                                Text("\(((hour+11) % 12)+1)")
                                    .font(.caption)
                                    .frame(width: 20, alignment: .trailing)
                                Color.gray
                                    .frame(height: 1)
                            }
                            .frame(height: hourHeight)
                            .id(hour)
                        }
                    }.onChange(of: filteredDay) {_ in
                        value.scrollTo(Calendar.current.component(.hour, from: filteredDay))
                    }
                    
                    //Invisible buttons to add an event
                    VStack(alignment: .leading, spacing: 0) {
                        Rectangle()
                            .fill(.clear)
                            .frame(height: hourHeight/2) //offset the buttons by 2 slots
                        
                        
                        ForEach(0..<(24*Int(hourHeight/DailyPlanner.minimumEventHeight)), id: \.self) {idx in
                            Rectangle()
                                .fill(Color.black.opacity(0.0001))
                                .onTapGesture {
                                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                                    impactMed.impactOccurred()
                                    
                                    clickedOnTime = getSelectedTime(idx: idx)
                                    editEventView?.setDate(date: clickedOnTime)
                                    dismiss()
                                    
                                }
                                .frame(height: DailyPlanner.minimumEventHeight)
                        }
                        
                    }
                    
                    let radarEvents = fetchedEvents.reversed().filter({ $0.eventType == N40Event.INFORMATION_TYPE })
                    
                    EventRenderCalculator.precalculateEventColumns(radarEvents)
                    
                    ForEach(radarEvents) { event in
                        eventCell(event, allEvents: radarEvents)
                    }
                    
                    
                    let otherEvents = fetchedEvents.reversed().filter({ $0.eventType != N40Event.INFORMATION_TYPE})
                    
                    EventRenderCalculator.precalculateEventColumns(otherEvents)
                    
                    ForEach(otherEvents) { event in
                        eventCell(event, allEvents: otherEvents)
                    }
                    
                    if (filteredDay.startOfDay == Date().startOfDay) {
                        Color.red
                            .frame(height: 1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .offset(x: 0, y: getNowOffset() + hourHeight/2)
                        
                        
                    }
                    
                    
                    
                }
                
            }
            .onAppear {
                hourHeight = UserDefaults.standard.double(forKey: "hourHeight")
                value.scrollTo(Calendar.current.component(.hour, from: filteredDay))
            }
        }
        
        
        
    }
    
    
    init (filter: Date, editEventView: EditEventView?) {
        let todayPredicateA = NSPredicate(format: "startDate >= %@", filter.startOfDay as NSDate)
        let todayPredicateB = NSPredicate(format: "startDate < %@", filter.endOfDay as NSDate)
        let scheduledPredicate = NSPredicate(format: "isScheduled == YES")
        
        let notAllDayPredicate = NSPredicate(format: "allDay == NO")
        
        _fetchedEvents = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [todayPredicateA, todayPredicateB, scheduledPredicate, notAllDayPredicate]))
        
        self.filteredDay = filter
        self.editEventView = editEventView
    }
    
    
    
    func getSelectedTime (idx: Int) -> Date {
        
        var dateComponents = DateComponents()
        dateComponents.year = Calendar.current.component(.year, from: filteredDay)
        dateComponents.month = Calendar.current.component(.month, from: filteredDay)
        dateComponents.day = Calendar.current.component(.day, from: filteredDay)
        dateComponents.hour = Int(Double(idx)*DailyPlanner.minimumEventHeight/hourHeight)
        dateComponents.minute = (idx % Int(hourHeight/DailyPlanner.minimumEventHeight))*Int(60*DailyPlanner.minimumEventHeight/hourHeight)

        // Create date from components
        let userCalendar = Calendar(identifier: .gregorian) // since the components above (like year 1980) are for Gregorian
        let someDateTime: Date = userCalendar.date(from: dateComponents)!
        
        return someDateTime
    }
    
   
    
    func eventCell(_ event: N40Event, allEvents: [N40Event]) -> some View {
        //all events is used for wrapping around other events.
        
        var height = Double(event.duration) / 60 * hourHeight
        if (height < DailyPlanner.minimumEventHeight) {
            height = DailyPlanner.minimumEventHeight
        }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)
        let offset = Double(hour) * (hourHeight) + Double(minute)/60  * hourHeight
        
     

        //get color for event cell
        var colorHex = "#FF7051" //default redish color
        
        if UserDefaults.standard.bool(forKey: "showEventsInGoalColor") {
            if event.getAttachedGoals.count > 0 {
                colorHex = event.getAttachedGoals.first!.color
            } else {
                if UserDefaults.standard.bool(forKey: "showNoGoalEventsGray") {
                    colorHex = "#b9baa2" // a grayish color if it's not assigned to a goal
                } else {
                    colorHex = event.color
                }
            }
        } else {
            colorHex = event.color
        }
        
        let numberOfColumns = event.getHighestEventIdx + 1
        
        return GeometryReader {geometry in
            ZStack {
                if event.eventType == N40Event.INFORMATION_TYPE {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray)
                        .opacity(0.0001)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke((Color(hex: colorHex) ?? DEFAULT_EVENT_COLOR), lineWidth: 2)
                                .opacity(0.5)
                        )
                } else if event.eventType == N40Event.BACKUP_TYPE {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray)
                        .opacity(0.25)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke((Color(hex: colorHex) ?? DEFAULT_EVENT_COLOR), lineWidth: 2)
                                .opacity(0.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill((Color(hex: colorHex) ?? DEFAULT_EVENT_COLOR))
                        .opacity(0.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                //If this is an information event, don't show the title if theres another non-information event at the same time.
                if !(event.eventType == N40Event.INFORMATION_TYPE && fetchedEvents.filter{ $0.startDate == event.startDate && $0.eventType != N40Event.INFORMATION_TYPE}.count > 0) {
                    
                    HStack {
                        if (event.eventType == N40Event.TODO_TYPE) {
                            Image(systemName: (event.status == 0) ? "square" : "checkmark.square")
                                    .disabled((event.status != 0))
                            
                        }
                        if event.contactMethod != 0 {
                            Image(systemName: N40Event.CONTACT_OPTIONS[Int(event.contactMethod)][1])
                        }
                        //Text("\((event.renderIdx ?? -1 )+1)/\(event.renderTotal ?? 0)") //just for testing render
                        Text(event.startDate.formatted(.dateTime.hour().minute()))
                        Text(event.name).bold()
                            .lineLimit(0)
                        Spacer()
                    }
                    .offset(y: (DailyPlanner.minimumEventHeight-height)/2)
                    .padding(.horizontal, 8)
                    
                }
                
                HStack {
                    Spacer()
                    if (event.eventType == N40Event.REPORTABLE_TYPE) {
                        if event.startDate > Date() {
                            Image(systemName: "circle.dotted")
                                .resizable()
                                .frame(width: 20, height:20)
                        } else if event.status == N40Event.UNREPORTED {
                            Image(systemName: "questionmark.circle.fill")
                                .resizable()
                                .foregroundColor(Color.orange)
                                .frame(width: 20, height:20)
                        } else if event.status == N40Event.SKIPPED {
                            Image(systemName: "slash.circle.fill")
                                .resizable()
                                .foregroundColor(Color.red)
                                .frame(width: 20, height:20)
                        } else if event.status == N40Event.ATTEMPTED {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .foregroundColor(Color.red)
                                .frame(width: 20, height:20)
                        } else if event.status == N40Event.HAPPENED {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .foregroundColor(Color.green)
                                .frame(width: 20, height:20)
                        }
                    } else if (event.eventType == N40Event.INFORMATION_TYPE) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .resizable()
                            .frame(width: 20, height:20)
                    }
                    
                    if (event.recurringTag != "") {
                        ZStack {
                            Image(systemName: "repeat")
                            if (event.isRecurringEventLast(viewContext: viewContext)) {
                                Image(systemName: "line.diagonal")
                                    .scaleEffect(x: -1.2, y: 1.2)
                            }
                        }
                    }
                    
                    
                }.padding(.horizontal, 8)
                
                
            }
            .buttonStyle(.plain)
            .font(.caption)
            .padding(.horizontal, 4)
            .frame(height: height, alignment: .top)
            .frame(width: (geometry.size.width-40)/CGFloat(numberOfColumns), alignment: .leading)
            .padding(.trailing, 30)
            .offset(x: 30 + (CGFloat(event.renderIdx ?? 0)*(geometry.size.width-40)/CGFloat(numberOfColumns)), y: offset + hourHeight/2)
            
        }
    }
    
    func getNowOffset() -> CGFloat {
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let offset = Double(hour)*hourHeight + Double(minute)/60*hourHeight
        
        return offset
        
        
    }
    
    
}



