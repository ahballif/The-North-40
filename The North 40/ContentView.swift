//
//  ContentView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/7/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext



    var body: some View {
        
        TabView {
            
            ToDoView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("To Do's", systemImage: "checklist")
                }
            CalendarView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
            PersonListView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("People", systemImage: "person.fill")
                }
            GoalListView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem{
                    Label("Goals", systemImage: "pencil.and.ruler.fill")
                }
            OfficeView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem{
                    Label("Office", systemImage: "books.vertical")
                }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        let viewContext = PersistenceController.shared.container.viewContext
        
//        let newEvent = N40Event(entity: N40Event.entity(), insertInto: viewContext)
//
//        newEvent.name = "Go to the Store"
//        newEvent.startDate = Date()
//        newEvent.eventType = 3
//
//        do {
//            try viewContext.save()
//        }catch {
//
//        }
//
        
        
        
        return ContentView().environment(\.managedObjectContext, viewContext)
    }
}