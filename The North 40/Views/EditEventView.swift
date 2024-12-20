//
//  EditEventView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/17/23.
//

import SwiftUI
import CoreData
import EventKit

struct EditEventView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    private static let NEVER_ENDING_REPEAT_LENGTH = 3 // years
    
    @State public var editEvent: N40Event?
    
    
    private let repeatOptions = ["No Repeat", "Every Day", "On Days:", "Every Week", "Every Two Weeks", "Monthly (Day of Month)", "Monthly (Week of Month)", "Yearly", "On Complete"]
    @State private var repeatMonday = true
    @State private var repeatTuesday = true
    @State private var repeatWednesday = true
    @State private var repeatThursday = true
    @State private var repeatFriday = true
    @State private var repeatSaturday = false
    @State private var repeatSunday = false
    
    @State private var repeatOnCompleteInDays = 0
    
    @State private var neverEndingRepeat = true
    
    @State private var eventTitle = ""
    @State private var location = ""
    
    @State private var information = ""
    
    @State public var isScheduled: Bool = true
    @State public var chosenStartDate: Date = Date()
    @State private var chosenEndDate = Date()
    @State private var duration = UserDefaults.standard.integer(forKey: "defaultEventDuration")
    @State private var allDay: Bool = false
    
    @State public var contactMethod = N40Event.CONTACT_OPTIONS[UserDefaults.standard.integer(forKey: "defaultContactMethod")]
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
    
    @State private var repeatUntil: Date = Date()
    
    @State private var showOnCalendar: Bool = UserDefaults.standard.bool(forKey: "shareEverythingToCalendar")
    
    @State private var eventHasNotification: Bool = false
    @State private var eventNotificationTime = 0
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
    
    @State private var isShowingSaveAsCopyConfirm: Bool = false
    
    //for the delete button
    @State private var isPresentingConfirm: Bool = false
    @State private var isPresentingRecurringDeleteConfirm: Bool = false
    
    // used to pass in a person or goal (for example if event created from person or goal)
    public var attachingGoal: N40Goal? = nil
    public var attachingPerson: N40Person? = nil
    
    @State private var showingSelectOnCalendarSheet = false
    
    @State var autoFocus = true
    @FocusState private var focusedField: FocusField?
    enum FocusField: Hashable {
        case field
      }
    
    
    @State var showingColorPickerSheet = false

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
                            .if(editEvent == nil && autoFocus) {view in
                                view.focused($focusedField, equals: .field)
                            }
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
                        HStack {
                            Text("Share Event to Calendar")
                            Spacer()
                            Toggle("shareToCalendar", isOn: $showOnCalendar).labelsHidden()
                        }.padding()
                    }
                    
                    VStack {
                        HStack {
                            Text("Notify me")
                            Spacer()
                            Toggle("hasNotification", isOn: $eventHasNotification).labelsHidden()
                        }
                        if eventHasNotification {
                            HStack {
                                Text("\(eventNotificationTime) minutes before. ")
                                Spacer()
                                Stepper("", value: $eventNotificationTime, in: 0...1440, step: 5)
                            }
                        }
                    }.padding()
                    
                    
                    VStack {
                        HStack{
                            Text("Attached People:")
                                .font(.title3)
                            Spacer()
                        }
                        
                        ForEach(attachedPeople) { person in
                            
                            HStack {
                                NavigationLink(destination: PersonDetailView(selectedPerson: person)) {
                                    Text(("\(person.title) \(person.firstName) \(person.lastName) \(person.company)").trimmingCharacters(in: .whitespacesAndNewlines))
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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.51) {  /// Anything over 0.5 seems to work
                    self.focusedField = .field
                }
                
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
                        
                        if (!editEvent!.isRecurringEventLast(viewContext: viewContext) && repeatOptionSelected != "On Complete") {
                            
                            Button {
                                isPresentingRecurringDeleteConfirm.toggle()
                            } label: {
                                Image(systemName: "trash")
                            }.confirmationDialog("Delete this event?",
                                                 isPresented: $isPresentingRecurringDeleteConfirm) {
                                Button("Just this event", role: .destructive) {
                                    
                                    deleteThisEvent()
                                    
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
                                    deleteThisEvent()
                                    
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
                        
                        // turn off all day if this is changed
                        // allDay = false // This didn't work because it changed the all day to off every time you just open the edit screen
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
                        
                        // turn off all day if this is changed
                        // allDay = false // This didn't work because it changed the all day to off every time you just open the edit screen
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
                            guard let address = URL(string: "http://maps.apple.com/?q=\(location.replacingOccurrences(of: " ", with: "+"))") else { return }
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
                    
                    Button {
                        showingColorPickerSheet.toggle()
                    } label: {
                        Rectangle().frame(width:30, height: 20)
                            .foregroundColor(selectedColor)
                    }.sheet(isPresented: $showingColorPickerSheet) {
                        ColorPickerView(selectedColor: $selectedColor)
                    }
                    
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
                        
                        //old system for choosing when to end the repeat
                        if (!isAlreadyRepeating && repeatOptionSelected != "No Repeat" && repeatOptionSelected != "On Complete" && !UserDefaults.standard.bool(forKey: "repeatByEndDate")) {
                            VStack {
                                if !neverEndingRepeat {
                                    HStack {

                                        //["No Repeat", "Every Day", "On Days:", "Every Week", "Every Two Weeks", "Monthly (Day of Month)", "Monthly (Week of Month)", "Yearly", "On Complete"]
                                        let occuranceText = repeatOptionSelected == "Every Day" ? "Months" : repeatOptionSelected == "On Days:" ? "Weeks" : repeatOptionSelected == "Every Week" ? "Weeks" : repeatOptionSelected == "Monthly (Day of Month)" || repeatOptionSelected == "Monthly (Week of Month)" ? "Months" : repeatOptionSelected == "Yearly" ? "Years" : "Occurances"

                                        Text("For")
                                        TextField("-", value: $numberOfRepeats, formatter: formatter)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                                                if let textField = obj.object as? UITextField {
                                                    textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
                                                }
                                            }
                                            .frame(width: 75)
                                            .padding(.horizontal)
                                        Text(occuranceText)
                                        Spacer()

                                        //                                Stepper("", onIncrement: {
                                        //                                    numberOfRepeats += 1
                                        //                                }, onDecrement: {
                                        //                                    if numberOfRepeats >= 1 {
                                        //                                        numberOfRepeats -= 1
                                        //                                    }
                                        //                                })
                                        //                                    .disabled(!isScheduled)

                                    }
                                    HStack {
                                        Button("Repeat Forever") {
                                            neverEndingRepeat = true
                                        }
                                    }
                                } else {
                                    Button("Repeat a finite amount") {
                                        neverEndingRepeat = false
                                    }
                                }
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
                        } else if !isAlreadyRepeating && repeatOptionSelected == "On Complete" {
                            HStack {
                                if eventType == N40Event.EVENT_TYPE_OPTIONS[N40Event.TODO_TYPE] || eventType == N40Event.EVENT_TYPE_OPTIONS[N40Event.REPORTABLE_TYPE] {
                                    Text("Repeat In")
                                    TextField("-", value: $repeatOnCompleteInDays, formatter: formatter)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                                            if let textField = obj.object as? UITextField {
                                                textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
                                            }
                                        }
                                        .frame(width: 75)
                                        .padding(.horizontal)
                                    Text("Days")
                                    Spacer()
                                    
//                                    Stepper("", value: $repeatOnCompleteInDays, in: 0...31)
//                                        .disabled(!isScheduled)
                                } else {
                                    Text("Event must be To-Do or Reportable type. ")
                                }
                            }
                        }
                        if !isAlreadyRepeating && repeatOptionSelected != repeatOptions[0] && repeatOptionSelected != "On Complete" && UserDefaults.standard.bool(forKey: "repeatByEndDate") {
                            HStack {
                                if !neverEndingRepeat {
                                    DatePicker(selection: $repeatUntil, in:Date.now..., displayedComponents: .date) {
                                        Text("End on:")
                                    }
                                    Spacer()
                                } else {
                                    Text("Repeating Forever")
                                    Spacer()
                                }
                                Button(neverEndingRepeat ? "Finite Amount" : "Repeat Forever") {
                                    neverEndingRepeat.toggle()
                                }
                            }
                        }
                    }.padding()
                }.border(.gray)
            }
        }
    }
    
    
    
