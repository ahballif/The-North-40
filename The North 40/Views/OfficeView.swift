//
//  OfficeView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/25/23.
//

import SwiftUI

struct OfficeView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("My Office")
                    .font(.title)
                    .padding()
                
                List {
                    
                    NavigationLink(destination: FinanceView()) {
                        Label("Budget and Finances", systemImage: "creditcard.and.123")
                    }
                    NavigationLink(destination: GroupsView()) {
                        Label("Person Groups", systemImage: "person.3")
                    }
                    NavigationLink(destination: StatsView()) {
                        Label("My Stats", systemImage: "chart.bar")
                    }
                    NavigationLink(destination: NotesView()) {
                        Label("Notes", systemImage: "note.text")
                    }
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape.2")
                    }
                }
                Spacer()
            }
        }
    }
}

struct OfficeView_Previews: PreviewProvider {
    static var previews: some View {
        OfficeView()
    }
}



struct FinanceView: View {
    var body: some View {
        Text("This is the finance page. ")
    }
}

struct GroupsView: View {
    var body: some View {
        Text("This is the groups view. ")
    }
}


struct StatsView: View {
    var body: some View {
        Text("This is the stats page. ")
    }
}


struct NotesView: View {
    var body: some View {
        Text("This is the notes page. ")
    }
}


struct SettingsView: View {
    var body: some View {
        Text("This is the Settings Page")
    }
}


