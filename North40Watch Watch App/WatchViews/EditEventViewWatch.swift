//
//  EditEventViewWatch.swift
//  North40Watch Watch App
//
//  Created by Addison Ballif on 9/3/24.
//

import SwiftUI
import CoreData

struct EditEventViewWatch: View {
    
    
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
            ScrollView {
                
                VStack{
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
                    
                    // make this not get adjusted by scroll wheel
                    if duration < 60 {
                        Text("Duration: \(duration) min").font(.system(size: 16))
                    } else {
                        Text("Duration: \(Int(duration/60)) h \(String(format: "%02d", duration%60)) min")
                            .font(.system(size: 16))
                    }
                    HStack{
                        Button {
                            if duration > 0 {
                                duration -= 5
                            }
                        } label: {
                            Image(systemName: "minus").frame(height: 15)
                        }.controlSize(.mini)
                        Spacer()
                        Button {
                            duration += 5
                        } label: {
                            Image(systemName: "plus").frame(height: 15)
                        }.controlSize(.mini)
                        
                    }
                    
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
                    
                    
                    Text(chosenStartDate.dateOnlyToString())
                    HStack{
                        Button {
                            chosenStartDate = Calendar.current.date(byAdding: .day, value: -1, to: chosenStartDate) ?? chosenStartDate
                        } label: {
                            Image(systemName: "minus").frame(height: 15)
                        }.controlSize(.mini)
                        Spacer()
                        Button {
                            chosenStartDate = Calendar.current.date(byAdding: .day, value: 1, to: chosenStartDate) ?? chosenStartDate
                        } label: {
                            Image(systemName: "plus").frame(height: 15)
                        }.controlSize(.mini)
                        
                    }
                    
                    
                    Text(chosenStartDate.timeOnlyToString())
                    HStack{
                        Button {
                            chosenStartDate = Calendar.current.date(byAdding: .minute, value: Int(-DailyPlannerWatch.minimumEventHeight*60.0/UserDefaults.standard.double(forKey: "hourHeight")), to: chosenStartDate) ?? chosenStartDate
                        } label: {
                            Image(systemName: "minus").frame(height: 15)
                        }.controlSize(.mini)
                        Spacer()
                        Button {
                            chosenStartDate = Calendar.current.date(byAdding: .minute, value: Int(DailyPlannerWatch.minimumEventHeight*60.0/UserDefaults.standard.double(forKey: "hourHeight")), to: chosenStartDate) ?? chosenStartDate
                        } label: {
                            Image(systemName: "plus").frame(height: 15)
                        }.controlSize(.mini)
                        
                    }
                    
                    
                    
                    
                    // Choosing date and time
                    Toggle("Scheduled: ", isOn: $isScheduled)
                    Toggle("All Day: ", isOn: $allDay)
                        .disabled(!isScheduled)
                    
                
//                    DatePicker(selection: $chosenStartDate, displayedComponents: .date) {}.frame(height: 100)
                    
                    
                    
                    Picker("Event Type: ", selection: $eventType) {
                        ForEach(N40Event.EVENT_TYPE_OPTIONS, id: \.self) {
                            Label($0[0], systemImage: $0[1])
                        }
                    }.frame(height: 60)
                    
                    
                    
                    
//                    Text("Event Medium: ")
                    
//                    Picker("Contact Method: ", selection: $contactMethod) {
//                        ForEach(N40Event.CONTACT_OPTIONS, id: \.self) {
//                            Label($0[0], systemImage: $0[1])
//                        }
//                    }
                    
                    // no location
                    
                    // no event type
                    
                    if (eventType == N40Event.EVENT_TYPE_OPTIONS[0]) && chosenStartDate < Date() {
                        //If it's a reportable event and it's in the past:
                        
                        VStack {
                            //This is the view where you can report on the event.
                            Text("Status: \(statusLabels[status])")
                            HStack {
                                
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
                                    }.buttonStyle(.borderless)
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
                                    }.buttonStyle(.borderless)
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
                                    }.buttonStyle(.borderless)
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
                                    }.buttonStyle(.borderless)
                                }
                                
                                
                                
                            }
                            
                            
                        }
                        
                    }
                    
                    
                    Text("Color: ")
                    
                    Button {
                        showingColorPickerSheet.toggle()
                    } label: {
                        Rectangle().frame(width:30, height: 20)
                            .foregroundColor(selectedColor)
                            .border(.white)
                    }.sheet(isPresented: $showingColorPickerSheet) {
                        ColorPickerViewWatch(selectedColor: $selectedColor)
                    }
//                    Rectangle().frame(width:30, height: 20)
//                        .foregroundColor(selectedColor)
                    
