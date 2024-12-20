//
//  GroupsView.swift
//  The North 40
//
//  Created by Addison Ballif on 9/10/23.
//

import SwiftUI

struct GroupsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Group.name, ascending: true)], animation: .default)
    private var fetchedGroups: FetchedResults<N40Group>
    
    
    @State private var groupsArray: [N40Group] = []
    
    var body: some View {
        ZStack {
        
            VStack {
                HStack {
                    Text("Person Groups").font(.title2)
                    Spacer()
                }
                
                List {
                    ForEach(groupsArray, id: \.self) {group in
                        NavigationLink (destination: EditGroupView(editGroup: group)) {
                            Text(group.name)
                        }
                    }.onMove(perform: move)
                }.listStyle(.plain)
                    .toolbar {
                        EditButton()
                    }
                
                
            }.padding()
            
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    NavigationLink (destination: EditGroupView()) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(minWidth: 50, maxWidth: 50)
                            .padding(30)
                    }
                }
            }
                
        }
        .onAppear {
            groupsArray = fetchedGroups.reversed().sorted {
                $0.priorityIndex > $1.priorityIndex
            }
            redistributePriorityIndices()
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        groupsArray.move(fromOffsets: source, toOffset: destination)
        redistributePriorityIndices()
        
    }
    
    private func redistributePriorityIndices () {
        var nextPriorityIndex = groupsArray.count - 1
        
        groupsArray.forEach {group in
            group.priorityIndex = Int16(nextPriorityIndex)
            nextPriorityIndex -= 1
        }
        
        do {
            try viewContext.save()
        }
        catch {
            // Handle Error
            print("Error info: \(error)")
        }
    }
    
    
}


