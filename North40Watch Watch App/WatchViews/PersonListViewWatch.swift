//
//  PersonListViewWatch.swift
//  North40Watch Watch App
//
//  Created by Addison Ballif on 9/4/24.
//

import SwiftUI

struct PersonListViewWatch: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W", "X","Y", "Z"]
    let alphabetString = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true), NSSortDescriptor(keyPath: \N40Person.firstName, ascending: true)], predicate: NSPredicate(format: "isArchived == NO"), animation: .default)
    private var unarchivedPeople: FetchedResults<N40Person>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true), NSSortDescriptor(keyPath: \N40Person.firstName, ascending: true)], predicate: NSPredicate(format: "isArchived == YES"), animation: .default)
    private var archivedPeople: FetchedResults<N40Person>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Group.priorityIndex, ascending: false)], animation: .default)
    private var allGroups: FetchedResults<N40Group>
    
    
    @State private var showingEditPersonSheet = false
    
    
    @State public var archive: Bool //whether or not this is the archived list or not.
    
    
    
    
    var body: some View {
        
        NavigationView {
            ZStack {
                VStack {
                    //get the full list of people to show on this screen (and sort them) (and filter them)
                    let allPeople = (archive ? archivedPeople : unarchivedPeople)
                    
                    
                    
                    
                        List {
                            //first go through the groups
                            ForEach(allGroups) {group in
                                let groupSet: [N40Person] = allPeople.filter{ $0.isInGroup(group)}
                                if groupSet.count > 0 {
                                    Section(header: Text(group.name)) {
                                        ForEach(groupSet) {person in
                                            personListItem(person: person)
                                        }
                                    }
                                }
                            }
                            //now go through ungrouped people
                            let ungroupedSet: [N40Person] = allPeople.filter{ $0.getGroups.count == 0}
                            if ungroupedSet.count > 0 {
                                Section(header: Text("Ungrouped People")) {
                                    ForEach(ungroupedSet) {person in
                                        personListItem(person: person)
                                    }
                                }
                            }
                        }
                    }
                    
                
                
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    HStack {
                        Spacer()
                        Button {
                            showingEditPersonSheet.toggle()
                        } label: {
                            Image(systemName: "plus.circle")
                        }.sheet(isPresented: $showingEditPersonSheet) {
                            PersonViewWatch(editPerson: nil)
                            
                        }
                    }
                }
            }
            .navigationTitle(Text(archive ? "Archived People" : "People"))
            .navigationBarTitleDisplayMode(.inline)
            
        }.if(archive) {view in
            //on the archive tab we want a stack view
            view.navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    
    private func personListItem (person: N40Person) -> some View {
        return NavigationLink(destination: PersonViewWatch(editPerson: person)) {
            HStack {
                if person.title != "" || person.firstName != "" {
                    Text("\(person.title) \(person.firstName)".trimmingCharacters(in: .whitespacesAndNewlines))
                }
                if person.company == "" {
                    Text("\(person.lastName)").bold()
                } else if person.company != "" && person.lastName != "" {
                    Text("\(person.lastName) (\(person.company))").bold()
                } else {
                    Text("\(person.company)").bold()
                }
                Spacer()
            }
        }.swipeActions {
            if !person.isArchived {
                Button("Archive", role: .destructive) {
                    withAnimation {
                        person.isArchived = true
                        
                        do {
                            try viewContext.save()
                        } catch {
                            // handle error
                        }
                        
                    }
                }
                .tint(.pink)
            } else {
                Button("Unarchive", role: .destructive) {
                    withAnimation {
                        person.isArchived = false
                        
                        do {
                            try viewContext.save()
                        } catch {
                            // handle error
                        }
                        
                        
                    }
                }
                .tint(.pink)
            }
        }
        
    }
}

