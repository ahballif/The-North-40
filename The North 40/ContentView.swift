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
    @Environment(\.colorScheme) var colorScheme
    

    //To show the unreported icon
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "status == %i", N40Event.UNREPORTED), NSPredicate(format: "eventType == %i", N40Event.REPORTABLE_TYPE), NSPredicate(format: "startDate < %@", Date() as NSDate)]))
    private var fetchedUnreporteds: FetchedResults<N40Event>
    
    @State private var selectedTab: N40TabOption = UIDevice.current.userInterfaceIdiom == .pad ? .dashboard : .todoview
    private enum N40TabOption {
        case dashboard, todoview, weekcalendar, calendar, personlist, goallist, office
    }
    
    private let cornerRadius = 10.0
    private let tabOpacity = 0.4
    private let tabColor = Color(red: 3.0/255.0, green: 110.0/255.0, blue: 20.0/255.0)
    
    var body: some View {
        VStack {
            //Show the selected Tab
            if selectedTab == .dashboard {
                DashboardView()
            } else if selectedTab == .todoview {
                ToDoView2()
            } else if selectedTab == .weekcalendar {
                WeekCalendarView()
            } else if selectedTab == .calendar {
                CalendarView()
            } else if selectedTab == .personlist {
                PersonListView()
            } else if selectedTab == .goallist {
                GoalListView2()
            } else {
                //office tab
                OfficeView()
            }
            HStack{
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Button {
                        selectedTab = .dashboard
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(tabColor).opacity(tabOpacity)
                            VStack {
                                Image(systemName: "gauge.medium")
                                Text("Dashboard").font(.caption)
                            }
                        }
                    }.buttonStyle(.plain).frame(maxWidth: .infinity)
                    
                    Button {
                        selectedTab = .weekcalendar
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(tabColor).opacity(tabOpacity)
                            VStack {
                                Image(systemName: "calendar")
                                Text("Schedule").font(.caption)
                            }
                        }
                    }.buttonStyle(.plain).frame(maxWidth: .infinity)
     
                } else {
                    Button {
                        selectedTab = .todoview
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(tabColor).opacity(tabOpacity)
                            VStack {
                                Image(systemName: "checklist")
                                Text("To Do's").font(.caption)
                            }
                        }
                    }.buttonStyle(.plain).frame(maxWidth: .infinity)
                    Button {
                        selectedTab = .calendar
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(tabColor).opacity(tabOpacity)
                            VStack {
                                Image(systemName: "calendar")
                                Text("Schedule").font(.caption)
                            }
                        }
                    }.buttonStyle(.plain).frame(maxWidth: .infinity)
   
                }
                Button {
                    selectedTab = .personlist
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(tabColor).opacity(tabOpacity)
                        VStack {
                            Image(systemName: "person.fill")
                            Text("People").font(.caption)
                        }
                    }
                }.buttonStyle(.plain).frame(maxWidth: .infinity)
                Button {
                    selectedTab = .goallist
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(tabColor).opacity(tabOpacity)
                        VStack {
                            Image(systemName: "pencil.and.ruler.fill")
                            Text("Goals").font(.caption)
                        }
                    }
                }.buttonStyle(.plain).frame(maxWidth: .infinity)
                Button {
                    selectedTab = .office
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(tabColor).opacity(tabOpacity)
                        VStack {
                            Image(systemName: "books.vertical")
                            Text("Office").font(.caption)
                        }
                    }
                }.buttonStyle(.plain).frame(maxWidth: .infinity)

            }.frame(height: 50)
                .padding(.horizontal, 5)
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
