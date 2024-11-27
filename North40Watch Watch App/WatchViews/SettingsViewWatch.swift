//
//  SettingsViewWatch.swift
//  North40Watch Watch App
//
//  Created by Addison Ballif on 9/5/24.
//

//
//  SettingsView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/29/23.
//

import SwiftUI
import CoreData

struct SettingsViewWatch: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var show7Days = UserDefaults.standard.bool(forKey: "show7Days")
    
    @State private var smallestDivision = Int( 60 * DailyPlannerWatch.minimumEventHeight / UserDefaults.standard.double(forKey: "hourHeight"))
    @State private var randomEventColor = UserDefaults.standard.bool(forKey: "randomEventColor")
    @State private var guessEventColor = UserDefaults.standard.bool(forKey: "guessEventColor")
    
    @State private var showEventsWithGoalColor = UserDefaults.standard.bool(forKey: "showEventsInGoalColor")
    @State private var showEventsWithoutGoalGray = UserDefaults.standard.bool(forKey: "showNoGoalEventsGray")
    @State private var showEventsWithPersonColor = UserDefaults.standard.bool(forKey: "showEventsWithPersonColor")
    
    @State private var showAllDayTodos = UserDefaults.standard.bool(forKey: "showAllDayTodos")
    
    @State private var showReportablesOnTodo = UserDefaults.standard.bool(forKey: "reportablesOnTodoList")
    @State private var showTodayTodosFront = UserDefaults.standard.bool(forKey: "showTodayTodosFront")
    
    @State private var contactMethod = N40Event.CONTACT_OPTIONS[UserDefaults.standard.integer(forKey: "defaultContactMethod")]
    @State public var eventType: [String] = N40Event.EVENT_TYPE_OPTIONS[UserDefaults.standard.integer(forKey: "defaultCalendarEventType")]
    
    @State private var setTimeOnTodoCompletion_ToDoView = UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_ToDoView")
    @State private var setTimeOnTodoCompletion_CalendarView = UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_CalendarView")
    @State private var setTimeOnTodoCompletion_EditEventView = UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_EditEventView")
    @State private var setTimeOnTodoCompletion_TimelineView = UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_TimelineView")
    @State private var setTimeOnTodoCompletion_AgendaView = UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_AgendaView")
    @State private var roundScheduleCompletedTodos = UserDefaults.standard.bool(forKey: "roundScheduleCompletedTodos")
    
    @State private var autoFocusOnCalendarNewEvent = UserDefaults.standard.bool(forKey: "autoFocusOnCalendarNewEvent")
    
    @State private var onlyScheduleUnscheduledTodos = UserDefaults.standard.bool(forKey: "onlyScheduleUnscheduledTodos")
    
    @State private var colorToDoList = UserDefaults.standard.bool(forKey: "colorToDoList")
    
    @State private var showHolidays = UserDefaults.standard.bool(forKey: "showHolidays")
    
    @State private var savingToFile = false
    @State private var importingFile = false
    @State private var importConfirm = false
    
    @State private var defaultColor: Color = (Color(hex: UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0)))
    @State private var randomFromColorScheme: Bool = UserDefaults.standard.bool(forKey: "randomFromColorScheme")
    @State private var defaultEventDuration: Int = UserDefaults.standard.integer(forKey: "defaultEventDuration")
    
    @State private var addContactOnCall = UserDefaults.standard.bool(forKey: "addContactOnCall")
    @State private var repeatByEndDate = UserDefaults.standard.bool(forKey: "repeatByEndDate")
    @State private var tintCompletedTodos = UserDefaults.standard.bool(forKey: "tintCompletedTodos")
    
    @State private var showingColorPickerSheet = false
    
    @State private var showCalendarChooser = false
    @State private var selectedCalendarsString = UserDefaults.standard.string(forKey: "selectedAppCalendars") ?? ""
        
    @State private var shareAllEventsToCalendar: Bool = UserDefaults.standard.bool(forKey: "shareEverythingToCalendar")
    
    @State private var showAllDayEvents = UserDefaults.standard.bool(forKey: "showAllDayEvents")
    
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    
                    
                    Text("Calendar Settings").font(.title3).padding()
                    
                    VStack {
                        Text("Calendar Resolution: \(smallestDivision) minutes")
                        
                        HStack{
                            Button {
                                if smallestDivision > 5 {
                                    smallestDivision -= 5
                                }
                                let newHourHeight: Double = DailyPlannerWatch.minimumEventHeight*60.0/Double(smallestDivision)
                                UserDefaults.standard.set(newHourHeight, forKey: "hourHeight")
                            } label: {
                                Image(systemName: "minus").frame(height: 15)
                            }.controlSize(.mini)
                            Spacer()
                            Button {
                                if smallestDivision < 30 {
                                    smallestDivision += 5
                                }
                                let newHourHeight: Double = DailyPlannerWatch.minimumEventHeight*60.0/Double(smallestDivision)
                                UserDefaults.standard.set(newHourHeight, forKey: "hourHeight")
                            } label: {
                                Image(systemName: "plus").frame(height: 15)
                            }.controlSize(.mini)
                            
                        }
                    }
