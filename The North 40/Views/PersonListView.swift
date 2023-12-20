//
//  PersonListView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

import SwiftUI


struct PersonListView: View {
    private var updater: RefreshView = RefreshView()
    @Environment(\.managedObjectContext) private var viewContext
    
    let alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W", "X","Y", "Z"]
    let alphabetString = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    @State private var showingEditPersonSheet = false
    @State private var showingArchivedPeopleSheet = false
    
    @FetchRequest var allPeople: FetchedResults<N40Person>
    @FetchRequest var allGroups: FetchedResults<N40Group>
    @FetchRequest var unassignedToGroupPeople: FetchedResults<N40Person>
    
    @State private var sortingAlphabetical = false
    @State private var searchText: String = ""
    
    private var isArchived: Bool
    
    init (archive: Bool = false) {
        
        _allPeople = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)])
        _allGroups = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Group.priorityIndex, ascending: false)])
        _unassignedToGroupPeople = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)], predicate: NSPredicate(format: "groups.@count == 0"))
        
        self.isArchived = archive
    }
    
    
    var body: some View {
        
        NavigationView {
            ZStack {
                VStack {
                    HStack {
                        Text("Sort all alphabetically: ")
                        Spacer()
                        Toggle("sortAlphabetically", isOn: $sortingAlphabetical).labelsHidden()
                    }.padding(.horizontal)
                    
                    if sortingAlphabetical {
                        
                        List{
                            let noLetterLastNames = allPeople.filter { $0.lastName.uppercased().filter(alphabetString.contains) == "" && $0.isArchived == isArchived && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}.sorted {
                                if $0.lastName != $1.lastName { // first, compare by last names
                                    return $0.lastName < $1.lastName
                                } else if $0.firstName != $1.firstName { //see if comparing by first names works
                                    return $0.firstName < $1.firstName
                                } else { // All other fields are tied, break ties by last name
                                    return $0.company < $1.company
                                }
                            }
                            if noLetterLastNames.count > 0 {
                                Section(header: Text("*")) {
                                    ForEach(noLetterLastNames, id: \.self) { person in
                                        personListItem(person: person)
                                    }
                                }
                            }
                            ForEach(alphabet, id: \.self) { letter in
                                let letterSet = allPeople.filter { $0.lastName.hasPrefix(letter) && $0.isArchived == isArchived && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}.sorted {
                                    if $0.lastName != $1.lastName { // first, compare by last names
                                        return $0.lastName < $1.lastName
                                    } else if $0.firstName != $1.firstName { //see if comparing by first names works
                                        return $0.firstName < $1.firstName
                                    } else { // All other fields are tied, break ties by last name
                                        return $0.company < $1.company
                                    }
                                }
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
                        
                    } else {
                        
                        List {
                            ForEach(allGroups) {group in
                                let groupSet: [N40Person] = group.getPeople.filter{ $0.isArchived == isArchived && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}.sorted {
                                    if $0.lastName != $1.lastName { // first, compare by last names
                                        return $0.lastName < $1.lastName
                                    } else if $0.firstName != $1.firstName { //see if comparing by first names works
                                        return $0.firstName < $1.firstName
                                    } else { // All other fields are tied, break ties by last name
                                        return $0.company < $1.company
                                    }
                                }
                                if groupSet.count > 0 {
                                    Section(header: Text(group.name)) {
                                        ForEach(groupSet) {person in
                                            personListItem(person: person)
                                        }
                                    }
                                }
                            }
                            //ungrouped people
                            let ungroupedSet = unassignedToGroupPeople.reversed().filter { $0.isArchived == isArchived && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}.sorted {
                                if $0.lastName != $1.lastName { // first, compare by last names
                                    return $0.lastName < $1.lastName
                                } else if $0.firstName != $1.firstName { //see if comparing by first names works
                                    return $0.firstName < $1.firstName
                                } else { // All other fields are tied, break ties by last name
                                    return $0.company < $1.company
                                }
                            }
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
                if isArchived == false {
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
            .navigationTitle(Text("People"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText)
        }.if(isArchived){view in
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
                Button("Archive") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            person.isArchived = true
                            
                            do {
                                try viewContext.save()
                            } catch {
                                // handle error
                            }
                            
                            updater.updater.toggle()
                        }
                    }
                }
                .tint(.pink)
            } else {
                Button("Unarchive") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            person.isArchived = false
                            
                            do {
                                try viewContext.save()
                            } catch {
                                // handle error
                            }
                            
                            updater.updater.toggle()
                            
                        }
                    }
                }
                .tint(.pink)
            }
        }
    }
    
}


