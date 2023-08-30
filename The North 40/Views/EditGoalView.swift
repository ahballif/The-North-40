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
    
    @State var editGoal: N40Goal?
    
    var body: some View {
        VStack {
            
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
            
            //Attaching people
            VStack {
                HStack{
                    Text("Attached People:")
                        .font(.title3)
                    Spacer()
                }
                
                ForEach(attachedPeople) { person in
                    HStack {
                        Text("\(person.firstName) \(person.lastName)")
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
            
            
            
            
            
            Spacer()
            
            
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
