//
//  PersonListView2.swift
//  The North 40
//
//  Created by Addison Ballif on 1/23/24.
//

import SwiftUI

struct PersonListView2: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W", "X","Y", "Z"]
    let alphabetString = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)], predicate: NSPredicate(format: "isArchived == NO"), animation: .default)
    private var unarchivedPeople: FetchedResults<N40Person>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)], predicate: NSPredicate(format: "isArchived == YES"), animation: .default)
    private var archivedPeople: FetchedResults<N40Person>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Group.priorityIndex, ascending: false)], animation: .default)
    private var allGroups: FetchedResults<N40Group>
    
    
    @State private var showingEditPersonSheet = false
    
    @State private var sortingAlphabetical = false
    @State private var searchText: String = ""
    
    @State public var archive: Bool //whether or not this is the archived list or not.
    
    
    
    
    var body: some View {
        
        NavigationView {
            ZStack {
                VStack {
                    //get the full list of people to show on this screen (and sort them) (and filter them)
                    let allPeople = (archive ? archivedPeople.sorted {
                        if $0.lastName != $1.lastName { // first, compare by last names
                            return $0.lastName < $1.lastName
                        } else if $0.firstName != $1.firstName { //see if comparing by first names works
                            return $0.firstName < $1.firstName
                        } else { // All other fields are tied, break ties by last name
                            return $0.company < $1.company
                        }
                    } : unarchivedPeople.sorted {
                        if $0.lastName != $1.lastName { // first, compare by last names
                            return $0.lastName < $1.lastName
                        } else if $0.firstName != $1.firstName { //see if comparing by first names works
                            return $0.firstName < $1.firstName
                        } else { // All other fields are tied, break ties by last name
                            return $0.company < $1.company
                        }
                    }).filter{(searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}
                    
                    
                    HStack {
                        Text("Sort all alphabetically: ")
                        Spacer()
                        Toggle("sortAlphabetically", isOn: $sortingAlphabetical).labelsHidden()
                    }.padding(.horizontal)
                    
                    if sortingAlphabetical {
                        ScrollViewReader { scrollProxy in
                            ZStack {
                                List {
                                    //First people who's last names don't have letters
                                    let noLetterLastNames = allPeople.filter{$0.lastName.uppercased().filter(alphabetString.contains) == "" }
                                    if noLetterLastNames.count > 0 {
                                        Section(header: Text("*")) {
                                            ForEach(noLetterLastNames, id: \.self) { person in
                                                personListItem(person: person)
                                            }
                                        }
                                    }
                                    //Now go through the letters
                                    ForEach(alphabet, id: \.self) {letter in
                                        let letterSet = allPeople.filter {$0.lastName.hasPrefix(letter)}
                                        if (letterSet.count > 0) {
                                            Section(header: Text(letter)) {
                                                ForEach(letterSet, id: \.self) { person in
                                                    personListItem(person: person)
                                                }
                                            }
                                        }
                                    }
                                }.listStyle(.sidebar)
                                    .padding(.horizontal, 3)
                                
                                
                                //letter bar
                                VStack {
                                    ForEach(alphabet, id: \.self) { letter in
                                        HStack {
                                            Spacer()
                                            Button(action: {
                                                print("letter = \(letter)")
                                                //need to figure out if there is a name in this section before I allow scrollto or it will crash
                                                if allPeople.first(where: { $0.lastName.prefix(1) == letter }) != nil {
                                                    withAnimation {
                                                        scrollProxy.scrollTo(letter)
                                                    }
                                                }
                                            }, label: {
                                                Text(letter)
                                                    .font(.system(size: 12))
                                                    .padding(.trailing, 7)
                                            })
                                        }
                                    }
                                }
                            }
                        }
                    } else {
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
                        }.listStyle(.sidebar)
                    }
                    
                    
                    
                }
                
                if archive == false {
                    //don't show the button when it's an archive list.
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            Button(action: {showingEditPersonSheet.toggle()}) {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(Circle())
                                    .frame(minWidth: 50, maxWidth: 50)
                                    .padding(30)
                            }
                            .sheet(isPresented: $showingEditPersonSheet) {
                                EditPersonView(editPerson: nil)
                                
                            }
                        }
                    }
                    
                }
            }
            .navigationTitle(Text(archive ? "Archived People" : "People"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText)
        }.if(archive) {view in
            //on the archive tab we want a stack view
            view.navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    
    private func personListItem (person: N40Person) -> some View {
        return NavigationLink(destination: PersonDetailView(selectedPerson: person)) {
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
        .contextMenu {
            //just have both
            if !person.isArchived {
                Button("Archive") {
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
                Button("Unarchive") {
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

