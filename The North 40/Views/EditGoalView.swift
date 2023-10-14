//
//  EditGoalView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/22/23.
//

import SwiftUI
import CoreData

private let placeholderString = "Event Description"

struct EditGoalView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @State private var name = ""
    @State private var deadline = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date()) ?? Date()
    @State private var hasDeadline = false
    
    @State private var information = placeholderString
    
    @State private var attachedPeople: [N40Person] = []
    @State private var showingAttachPeopleSheet = false
    
    @State private var isPresentingDeleteConfirm = false
    
    @State public var endGoals: [N40Goal] = []
    @State private var showingChooseParentGoalSheet = false
    
    @State private var selectedColor: Color = Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 0.5) //start with a random color.
    
    @State var editGoal: N40Goal?
    @State public var parentGoal: N40Goal?
    
    var body: some View {
        ScrollView {
            
            if (editGoal == nil) {
                HStack{
                    Button("Cancel") {dismiss()}
                    Spacer()
                    Text("Create New Goal")
                    Spacer()
                    Button("Done") {
                        saveGoal()
                        dismiss()
                    }
                }
            }
            
            //Title of the event
            TextField("Goal Title", text: $name).font(.title2)
            
            TextEditor(text: $information)
                .foregroundColor(self.information == placeholderString ? .secondary : .primary)
                .onTapGesture {
                    if self.information == placeholderString {
                        self.information = ""
                    }
                }
                .padding(.horizontal)
                .frame(minHeight: 150)
            
            //Choosing date and time
            Toggle("Set Deadline", isOn: $hasDeadline)
            
            DatePicker("Deadline: ", selection: $deadline, displayedComponents: [.date])
            
            HStack {
                Spacer()
                Text("Color: ")
                ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
            }
            
            
            VStack {
                HStack{
                    Text("End Goals:")
                        .font(.title3)
                    Spacer()
                }
                
                ForEach(endGoals) { eachEndGoal in
                    HStack {
                        NavigationLink(destination: GoalDetailView(selectedGoal: eachEndGoal)) {
                            Text("\(eachEndGoal.name)")
                        }.buttonStyle(.plain)
                        Spacer()
                        Button {
                            removeParent(endGoal: eachEndGoal)
                        } label: {
                            Image(systemName: "multiply")
                        }
                    }.padding()
                }
                
                Button(action: {
                    showingChooseParentGoalSheet.toggle()
                }) {
                    Label("Add End Goal", systemImage: "plus").padding()
                }.sheet(isPresented: $showingChooseParentGoalSheet) {
                    SelectGoalView(editGoalView: self)
                }
                    
                
            }.padding(.vertical)
            
            //Attaching people
            VStack {
                HStack{
                    Text("Attached People:")
                        .font(.title3)
                    Spacer()
                }
                
                ForEach(attachedPeople) { person in
                    HStack {
                        NavigationLink(destination: PersonDetailView(selectedPerson: person)) {
                            Text((person.title == "" ? "\(person.firstName)" : "\(person.title)") + " \(person.lastName)")
                        }.buttonStyle(.plain)
                        Spacer()
                        Button {
                            removePerson(removedPerson: person)
                        } label: {
                            Image(systemName: "multiply")
                        }
                    }.padding()
                }
                
                Button(action: {
                    showingAttachPeopleSheet.toggle()
                }) {
                    Label("Attach Person", systemImage: "plus").padding()
                }.sheet(isPresented: $showingAttachPeopleSheet) {
                    SelectPeopleView(editGoalView: self)
                }
                
                    
                
            }.padding(.vertical)
            
            
            if (editGoal != nil) {
                Button(role: .destructive, action: {
                    isPresentingDeleteConfirm = true
                }, label: {
                    Text("Delete Goal")
                }).confirmationDialog("Are you sure you want to delete this goal?",
                                      isPresented: $isPresentingDeleteConfirm) {
                     Button("Delete Goal", role: .destructive) {
                         viewContext.delete(editGoal!)
                         do {
                             try viewContext.save()
                         }
                         catch {
                             // Handle Error
                             print("Error info: \(error)")
                         }
                         
                         dismiss()
                     }
                 } message: {
                     Text("Are you sure you want to delete this goal?")
                 }
            }
            
            
            
            
            
            
        }.padding()
            .onAppear { populateFields() }
            .toolbar {
                if (editGoal != nil) {
                    
                    ToolbarItemGroup {
                        Text("Edit Goal")
                        Spacer()
                        Button("Done") {
                            saveGoal()
                            dismiss()
                        }
                    }
                    
                }
            }
    }
    
    
    func saveGoal () {
        
        withAnimation {
            
            let newGoal = editGoal ?? N40Goal(context: viewContext)
            
            newGoal.name = name
            newGoal.information = information
            newGoal.hasDeadline = hasDeadline
            newGoal.deadline = deadline.endOfDay
            
            if editGoal != nil {
                //We need to remove all the people and goals before we reattach any.
                let alreadyAttachedPeople = editGoal?.getAttachedPeople ?? []
                
                alreadyAttachedPeople.forEach {person in
                    newGoal.removeFromAttachedPeople(person)
                }
                
                
                
            }
            //Now add back only the ones that are selected.
            attachedPeople.forEach {person in
                newGoal.addToAttachedPeople(person)
            }
            
            newGoal.color = selectedColor.toHex() ?? "#40BF50"
            
            for goal in newGoal.getEndGoals {
                newGoal.removeFromEndGoals(goal)
            }
            for goal in endGoals {
                newGoal.addToEndGoals(goal)
            }
            
            newGoal.priorityIndex = getDefaultPriorityIndex()
            
            
            // To save the new entity to the persistent store, call
            // save on the context
            do {
                try viewContext.save()
            }
            catch {
                // Handle Error
                print("Error info: \(error)")
                
            }
            
        }
        
        
    }
    
    func populateFields() {
        
        name = editGoal?.name ?? ""
        information = editGoal?.information ?? placeholderString
        hasDeadline = editGoal?.hasDeadline ?? false
        deadline = editGoal?.deadline ?? (Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date()) ?? Date())
       
        if editGoal != nil {
            selectedColor = Color(hex: editGoal?.color ?? "#40BF50") ?? Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 0.5)
        } else {
            selectedColor = Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 1.0)
        }
        
        endGoals = []
        for endGoal in editGoal?.getEndGoals ?? [] {
            endGoals.append(endGoal)
        }
        if parentGoal != nil {
            endGoals.append(parentGoal!)
        }
        
        editGoal?.attachedPeople?.forEach {person in
            attachedPeople.append(person as! N40Person)
        }
        
        
    }
    
    public func attachPerson(addPerson: N40Person) {
        //attaches a person to the attachedPeople array. (Used by the SelectPeopleView
        attachedPeople.append(addPerson)
    }
    
    public func removePerson(removedPerson: N40Person) {
        //removes a person from the attachedPeople array. (Used by the button on each list item)
        let idx = attachedPeople.firstIndex(of: removedPerson) ?? -1
        if idx != -1 {
            attachedPeople.remove(at: idx)
        }
    }
    
    public func addEndGoal(newEndGoal: N40Goal) {
        endGoals.append(newEndGoal)
    }
    public func removeParent(endGoal: N40Goal) {
        let idx = endGoals.firstIndex(of: endGoal) ?? -1
        if idx != -1 {
            endGoals.remove(at: idx)
        }
    }
    
    private func getDefaultPriorityIndex () -> Int16 {
        let fetchGoalsRequest: NSFetchRequest<N40Goal> = N40Goal.fetchRequest()
        fetchGoalsRequest.sortDescriptors = [NSSortDescriptor(keyPath: \N40Goal.priorityIndex, ascending: false)]
        fetchGoalsRequest.predicate = NSPredicate(format: "isCompleted == NO")
        
        var answer = 0
        
        do {
            // Peform Fetch Request
            let allGoals = try viewContext.fetch(fetchGoalsRequest)
            
            answer = allGoals.count
        } catch {
            print("couldn't fetch goals")
        }
        
        return Int16(answer)
    }
    
}

