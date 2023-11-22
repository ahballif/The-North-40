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
    
    
    @State private var smallestDivision = Int( 60 * DailyPlanner.minimumEventHeight / UserDefaults.standard.double(forKey: "hourHeight"))
    @State private var randomEventColor = UserDefaults.standard.bool(forKey: "randomEventColor")
    @State private var guessEventColor = UserDefaults.standard.bool(forKey: "guessEventColor")
    
    @State private var showEventsWithGoalColor = UserDefaults.standard.bool(forKey: "showEventsInGoalColor")
    @State private var showEventsWithoutGoalGray = UserDefaults.standard.bool(forKey: "showNoGoalEventsGray")
    
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
    
    @State private var savingToFile = false
    @State private var importingFile = false
    @State private var importConfirm = false
    
    @State private var defaultColor: Color = (Color(hex: UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0)))
    
    var body: some View {
        VStack {
            ScrollView {
                Text("Settings")
                    .font(.title2)
                
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
                    HStack {
                        Text("Make Events without Goal Gray: ")
                        Spacer()
                        Toggle("eventsWithoutGoalColor", isOn: $showEventsWithoutGoalGray)
                            .labelsHidden()
                            .onChange(of: showEventsWithoutGoalGray) {_ in
                                UserDefaults.standard.set(showEventsWithoutGoalGray, forKey: "showNoGoalEventsGray")
                            }
                    }.disabled(!showEventsWithGoalColor)
                    HStack{
                        Text("Show All-Day To-Dos: ")
                        Spacer()
                        Toggle("showAllDayTodos", isOn: $showAllDayTodos)
                            .labelsHidden()
                            .onChange(of: showAllDayTodos) {_ in
                                UserDefaults.standard.set(showAllDayTodos, forKey: "showAllDayTodos")
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
                    HStack {
                        Text("Use Today/Inbox/Buckelist Sorting: ")
                        Spacer()
                        Toggle("showTodayTodosFront", isOn: $showTodayTodosFront)
                            .labelsHidden()
                            .onChange(of: showTodayTodosFront) {_ in
                                UserDefaults.standard.set(showTodayTodosFront, forKey: "showTodayTodosFront")
                            }
                    }
                }
                
                
                VStack {
                    
                    Text("Event Settings").font(.title3).padding()
                    
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
                }
                VStack{
                    HStack {
                        Text("Set time on to-do completion: ")
                        Spacer()
                    }
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
                }
                
                
                
                VStack {
                    
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
                    }
                    HStack {
                        Text("This will only delete any events that cannot be accessed in any way, such as events that are unscheduled and are not attached to any goals or people. ").font(.caption)
                    }
                    
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
                    }
                    HStack {
                        Text("Export your data base to a file for backup. ").font(.caption)
                    }
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
                    }
                    
                    
                }
                
                
            }.padding()
            
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
