//
//  OfficeView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/25/23.
//

import SwiftUI

struct OfficeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "status == %i", N40Event.UNREPORTED), NSPredicate(format: "eventType == %i", N40Event.REPORTABLE_TYPE), NSPredicate(format: "startDate < %@", Date() as NSDate)]))
    private var fetchedUnreporteds: FetchedResults<N40Event>
    
    
    
    var body: some View {
        NavigationView {
            VStack {
                Text("My Office")
                    .font(.title)
                    .padding()
                
                List {
                    NavigationLink(destination: NotesView()) {
                        Label("Notes", systemImage: "note.text")
                    }
//                    NavigationLink(destination: IndicatorsView()) {
//                        Label("Indicators", systemImage: "chart.xyaxis.line")
//                    }
                    NavigationLink(destination: FinanceView()) {
                        Label("Budget and Finances", systemImage: "creditcard.and.123")
                    }
                    NavigationLink(destination: UnreportedView()) {
                        Label("Unreported Events: ", systemImage: "questionmark.circle").badge(fetchedUnreporteds.count)
                    }
                    NavigationLink(destination: GroupsView()) {
                        Label("Person Groups", systemImage: "person.3")
                    }
//                    NavigationLink(destination: StatsView()) {
//                        Label("My Stats", systemImage: "chart.bar")
//                    }
//                    NavigationLink(destination: MapView()) {
//                        Label("Map", systemImage: "map")
//                    }
                    NavigationLink(destination: SmartSortView()) {
                        Label("People Randomizer", systemImage: "lightbulb.led")
                    }
                    NavigationLink(destination: PersonListView2(archive: true)) {
                        Label("Archived People", systemImage: "person.badge.clock")
                    }
                    NavigationLink(destination: ColorSchemeView()) {
                        Label("Color Schemes", systemImage: "paintpalette")
                    }
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape.2")
                    }
                    
                    Group {
                        NavigationLink(destination: AboutView()) {
                            Label {
                                Text("About North 40")
                            } icon: {
                                if colorScheme == .dark {
                                    Image("N40Black")
                                        .resizable()
                                        .scaledToFit()
                                        .colorInvert()
                                } else {
                                    Image("N40Black")
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                        }
//                        NavigationLink(destination: TutorialView()) {
//                            Text("Using the App")
//                        }
//                        NavigationLink(destination: GoalTipsView()) {
//                            Text("Tips for Goal Setting")
//                        }
                    }
                }
                Spacer()
            }
        }
    }
}

struct UnreportedView: View {
    private var updater: RefreshView = RefreshView()
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "status == %i", N40Event.UNREPORTED), NSPredicate(format: "eventType == %i", N40Event.REPORTABLE_TYPE), NSPredicate(format: "startDate < %@", Date() as NSDate)]))
    private var fetchedUnreporteds: FetchedResults<N40Event>
    
    
    var body: some View {
        VStack {
            HStack {
                Text("Unreported Events: ").font(.title2)
                Spacer()
            }.padding(.horizontal)
            
            
            if (fetchedUnreporteds.count > 0) {
                List(fetchedUnreporteds) { event in
                    NavigationLink(destination: EditEventView(editEvent: event)) {
                        HStack {
                            Text(event.name)
                            Spacer()
                            Text(dateToString(date: event.startDate))
                            Image(systemName: "questionmark.circle.fill")
                                .resizable()
                                .foregroundColor(Color.orange)
                                .frame(width: 20, height:20)
                        }
                    }
                }.scrollContentBackground(.hidden)
                    
            } else {
            
                VStack {
                    Text("You have no unreported events.")
                    Image(systemName: "bird")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                    Text("You're on top of it!")
                }.padding()
            
            }
        }
    }
    
    private func dateToString(date: Date) -> String {
        // Create Date Formatter
        let dateFormatter = DateFormatter()

        // Set Date Format
        dateFormatter.dateFormat = "MMM d, hh:mm a"
        
        // Convert Date to String
        return dateFormatter.string(from: date)
    }
}

struct MapView: View {
    var body: some View {
        Text("This is the map view")
    }
}

struct StatsView: View {
    var body: some View {
        Text("This is the stats page. ")
    }
}


