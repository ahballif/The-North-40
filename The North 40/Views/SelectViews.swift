//
//  SelectViews.swift
//  The North 40
//
//  Created by Addison Ballif on 12/19/23.
//

import CoreData
import SwiftUI



// ********************** SELECT PEOPLE VIEW ***************************
// A sheet that pops up where you can select people to be attached.

public struct SelectPeopleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    let alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W", "X","Y", "Z"]
    let alphabetString = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)], animation: .default)
    private var fetchedPeople: FetchedResults<N40Person>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Group.priorityIndex, ascending: false)], animation: .default)
    private var allGroups: FetchedResults<N40Group>
    
    @State private var sortingAlphabetical = false
    
    var editEventView: EditEventView?
    var editGoalView: EditGoalView?
    var editGroupView: EditGroupView?
    var editNoteView: EditNoteView?
    
    var selectedPeopleList: [N40Person]
    
    @State private var isArchived = false
    
    @State private var searchText: String = ""
    
    @State private var showingAddPersonSheet = false
    
    public var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Sort all alphabetically: ")
                    Spacer()
                    Toggle("sortAlphabetically", isOn: $sortingAlphabetical).labelsHidden()
                }.padding()
                
                List{
                    Section {
                        Button {
                            showingAddPersonSheet.toggle()
                        } label: {
                            Label("Create New Person", systemImage: "plus")
                        }.sheet(isPresented: $showingAddPersonSheet) {
                            EditPersonView()
                        }
                    }
                    if sortingAlphabetical {
                        
                        
                        let noLetterLastNames = fetchedPeople.reversed().filter { $0.lastName.uppercased().filter(alphabetString.contains) == "" && $0.isArchived == isArchived && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}.sorted { $0.lastName < $1.lastName }
                        if noLetterLastNames.count > 0 {
                            Section(header: Text("*")) {
                                ForEach(noLetterLastNames, id: \.self) { person in
                                    if editGroupView != nil {
                                        //edit group view wants it displayed a little differently
                                        //see if the person is already in the group.
                                        if !person.getGroups.contains(editGroupView!.editGroup ?? N40Group()) {
                                            if !selectedPeopleList.contains(person) {
                                                personListItem(person: person)
                                            }
                                        }
                                    } else {
                                        if !selectedPeopleList.contains(person) {
                                            personListItem(person: person)
                                        }
                                    }
                                }
                            }
                        }
                        ForEach(alphabet, id: \.self) { letter in
                            let letterSet = fetchedPeople.reversed().filter { $0.lastName.hasPrefix(letter) && $0.isArchived == isArchived && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}.sorted { $0.lastName < $1.lastName }
                            if (letterSet.count > 0) {
                                Section(header: Text(letter)) {
                                    ForEach(letterSet, id: \.self) { person in
                                        if editGroupView != nil {
                                            //edit group view wants it displayed a little differently
                                            //see if the person is already in the group.
                                            if !person.getGroups.contains(editGroupView!.editGroup ?? N40Group()) {
                                                if !selectedPeopleList.contains(person) {
                                                    personListItem(person: person)
                                                }
                                            }
                                        } else {
                                            if !selectedPeopleList.contains(person) {
                                                personListItem(person: person)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        
                    } else {
                        ForEach(allGroups) {group in
                            let groupSet: [N40Person] = group.getPeople.filter{ $0.isArchived == isArchived && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}
                            if groupSet.count > 0 {
                                Section(header: Text(group.name)) {
                                    //first a button to attach the whole group
                                    Button("Attach Entire Group") {
                                        for eachPerson in groupSet {
                                            if editEventView != nil {
                                                editEventView!.attachPerson(addPerson: eachPerson)
                                            } else if editGoalView != nil {
                                                editGoalView!.attachPerson(addPerson: eachPerson)
                                            } else if editNoteView != nil {
                                                editNoteView!.attachPerson(addPerson: eachPerson)
                                            } else if editGroupView != nil {
                                                editGroupView!.attachPerson(addPerson: eachPerson)
                                            }
                                        }
                                        dismiss()
                                    }.foregroundColor(.blue)
                                    
                                    ForEach(groupSet) {person in
                                        if editGroupView != nil {
                                            //edit group view wants it displayed a little differently
                                            //see if the person is already in the group.
                                            if !person.getGroups.contains(editGroupView!.editGroup ?? N40Group()) {
                                                if !selectedPeopleList.contains(person) {
                                                    personListItem(person: person)
                                                }
                                            }
                                        } else {
                                            if !selectedPeopleList.contains(person) {
                                                personListItem(person: person)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        let ungroupedSet = fetchedPeople.reversed().filter { $0.isArchived == isArchived && $0.getGroups.count < 1 && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}.sorted {$0.lastName < $1.lastName}
                        if ungroupedSet.count > 0 {
                            Section(header: Text("Ungrouped People")) {
                                ForEach(ungroupedSet) {person in
                                    if editGroupView != nil {
                                        //edit group view wants it displayed a little differently
                                        //see if the person is already in the group.
                                        if !person.getGroups.contains(editGroupView!.editGroup ?? N40Group()) {
                                            if !selectedPeopleList.contains(person) {
                                                personListItem(person: person)
                                            }
                                        }
                                    } else {
                                        if !selectedPeopleList.contains(person) {
                                            personListItem(person: person)
                                        }
                                    }
                                }
                            }
                        }
                        
                    }
                }.listStyle(.insetGrouped)
                    .padding(.horizontal, 3)
            }.searchable(text: $searchText)
        }
    }
    
    
    
    
    private func personListItem (person: N40Person) -> some View {
        return HStack {
            Text((person.title == "" ? "" : "\(person.title) ") + "\(person.firstName) \(person.lastName)")
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if editEventView != nil {
                editEventView!.attachPerson(addPerson: person)
            } else if editGoalView != nil {
                editGoalView!.attachPerson(addPerson: person)
            } else if editNoteView != nil {
                editNoteView!.attachPerson(addPerson: person)
            } else if editGroupView != nil {
                editGroupView!.attachPerson(addPerson: person)
            }
            dismiss()
        }
    }
}

// ********************** SELECT GOAL VIEW ***************************
// A sheet that pops up where you can select people to be attached.

public struct SelectGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.priorityIndex, ascending: false)], predicate: NSPredicate(format: "isCompleted == NO"), animation: .default)
    private var fetchedGoals: FetchedResults<N40Goal>
    
    var editEventView: EditEventView?
    var editGoalView: EditGoalView?
    var editGroupView: EditGroupView?
    var editNoteView: EditNoteView?
    
    @State private var showingAddGoalSheet = false
    
    public var body: some View {
        List {
            Button {
                showingAddGoalSheet.toggle()
            } label: {
                Label("Create New Goal", systemImage: "plus")
            }.sheet(isPresented: $showingAddGoalSheet) {
                EditGoalView()
            }
            ForEach(fetchedGoals) {goal in
                if goal.getEndGoals.count == 0 {
                    goalBox(goal)
                        .onTapGesture {
                            if editEventView != nil {
                                editEventView!.attachGoal(addGoal: goal)
                            } else if editGoalView != nil {
                                editGoalView!.addEndGoal(newEndGoal: goal)
                            } else if editGroupView != nil {
                                editGroupView!.attachGoal(addGoal: goal)
                            } else if editNoteView != nil {
                                editNoteView!.attachGoal(addGoal: goal)
                            }
                            dismiss()
                        }
                    ForEach(goal.getSubGoals, id: \.self) {subGoal in
                        if !subGoal.isCompleted {
                            goalBox(subGoal)
                                .padding(.leading, 25.0)
                                .onTapGesture {
                                    if editEventView != nil {
                                        editEventView!.attachGoal(addGoal: goal)
                                    } else if editGoalView != nil {
                                        editGoalView!.addEndGoal(newEndGoal: goal)
                                    } else if editGroupView != nil {
                                        editGroupView!.attachGoal(addGoal: goal)
                                    } else if editNoteView != nil {
                                        editNoteView!.attachGoal(addGoal: goal)
                                    }
                                    dismiss()
                                }
                        }
                    }
                }
            }
        }
    }
    
    private func goalBox (_ goal: N40Goal) -> some View {
        return VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundColor(Color(hex: goal.color))
                    .opacity(1.0)
                    .frame(height: 50.0)
                HStack {
                    Text(goal.name)
                    Spacer()
                }.padding()
            }
            if goal.hasDeadline {
                HStack {
                    Text("Deadline: \(goal.deadline.dateOnlyToString())")
                    Spacer()
                }.padding()
            }
        }.background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: goal.color)!)
                .opacity(0.5)
        )
    }
    
}