//                    caption("Defines the smallest time interval that the calendar is divided into. Events shorter than this duration will appear to take up this amount of time.")
                    
                    
                    VStack {
                        Toggle("Show Events with Goal Color: ", isOn: $showEventsWithGoalColor)
                            .onChange(of: showEventsWithGoalColor) {_ in
                                UserDefaults.standard.set(showEventsWithGoalColor, forKey: "showEventsInGoalColor")
                            }
//                        caption("Show events with the color of the first goal that is attached to them.")
                        Toggle("Show Events with Person Color: ", isOn: $showEventsWithPersonColor)
                            .onChange(of: showEventsWithPersonColor) {_ in
                                UserDefaults.standard.set(showEventsWithPersonColor, forKey: "showEventsWithPersonColor")
                            }
//                        caption("Show events with the color of the first person that is attached to them. Attachment to a goal will take priority over attachment to a person when choosing what color to display the event. Events with only be colored by person if the person has a favorite color (assigned in the edit person view). ")
                        Toggle("Make Events without Goal or Person Gray: ", isOn: $showEventsWithoutGoalGray)
                            .onChange(of: showEventsWithoutGoalGray) {_ in
                                UserDefaults.standard.set(showEventsWithoutGoalGray, forKey: "showNoGoalEventsGray")
                            }.disabled(!showEventsWithGoalColor && !showEventsWithPersonColor)
//                        caption("If an event does not have a goal attached or a person with a favorite color, the event will show in gray.")
                        
                        Toggle("Tint Completed To-Dos: ", isOn: $tintCompletedTodos)
                            .onChange(of: tintCompletedTodos) { _ in
                                UserDefaults.standard.set(tintCompletedTodos, forKey: "tintCompletedTodos")
                            }
//                        caption("If the event is a to-do event and is completed, the event will be faded on the calendar. ")
                        Toggle("Show All-Day Events: ", isOn: $showAllDayEvents)
                            .onChange(of: showAllDayEvents) {_ in
                                UserDefaults.standard.set(showAllDayEvents, forKey: "showAllDayEvents")
                            }
                        if showAllDayEvents {
                            Toggle("Show All-Day To-Dos: ", isOn: $showAllDayTodos)
                                .onChange(of: showAllDayTodos) {_ in
                                    UserDefaults.standard.set(showAllDayTodos, forKey: "showAllDayTodos")
                                }
                            
                            Toggle("Show Holidays: ", isOn: $showHolidays)
                                .onChange(of: showHolidays) {_ in
                                    UserDefaults.standard.set(showHolidays, forKey: "showHolidays")
                                }
                            
                        }
                       
                        
                        
                        
                    }
                    VStack {
                        Text("To-Do List Settings").font(.title3).padding()
                        
                        Toggle("Show Reportables in To-Do List: ", isOn: $showReportablesOnTodo)
                            .onChange(of: showReportablesOnTodo) {_ in
                                UserDefaults.standard.set(showReportablesOnTodo, forKey: "reportablesOnTodoList")
                            }
//                        HStack { //Currently obsolete when using ToDoView2
//                            Text("Use Today/Inbox/Buckelist Sorting: ")
//                            Spacer()
//                            Toggle("showTodayTodosFront", isOn: $showTodayTodosFront)
//                                .labelsHidden()
//                                .onChange(of: showTodayTodosFront) {_ in
//                                    UserDefaults.standard.set(showTodayTodosFront, forKey: "showTodayTodosFront")
//                                }
//                        }
                        
                        Toggle("Color To-Do's on To-Do List", isOn: $colorToDoList)
                            .onChange(of: colorToDoList) {_ in
                                UserDefaults.standard.set(colorToDoList, forKey: "colorToDoList")
                            }
//                        caption("Colors them based on the color settings in calendar settings defined above.")
                    }
                    
                    
                    VStack {
                        
                        Text("Event Settings").font(.title3).padding(.vertical)
                        
                        VStack {
                            HStack {
                                Text("Default Event Type: ")
                                Spacer()
                            }
                            Picker("Event Type: ", selection: $eventType) {
                                ForEach(N40Event.EVENT_TYPE_OPTIONS, id: \.self) {
                                    Label($0[0], systemImage: $0[1])
                                }
                            }.frame(height: 60.0)
                            .onChange(of: eventType) {_ in
                                UserDefaults.standard.set(N40Event.EVENT_TYPE_OPTIONS.firstIndex(of: eventType) ?? 1, forKey: "defaultCalendarEventType")
                            }
                        }
                        
                        VStack {
                            HStack {
                                Text("Default Contact Method: ")
                                Spacer()
                            }
                            Picker("Contact Method: ", selection: $contactMethod) {
                                ForEach(N40Event.CONTACT_OPTIONS, id: \.self) {
                                    Label($0[0], systemImage: $0[1])
                                }
                            }.frame(height: 60.0)
                            .onChange(of: contactMethod) {_ in
                                UserDefaults.standard.set(N40Event.CONTACT_OPTIONS.firstIndex(of: contactMethod) ?? 0, forKey: "defaultContactMethod")
                            }
                        }
                        
                        VStack {
                            Text("Default Duration: \(defaultEventDuration)")
                            
                            HStack{
                                Button {
                                    if UserDefaults.standard.integer(forKey: "defaultEventDuration") >= 5 {
                                        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "defaultEventDuration") - 5, forKey: "defaultEventDuration")
                                        defaultEventDuration = UserDefaults.standard.integer(forKey: "defaultEventDuration")
                                    }
                                } label: {
                                    Image(systemName: "minus").frame(height: 15)
                                }.controlSize(.mini)
                                Spacer()
                                Button {
                                    UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "defaultEventDuration") + 5, forKey: "defaultEventDuration")
                                    defaultEventDuration = UserDefaults.standard.integer(forKey: "defaultEventDuration")
                                } label: {
                                    Image(systemName: "plus").frame(height: 15)
                                }.controlSize(.mini)
                                
                            }
                        }
                        
                        Toggle("Auto Type on Calendar New Event: ", isOn: $autoFocusOnCalendarNewEvent)
                            .onChange(of: autoFocusOnCalendarNewEvent) {_ in
                                UserDefaults.standard.set(autoFocusOnCalendarNewEvent, forKey: "autoFocusOnCalendarNewEvent")
                            }
                        
