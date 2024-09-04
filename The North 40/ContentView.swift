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
    

//    //To show the unreported icon
//    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "status == %i", N40Event.UNREPORTED), NSPredicate(format: "eventType == %i", N40Event.REPORTABLE_TYPE), NSPredicate(format: "startDate < %@", Date() as NSDate)]))
//    private var fetchedUnreporteds: FetchedResults<N40Event>
//    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40ColorScheme.priorityIndex, ascending: true)], predicate: NSPredicate(format: "priorityIndex == 0"))
    private var fetchedColorScheme: FetchedResults<N40ColorScheme>
    
    @State private var selectedTab: N40TabOption = UIDevice.current.userInterfaceIdiom == .pad ? .dashboard : .todoview
    private enum N40TabOption {
        case dashboard, todoview, weekcalendar, calendar, personlist, goallist, office
    }
    
    private let cornerRadius = 10.0
    private let tabOpacity = 0.6
    private let selectedBuff = 0.2
    
    
    var body: some View {
        VStack {
            ZStack {
                
                //Show the person tab in the background all the time
                PersonListView2(archive: false)
                
                //Show the selected Tab
                if selectedTab == .dashboard {
                    Rectangle().foregroundColor(((colorScheme == .dark) ? .black : .white))
                    DashboardView()
                } else if selectedTab == .todoview {
                    ToDoView2()
                } else if selectedTab == .weekcalendar {
                    Rectangle().foregroundColor(((colorScheme == .dark) ? .black : .white))
                    WeekCalendarView()
                } else if selectedTab == .calendar {
                    Rectangle().foregroundColor(((colorScheme == .dark) ? .black : .white))
                    CalendarView()
                } else if selectedTab == .personlist {
                    //Show nothing over the top of the person list
                } else if selectedTab == .goallist {
                    GoalListView2()
                } else {
                    //office tab
                    OfficeView()
                }
            }
            HStack{
                let colorSchemeColor = fetchedColorScheme.count > 0 ? unpackColorsFromString(colorString: fetchedColorScheme.first!.colorsString)[1] : Color(red: 3.0/255.0, green: 110.0/255.0, blue: 20.0/255.0)
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Button {
                        selectedTab = .dashboard
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(colorSchemeColor).opacity(tabOpacity - (selectedTab == .dashboard ? 0.0 : selectedBuff))
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
                            RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(colorSchemeColor).opacity(tabOpacity - (selectedTab == .weekcalendar ? 0.0 : selectedBuff))
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
                            RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(colorSchemeColor).opacity(tabOpacity - (selectedTab == .todoview ? 0.0 : selectedBuff))
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
                            RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(colorSchemeColor).opacity(tabOpacity - (selectedTab == .calendar ? 0.0 : selectedBuff))
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
                        RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(colorSchemeColor).opacity(tabOpacity - (selectedTab == .personlist ? 0.0 : selectedBuff))
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
                        RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(colorSchemeColor).opacity(tabOpacity - (selectedTab == .goallist ? 0.0 : selectedBuff))
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
                        RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(colorSchemeColor).opacity(tabOpacity - (selectedTab == .office ? 0.0 : selectedBuff))
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
