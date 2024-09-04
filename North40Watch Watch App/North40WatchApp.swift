//
//  North40WatchApp.swift
//  North40Watch Watch App
//
//  Created by Addison Ballif on 9/3/24.
//

import SwiftUI
import CoreData


@main
struct North40Watch_Watch_AppApp: App {
    let persistenceController = PersistenceController.shared

    @State private var showingTutorialSheet = false
    
    
    //default color scheme
    private let defaultColorSchemeString = "#053528,#06553d,#38795e,#c4a562,#ac8f4f"
    private let defaultColorSchemeName = "North 40 Default"
    
    private let workingColorSchemeString = "#99de7c,#f7d84a,#7eaed9,#db747b,#f7ca86,#aeafb0,#c7a058"
    private let workingColorSchemeName = "Working Colors"
    
    init() {
        UserDefaults.standard.register(defaults: [
            "hourHeight": 100.0,
            "randomEventColor": false,
            "randomFromColorScheme":true,
            "guessEventColor": true,
            "defaultContactMethod": 0,
            "defaultCalendarEventType": 1,
            "scheduleCompletedTodos_ToDoView": false,
            "scheduleCompletedTodos_CalendarView": false,
            "scheduleCompletedTodos_AgendaView": false,
            "scheduleCompletedTodos_EditEventView": false,
            "scheduleCompletedTodos_TimelineView": false,
            "showingInfoEvents": true,
            "showingBackupEvents": true,
            "showEventsInGoalColor": true,
            "showNoGoalEventsGray": false,
            "firstOpen": true,
            "reportablesOnTodoList": false,
            "showTodayTodosFront": true,
            "showAllDayTodos":true,
            "roundScheduleCompletedTodosschedu":false,
            "defaultColor":"#FF7051",
            "showHolidays":true,
            "defaultEventDuration": 0, // in minutes
            "addContactOnCall":false,
            "tintCompletedTodos":false,
            "showEventsWithPersonColor":true,
            "todoSortByGoals":false,
            "colorToDoList":true,
            "repeatByEndDate":true,
            "show7Days":true,
            "onlyScheduleUnscheduledTodos":false,
            "autoFocusOnCalendarNewEvent":true,
            "showingAgenda":false,
            "selectedAppCalendars":"",
            "showingSharedEvents":true,
            "shareEverythingToCalendar":false,
            "showAllDayEvents":true // watch only
        ])
        
        
        //if there are no color schemes, add the default one.
        let fetchRequest: NSFetchRequest<N40ColorScheme> = N40ColorScheme.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priorityIndex", ascending: true)]
        
        do {
            // Peform Fetch Request
            let fetchedColorSchemes = try persistenceController.container.viewContext.fetch(fetchRequest)
            
            if fetchedColorSchemes.count == 0 {
                //add the color scheme
                let newColorScheme1 = N40ColorScheme(context: persistenceController.container.viewContext)
                newColorScheme1.colorsString = defaultColorSchemeString
                newColorScheme1.name = defaultColorSchemeName
                newColorScheme1.photo = nil
                
                let newColorScheme2 = N40ColorScheme(context: persistenceController.container.viewContext)
                newColorScheme2.colorsString = workingColorSchemeString
                newColorScheme2.name = workingColorSchemeName
                newColorScheme2.photo = nil
                newColorScheme2.priorityIndex = 2
                
                do {
                    try persistenceController.container.viewContext.save()
                }
                catch {
                    // Handle Error
                    print("Error info: \(error)")
                }
            }
        } catch let error as NSError {
            print("Couldn't fetch other recurring events. \(error), \(error.userInfo)")
        }
        
            
            
        
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentViewWatch()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    //UserDefaults.standard.set(true, forKey: "firstOpen")//just for testing
                    
                    if UserDefaults.standard.bool(forKey: "firstOpen") {
                        UserDefaults.standard.set(false, forKey: "firstOpen")
//                        showingTutorialSheet.toggle()
//                        
                        
                        
                        
                        
                        
                    }
                    
                    //if there are no color schemes, add the color scheme
                    let fetchRequest: NSFetchRequest<N40ColorScheme> = N40ColorScheme.fetchRequest()
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priorityIndex", ascending: true)]
                    
                    do {
                        // Peform Fetch Request
                        let fetchedColorSchemes = try persistenceController.container.viewContext.fetch(fetchRequest)
                        
                        if fetchedColorSchemes.count == 0 {
                            //add the color scheme
                            let newColorScheme = N40ColorScheme(context: persistenceController.container.viewContext)
                            newColorScheme.colorsString = defaultColorSchemeString
                            newColorScheme.name = defaultColorSchemeName
                            newColorScheme.photo = nil
                            
                            do {
                                try persistenceController.container.viewContext.save()
                            }
                            catch {
                                // Handle Error
                                print("Error info: \(error)")
                            }
                        }
                    } catch let error as NSError {
                        print("Couldn't fetch other recurring events. \(error), \(error.userInfo)")
                    }
                    
                }
        }
    }
}