//                        Toggle("Calculate Repeat Based Off End Date: ", isOn: $repeatByEndDate)
//                            .onChange(of: repeatByEndDate) {_ in
//                                UserDefaults.standard.set(repeatByEndDate, forKey: "repeatByEndDate")
//                            }
//                        caption("If this is not selected, events with an end date will repeat for a selected duration.")
                    }
                    VStack {
                        Toggle("Default Color Random: ",isOn: $randomEventColor)
                            .onChange(of: randomEventColor) {_ in
                                UserDefaults.standard.set(randomEventColor, forKey: "randomEventColor")
                            }
                        
                        if !randomEventColor {
                            Toggle("Random From First Color Scheme: ", isOn: $randomFromColorScheme)
                                .onChange(of: randomFromColorScheme) {_ in
                                    UserDefaults.standard.set(randomFromColorScheme, forKey: "randomFromColorScheme")
                                }
                            if !randomFromColorScheme {
                                VStack{
                                    Text("Default Event Color: ")
                                    Button {
                                        showingColorPickerSheet.toggle()
                                    } label: {
                                        Rectangle().frame(width:30, height: 20)
                                            .foregroundColor(defaultColor)
                                    }.sheet(isPresented: $showingColorPickerSheet) {
                                        ColorPickerViewWatch(selectedColor: $defaultColor)
                                    }.onChange(of: defaultColor) {_ in
                                            UserDefaults.standard.set(defaultColor.toHex() ?? "#FF7051", forKey: "defaultColor")
                                        }
                                }
                            }
                        }
                        
                        
                        
                        Toggle("Guess event color: ", isOn: $guessEventColor)
                            .onChange(of: guessEventColor) {_ in
                                UserDefaults.standard.set(guessEventColor, forKey: "guessEventColor")
                            }
//                        caption("The app can try to guess the color of the event based on if it has the same name as an event in the past. Make sure it is spelled the same and push enter after entering event title to make the guess. ")
                        
//                        HStack {
//                            Text("Create event when contacting person: ")
//                            Spacer()
//                            Toggle("addContactOnCall", isOn: $addContactOnCall)
//                                .onChange(of: addContactOnCall) {_ in
//                                    UserDefaults.standard.set(addContactOnCall, forKey: "addContactOnCall")
//                                }
//                                .labelsHidden()
//                        }
//                        caption("Creates an event with the correct contact type when you push the button on a person's contact view to text, call, etc. ")
                    }
                    VStack{
                        HStack {
                            Text("Set time on to-do completion: ").padding().font(.title3)
                            Spacer()
                        }
//                        caption("When completing a to-do event, you can make the app update the time of the event to the time you checked it off. This setting is separate for several different views.")
                        Toggle("on To-Do View: ", isOn: $setTimeOnTodoCompletion_ToDoView)
                            .onChange(of: setTimeOnTodoCompletion_ToDoView) {_ in
                                UserDefaults.standard.set(setTimeOnTodoCompletion_ToDoView, forKey: "scheduleCompletedTodos_ToDoView")
                            }
                        Toggle("on Calendar View: ", isOn: $setTimeOnTodoCompletion_CalendarView)
                            .onChange(of: setTimeOnTodoCompletion_CalendarView) {_ in
                                UserDefaults.standard.set(setTimeOnTodoCompletion_CalendarView, forKey: "scheduleCompletedTodos_CalendarView")
                            }
                        Toggle("on Edit To-Do View: ", isOn: $setTimeOnTodoCompletion_EditEventView)
                            .onChange(of: setTimeOnTodoCompletion_EditEventView) {_ in
                                UserDefaults.standard.set(setTimeOnTodoCompletion_EditEventView, forKey: "scheduleCompletedTodos_EditEventView")
                            }
                        
                        
                        Toggle("Round Time On Complete: ", isOn: $roundScheduleCompletedTodos)
                            .onChange(of: roundScheduleCompletedTodos) {_ in
                                UserDefaults.standard.set(roundScheduleCompletedTodos, forKey: "roundScheduleCompletedTodos")
                            }
//                        caption("Round the time of the event based on the calendar resolution determined above in calendar settings.")
                        
                        Toggle("Only Schedule Unscheduled Todos: ", isOn: $onlyScheduleUnscheduledTodos)
                            .onChange(of: onlyScheduleUnscheduledTodos) {_ in
                                UserDefaults.standard.set(onlyScheduleUnscheduledTodos, forKey: "onlyScheduleUnscheduledTodos")
                            }
                    }
                    
                    