// ********************** SELECT PEOPLE VIEW ***************************
// A sheet that pops up where you can select people to be attached.

fileprivate struct SelectPeopleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W", "X","Y", "Z"]
    let alphabetString = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    @State private var sortingAlphabetical = false
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Group.priorityIndex, ascending: false)], animation: .default)
    private var allGroups: FetchedResults<N40Group>
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)], animation: .default)
    private var fetchedPeople: FetchedResults<N40Person>
    
    var editGoalView: EditGoalView
    
    @State private var searchText: String = ""
    @State private var isArchived = false
    
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Sort all alphabetically: ")
                    Spacer()
                    Toggle("sortAlphabetically", isOn: $sortingAlphabetical).labelsHidden()
                }.padding()
                
                if sortingAlphabetical {
                    
                    List{
                        let noLetterLastNames = fetchedPeople.reversed().filter { $0.lastName.uppercased().filter(alphabetString.contains) == "" && $0.isArchived == isArchived && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}.sorted { $0.lastName < $1.lastName }
                        if noLetterLastNames.count > 0 {
                            Section(header: Text("*")) {
                                ForEach(noLetterLastNames, id: \.self) { person in
                                    personListItem(person: person)
                                }
                            }
                        }
                        ForEach(alphabet, id: \.self) { letter in
                            let letterSet = fetchedPeople.reversed().filter { $0.lastName.hasPrefix(letter) && $0.isArchived == isArchived && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}.sorted { $0.lastName < $1.lastName }
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
                            let groupSet: [N40Person] = group.getPeople.filter{ $0.isArchived == isArchived && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}
                            if groupSet.count > 0 {
                                Section(header: Text(group.name)) {
                                    ForEach(groupSet) {person in
                                        personListItem(person: person)
                                    }
                                }
                            }
                        }
                        let ungroupedSet = fetchedPeople.reversed().filter { $0.isArchived == isArchived && $0.getGroups.count < 1 && (searchText == "" || $0.getFullName.uppercased().contains(searchText.uppercased()))}.sorted {$0.lastName < $1.lastName}
                        if ungroupedSet.count > 0 {
                            Section(header: Text("Ungrouped People")) {
                                ForEach(ungroupedSet) {person in
                                    personListItem(person: person)
                                }
                            }
                        }
                    }.listStyle(.sidebar)
                }
                
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
            editGoalView.attachPerson(addPerson: person)
            dismiss()
        }
    }
}

struct EditGoalView_Previews: PreviewProvider {
    static var previews: some View {
        EditGoalView(editGoal: nil)
    }
}

// ********************** SELECT GOAL VIEW ***************************
// (This version is meant for pulling up from the parent Goal's perspective.

// A sheet that pops up where you can select people to be attached.

fileprivate struct SelectGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.priorityIndex, ascending: false)], predicate: NSPredicate(format: "isCompleted == NO"), animation: .default)
    private var fetchedGoals: FetchedResults<N40Goal>
    
    var editGoalView: EditGoalView
    
    var body: some View {
        List {
            ForEach(fetchedGoals) {goal in
                if (goal != editGoalView.editGoal) {
                    if goal.getEndGoals.count == 0 {
                        goalBox(goal)
                            .onTapGesture {
                                editGoalView.addEndGoal(newEndGoal: goal)
                                dismiss()
                            }
                        ForEach(goal.getSubGoals, id: \.self) {subGoal in
                            if !subGoal.isCompleted && (subGoal != editGoalView.editGoal) {
                                goalBox(subGoal)
                                    .padding(.leading, 25.0)
                                    .onTapGesture {
                                        editGoalView.addEndGoal(newEndGoal: subGoal)
                                        dismiss()
                                    }
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


