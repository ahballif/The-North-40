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


    //To show the unreported icon
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "status == %i", N40Event.UNREPORTED), NSPredicate(format: "eventType == %i", N40Event.REPORTABLE_TYPE), NSPredicate(format: "startDate < %@", Date() as NSDate)]))
    private var fetchedUnreporteds: FetchedResults<N40Event>
    

    var body: some View {
        
        TabView {
            if UIDevice.current.userInterfaceIdiom == .pad {
                DashboardView()
                    .environment(\.managedObjectContext, viewContext)
                    .tabItem {
                        Label("Dashboard", systemImage: "gauge.medium")
                    }
                    .toolbarBackground(.visible, for: .tabBar)
            }
            if UIDevice.current.userInterfaceIdiom != .pad {
                ToDoView2()
                    .environment(\.managedObjectContext, viewContext)
                    .tabItem {
                        Label("To Do's", systemImage: "checklist")
                    }
                    .toolbarBackground(.visible, for: .tabBar)
            }
            if UIDevice.current.userInterfaceIdiom == .pad {
                WeekCalendarView()
                    .environment(\.managedObjectContext, viewContext)
                    .tabItem {
                        Label("Schedule", systemImage: "calendar")
                    }
                    .toolbarBackground(.visible, for: .tabBar)
            } else {
                CalendarView()
                    .environment(\.managedObjectContext, viewContext)
                    .tabItem {
                        Label("Schedule", systemImage: "calendar")
                    }
                    .toolbarBackground(.visible, for: .tabBar)
            }
            PersonListView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("People", systemImage: "person.fill")
                }
                .toolbarBackground(.visible, for: .tabBar)
            GoalListView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem{
                    Label("Goals", systemImage: "pencil.and.ruler.fill")
                }
                .toolbarBackground(.visible, for: .tabBar)
            OfficeView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem{
                    Label("Office", systemImage: "books.vertical")
                }
                .badge(fetchedUnreporteds.count)
                .toolbarBackground(.visible, for: .tabBar)
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()



class RefreshView: ObservableObject {
    @Published var updater: Bool = false
}