//                    VStack {
//                        VStack {
//                            Rectangle().frame(height: 1)
//                            Button("Privacy Policy") {
//                                if let yourURL = URL(string: "https://ahballif.github.io/North40/privacyPolicy") {
//                                        UIApplication.shared.open(yourURL, options: [:], completionHandler: nil)
//                                    }
//                            }
//                            Rectangle().frame(height: 1)
//                            NavigationLink("Acknowledgments", destination: AcknowledgmentsView())
//                            Rectangle().frame(height: 1)
//                            
//                            
//                        }
                        
//                        HStack {
//                            Button("Delete Inaccessible Events") {
//                                
//                                let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
//                                
//                                let isNotScheduledPredicate = NSPredicate(format: "isScheduled = %d", false)
//                                let hasNoPeoplePredicate = NSPredicate(format: "attachedPeople.@count == 0")
//                                let hasNoGoalsPredicate = NSPredicate(format: "attachedGoals.@count == 0")
//                                let hasNoTransactionsPredicate = NSPredicate(format: "attachedTransactions.@count == 0")
//                                let isNotTodoPredicate = NSPredicate(format: "eventType != %i", N40Event.TODO_TYPE)
//                                
//                                let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [isNotScheduledPredicate, hasNoGoalsPredicate, hasNoPeoplePredicate, isNotTodoPredicate, hasNoTransactionsPredicate])
//                                fetchRequest.predicate = compoundPredicate
//                                
//                                do {
//                                    // Peform Fetch Request
//                                    let fetchedEvents = try viewContext.fetch(fetchRequest)
//                                    
//                                    fetchedEvents.forEach { recurringEvent in
//                                        viewContext.delete(recurringEvent)
//                                    }
//                                    
//                                    // To save the entities to the persistent store, call
//                                    // save on the context
//                                    do {
//                                        try viewContext.save()
//                                    }
//                                    catch {
//                                        // Handle Error
//                                        print("Error info: \(error)")
//                                        
//                                    }
//                                    
//                                    
//                                } catch let error as NSError {
//                                    print("Couldn't fetch other recurring events. \(error), \(error.userInfo)")
//                                }
//                                
//                                
//                            }
//                            Spacer()
//                        }.padding(.vertical, 10)
//                        caption("This will only delete any events that cannot be accessed in any way, such as events that are unscheduled and are not attached to any goals or people. To-do events will also not be deleted.")
                        
                        
//                        HStack {
//                            Button("Export Database to File") {
//                                savingToFile.toggle()
//                                
//                                let dateFormatter = DateFormatter()
//                                dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
//                                
//                                let file = "\(dateFormatter.string(from: Date()))_database.txt" //this is the file. we will write to and read from it
//                                
//                                let text = Exporter.encodeDatabase(viewContext: viewContext)
//                                
//                                if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//                                    
//                                    let fileURL = dir.appendingPathComponent(file)
//                                    
//                                    //writing
//                                    do {
//                                        try text.write(to: fileURL, atomically: false, encoding: .utf8)
//                                    }
//                                    catch {/* error handling here */}
//                                    
//                                }
//                                
//                            }.alert("Saved", isPresented: $savingToFile) {
//                            } message: {
//                                Text("The database file has been saved to your app documents folder. ")
//                            }
//                            Spacer()
//                        }.padding(.vertical, 10)
//                        caption("Export your data base to a file for backup. ")
//                        
//                        HStack {
//                            Button("Export all person photos") {
//                                let fetchRequest: NSFetchRequest<N40Person> = N40Person.fetchRequest()
//                                do {
//                                    // Peform Fetch Request
//                                    let fetchedPeople = try viewContext.fetch(fetchRequest)
//                                    for person: N40Person in fetchedPeople {
//                                        if person.photo != nil {
//                                            if let image = UIImage(data: person.photo!) {
//                                                if let data = image.pngData() {
//                                                    
//                                                    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//                                                        
//                                                        let filename = dir.appendingPathComponent(("\(person.title.capitalized)\(person.firstName.capitalized)\(person.lastName.capitalized)\(person.company.capitalized).png"))
//                                                        try? data.write(to: filename)
//                                                        
//                                                    }
//                                                }
//                                            }
//                                        }
//                                    }
//                                } catch let error as NSError {
//                                    print("Couldn't fetch transactions. \(error), \(error.userInfo)")
//                                }
//                            }
//                            Spacer()
//                        }.padding(.vertical, 10)
//                        HStack {
//                            Button("Import Database File") {
//                                importConfirm.toggle()
//                            }.confirmationDialog("Overwrite database", isPresented: $importConfirm) {
//                                Button (role: .destructive) {
//                                    importingFile.toggle()
//                                } label: {
//                                    Text("Overwrite")
//                                }
//                            } message: {
//                                Text("Importing a new database will overwrite the current database. Are you sure you want to overwrite the current database?")
//                            }
//                            .fileImporter(
//                                isPresented: $importingFile,
//                                allowedContentTypes: [.plainText]
//                            ) { result in
//                                switch result {
//                                case .success(let file):
//                                    Importer.decodeDatabase(inputData: readFile(fileURL: file.absoluteURL), viewContext: viewContext)
//                                case .failure(let error):
//                                    print(error.localizedDescription)
//                                }
//                            }
//                            Spacer()
//                        }.padding(.vertical, 10)
//                        HStack {
//                            Button("Import Person Pictures") {
//                                Importer.importPersonPictures(viewContext: viewContext)
//                            }
//                            Spacer()
//                        }.padding(.vertical, 10)
//                        
//                    }
                    
                }
            }.padding()
            
        }.navigationTitle("Settings")
            .onAppear {
                //Update the settings to what they should be
                show7Days = UserDefaults.standard.bool(forKey: "show7Days")
                
                smallestDivision = Int( 60 * DailyPlannerWatch.minimumEventHeight / UserDefaults.standard.double(forKey: "hourHeight"))
                randomEventColor = UserDefaults.standard.bool(forKey: "randomEventColor")
                guessEventColor = UserDefaults.standard.bool(forKey: "guessEventColor")
                
                showEventsWithGoalColor = UserDefaults.standard.bool(forKey: "showEventsInGoalColor")
                showEventsWithoutGoalGray = UserDefaults.standard.bool(forKey: "showNoGoalEventsGray")
                showEventsWithPersonColor = UserDefaults.standard.bool(forKey: "showEventsWithPersonColor")
                
                showAllDayTodos = UserDefaults.standard.bool(forKey: "showAllDayTodos")
                
                 showReportablesOnTodo = UserDefaults.standard.bool(forKey: "reportablesOnTodoList")
                 showTodayTodosFront = UserDefaults.standard.bool(forKey: "showTodayTodosFront")
                
                 contactMethod = N40Event.CONTACT_OPTIONS[UserDefaults.standard.integer(forKey: "defaultContactMethod")]
                eventType = N40Event.EVENT_TYPE_OPTIONS[UserDefaults.standard.integer(forKey: "defaultCalendarEventType")]
                
                 setTimeOnTodoCompletion_ToDoView = UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_ToDoView")
                 setTimeOnTodoCompletion_CalendarView = UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_CalendarView")
                 setTimeOnTodoCompletion_EditEventView = UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_EditEventView")
                 setTimeOnTodoCompletion_TimelineView = UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_TimelineView")
                 setTimeOnTodoCompletion_AgendaView = UserDefaults.standard.bool(forKey: "scheduleCompletedTodos_AgendaView")
                 roundScheduleCompletedTodos = UserDefaults.standard.bool(forKey: "roundScheduleCompletedTodos")
                
                 autoFocusOnCalendarNewEvent = UserDefaults.standard.bool(forKey: "autoFocusOnCalendarNewEvent")
                
                 onlyScheduleUnscheduledTodos = UserDefaults.standard.bool(forKey: "onlyScheduleUnscheduledTodos")
                
                 colorToDoList = UserDefaults.standard.bool(forKey: "colorToDoList")
                
                 showHolidays = UserDefaults.standard.bool(forKey: "showHolidays")
                
                
                
                 defaultColor = (Color(hex: UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0)))
                 randomFromColorScheme = UserDefaults.standard.bool(forKey: "randomFromColorScheme")
                 defaultEventDuration = UserDefaults.standard.integer(forKey: "defaultEventDuration")
                
                 addContactOnCall = UserDefaults.standard.bool(forKey: "addContactOnCall")
                 repeatByEndDate = UserDefaults.standard.bool(forKey: "repeatByEndDate")
                 tintCompletedTodos = UserDefaults.standard.bool(forKey: "tintCompletedTodos")
            
                 selectedCalendarsString = UserDefaults.standard.string(forKey: "selectedAppCalendars") ?? ""
                    
                 shareAllEventsToCalendar = UserDefaults.standard.bool(forKey: "shareEverythingToCalendar")
                
                 showAllDayEvents = UserDefaults.standard.bool(forKey: "showAllDayEvents")
            }
    }
    
    
    private func caption(_ text: String) -> some View {
        return HStack {
            Text(text).font(.caption)
            Spacer()
        }
    }

}

fileprivate func readFile(fileURL: URL) -> String {
    var text = ""
    //reading
        do {
            text = try String(contentsOf: fileURL, encoding: .utf8)
        }
    catch {
        print("Could not read file")
    }
    
    return text
}



struct AcknowledgmentsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Acknowledgments").font(.title)
                
                Text("Sven Tiigi for YouTubePlayerView").font(.title2)
                Text("The MIT License (MIT)\n\nCopyright (c) 2023 Sven Tiigi\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. \n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.")
            }.padding()
        }
    }
}


