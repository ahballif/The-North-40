//
//  NotesView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/28/23.
//

import SwiftUI

struct NotesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Note.date, ascending: true)])
    private var fetchedNotes: FetchedResults<N40Note>
    
    @State private var showingCreateSheet = false
    
    @State private var editNoteItem: N40Note? = nil
    
    
    var body: some View {
        VStack {
            Text("Notes")
                .font(.title)
            
            List {
                ForEach(fetchedNotes) {note in
                    Button(note.title) {
                        editNoteItem = note
                    }.foregroundColor(((colorScheme == .dark) ? .white : .black))
                        
                }.sheet(item: $editNoteItem) {item in
                    EditNoteView(editNote: item)
                }
                
                Button {
                    showingCreateSheet.toggle()
                } label: {
                    Label("Add Note", systemImage: "plus")
                }.sheet(isPresented: $showingCreateSheet) {
                    EditNoteView()
                }
            }
            
            
            
        }
    }
}



struct EditNoteView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    public var editNote: N40Note?
    
    @State private var title = ""
    @State private var information = ""
    @State private var date = Date()
    
    @State private var attachedPeople: [N40Person] = []
    @State private var attachedGoals: [N40Goal] = []
    
    @State private var showingAttachPeopleSheet = false
    @State private var showingAttachGoalSheet = false
    
    
    var body: some View {
        VStack {
            
            
            HStack{
                Button("Cancel") {dismiss()}
                Spacer()
                Text(editNote != nil ? "Edit Note" : "Create New Note")
                Spacer()
                Button("Done") {
                    saveNote()
                    dismiss()
                }
            }
            
            ScrollView {
                
                //title
                HStack {
                    TextField("Note Title", text: $title).font(.title2)
                    Spacer()
                }
                HStack {
                    
                    DatePicker(selection: $date) {
                        Text("Date: ")
                    }
                    Spacer()
                }
                
                
                TextEditor(text: $information)
                    .padding(.horizontal)
                    .shadow(color: .gray, radius: 5)
                    .frame(minHeight: 200)
                
                
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
                        SelectPeopleView(editNoteView: self)
                    }
                    
                        
                    
                }
                
                VStack {
                    HStack{
                        Text("Attached Goals:")
                            .font(.title3)
                        Spacer()
                    }
                    
                    ForEach(attachedGoals) { goal in
                        HStack {
                            Text(goal.name)
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
                        SelectGoalView(editNoteView: self)
                    }
                    
                        
                    
                }
                
                
            }
            
            
            
            
        }
        .padding()
            .onAppear {
                populateFields()
            }
    }
    
    func saveNote () {
        
        withAnimation {
            
            let newNote = editNote ?? N40Note(context: viewContext)
            
            newNote.title = title
            newNote.information = information
            newNote.date = date
            
            if editNote != nil {
                //We need to remove all the people and goals before we reattach any.
                let alreadyAttachedPeople = editNote?.getAttachedPeople ?? []
                let alreadyAttachedGoals = editNote?.getAttachedGoals ?? []
                
                alreadyAttachedPeople.forEach {person in
                    newNote.removeFromAttachedPeople(person)
                }
                alreadyAttachedGoals.forEach {goal in
                    newNote.removeFromAttachedGoals(goal)
                }
                
            }
            //Now add back only the ones that are selected.
            attachedPeople.forEach {person in
                newNote.addToAttachedPeople(person)
            }
            attachedGoals.forEach {goal in
                newNote.addToAttachedGoals(goal)
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
    
    func populateFields() {
        
        title = editNote?.title ?? ""
        information = editNote?.information ?? ""
        date = editNote?.date ?? Date()
        
        editNote?.attachedPeople?.reversed().forEach { person in
            attachedPeople.append(person as! N40Person)
        }
        editNote?.attachedGoals?.reversed().forEach { goal in
            attachedGoals.append(goal as! N40Goal)
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
            
            editNote?.removeFromAttachedPeople(removedPerson)
            
        }
    }
    
    public func attachGoal (addGoal: N40Goal)  {
        //attaches a goal to the attachedGoal array.
        attachedGoals.append(addGoal)
    }
    public func removeGoal (removedGoal: N40Goal) {
        let idx = attachedGoals.firstIndex(of: removedGoal) ?? -1
        if idx != -1 {
            attachedGoals.remove(at: idx)
            
            editNote?.removeFromAttachedGoals(removedGoal)
        }
    }
    
    private func deleteNote () {
        if (editNote != nil) {
            viewContext.delete(editNote!)
            
            do {
                try viewContext.save()
            }
            catch {
                // Handle Error
                print("Error info: \(error)")
            }
        } else {
            print("Cannot delete event because it has not been created yet. ")
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
    
    var editNoteView: EditNoteView
    
    var body: some View {
        List(fetchedPeople) {person in
            HStack {
                Text("\(person.firstName) \(person.lastName)")
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                editNoteView.attachPerson(addPerson: person)
                dismiss()
            }
            
        }
    }
}

// ********************** SELECT GOAL VIEW ***************************
// A sheet that pops up where you can select people to be attached.

fileprivate struct SelectGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.deadline, ascending: true)], animation: .default)
    private var fetchedGoals: FetchedResults<N40Goal>
    
    var editNoteView: EditNoteView
    
    var body: some View {
        List(fetchedGoals) {goal in
            HStack {
                Text(goal.name)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                editNoteView.attachGoal(addGoal: goal)
                dismiss()
            }
            
        }
    }
}
