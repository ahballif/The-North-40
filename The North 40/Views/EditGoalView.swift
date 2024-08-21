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
    
    @State private var showingColorPickerSheet = false
    
    @State private var selectedColor: Color = Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 0.5) //start with a random color.
    
    @State var editGoal: N40Goal?
    @State public var parentGoal: N40Goal?
    
    @State private var showOnCalendar = false
    
    @FocusState private var focusedField: FocusField?
    enum FocusField: Hashable {
        case title, body
    }
    
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
                .focused($focusedField, equals: .title)
            
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
                Button {
                    showingColorPickerSheet.toggle()
                } label: {
                    Rectangle().frame(width:30, height: 20)
                        .foregroundColor(selectedColor)
                }.sheet(isPresented: $showingColorPickerSheet) {
                    ColorPickerView(selectedColor: $selectedColor)
                }
            }
            
            Toggle("Make goal-specific calendar in Apple Calendar", isOn: $showOnCalendar)
            
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
                            Text(("\(person.title) \(person.firstName) \(person.lastName) \(person.company)").trimmingCharacters(in: .whitespacesAndNewlines))
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
                    SelectPeopleView(editGoalView: self, selectedPeopleList: attachedPeople)
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
            .onAppear { 
                populateFields()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.51) {  /// Anything over 0.5 seems to work
                    if editGoal == nil {
                        self.focusedField = .title
                    }
                }
            }
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
            
            newGoal.sharedToCalendar = showOnCalendar
            
            for goal in newGoal.getEndGoals {
                newGoal.removeFromEndGoals(goal)
            }
            for goal in endGoals {
                if goal != newGoal {
                    newGoal.addToEndGoals(goal)
                }
            }
            
            if editGoal == nil {
                newGoal.priorityIndex = getDefaultPriorityIndex()
            }
            
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
        
        showOnCalendar = editGoal?.sharedToCalendar ?? false
        
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
        if (!attachedPeople.contains(addPerson)) {
            attachedPeople.append(addPerson)
        }
    }
    
    public func removePerson(removedPerson: N40Person) {
        //removes a person from the attachedPeople array. (Used by the button on each list item)
        let idx = attachedPeople.firstIndex(of: removedPerson) ?? -1
        if idx != -1 {
            attachedPeople.remove(at: idx)
        }
    }
    
    public func setSelectedPeople(selectedPeople: [N40Person]) {
        //just resets the list to a new value
        attachedPeople = selectedPeople
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
        fetchGoalsRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "isCompleted == NO"), NSPredicate(format: "isArchived == NO")])
        
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

