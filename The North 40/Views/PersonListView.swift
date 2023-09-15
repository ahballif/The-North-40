//
//  PersonListView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

import SwiftUI

struct PersonListView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    let alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W", "X","Y", "Z"]
    let alphabetString = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    @State private var showingEditPersonSheet = false
    
    @FetchRequest var allPeople: FetchedResults<N40Person>
    @FetchRequest var allGroups: FetchedResults<N40Group>
    @FetchRequest var unassignedToGroupPeople: FetchedResults<N40Person>
    
    @State private var sortingAlphabetical = false
    
    
    
    init () {
        _allPeople = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)])
        _allGroups = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Group.priorityIndex, ascending: false)])
        _unassignedToGroupPeople = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)], predicate: NSPredicate(format: "groups.@count == 0"))
        
        
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
                            let noLetterLastNames = allPeople.filter { $0.lastName.uppercased().filter(alphabetString.contains) == ""}
                            if noLetterLastNames.count > 0 {
                                Section(header: Text("*")) {
                                    ForEach(noLetterLastNames, id: \.self) { person in
                                        NavigationLink(destination: PersonDetailView(selectedPerson: person)) {
                                            HStack {
                                                Text((person.title == "" ? "" : "\(person.title) ") + "\(person.firstName)")
                                                Text("\(person.lastName)").bold()
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                            ForEach(alphabet, id: \.self) { letter in
                                let letterSet = allPeople.filter { $0.lastName.hasPrefix(letter) }
                                if (letterSet.count > 0) {
                                    Section(header: Text(letter)) {
                                        ForEach(letterSet, id: \.self) { person in
                                            NavigationLink(destination: PersonDetailView(selectedPerson: person)) {
                                                HStack {
                                                    Text((person.title == "" ? "" : "\(person.title) ") + "\(person.firstName)")
                                                    Text("\(person.lastName)").bold()
                                                    Spacer()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }.listStyle(.sidebar)
                            .padding(.horizontal, 3)
                        
                    } else {
                        
                        List {
                            ForEach(allGroups) {group in
                                Section(header: Text(group.name)) {
                                    ForEach(group.getPeople, id: \.self) {person in
                                        NavigationLink(destination: PersonDetailView(selectedPerson: person)) {
                                            HStack {
                                                Text((person.title == "" ? "" : "\(person.title) ") + "\(person.firstName)")
                                                Text("\(person.lastName)").bold()
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                            Section(header: Text("Ungrouped People")) {
                                ForEach(unassignedToGroupPeople) {person in
                                    NavigationLink(destination: PersonDetailView(selectedPerson: person)) {
                                        HStack {
                                            Text((person.title == "" ? "" : "\(person.title) ") + "\(person.firstName)")
                                            Text("\(person.lastName)").bold()
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }.listStyle(.sidebar)
                    }
                    
                }
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
            .navigationTitle(Text("People"))
            .navigationBarTitleDisplayMode(.inline)
            
            
        }
        
    }
    
}