struct EditGroupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @State public var editGroup: N40Group? = nil
    
    @State private var name = ""
    @State private var information = ""
    
    
    @State private var attachedPeople: [N40Person] = []
    @State private var showingAttachPeopleSheet = false
    
    @State private var attachedGoals: [N40Goal] = []
    @State private var showingAttachGoalSheet = false
    
    @State private var showingAttachedGoalsSheet = false
    @State private var showingDeleteConfirm = false
    @State private var isDeleting = false
    
    var body: some View {
        VStack {
            VStack {
                
                TextField("Group Name", text: $name).font(.title2)
                    .onSubmit {
                        saveGroup()
                    }
                
                //            VStack {
                //                HStack {
                //                    Text("Description: ")
                //                    Spacer()
                //                }
                //                TextEditor(text: $information)
                //                    .padding(.horizontal)
                //                    .shadow(color: .gray, radius: 5)
                //                    .frame(minHeight: 75)
                //            }
                
                HStack{
                    Text("Attached People:")
                        .font(.title3)
                    Spacer()
                }
                
            }.padding()
                .navigationTitle(Text("Edit Group View"))
            
            List {
                ForEach(attachedPeople) { person in
                    
                    HStack {
                        NavigationLink(destination: PersonDetailView(selectedPerson: person)) {
                            Text(("\(person.title) \(person.firstName) \(person.lastName) \(person.company)").trimmingCharacters(in: .whitespacesAndNewlines))
                        }.buttonStyle(.plain)
                        
                        Spacer()
                        Button {
                            removePerson(removedPerson: person)
                        } label: {
                            Image(systemName: "multiply")
                        }.buttonStyle(.plain)
                    }
                }
                
                Button(action: {
                    showingAttachPeopleSheet.toggle()
                }) {
                    Label("Attach Person", systemImage: "plus").padding()
                }.sheet(isPresented: $showingAttachPeopleSheet) {
                    SelectPeopleView(editGroupView: self, selectedPeopleList: attachedPeople)
                }
            }.listStyle(.plain)
            .toolbar {
                if editGroup != nil {
                    Button {
                        showingDeleteConfirm.toggle()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .confirmationDialog("Delete Group?", isPresented: $showingDeleteConfirm) {
                        Button(role: .destructive) {
                            isDeleting = true
                            viewContext.delete(editGroup!)
                            
                            do {
                                try viewContext.save()
                            }
                            catch {
                                // Handle Error
                                print("Error info: \(error)")
                                
                            }
                            
                            dismiss()
                            
                        } label: {
                            Text("Delete Group?")
                        }
                    } message: {
                        Text("Are you sure you want to delete this group? ")
                    }
                }
                
                Button {
                    showingAttachedGoalsSheet.toggle()
                } label: {
                    Image(systemName: "paperclip")
                }.sheet(isPresented: $showingAttachedGoalsSheet) {
                    
                    VStack {
                        VStack {
                            HStack{
                                Text("Attached Goals:")
                                    .font(.title3)
                                Spacer()
                            }
                            
                            ForEach(attachedGoals) { goal in
                                HStack {
                                    NavigationLink(destination: GoalDetailView(selectedGoal: goal)) {
                                        Text(goal.name)
                                        
                                    }
                                    .buttonStyle(.plain)
                                        
                                    Spacer()
                                    Button {
                                        removeGoal(removedGoal: goal)
                                    } label: {
                                        Image(systemName: "multiply")
                                    }
                                }.padding()
                            }
                            
                            Button(action: {
                                showingAttachGoalSheet.toggle()
                            }) {
                                Label("Attach Goal", systemImage: "plus").padding()
                            }.sheet(isPresented: $showingAttachGoalSheet) {
                                SelectGoalView(editGroupView: self)
                            }
                            
                                
                            
                        }
                        
                        Spacer()
                    }.padding()
                }
                
                
            }
            
            
            
            
            
        }.onAppear {
            populateFields()
        }
    }
    
    
    public func attachPerson(addPerson: N40Person) {
        //attaches a person to the attachedPeople array. (Used by the SelectPeopleView
        if (!attachedPeople.contains(addPerson)) {
            attachedPeople.append(addPerson)
        }
        saveGroup()
    }
    
    public func removePerson(removedPerson: N40Person) {
        //removes a person from the attachedPeople array. (Used by the button on each list item)
        let idx = attachedPeople.firstIndex(of: removedPerson) ?? -1
        if idx != -1 {
            attachedPeople.remove(at: idx)
        }
        saveGroup()
    }
    
    public func setSelectedPeople(selectedPeople: [N40Person]) {
        //just resets the list to a new value
        attachedPeople = selectedPeople
        saveGroup()
    }
    
    public func attachGoal (addGoal: N40Goal)  {
        //attaches a goal to the attachedGoal array.
        attachedGoals.append(addGoal)
        saveGroup()
    }
    public func removeGoal (removedGoal: N40Goal) {
        let idx = attachedGoals.firstIndex(of: removedGoal) ?? -1
        if idx != -1 {
            attachedGoals.remove(at: idx)
        }
        saveGroup()
    }
    
    private func populateFields() {
        if editGroup != nil {
            name = editGroup?.name ?? ""
            information = editGroup?.information ?? ""
            
            
            attachedPeople = []
            attachedGoals = []
            
            editGroup?.people?.forEach {person in
                attachedPeople.append(person as! N40Person)
            }
            editGroup?.goals?.forEach {goal in
                attachedGoals.append(goal as! N40Goal)
            }
        }
    }
    
    private func saveGroup () {
        withAnimation {
            
            let newGroup = editGroup ?? N40Group(context: viewContext)
            
            if editGroup == nil {editGroup = newGroup}
            
            newGroup.name = self.name
            newGroup.information = self.information
            
            if self.name == "" {
                newGroup.name = "Untitled Group"
            }
            
            if editGroup != nil {
                //We need to remove all the people and goals before we reattach any.
                let alreadyAttachedPeople = editGroup?.getPeople ?? []
                let alreadyAttachedGoals = editGroup?.getGoals ?? []
                
                alreadyAttachedPeople.forEach {person in
                    newGroup.removeFromPeople(person)
                }
                alreadyAttachedGoals.forEach {goal in
                    newGroup.removeFromGoals(goal)
                }
                
            }
            //Now add back only the ones that are selected.
            attachedPeople.forEach {person in
                newGroup.addToPeople(person)
            }
            attachedGoals.forEach {goal in
                newGroup.addToGoals(goal)
            }
            
            do {
                try viewContext.save()
            }
            catch {
                // Handle Error
                print("Error info: \(error)")
                
            }
            
            
        }
    }
    
}


