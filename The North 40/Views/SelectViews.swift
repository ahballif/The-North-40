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
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true), NSSortDescriptor(keyPath: \N40Person.firstName, ascending: true)], animation: .default)
    private var allPeople: FetchedResults<N40Person>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Group.priorityIndex, ascending: false)], animation: .default)
    private var allGroups: FetchedResults<N40Group>
    
    @State private var sortingAlphabetical = false
    
    var editEventView: EditEventView?
    var editGoalView: EditGoalView?
    var editGroupView: EditGroupView?
    var editNoteView: EditNoteView?
    
    @State var selectedPeopleList: [N40Person]
    
    @State private var isArchived = false
    
    @State private var searchText: String = ""
    
    @State private var showingAddPersonSheet = false
    
    init(editEventView: EditEventView? = nil, editGoalView: EditGoalView? = nil, editGroupView: EditGroupView? = nil, editNoteView: EditNoteView? = nil, selectedPeopleList: [N40Person]) {
        self.editEventView = editEventView
        self.editGoalView = editGoalView
        self.editGroupView = editGroupView
        self.editNoteView = editNoteView
        
        self._selectedPeopleList = State(initialValue: selectedPeopleList)
    }
    
    public var body: some View {
        
        
        NavigationStack {
            //                VStack{
            //                    HStack {
            //
            //                    }.padding()
            //
            
            
            if sortingAlphabetical {
                ScrollViewReader { scrollProxy in
                    ZStack {
                        List {
                            Section { //add new person button
                                Button {
                                    showingAddPersonSheet.toggle()
                                } label: {
                                    Label("Create New Person", systemImage: "plus")
                                }.sheet(isPresented: $showingAddPersonSheet) {
                                    EditPersonView()
                                }
                            }
                            
                            //First people who's last names don't have letters
                            let noLetterLastNames = allPeople.filter{$0.lastName.uppercased().filter(alphabetString.contains) == "" }.filter{(searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}
                            if noLetterLastNames.count > 0 {
                                Section(header: Text("*")) {
                                    ForEach(noLetterLastNames, id: \.self) { person in
                                        personListItem(person: person)
                                    }
                                }
                            }
                            //Now go through the letters
                            ForEach(alphabet, id: \.self) {letter in
                                let letterSet = allPeople.filter {$0.lastName.hasPrefix(letter)}.filter{(searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}
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
                    Section { //add new person button
                        Button {
                            showingAddPersonSheet.toggle()
                        } label: {
                            Label("Create New Person", systemImage: "plus")
                        }.sheet(isPresented: $showingAddPersonSheet) {
                            EditPersonView()
                        }
                    }
                    
                    //first go through the groups
                    ForEach(allGroups) {group in
                        let groupSet: [N40Person] = allPeople.filter{ $0.isInGroup(group)}.filter{(searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}
                        if groupSet.count > 0 {
                            Section(header: Text(group.name)) {
                                ForEach(groupSet) {person in
                                    personListItem(person: person)
                                }
                            }
                        }
                    }
                    //now go through ungrouped people
                    let ungroupedSet: [N40Person] = allPeople.filter{ $0.getGroups.count == 0}.filter{(searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}
                    if ungroupedSet.count > 0 {
                        Section(header: Text("Ungrouped People")) {
                            ForEach(ungroupedSet) {person in
                                personListItem(person: person)
                            }
                        }
                    }
                }.listStyle(.sidebar)
            }
            VStack{}
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Attach") {
                            if editEventView != nil {
                                editEventView!.setSelectedPeople(selectedPeople: selectedPeopleList)
                            } else if editGoalView != nil {
                                editGoalView!.setSelectedPeople(selectedPeople: selectedPeopleList)
                            } else if editGroupView != nil {
                                editGroupView!.setSelectedPeople(selectedPeople: selectedPeopleList)
                            } else if editNoteView != nil {
                                editNoteView!.setSelectedPeople(selectedPeople: selectedPeopleList)
                            }
                            dismiss()
                        }
                    }
                    
                }
            
        }.searchable(text: $searchText)
            
            
    }
    
    private func containsWholeGroup(groupSet: [N40Person]) -> Bool {
        for eachPerson in groupSet {
            if !selectedPeopleList.contains(eachPerson) {
                return false
            }
        }
        return true
    }
    
    
    private func personListItem (person: N40Person) -> some View {
        return HStack {
            Text(("\(person.title) \(person.firstName) \(person.lastName) \(person.company)").trimmingCharacters(in: .whitespacesAndNewlines))
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if selectedPeopleList.contains(person) {
                let index = selectedPeopleList.firstIndex(of: person)
                if index != nil {
                    selectedPeopleList.remove(at: index!)
                }
            } else {
                selectedPeopleList.append(person)
            }
        }
        .if(selectedPeopleList.contains(person)) {view in
            view.listRowBackground(Color(hex: "#8fb398") ?? Color.gray)
        }
    }
}

// ********************** SELECT GOAL VIEW ***************************
// A sheet that pops up where you can select people to be attached.

public struct SelectGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.priorityIndex, ascending: false)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "isCompleted == NO"), NSPredicate(format: "isArchived == NO")]), animation: .default)
    private var fetchedGoals: FetchedResults<N40Goal>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.priorityIndex, ascending: false)], predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "isCompleted == NO"), NSPredicate(format: "isArchived == YES")]), animation: .default)
    private var fetchedArchivedGoals: FetchedResults<N40Goal>
    
    var editEventView: EditEventView?
    var editGoalView: EditGoalView?
    var editGroupView: EditGroupView?
    var editNoteView: EditNoteView?
    
    @State private var showingArchivedGoals = false
    
    @State private var showingAddGoalSheet = false
    
    public var body: some View {
        ZStack {
            
            
            VStack {
                ZStack {
                    HStack {
                        Spacer()
                        Button {
                            showingArchivedGoals.toggle()
                        } label: {
                            HStack {
                                if showingArchivedGoals {
                                    Label("Archived Goals", systemImage: "archivebox.fill")
                                } else {
                                    Label("Current Goals", systemImage: "archivebox")
                                }
                                Image(systemName: "chevron.up.chevron.down")
                            }.padding()
                        }
                        Spacer()
                        
                    }
                    HStack{
                        Spacer()
                        Button("Close") {
                            dismiss()
                        }.padding()
                            .buttonStyle(.borderedProminent)
                    }
                }
                
                List {
                    Button {
                        showingAddGoalSheet.toggle()
                    } label: {
                        Label("Create New Goal", systemImage: "plus")
                    }.sheet(isPresented: $showingAddGoalSheet) {
                        EditGoalView()
                    }
                    if showingArchivedGoals {
                        ForEach(fetchedArchivedGoals.sorted(by: {$0.priorityIndex > $1.priorityIndex})) {goal in
                            goalBoard(goal)
                                .padding(.leading, goal.endGoalLayers == 3 ? 60 : goal.endGoalLayers == 2 ? 45 : goal.endGoalLayers == 1 ? 25 : 0)
                        }
                    } else {
                        ForEach(fetchedGoals.sorted(by: {$0.priorityIndex > $1.priorityIndex})) {goal in
                            goalBoard(goal)
                                .padding(.leading, goal.endGoalLayers == 3 ? 60 : goal.endGoalLayers == 2 ? 45 : goal.endGoalLayers == 1 ? 25 : 0)
                        }
                    }
                }
            }
        }
    }
    
    private func goalBoard(_ goal: N40Goal) -> some View {
        
        return VStack {
            
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(Color(hex: goal.color))
                    .opacity(0.65)
                    .frame(height: 50.0)
                VStack{
                    HStack{
                        Text(goal.name)
                        Spacer()
                    }
                    HStack{
                        if !goal.isCompleted {
                            if goal.hasDeadline {
                                Text("By: \(goal.deadline.dateOnlyToString())").font(.caption)
                                Spacer()
                            }
                        } else {
                            Text("Completed: \(goal.dateCompleted.dateOnlyToString())").font(.caption)
                            Spacer()
                        }
                    }
                }.padding(.horizontal)
                    .padding(.vertical, 5)
            }.onTapGesture {
                if editEventView != nil {
                    editEventView!.attachGoal(addGoal: goal)
                } else if editGoalView != nil {
                    editGoalView!.addEndGoal(newEndGoal: goal)
                } else if editNoteView != nil {
                    editNoteView!.attachGoal(addGoal: goal)
                } else if editGroupView != nil {
                    editGroupView!.attachGoal(addGoal: goal)
                }
                dismiss()
            }
            
        }
    }
    
}

