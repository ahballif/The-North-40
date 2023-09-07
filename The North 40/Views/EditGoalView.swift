//
//  EditGoalView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/22/23.
//

import SwiftUI

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
    
    @State public var parentGoal: N40Goal? = nil
    @State private var showingChooseParentGoalSheet = false
    
    @State private var selectedColor: Color = Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 0.5) //start with a random color.
    
    @State var editGoal: N40Goal?
    
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
                .frame(maxHeight: 150)
            
            //Choosing date and time
            Toggle("Set Deadline", isOn: $hasDeadline)
            
            DatePicker("Deadline: ", selection: $deadline, displayedComponents: [.date])
            
            HStack {
                Spacer()
                Text("Color: ")
                ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
            }
            
            
            //Choosing Parent Goal
            HStack {
                Button("End Goal: \(parentGoal != nil ? parentGoal!.name : "No Parent Goal Selected")") {
                    showingChooseParentGoalSheet.toggle()
                }.sheet(isPresented: $showingChooseParentGoalSheet) {
                    SelectGoalView(editGoalView: self)
                }
            }
            
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
            
            newGoal.endGoal = parentGoal
            
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
        if parentGoal == nil {
            parentGoal = editGoal?.endGoal
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
            
            editGoal?.removeFromAttachedPeople(removedPerson)
            
        }
    }
    
    public func setParent(newParent: N40Goal?) {
        if newParent != nil {
            //Set the new parent
            parentGoal = newParent
        } else {
            //Remove the parent
            parentGoal = nil
        }
    }
    public func removeParent() {
        self.setParent(newParent: nil)
    }
    
}

// ********************** SELECT PEOPLE VIEW ***************************
// A sheet that pops up where you can select people to be attached.

fileprivate struct SelectPeopleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)], animation: .default)
    private var fetchedPeople: FetchedResults<N40Person>
    
    var editGoalView: EditGoalView
    
    var body: some View {
        List(fetchedPeople) {person in
            HStack {
                Text("\(person.firstName) \(person.lastName)")
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                editGoalView.attachPerson(addPerson: person)
                dismiss()
            }
            
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
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.deadline, ascending: true)], animation: .default)
    private var fetchedGoals: FetchedResults<N40Goal>
    
    var editGoalView: EditGoalView
    
    var body: some View {
        List {
            Button("No Parent") {
                editGoalView.removeParent()
                dismiss()
            }
            ForEach(fetchedGoals) {goal in
                if (goal != editGoalView.editGoal) {
                    HStack {
                        Text(goal.name)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editGoalView.setParent(newParent: goal)
                        dismiss()
                    }
                }
            }
        }
    }
}


