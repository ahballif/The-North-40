//
//  ContentViewWatch.swift
//  North40Watch Watch App
//
//  Created by Addison Ballif on 9/3/24.
//

import SwiftUI

struct ContentViewWatch: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var isShowingDefaultView = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                NavigationLink(destination: ToDoViewWatch()) {
                    Label("To Do's", systemImage: "checklist")
                }
                NavigationLink(destination: CalendarViewWatch()) {
                    Label("Schedule", systemImage: "calendar")
                }
                NavigationLink(destination: PersonListViewWatch(archive: false)) {
                    Label("People", systemImage: "person.fill")
                }
                NavigationLink(destination: GoalListViewWatch()) {
                    Label("Goals", systemImage: "pencil.and.ruler.fill")
                }
            }
        }
    }
}

