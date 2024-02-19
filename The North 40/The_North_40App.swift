//
//  The_North_40App.swift
//  The North 40
//
//  Created by Addison Ballif on 8/7/23.
//

import SwiftUI
import CoreData

@main
struct The_North_40App: App {
    let persistenceController = PersistenceController.shared

    @State private var showingTutorialSheet = false
    
    init() {
        UserDefaults.standard.register(defaults: [
            "hourHeight": 100.0,
            "randomEventColor": false,
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
            "onlyScheduleUnscheduledTodos":false
        ])
        
        
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    //UserDefaults.standard.set(true, forKey: "firstOpen")//just for testing
                    
                    if UserDefaults.standard.bool(forKey: "firstOpen") {
                        UserDefaults.standard.set(false, forKey: "firstOpen")
                        showingTutorialSheet.toggle()
                    }
                }.sheet(isPresented: $showingTutorialSheet) {
                    NavigationView {
                        AboutView(hasDoneBar: true)
                    }
                }
        }
    }
}
