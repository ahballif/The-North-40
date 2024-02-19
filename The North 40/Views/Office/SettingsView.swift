//
//  SettingsView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/29/23.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var show7Days = UserDefaults.standard.bool(forKey: "show7Days")
    
    @State private var smallestDivision = Int( 60 * DailyPlanner.minimumEventHeight / UserDefaults.standard.double(forKey: "hourHeight"))
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
    
    @State private var onlyScheduleUnscheduledTodos = UserDefaults.standard.bool(forKey: "onlyScheduleUnscheduledTodos")
    
    @State private var colorToDoList = UserDefaults.standard.bool(forKey: "colorToDoList")
    
    @State private var showHolidays = UserDefaults.standard.bool(forKey: "showHolidays")
    
    @State private var savingToFile = false
    @State private var importingFile = false
    @State private var importConfirm = false
    
    @State private var defaultColor: Color = (Color(hex: UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0)))
    @State private var defaultEventDuration: Int = UserDefaults.standard.integer(forKey: "defaultEventDuration")
    
    @State private var addContactOnCall = UserDefaults.standard.bool(forKey: "addContactOnCall")
    @State private var repeatByEndDate = UserDefaults.standard.bool(forKey: "repeatByEndDate")
    @State private var tintCompletedTodos = UserDefaults.standard.bool(forKey: "tintCompletedTodos")
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    
                    Text("Settings")
                        .font(.title2).bold()
                    Text("Calendar Settings").font(.title3).padding()
                    HStack {
                        Text("Calendar Resolution: \(smallestDivision) minutes")
                        Spacer()
                        Stepper("", value: $smallestDivision, in: 5...30, step: 5)
                            .onChange(of: smallestDivision)  { _ in
                                // minimumEventHeight / hourHeight == smallestDivision / 60
                                // SO hourHeight = 60 * minimumEventHeight / smallestDivision
                                // AND smallestDivision = Int( 60 * minimumEventHeight / hourHeight)
                                
                                let newHourHeight: Double = DailyPlanner.minimumEventHeight*60.0/Double(smallestDivision)
                                UserDefaults.standard.set(newHourHeight, forKey: "hourHeight")
                            }
                            .labelsHidden()
                    }
                    caption("Defines the smallest time interval that the calendar is divided into. Events shorter than this duration will appear to take up this amount of time.")
                    
                    
                    VStack {
                        HStack {
                            Text("Show Events with Goal Color: ")
                            Spacer()
                            Toggle("eventsWithGoalColor", isOn: $showEventsWithGoalColor)
                                .labelsHidden()
                                .onChange(of: showEventsWithGoalColor) {_ in
                                    UserDefaults.standard.set(showEventsWithGoalColor, forKey: "showEventsInGoalColor")
                                }
                        }
                        caption("Show events with the color of the first goal that is attached to them.")
                        HStack {
                            Text("Show Events with Person Color: ")
                            Spacer()
                            Toggle("showEventsWithPersonColor", isOn: $showEventsWithPersonColor)
                                .labelsHidden()
                                .onChange(of: showEventsWithPersonColor) {_ in
                                    UserDefaults.standard.set(showEventsWithPersonColor, forKey: "showEventsWithPersonColor")
                                }
                        }
                        caption("Show events with the color of the first person that is attached to them. Attachment to a goal will take priority over attachment to a person when choosing what color to display the event. Events with only be colored by person if the person has a favorite color (assigned in the edit person view). ")
                        HStack {
                            Text("Make Events without Goal or Person Gray: ")
                            Spacer()
                            Toggle("eventsWithoutGoalColor", isOn: $showEventsWithoutGoalGray)
                                .labelsHidden()
                                .onChange(of: showEventsWithoutGoalGray) {_ in
                                    UserDefaults.standard.set(showEventsWithoutGoalGray, forKey: "showNoGoalEventsGray")
                                }
                        }.disabled(!showEventsWithGoalColor && !showEventsWithPersonColor)
                        caption("If an event does not have a goal attached or a person with a favorite color, the event will show in gray.")
                        HStack{
                            Text("Tint Completed To-Dos: ")
                            Spacer()
                            Toggle("tintCompletedTodos", isOn: $tintCompletedTodos)
                                .labelsHidden()
                                .onChange(of: tintCompletedTodos) { _ in
                                    UserDefaults.standard.set(tintCompletedTodos, forKey: "tintCompletedTodos")
                                }
                        }
                        caption("If the event is a to-do event and is completed, the event will be faded on the calendar. ")
                        HStack{
                            Text("Show All-Day To-Dos: ")
                            Spacer()
                            Toggle("showAllDayTodos", isOn: $showAllDayTodos)
                                .labelsHidden()
                                .onChange(of: showAllDayTodos) {_ in
                                    UserDefaults.standard.set(showAllDayTodos, forKey: "showAllDayTodos")
                                }
                        }
                        HStack {
                            Text("Show Holidays: ")
                            Spacer()
                            Toggle("showHolidays", isOn: $showHolidays)
                                .labelsHidden()
                                .onChange(of: showHolidays) {_ in
                                    UserDefaults.standard.set(showHolidays, forKey: "showHolidays")
                                }
                        }
                        HStack {
                            Text("Show 7 Days on Weekly Calendar View")
                            Spacer()
                            Toggle("show7Days", isOn: $show7Days)
                                .labelsHidden()
                                .onChange(of: show7Days) {_ in
                                    UserDefaults.standard.set(show7Days, forKey: "show7Days")
                                }
                        }
                    }
                    VStack {
                        Text("To-Do List Settings").font(.title3).padding()
                        
                        HStack {
                            Text("Show Reportables in To-Do List: ")
                            Spacer()
                            Toggle("reportablesOnTodoList", isOn: $showReportablesOnTodo)
                                .labelsHidden()
                                .onChange(of: showReportablesOnTodo) {_ in
                                    UserDefaults.standard.set(showReportablesOnTodo, forKey: "reportablesOnTodoList")
                                }
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
                        HStack {
                            Text("Color To-Do's on To-Do List")
                            Spacer()
                            Toggle("colorToDoList", isOn: $colorToDoList)
                                .labelsHidden()
                                .onChange(of: colorToDoList) {_ in
                                    UserDefaults.standard.set(colorToDoList, forKey: "colorToDoList")
                                }
                        }
                        caption("Colors them based on the color settings in calendar settings defined above.")
                    }
                    
                    
                    VStack {
                        
                        Text("Event Settings").font(.title3).padding(.vertical)
                        
                        VStack {
                            HStack {
                                Text("Default Event Type: ")
                                Spacer()
                            }
                            HStack {
                                Spacer()
                                Picker("Event Type: ", selection: $eventType) {
                                    ForEach(N40Event.EVENT_TYPE_OPTIONS, id: \.self) {
                                        Label($0[0], systemImage: $0[1])
                                    }
                                }.onChange(of: eventType) {_ in
                                    UserDefaults.standard.set(N40Event.EVENT_TYPE_OPTIONS.firstIndex(of: eventType) ?? 1, forKey: "defaultCalendarEventType")
                                }
                            }
                        }
                        
                        HStack {
                            Text("Default Contact Method: ")
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            Picker("Contact Method: ", selection: $contactMethod) {
                                ForEach(N40Event.CONTACT_OPTIONS, id: \.self) {
                                    Label($0[0], systemImage: $0[1])
                                }
                            }.onChange(of: contactMethod) {_ in
                                UserDefaults.standard.set(N40Event.CONTACT_OPTIONS.firstIndex(of: contactMethod) ?? 0, forKey: "defaultContactMethod")
                            }
                        }
                        
                        HStack {
                            Text("Default Duration: ")
                            Spacer()
                            Text("\(defaultEventDuration)")
                            Stepper("defaultEventDuration", onIncrement: {
                                UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "defaultEventDuration") + 5, forKey: "defaultEventDuration")
                                defaultEventDuration = UserDefaults.standard.integer(forKey: "defaultEventDuration")
                            }, onDecrement: {
                                if UserDefaults.standard.integer(forKey: "defaultEventDuration") >= 5 {
                                    UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "defaultEventDuration") - 5, forKey: "defaultEventDuration")
                                    defaultEventDuration = UserDefaults.standard.integer(forKey: "defaultEventDuration")
                                }
                            }).labelsHidden()
                        }
                        HStack {
                            Text("Calculate Repeat Based Off End Date: ")
                            Spacer()
                            Toggle("repeatByEndDate", isOn: $repeatByEndDate)
                                .labelsHidden()
                                .onChange(of: repeatByEndDate) {_ in
                                    UserDefaults.standard.set(repeatByEndDate, forKey: "repeatByEndDate")
                                }
                        }
                        caption("If this is not selected, events with an end date will repeat for a selected duration.")
                    }
                    VStack {
                        HStack {
                            Text("Default Color Random: ")
                            Spacer()
                            Toggle("randomEventColor",isOn: $randomEventColor)
                                .onChange(of: randomEventColor) {_ in
                                    UserDefaults.standard.set(randomEventColor, forKey: "randomEventColor")
                                }
                                .labelsHidden()
                        }
                        if !randomEventColor {
                            HStack{
                                Text("Default Event Color: ")
                                Spacer()
                                ColorPicker("ColorPicker", selection: $defaultColor, supportsOpacity: false)
                                    .labelsHidden()
                                    .onChange(of: defaultColor) {_ in
                                        UserDefaults.standard.set(defaultColor.toHex() ?? "#FF7051", forKey: "defaultColor")
                                    }
                            }
                        }
                        
                        
                        
                        HStack {
                            Text("Guess event color: ")
                            Spacer()
                            Toggle("guessEventColor", isOn: $guessEventColor)
                                .onChange(of: guessEventColor) {_ in
                                    UserDefaults.standard.set(guessEventColor, forKey: "guessEventColor")
                                }
                                .labelsHidden()
                        }
                        caption("The app can try to guess the color of the event based on if it has the same name as an event in the past. Make sure it is spelled the same and push enter after entering event title to make the guess. ")
                        
                        HStack {
                            Text("Create event when contacting person: ")
                            Spacer()
                            Toggle("addContactOnCall", isOn: $addContactOnCall)
                                .onChange(of: addContactOnCall) {_ in
                                    UserDefaults.standard.set(addContactOnCall, forKey: "addContactOnCall")
                                }
                                .labelsHidden()
                        }
                        caption("Creates an event with the correct contact type when you push the button on a person's contact view to text, call, etc. ")
                    }
                    VStack{
                        HStack {
                            Text("Set time on to-do completion: ").padding().font(.title3)
                            Spacer()
                        }
                        caption("When completing a to-do event, you can make the app update the time of the event to the time you checked it off. This setting is separate for several different views.")
                        HStack {
                            Text("on To-Do View: ").padding(.leading)
                            Spacer()
                            Toggle("scheduleOnComplete", isOn: $setTimeOnTodoCompletion_ToDoView)
                                .labelsHidden()
                                .onChange(of: setTimeOnTodoCompletion_ToDoView) {_ in
                                    UserDefaults.standard.set(setTimeOnTodoCompletion_ToDoView, forKey: "scheduleCompletedTodos_ToDoView")
                                }
                        }
                        HStack {
                            Text("on Calendar View: ").padding(.leading)
                            Spacer()
                            Toggle("scheduleOnComplete", isOn: $setTimeOnTodoCompletion_CalendarView)
                                .labelsHidden()
                                .onChange(of: setTimeOnTodoCompletion_CalendarView) {_ in
                                    UserDefaults.standard.set(setTimeOnTodoCompletion_CalendarView, forKey: "scheduleCompletedTodos_CalendarView")
                                }
                        }
                        HStack {
                            Text("on Agenda View: ").padding(.leading)
                            Spacer()
                            Toggle("scheduleOnComplete", isOn: $setTimeOnTodoCompletion_AgendaView)
                                .labelsHidden()
                                .onChange(of: setTimeOnTodoCompletion_AgendaView) {_ in
                                    UserDefaults.standard.set(setTimeOnTodoCompletion_AgendaView, forKey: "scheduleCompletedTodos_AgendaView")
                                }
                        }
                        HStack {
                            Text("on Edit To-Do View: ").padding(.leading)
                            Spacer()
                            Toggle("scheduleOnComplete", isOn: $setTimeOnTodoCompletion_EditEventView)
                                .labelsHidden()
                                .onChange(of: setTimeOnTodoCompletion_EditEventView) {_ in
                                    UserDefaults.standard.set(setTimeOnTodoCompletion_EditEventView, forKey: "scheduleCompletedTodos_EditEventView")
                                }
                        }
                        HStack {
                            Text("on Timeline View: ").padding(.leading)
                            Spacer()
                            Toggle("scheduleOnComplete", isOn: $setTimeOnTodoCompletion_TimelineView)
                                .labelsHidden()
                                .onChange(of: setTimeOnTodoCompletion_TimelineView) {_ in
                                    UserDefaults.standard.set(setTimeOnTodoCompletion_TimelineView, forKey: "scheduleCompletedTodos_TimelineView")
                                }
                        }
                        HStack {
                            Text("Round Time On Complete: ")
                            Spacer()
                            Toggle("scheduleOnComplete", isOn: $roundScheduleCompletedTodos)
                                .labelsHidden()
                                .onChange(of: roundScheduleCompletedTodos) {_ in
                                    UserDefaults.standard.set(roundScheduleCompletedTodos, forKey: "roundScheduleCompletedTodos")
                                }
                        }
                        caption("Round the time of the event based on the calendar resolution determined above in calendar settings.")
                        
                        HStack{
                            Text("Only Schedule Unscheduled Todos: ")
                            Spacer()
                            Toggle("onlyScheduleUnscheduledTodos", isOn: $onlyScheduleUnscheduledTodos)
                                .labelsHidden()
                                .onChange(of: onlyScheduleUnscheduledTodos) {_ in
                                    UserDefaults.standard.set(onlyScheduleUnscheduledTodos, forKey: "onlyScheduleUnscheduledTodos")
                                }
                        }
                    }
                    
                    
                    VStack {
                        VStack {
                            Rectangle().frame(height: 1)
                            Button("Privacy Policy") {
                                if let yourURL = URL(string: "https://ahballif.github.io/North40/privacyPolicy") {
                                        UIApplication.shared.open(yourURL, options: [:], completionHandler: nil)
                                    }
                            }
                            Rectangle().frame(height: 1)
                            NavigationLink("Acknowledgments", destination: AcknowledgmentsView())
                            Rectangle().frame(height: 1)
                            
                            
                        }
                        
                        HStack {
                            Button("Delete Inaccessible Events") {
                                
                                let fetchRequest: NSFetchRequest<N40Event> = N40Event.fetchRequest()
                                
                                let isNotScheduledPredicate = NSPredicate(format: "isScheduled = %d", false)
                                let hasNoPeoplePredicate = NSPredicate(format: "attachedPeople.@count == 0")
                                let hasNoGoalsPredicate = NSPredicate(format: "attachedGoals.@count == 0")
                                let hasNoTransactionsPredicate = NSPredicate(format: "attachedTransactions.@count == 0")
                                let isNotTodoPredicate = NSPredicate(format: "eventType != %i", N40Event.TODO_TYPE)
                                
                                let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [isNotScheduledPredicate, hasNoGoalsPredicate, hasNoPeoplePredicate, isNotTodoPredicate, hasNoTransactionsPredicate])
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
                                
                                
                            }
                            Spacer()
                        }.padding(.vertical, 10)
                        caption("This will only delete any events that cannot be accessed in any way, such as events that are unscheduled and are not attached to any goals or people. To-do events will also not be deleted.")
                        
                        
                        HStack {
                            Button("Export Database to File") {
                                savingToFile.toggle()
                                
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
                                
                                let file = "\(dateFormatter.string(from: Date()))_database.txt" //this is the file. we will write to and read from it
                                
                                let text = Exporter.encodeDatabase(viewContext: viewContext)
                                
                                if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                                    
                                    let fileURL = dir.appendingPathComponent(file)
                                    
                                    //writing
                                    do {
                                        try text.write(to: fileURL, atomically: false, encoding: .utf8)
                                    }
                                    catch {/* error handling here */}
                                    
                                }
                                
                            }.alert("Saved", isPresented: $savingToFile) {
                            } message: {
                                Text("The database file has been saved to your app documents folder. ")
                            }
                            Spacer()
                        }.padding(.vertical, 10)
                        caption("Export your data base to a file for backup. ")
                        
                        HStack {
                            Button("Export all person photos") {
                                let fetchRequest: NSFetchRequest<N40Person> = N40Person.fetchRequest()
                                do {
                                    // Peform Fetch Request
                                    let fetchedPeople = try viewContext.fetch(fetchRequest)
                                    for person: N40Person in fetchedPeople {
                                        if person.photo != nil {
                                            if let image = UIImage(data: person.photo!) {
                                                if let data = image.pngData() {
                                                    
                                                    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                                                        
                                                        let filename = dir.appendingPathComponent(("\(person.title.capitalized)\(person.firstName.capitalized)\(person.lastName.capitalized)\(person.company.capitalized).png"))
                                                        try? data.write(to: filename)
                                                        
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } catch let error as NSError {
                                    print("Couldn't fetch transactions. \(error), \(error.userInfo)")
                                }
                            }
                            Spacer()
                        }.padding(.vertical, 10)
                        HStack {
                            Button("Import Database File") {
                                importConfirm.toggle()
                            }.confirmationDialog("Overwrite database", isPresented: $importConfirm) {
                                Button (role: .destructive) {
                                    importingFile.toggle()
                                } label: {
                                    Text("Overwrite")
                                }
                            } message: {
                                Text("Importing a new database will overwrite the current database. Are you sure you want to overwrite the current database?")
                            }
                            .fileImporter(
                                isPresented: $importingFile,
                                allowedContentTypes: [.plainText]
                            ) { result in
                                switch result {
                                case .success(let file):
                                    Importer.decodeDatabase(inputData: readFile(fileURL: file.absoluteURL), viewContext: viewContext)
                                case .failure(let error):
                                    print(error.localizedDescription)
                                }
                            }
                            Spacer()
                        }.padding(.vertical, 10)
                        HStack {
                            Button("Import Person Pictures") {
                                Importer.importPersonPictures(viewContext: viewContext)
                            }
                            Spacer()
                        }.padding(.vertical, 10)
                        
                    }
                    
                }.padding()
            }//.padding()
            
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