//    public func attachPerson(addPerson: N40Person) {
//        //attaches a person to the attachedPeople array. (Used by the SelectPeopleView
//        if (!attachedPeople.contains(addPerson)) {
//            attachedPeople.append(addPerson)
//            if addPerson.sharedToCalendar {
//                showOnCalendar = true
//            }
//        }
//    }
    
    public func removePerson(removedPerson: N40Person) {
        //removes a person from the attachedPeople array. (Used by the button on each list item)
        let idx = attachedPeople.firstIndex(of: removedPerson) ?? -1
        if idx != -1 {
            attachedPeople.remove(at: idx)
        }
    }
    
    public func setSelectedPeople(selectedPeople: [N40Person]) {
        //just resets the list to a new value
        attachedPeople = selectedPeople
        for attachedPerson in attachedPeople {
            if attachedPerson.sharedToCalendar {
                showOnCalendar = true
                break
            }
        }
    }
    
    public func attachGoal (addGoal: N40Goal)  {
        //attaches a goal to the attachedGoal array.
        if (!attachedGoals.contains(addGoal)) {
            attachedGoals.append(addGoal)
            if addGoal.sharedToCalendar {
                showOnCalendar = true
            }
        }
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
            
            eventHasNotification = editEvent?.notificationID != ""
            eventNotificationTime = Int(editEvent?.notificationTime ?? 0)
            
            repeatOnCompleteInDays = Int(editEvent!.repeatOnCompleteInDays)
            if repeatOnCompleteInDays > 0  {
                repeatOptionSelected = "On Complete"
                isAlreadyRepeating = false
                redoingEventRepeat = false //doesn't apply to this type of repeat.
            } else if editEvent!.recurringTag != "" {
                isAlreadyRepeating = true
            }
            
            showOnCalendar = editEvent?.sharedWithCalendar != ""
            
            attachedPeople = []
            attachedGoals = []
            
            editEvent?.attachedPeople?.forEach {person in
                attachedPeople.append(person as! N40Person)
            }
            editEvent?.attachedGoals?.forEach {goal in
                attachedGoals.append(goal as! N40Goal)
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
        if editEvent != nil {
            selectedColor = Color(hex: editEvent?.color ?? UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 0.5)
        } else {
            if UserDefaults.standard.bool(forKey: "randomEventColor") {
                selectedColor = Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 1.0)
            } else if UserDefaults.standard.bool(forKey: "randomFromColorScheme") {
                let fetchRequest: NSFetchRequest<N40ColorScheme> = N40ColorScheme.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priorityIndex", ascending: true)]
                
                do {
                    // Peform Fetch Request
                    let fetchedColorSchemes = try viewContext.fetch(fetchRequest)
                    
                    if fetchedColorSchemes.count > 0 {
                        let colorPalette = unpackColorsFromString(colorString: fetchedColorSchemes.first!.colorsString)
                        if colorPalette.count > 0 {
                            selectedColor = colorPalette.randomElement() ?? Color(hex: editEvent?.color ?? UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))
                            // (the default selected color is the optional argument)
                        } else {
                            //just use the default selected color
                            selectedColor = Color(hex: editEvent?.color ?? UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))
                        }
                    } else {
                        //just use the default selected color
                        selectedColor = Color(hex: editEvent?.color ?? UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))
                    }
                    
                    
                } catch let error as NSError {
                    print("Couldn't fetch other recurring events. \(error), \(error.userInfo)")
                }
            } else {
                selectedColor = Color(hex: editEvent?.color ?? UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))
            }
        }
        
        repeatUntil = chosenStartDate
        
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
                        defaultName = ("\(attachedPeople[0].title) \(attachedPeople[0].firstName) \(attachedPeople[0].lastName) \(attachedPeople[0].company)").trimmingCharacters(in: .whitespacesAndNewlines)
                        for eachPerson in attachedPeople {
                            if eachPerson != attachedPeople[0] {
                                defaultName += ", " + ("\(eachPerson.title) \(eachPerson.firstName) \(eachPerson.lastName) \(eachPerson.company)").trimmingCharacters(in: .whitespacesAndNewlines)
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
            
            let oldEventDate = newEvent.startDate
            
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
            
            // save the notification
            if eventHasNotification {
                NotificationHandler.instance.updateNotification(event: newEvent, pretime: Int16(eventNotificationTime), viewContext: viewContext)
            } else if !eventHasNotification && newEvent.notificationID != "" {
                NotificationHandler.instance.deletePendingNotification(event: newEvent)
            }
            
            // Share it calendar if it needs to be shared
            if newEvent.sharedWithCalendar != "" && !showOnCalendar {
                // This means that the switch was turned off and we need to delete the event, and remove the UUID tag
                let eventTag = newEvent.sharedWithCalendar
                let eventStore = EKEventStore()
                eventStore.requestAccess(to: .event) { (granted, error) in
                    if granted {
                        print("Access granted")
                        
                        // It has already been shared, so fetch and delete it
                        let calendars = getN40RelatedCalendars(viewContext: viewContext, eventStore: eventStore)
                        
                        
                        let predicate = eventStore.predicateForEvents(withStart: Calendar.current.date(byAdding: .day, value: -1, to: oldEventDate) ?? oldEventDate, end: Calendar.current.date(byAdding: .day, value: 2, to: oldEventDate) ?? oldEventDate, calendars: calendars)
                            
                        let fetchedEKEvents = eventStore.events(matching: predicate).filter { event in
                            return event.notes?.contains(eventTag) == true
                        }
                        
                        // delete them
                        for event in fetchedEKEvents {
                            do {
                                try eventStore.remove(event, span: .thisEvent, commit: true)
                                print("Event deleted successfully.")
                            } catch {
                                print("Failed to delete event: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        print("Access denied")
                        if let error = error {
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                }
                
                // remove the tag
                newEvent.sharedWithCalendar = ""
                
            } else if showOnCalendar {
                
                if newEvent.sharedWithCalendar == "" {
                    // First time being shared to give it a tag.
                    //   It's important that this line gets done earlier and not in the query thread because
                    //   creating the duplicates needs this part and it might not be done in time for duplicates
                    //   if its put inside the query thread.
                    newEvent.sharedWithCalendar = UUID().uuidString
                }
                    
                let eventStore = EKEventStore()
                eventStore.requestAccess(to: .event) { (granted, error) in
                    if granted {
                        print("Access granted")
                        // Proceed to fetch and filter events
                        if newEvent.sharedWithCalendar != "" {
                            updateEventOnEKStore(newEvent, eventStore: eventStore, viewContext: viewContext)
                        } else {
                            // It hasn't been shared so we need to make a calendar event
                            makeNewCalendarEventToEKStore(newEvent, eventStore: eventStore, viewContext: viewContext)
                        }
                    } else {
                        print("Access denied")
                        if let error = error {
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            
            
            if saveAsCopy {
                //don't repeat the duplicate (unless a new repeat options was selected)
                newEvent.recurringTag = ""
            } else {
                if redoingEventRepeat {
                    deleteAllRecurringEvents(includeThisEvent: false)
                }
            }
            
            
            if repeatOptionSelected != repeatOptions[0] && repeatOptionSelected != "On Complete" {
                //Making recurring events
                makeRecurringEvents(newEvent: newEvent)
                
                
                // Now if this event was shared we need to share the duplicates also
                // This loop only gets ran to make the recurring events, so all the EK stuff is just to make events
                if newEvent.sharedWithCalendar != "" {
                    // first fetch all the duplicates we just made
                    
                    EditEventView.makeRecurringEventsOnEK(newEvent: newEvent, vc: viewContext)
                }
                
            } else if repeatOptionSelected == "On Complete" {
                newEvent.repeatOnCompleteInDays = Int16(repeatOnCompleteInDays)
                if newEvent.recurringTag == "" {
                    let recurringTag = UUID().uuidString
                    newEvent.recurringTag = recurringTag
                }
                
            }
            // remove repeat after days if it's been turned off
            if repeatOptionSelected == repeatOptions[0] {
                newEvent.repeatOnCompleteInDays = 0
            }
            
            //duplicate the event if repeatOnCompleteInDays is greater than 0
            if newEvent.repeatOnCompleteInDays > 0 && newEvent.status != N40Event.UNREPORTED && (eventType == N40Event.EVENT_TYPE_OPTIONS[N40Event.TODO_TYPE] || eventType  == N40Event.EVENT_TYPE_OPTIONS[N40Event.REPORTABLE_TYPE]) {
                for futureOccurance in newEvent.getFutureRecurringEvents(viewContext: viewContext) {
                    viewContext.delete(futureOccurance)
                }
                duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: Int(newEvent.repeatOnCompleteInDays), to: newEvent.startDate) ?? newEvent.startDate, vc: viewContext)
                
                // Make that duplicate on calendar if needed
                if newEvent.sharedWithCalendar != "" {
                    EditEventView.makeRecurringEventsOnEK(newEvent: newEvent, vc: viewContext)
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
    
    public static func makeRecurringEventsOnEK(newEvent: N40Event, vc: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
        
        let isScheduledPredicate = NSPredicate(format: "isScheduled = %d", true)
        let isFuturePredicate = NSPredicate(format: "startDate > %@", (newEvent.startDate as CVarArg)) //will NOT include this event
        let sameTagPredicate = NSPredicate(format: "recurringTag == %@", newEvent.recurringTag)
        
        let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [isScheduledPredicate, isFuturePredicate, sameTagPredicate])
        fetchRequest.predicate = compoundPredicate
        
        do {
            // Peform Fetch Request
            let fetchedEvents = try vc.fetch(fetchRequest)
            
            // then get into the store
            let eventStore = EKEventStore()
            eventStore.requestAccess(to: .event) { (granted, error) in
                if granted {
                    
                    // now loop through them and make the stuff
                    fetchedEvents.forEach { recurringEvent in
                        // make sure it has a tag
                        recurringEvent.sharedWithCalendar = UUID().uuidString
                        
                        makeNewCalendarEventToEKStore(recurringEvent, eventStore: eventStore, viewContext: vc)
                    }
                    
                    // save on the context
                    do {
                        try vc.save()
                    }
                    catch {
                        // Handle Error
                        print("Error info: \(error)")
                        
                    }
                    
                } else {
                    print("Access denied")
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    }
                    
                    // It didn't work so just don't do anything i guess
                }
            }
        } catch let error as NSError {
            print("Couldn't fetch other recurring events. \(error), \(error.userInfo)")
        }
    }
    
    private func makeRecurringEvents(newEvent: N40Event) {
        
        
        
        newEvent.repeatOnCompleteInDays = 0
        if newEvent.recurringTag == "" {
            let recurringTag = UUID().uuidString
            newEvent.recurringTag = recurringTag
        }
        if repeatOptionSelected == "Every Day" {
            //Repeat Daily
            if neverEndingRepeat {numberOfRepeats = 12*EditEventView.NEVER_ENDING_REPEAT_LENGTH}
            if !UserDefaults.standard.bool(forKey: "repeatByEndDate") || neverEndingRepeat {
                if numberOfRepeats > 1 {
                    for i in 1...numberOfRepeats*30 {
                        duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i, to: newEvent.startDate) ?? newEvent.startDate, vc: viewContext)
                    }
                }
            } else {
                var nextRepeatDay = Calendar.current.date(byAdding: .day, value: 1, to: newEvent.startDate) ?? newEvent.startDate
                while nextRepeatDay.startOfDay <= repeatUntil.startOfDay {
                    duplicateN40Event(originalEvent: newEvent, newStartDate: nextRepeatDay, vc: viewContext)
                    nextRepeatDay = Calendar.current.date(byAdding: .day, value: 1, to: nextRepeatDay) ?? nextRepeatDay
                }
            }
        } else if repeatOptionSelected == "Every Week" {
            //Repeat Weekly
            if neverEndingRepeat {numberOfRepeats = 52*EditEventView.NEVER_ENDING_REPEAT_LENGTH}
            if !UserDefaults.standard.bool(forKey: "repeatByEndDate") || neverEndingRepeat {
                if numberOfRepeats > 1 {
                    for i in 1...numberOfRepeats-1 {
                        duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i*7, to: newEvent.startDate) ?? newEvent.startDate, vc: viewContext)
                    }
                }
            } else {
                var nextRepeatDay = Calendar.current.date(byAdding: .day, value: 7, to: newEvent.startDate) ?? newEvent.startDate
                while nextRepeatDay.startOfDay <= repeatUntil.startOfDay {
                    duplicateN40Event(originalEvent: newEvent, newStartDate: nextRepeatDay, vc: viewContext)
                    nextRepeatDay = Calendar.current.date(byAdding: .day, value: 7, to: nextRepeatDay) ?? nextRepeatDay
                }
            }
        } else if repeatOptionSelected == "Every Two Weeks" {
            if neverEndingRepeat {numberOfRepeats = 26*EditEventView.NEVER_ENDING_REPEAT_LENGTH}
            if !UserDefaults.standard.bool(forKey: "repeatByEndDate") || neverEndingRepeat {
                if numberOfRepeats > 1 {
                    for i in 1...numberOfRepeats-1 {
                        duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .day, value: i*14, to: newEvent.startDate) ?? newEvent.startDate, vc: viewContext)
                    }
                }
            } else {
                var nextRepeatDay = Calendar.current.date(byAdding: .day, value: 14, to: newEvent.startDate) ?? newEvent.startDate
                while nextRepeatDay.startOfDay <= repeatUntil.startOfDay {
                    duplicateN40Event(originalEvent: newEvent, newStartDate: nextRepeatDay, vc: viewContext)
                    nextRepeatDay = Calendar.current.date(byAdding: .day, value: 14, to: nextRepeatDay) ?? nextRepeatDay
                }
            }
        } else if repeatOptionSelected == "Monthly (Day of Month)" {
            //Repeat Monthly
            if neverEndingRepeat {numberOfRepeats = 12*EditEventView.NEVER_ENDING_REPEAT_LENGTH}
            if !UserDefaults.standard.bool(forKey: "repeatByEndDate") || neverEndingRepeat {
                if numberOfRepeats > 1 {
                    for i in 1...numberOfRepeats-1 {
                        duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .month, value: i, to: newEvent.startDate) ?? newEvent.startDate, vc: viewContext)
                    }
                }
            } else {
                var nextRepeatDay = Calendar.current.date(byAdding: .month, value: 1, to: newEvent.startDate) ?? newEvent.startDate
                while nextRepeatDay.startOfDay <= repeatUntil.startOfDay {
                    duplicateN40Event(originalEvent: newEvent, newStartDate: nextRepeatDay, vc: viewContext)
                    nextRepeatDay = Calendar.current.date(byAdding: .month, value: 1, to: nextRepeatDay) ?? nextRepeatDay
                }
            }
        } else if repeatOptionSelected == "Monthly (Week of Month)" {
            // Repeat monthly keeping the day of week
            if neverEndingRepeat {numberOfRepeats = 12*EditEventView.NEVER_ENDING_REPEAT_LENGTH}
            
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
            
            
            if !UserDefaults.standard.bool(forKey: "repeatByEndDate") || neverEndingRepeat {
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
                    
                    
                    
                    duplicateN40Event(originalEvent: newEvent, newStartDate: repeatDate, vc: viewContext)
                    lastCreatedDate = repeatDate
                    repeatsMade += 1
                }
            } else {
                while repeatDate.startOfDay <= repeatUntil.startOfDay {
                    if repeatDate != lastCreatedDate {
                        duplicateN40Event(originalEvent: newEvent, newStartDate: repeatDate, vc: viewContext)
                        lastCreatedDate = repeatDate
                    }
                    
                    //While the next date is in the same month as the last created date
                    while Calendar.current.component(.month, from: lastCreatedDate) >= Calendar.current.component(.month, from: repeatDate) {
                        //add a week to the next date until it crosses over to the next month
                        repeatDate = Calendar.current.date(byAdding: .day, value: 7, to: repeatDate) ?? repeatDate
                    }
                    //Now the repeat date should be in the next month,
                    // ex. if doing first sunday of the month, it should be the next first sunday
                    
                    //now make it the right week of the month
                    repeatDate = Calendar.current.date(byAdding: .day, value: (weekOfMonth-1)*7, to: repeatDate) ?? repeatDate
                    
                }
            }
             
        } else if repeatOptionSelected == "Yearly" {
            //Repeat Yearly
            if neverEndingRepeat {numberOfRepeats = 50} //repeat for 50 years
            if !UserDefaults.standard.bool(forKey: "repeatByEndDate") || neverEndingRepeat {
                if numberOfRepeats > 1 {
                    for i in 1...numberOfRepeats-1 {
                        duplicateN40Event(originalEvent: newEvent, newStartDate: Calendar.current.date(byAdding: .year, value: i, to: newEvent.startDate) ?? newEvent.startDate, vc: viewContext)
                    }
                }
            } else {
                var nextRepeatDay = Calendar.current.date(byAdding: .year, value: 1, to: newEvent.startDate) ?? newEvent.startDate
                while nextRepeatDay.startOfDay <= repeatUntil.startOfDay {
                    duplicateN40Event(originalEvent: newEvent, newStartDate: nextRepeatDay, vc: viewContext)
                    nextRepeatDay = Calendar.current.date(byAdding: .year, value: 1, to: nextRepeatDay) ?? nextRepeatDay
                }
            }
        } else if repeatOptionSelected == "On Days:" {
            //Repeat on days
            if neverEndingRepeat {numberOfRepeats = 52*EditEventView.NEVER_ENDING_REPEAT_LENGTH}
            if (!UserDefaults.standard.bool(forKey: "repeatByEndDate") || neverEndingRepeat) {
                repeatUntil = Calendar.current.date(byAdding: .day, value: 7*(numberOfRepeats) - 1, to: newEvent.startDate) ?? newEvent.startDate
            }
            
            var lastCreatedDay = Calendar.current.date(byAdding: .day, value: 1, to: newEvent.startDate) ?? newEvent.startDate
            while lastCreatedDay.startOfDay <= repeatUntil.startOfDay {
                if (lastCreatedDay.dayOfWeek() == "Monday" && repeatMonday) || (lastCreatedDay.dayOfWeek() == "Tuesday" && repeatTuesday) || (lastCreatedDay.dayOfWeek() == "Wednesday" && repeatWednesday) || (lastCreatedDay.dayOfWeek() == "Thursday" && repeatThursday) || (lastCreatedDay.dayOfWeek() == "Friday" && repeatFriday) || (lastCreatedDay.dayOfWeek() == "Saturday" && repeatSaturday) || (lastCreatedDay.dayOfWeek() == "Sunday" && repeatSunday) {
                    //the day matches a day that should be repeated
                    duplicateN40Event(originalEvent: newEvent, newStartDate: lastCreatedDay, vc: viewContext)
                }
                lastCreatedDay = Calendar.current.date(byAdding: .day, value: 1, to: lastCreatedDay) ?? lastCreatedDay
            }
        }
    }
    
    
    private func deleteEventInCoreDataAndCalendar(_ event: N40Event) {
        
        let oldEventDate = event.startDate
        let eventTag = event.sharedWithCalendar
        
        //check if there is a notification to cancel
        if event.notificationID != "" {
            NotificationHandler.instance.deletePendingNotification(event: event)
        }
        
        // first see if there is an event in calendar that needs to get deleted also
        if event.sharedWithCalendar != "" {
            // We also need to delete the calendar copy
            let eventStore = EKEventStore()
            eventStore.requestAccess(to: .event) { (granted, error) in
                if granted {
                    
                    // It has already been shared, so fetch and delete it
                    let calendars = getN40RelatedCalendars(viewContext: viewContext, eventStore: eventStore)
                    
                    let predicate = eventStore.predicateForEvents(withStart: Calendar.current.date(byAdding: .day, value: -1, to: oldEventDate) ?? oldEventDate, end: Calendar.current.date(byAdding: .day, value: 2, to: oldEventDate) ?? oldEventDate, calendars: calendars)
                    
                    let fetchedEKEvents = eventStore.events(matching: predicate).filter { event in
                        return event.notes?.contains(eventTag) == true
                    }
                    
                    // delete them
                    for event in fetchedEKEvents {
                        do {
                            try eventStore.remove(event, span: .thisEvent, commit: true)
                            print("Event deleted successfully.")
                        } catch {
                            print("Failed to delete event: \(error.localizedDescription)")
                        }
                    }
                        
                    
                    // after deleting we can delete the event
                    deleteEventInCoreData(event)

                    
                } else {
                    print("Access denied")
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    }
                    
                    // It didn't work so just delete it anyway
                    deleteEventInCoreData(event)
                }
            }
        } else {
            // It isn't shared so just delete it in coredata
            deleteEventInCoreData(event)
        }
        
        
        
    }
    
    private func deleteEventInCoreData(_ event: N40Event) {
        //now delete the event in coredata
        viewContext.delete(editEvent!)
        
        do {
            try viewContext.save()
        }
        catch {
            // Handle Error
            print("Error info: \(error)")
        }
    }
    
    private func deleteThisEvent() {
        if (editEvent != nil) {
            
            deleteEventInCoreDataAndCalendar(editEvent!)
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
                
                // first lets do a quick check to see if it needs to be done in an EKShare query
                var needsEKquery = false
                fetchedEvents.forEach { recurringEvent in
                    if recurringEvent.sharedWithCalendar != "" {
                        needsEKquery = true
                    }
                }
                
                if needsEKquery {
                    let eventStore = EKEventStore()
                    eventStore.requestAccess(to: .event) { (granted, error) in
                        if granted {
                            
                            // now we can loop through and if it's shared to calendar, delete it there too
                            
                            fetchedEvents.forEach { recurringEvent in
                                
                                // first see if there is an event in calendar that needs to get deleted also
                                if recurringEvent.sharedWithCalendar != "" {
                                    // We also need to delete the calendar copy
                                    
                                    let oldEventDate = recurringEvent.startDate
                                    let eventTag = recurringEvent.sharedWithCalendar
                                    
                                    
                                    // It has already been shared, so fetch and delete it
                                    let calendars = getN40RelatedCalendars(viewContext: viewContext, eventStore: eventStore)
                                    let predicate = eventStore.predicateForEvents(withStart: Calendar.current.date(byAdding: .day, value: -1, to: oldEventDate) ?? oldEventDate, end: Calendar.current.date(byAdding: .day, value: 2, to: oldEventDate) ?? oldEventDate, calendars: calendars)
                                        
                                    let fetchedEKEvents = eventStore.events(matching: predicate).filter { event in
                                        return event.notes?.contains(eventTag) == true
                                    }
                                    
                                    // delete them
                                    for event in fetchedEKEvents {
                                        do {
                                            try eventStore.remove(event, span: .thisEvent, commit: true)
                                            print("Event deleted successfully.")
                                        } catch {
                                            print("Failed to delete event: \(error.localizedDescription)")
                                        }
                                    }
                                        
                                    // now that it has been used to delete the calendar copy, we can delete it in coredata
                                    viewContext.delete(recurringEvent)

                                } else {
                                    // just delete the event in coredata
                                    viewContext.delete(recurringEvent)
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
                            
                            
                        } else {
                            print("Access denied")
                            if let error = error {
                                print("Error: \(error.localizedDescription)")
                            }
                            
                            // it didn't work so just do it normally
                            fetchedEvents.forEach { recurringEvent in
                                viewContext.delete(recurringEvent)
                            }
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
                } else {
                    // Nothing is shared to calendar so just do it normally
                    fetchedEvents.forEach { recurringEvent in
                        viewContext.delete(recurringEvent)
                    }
                    // save on the context
                    do {
                        try viewContext.save()
                    }
                    catch {
                        // Handle Error
                        print("Error info: \(error)")
                        
                    }
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
            

            // Now do stuff
            let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
            
            let isScheduledPredicate = NSPredicate(format: "isScheduled = %d", true)
            let isFuturePredicate = NSPredicate(format: "startDate >= %@", ((editEvent?.startDate ?? Date()) as CVarArg)) //will include this event
            let sameTagPredicate = NSPredicate(format: "recurringTag == %@", (editEvent!.recurringTag))
            
            let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [isScheduledPredicate, isFuturePredicate, sameTagPredicate])
            fetchRequest.predicate = compoundPredicate
            
            do {
                // Peform Fetch Request
                let fetchedEvents = try viewContext.fetch(fetchRequest)
                
                // if it's shared, we want the iteration done inside the EKEventStore quere so it doesn't make a new quere for each loop.
                if editEvent!.sharedWithCalendar != "" || showOnCalendar {
                    let eventStore = EKEventStore()
                    eventStore.requestAccess(to: .event) { (granted, error) in
                        if granted {
                            
                            // now we can iterate through
                            fetchedEvents.forEach { recurringEvent in
                                
                                let oldEventDate = recurringEvent.startDate
                                saveSpecificRecurringEventInCoreData(recurringEvent)
                                
                                
                            
                                if recurringEvent.sharedWithCalendar != "" && !showOnCalendar {
                                    // This means that the switch was turned off and we need to delete the event, and remove the UUID tag
                                    
                            
                                    // It has already been shared, so fetch and delete it
                                    let calendars = getN40RelatedCalendars(viewContext: viewContext, eventStore: eventStore)
                                    
                                    let predicate = eventStore.predicateForEvents(withStart: Calendar.current.date(byAdding: .day, value: -1, to: oldEventDate) ?? oldEventDate, end: Calendar.current.date(byAdding: .day, value: 2, to: oldEventDate) ?? oldEventDate, calendars: calendars)
                                    
                                    let fetchedEKEvents = eventStore.events(matching: predicate).filter { event in
                                        return event.notes?.contains(recurringEvent.sharedWithCalendar) == true
                                    }
                                    
                                    // delete them
                                    for event in fetchedEKEvents {
                                        do {
                                            try eventStore.remove(event, span: .thisEvent, commit: true)
                                            print("Event deleted successfully.")
                                        } catch {
                                            print("Failed to delete event: \(error.localizedDescription)")
                                        }
                                    }
                                    
                                    // remove the tag
                                    recurringEvent.sharedWithCalendar = ""
                                   
                                } else if showOnCalendar {
                                    // This means that the switch is on so it either needs a tag or it just needs to be updated
                            
                                    if recurringEvent.sharedWithCalendar != "" {
                                        updateEventOnEKStore(recurringEvent, eventStore: eventStore, viewContext: viewContext)
                                        
                                    } else {
                                        // It hasn't been shared so we need to make a calendar event
                                        recurringEvent.sharedWithCalendar = UUID().uuidString
                                        
                                        makeNewCalendarEventToEKStore(recurringEvent, eventStore: eventStore, viewContext: viewContext)
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
                            
                            
                        } else {
                            print("Access denied")
                            if let error = error {
                                print("Error: \(error.localizedDescription)")
                            }
                            
                            // The share didn't work so just do it normally
                            fetchedEvents.forEach { recurringEvent in
                                
                                saveSpecificRecurringEventInCoreData(recurringEvent)
                                
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
                        }
                    }
                } else {
                    // Don't do shared stuff, just go through without it
                    
                    fetchedEvents.forEach { recurringEvent in
                        
                        saveSpecificRecurringEventInCoreData(recurringEvent)
                        
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
                    
                    
                }
                
                
                
                
                // now make the duplicate events on the calendar
                
                
            } catch let error as NSError {
                print("Couldn't fetch other recurring events. \(error), \(error.userInfo)")
            }
        } else {
            print("Cannot save updates to the other recurring events because they have not been created yet. ")
        }
    }
    
    
    
    private func saveSpecificRecurringEventInCoreData(_ recurringEvent: N40Event) {
        
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
        let alreadyAttachedPeople = recurringEvent.getAttachedPeople
        let alreadyAttachedGoals = recurringEvent.getAttachedGoals
        
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
    
    
    
    public func setDate(date: Date) {
        chosenStartDate = date
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
        
        if UserDefaults.standard.bool(forKey: "showEventsInGoalColor") && event.getAttachedGoals.count > 0 {
            //draw with the goal color
            colorHex = event.getAttachedGoals.first!.color
        } else if UserDefaults.standard.bool(forKey: "showEventsWithPersonColor") && event.getFirstFavoriteColor() != nil {
            //draw with the person color
            colorHex = event.getFirstFavoriteColor()!
        } else if (UserDefaults.standard.bool(forKey: "showEventsInGoalColor") || UserDefaults.standard.bool(forKey: "showEventsWithPersonColor")) && UserDefaults.standard.bool(forKey: "showNoGoalEventsGray") {
            //draw with the gray color
            colorHex = "#b9baa2"
        } else {
            //draw with the original color
            colorHex = event.color
        }
        
        
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
                            if (event.isRecurringEventLast(viewContext: viewContext) && event.repeatOnCompleteInDays == 0) {
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
            .frame(width: (geometry.size.width-40)/CGFloat(event.numberOfColumns ?? 1), alignment: .leading)
            .padding(.trailing, 30)
            .offset(x: 30 + (CGFloat(event.renderIdx ?? 0)*(geometry.size.width-40)/CGFloat(event.numberOfColumns ?? 1)), y: offset + hourHeight/2)
            
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