//                    VStack {
//                        VStack {
//                            HStack {
//                                Text("Repeat event: ")
//                                if (!isAlreadyRepeating) {
//                                    Picker("", selection: $repeatOptionSelected) {
//                                        ForEach(repeatOptions, id: \.self) { option in
//                                            Text(option)
//                                        }
//                                    }.disabled(!isScheduled)
//                                    
//                                    
//                                    Spacer()
//                                    
//                                    
//                                } else {
//                                    Text("This is a repeating event. ")
//                                    Button("Edit the repeat cycle") {
//                                        redoingEventRepeat = true
//                                        isAlreadyRepeating = false //this will trigger the options to load on the screen
//                                    }
//                                    Spacer()
//                                }
//                            }
//                            
//                            //old system for choosing when to end the repeat
//                            if (!isAlreadyRepeating && repeatOptionSelected != "No Repeat" && repeatOptionSelected != "On Complete" && !UserDefaults.standard.bool(forKey: "repeatByEndDate")) {
//                                VStack {
//                                    if !neverEndingRepeat {
//                                        HStack {
//                                            
//                                            //["No Repeat", "Every Day", "On Days:", "Every Week", "Every Two Weeks", "Monthly (Day of Month)", "Monthly (Week of Month)", "Yearly", "On Complete"]
//                                            let occuranceText = repeatOptionSelected == "Every Day" ? "Months" : repeatOptionSelected == "On Days:" ? "Weeks" : repeatOptionSelected == "Every Week" ? "Weeks" : repeatOptionSelected == "Monthly (Day of Month)" || repeatOptionSelected == "Monthly (Week of Month)" ? "Months" : repeatOptionSelected == "Yearly" ? "Years" : "Occurances"
//                                            
//                                            Text("For")
//                                            TextField("-", value: $numberOfRepeats, formatter: formatter)
//                                            //                                                    .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
//                                            //                                                        if let textField = obj.object as? UITextField {
//                                            //                                                            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
//                                            //                                                        }
//                                            //                                                    }
//                                                .frame(width: 75)
//                                                .padding(.horizontal)
//                                            Text(occuranceText)
//                                            Spacer()
//                                            
//                                            //                                Stepper("", onIncrement: {
//                                            //                                    numberOfRepeats += 1
//                                            //                                }, onDecrement: {
//                                            //                                    if numberOfRepeats >= 1 {
//                                            //                                        numberOfRepeats -= 1
//                                            //                                    }
//                                            //                                })
//                                            //                                    .disabled(!isScheduled)
//                                            
//                                        }
//                                        HStack {
//                                            Button("Repeat Forever") {
//                                                neverEndingRepeat = true
//                                            }
//                                        }
//                                    } else {
//                                        Button("Repeat a finite amount") {
//                                            neverEndingRepeat = false
//                                        }
//                                    }
//                                }
//                            }
//                            if (!isAlreadyRepeating && repeatOptionSelected == "On Days:") {
//                                VStack {
//                                    HStack {
//                                        Text("Monday")
//                                        Spacer()
//                                        Button {
//                                            repeatMonday.toggle()
//                                        } label: {
//                                            if repeatMonday {
//                                                Image(systemName: "checkmark.square.fill")
//                                            } else {
//                                                Image(systemName: "square")
//                                            }
//                                        }
//                                    }
//                                    HStack {
//                                        Text("Tuesday")
//                                        Spacer()
//                                        Button {
//                                            repeatTuesday.toggle()
//                                        } label: {
//                                            if repeatTuesday {
//                                                Image(systemName: "checkmark.square.fill")
//                                            } else {
//                                                Image(systemName: "square")
//                                            }
//                                        }
//                                    }
//                                    HStack {
//                                        Text("Wednesday")
//                                        Spacer()
//                                        Button {
//                                            repeatWednesday.toggle()
//                                        } label: {
//                                            if repeatWednesday {
//                                                Image(systemName: "checkmark.square.fill")
//                                            } else {
//                                                Image(systemName: "square")
//                                            }
//                                        }
//                                    }
//                                    HStack {
//                                        Text("Thursday")
//                                        Spacer()
//                                        Button {
//                                            repeatThursday.toggle()
//                                        } label: {
//                                            if repeatThursday {
//                                                Image(systemName: "checkmark.square.fill")
//                                            } else {
//                                                Image(systemName: "square")
//                                            }
//                                        }
//                                    }
//                                    HStack {
//                                        Text("Friday")
//                                        Spacer()
//                                        Button {
//                                            repeatFriday.toggle()
//                                        } label: {
//                                            if repeatFriday {
//                                                Image(systemName: "checkmark.square.fill")
//                                            } else {
//                                                Image(systemName: "square")
//                                            }
//                                        }
//                                    }
//                                    HStack {
//                                        Text("Saturday")
//                                        Spacer()
//                                        Button {
//                                            repeatSaturday.toggle()
//                                        } label: {
//                                            if repeatSaturday {
//                                                Image(systemName: "checkmark.square.fill")
//                                            } else {
//                                                Image(systemName: "square")
//                                            }
//                                        }
//                                    }
//                                    HStack {
//                                        Text("Sunday")
//                                        Spacer()
//                                        Button {
//                                            repeatSunday.toggle()
//                                        } label: {
//                                            if repeatSunday {
//                                                Image(systemName: "checkmark.square.fill")
//                                            } else {
//                                                Image(systemName: "square")
//                                            }
//                                        }
//                                    }
//                                }
//                            } else if !isAlreadyRepeating && repeatOptionSelected == "On Complete" {
//                                HStack {
//                                    if eventType == N40Event.EVENT_TYPE_OPTIONS[N40Event.TODO_TYPE] || eventType == N40Event.EVENT_TYPE_OPTIONS[N40Event.REPORTABLE_TYPE] {
//                                        Text("Repeat In")
//                                        TextField("-", value: $repeatOnCompleteInDays, formatter: formatter)
//                                        //                                                .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
//                                        //                                                    if let textField = obj.object as? UITextField {
//                                        //                                                        textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
//                                        //                                                    }
//                                        //                                                }
//                                            .frame(width: 75)
//                                            .padding(.horizontal)
//                                        Text("Days")
//                                        Spacer()
//                                        
//                                        //                                    Stepper("", value: $repeatOnCompleteInDays, in: 0...31)
//                                        //                                        .disabled(!isScheduled)
//                                    } else {
//                                        Text("Event must be To-Do or Reportable type. ")
//                                    }
//                                }
//                            }
//                            if !isAlreadyRepeating && repeatOptionSelected != repeatOptions[0] && repeatOptionSelected != "On Complete" && UserDefaults.standard.bool(forKey: "repeatByEndDate") {
//                                HStack {
//                                    if !neverEndingRepeat {
//                                        DatePicker(selection: $repeatUntil, in:Date.now..., displayedComponents: .date) {
//                                            Text("End on:")
//                                        }
//                                        Spacer()
//                                    } else {
//                                        Text("Repeating Forever")
//                                        Spacer()
//                                    }
//                                    Button(neverEndingRepeat ? "Finite Amount" : "Repeat Forever") {
//                                        neverEndingRepeat.toggle()
//                                    }
//                                }
//                            }
//                        }.padding()
//                    }.border(.gray)
                    
                    
                    
                    
                    
                }.padding()
                
                
                
            }
            
            
            
        }.padding()
            .onAppear {
                populateFields()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.51) {  /// Anything over 0.5 seems to work
                    self.focusedField = .field
                }
                
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if (editEvent != nil) {
                        if (!editEvent!.isRecurringEventLast(viewContext: viewContext) && repeatOptionSelected != "On Complete") {
                            HStack {
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
                                
                                Button {
                                    isShowingEditAllConfirm.toggle()
                                } label: {
                                    Image(systemName: "checkmark.circle")
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
                            }
                            
                        } else {
                            HStack {
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
                                
                                Button {
                                    saveEvent()
                                    dismiss()
                                } label: {
                                    Image(systemName: "checkmark.circle")
                                }
                            }
                            
                        }
                    } else {
                        Button {
                            saveEvent()
                            dismiss()
                        } label: {
                            Image(systemName: "checkmark.circle")
                        }
                    }
                }
            }
        
            
        
        
    }
    
    
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
            // Watch version doesn't use color schemes
            if UserDefaults.standard.bool(forKey: "randomEventColor") {
                selectedColor = Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 1.0)
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
            
            
            // No EK sharing stuff on watchOS
            
            
            
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
                
                
                // No EK sharing stuff on watchOS
                
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
                
                // no EK sharing stuff on watchOS
                
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
    
    
    
    private func makeRecurringEvents(newEvent: N40Event) {
        
        
        
        newEvent.repeatOnCompleteInDays = 0
        if newEvent.recurringTag == "" {
            let recurringTag = UUID().uuidString
            newEvent.recurringTag = recurringTag
        }
        if repeatOptionSelected == "Every Day" {
            //Repeat Daily
            if neverEndingRepeat {numberOfRepeats = 12*EditEventViewWatch.NEVER_ENDING_REPEAT_LENGTH}
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
            if neverEndingRepeat {numberOfRepeats = 52*EditEventViewWatch.NEVER_ENDING_REPEAT_LENGTH}
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
            if neverEndingRepeat {numberOfRepeats = 26*EditEventViewWatch.NEVER_ENDING_REPEAT_LENGTH}
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
            if neverEndingRepeat {numberOfRepeats = 12*EditEventViewWatch.NEVER_ENDING_REPEAT_LENGTH}
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
            if neverEndingRepeat {numberOfRepeats = 12*EditEventViewWatch.NEVER_ENDING_REPEAT_LENGTH}
            
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
            if neverEndingRepeat {numberOfRepeats = 52*EditEventViewWatch.NEVER_ENDING_REPEAT_LENGTH}
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
            
            deleteEventInCoreData(editEvent!)
            // no EK sharing stuff on watchOS
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
                
                // No EK sharing stuff on watchOS
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
                
                // Now EK sharing stuff on watchOS
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
