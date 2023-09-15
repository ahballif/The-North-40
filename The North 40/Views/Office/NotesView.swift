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
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Note.date, ascending: true)], predicate: NSPredicate(format: "archived == NO"))
    private var fetchedNotes: FetchedResults<N40Note>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Note.date, ascending: true)], predicate: NSPredicate(format: "archived == YES"))
    private var fetchedArchivedNotes: FetchedResults<N40Note>
    
    @State private var showingCreateSheet = false
    
    @State private var editNoteItem: N40Note? = nil
    
    @State private var showingArchivedNotesSheet = false
    
    var body: some View {
        VStack {
            Text("Notes")
                .font(.title)
            
            List {
                ForEach(fetchedNotes) {note in
                    Button(note.title) {
                        editNoteItem = note
                    }.foregroundColor(((colorScheme == .dark) ? .white : .black))
                        .swipeActions {
                            Button {
                                note.archived = true
                                
                                do {
                                    try viewContext.save()
                                }
                                catch {
                                    // Handle Error
                                    print("Error info: \(error)")
                                }
                            } label: {
                                Label("Archive", systemImage: "Archive Box")
                            }.tint(.purple)
                        }
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
            
        
            .toolbar {
                Button {
                    showingArchivedNotesSheet.toggle()
                } label: {
                    Label("Archived", systemImage: "archivebox")
                }.sheet(isPresented: $showingArchivedNotesSheet) {
                    VStack {
                        HStack {
                            Text("Archived Notes").font(.title2)
                            Spacer()
                        }.padding()
                        List {
                            ForEach(fetchedArchivedNotes) {archiveNote in
                                Text(archiveNote.title)
                                    .swipeActions {
                                        Button {
                                            archiveNote.archived = false
                                        } label: {
                                            Label("Unarchive", systemImage: "arrowshape.left.fill")
                                        }.tint(.green)
                                    }
                            }
                        }
                    }
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
    
    @State private var showingOptionsSheet = false
    
    @State private var showingConfirmDelete = false
    
    var body: some View {
        VStack {
            
            
            HStack{
                Button("Cancel") {dismiss()}
                Spacer()
                Text(editNote != nil ? "Edit Note" : "Create New Note")
                Spacer()
                Button() {
                    showingConfirmDelete.toggle()
                } label: {
                    Image(systemName: "trash")
                }.confirmationDialog("Delete Note?", isPresented: $showingConfirmDelete) {
                    Button("Delete Note", role: .destructive) {
                        deleteNote()
                        
                    }
                } message: {
                    Text("Are you sure you want to delete this note?")
                }
                
                Button {
                    showingOptionsSheet.toggle()
                } label: {
                    Image(systemName: "paperclip")
                }.sheet(isPresented: $showingOptionsSheet) {
                    attachPeopleSheetView()
                }
                Button("Done") {
                    saveNote()
                    dismiss()
                }
            }
            
            
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
                .shadow(color: .gray, radius: 5)
            
            
            
            
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
    
    private func attachPeopleSheetView () -> some View {
        return VStack {
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
                        NavigationLink(destination: GoalDetailView(selectedGoal: goal)) {
                            Text(goal.name)
                        }.buttonStyle(.plain)
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
            Spacer()
        }
    }
    
}





// ********************** SELECT PEOPLE VIEW ***************************
// A sheet that pops up where you can select people to be attached.

fileprivate struct SelectPeopleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W", "X","Y", "Z"]
    let alphabetString = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)], animation: .default)
    private var fetchedPeople: FetchedResults<N40Person>
    
    var editNoteView: EditNoteView
    
    var body: some View {
        
        
        List{
            let noLetterLastNames = fetchedPeople.filter { $0.lastName.uppercased().filter(alphabetString.contains) == ""}
            if noLetterLastNames.count > 0 {
                Section(header: Text("*")) {
                    ForEach(noLetterLastNames, id: \.self) { person in
                        HStack {
                            Text((person.title == "" ? "" : "\(person.title) ") + "\(person.firstName) \(person.lastName)")
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
            ForEach(alphabet, id: \.self) { letter in
                let letterSet = fetchedPeople.filter { $0.lastName.hasPrefix(letter) }
                if (letterSet.count > 0) {
                    Section(header: Text(letter)) {
                        ForEach(letterSet, id: \.self) { person in
                            HStack {
                                Text((person.title == "" ? "" : "\(person.title) ") + "\(person.firstName) \(person.lastName)")
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
            }
        }.padding(.horizontal, 3)
    }
}

// ********************** SELECT GOAL VIEW ***************************
// A sheet that pops up where you can select people to be attached.

fileprivate struct SelectGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.priorityIndex, ascending: false)], animation: .default)
    private var fetchedGoals: FetchedResults<N40Goal>
    
    var editNoteView: EditNoteView
    
    var body: some View {
        List(fetchedGoals) {goal in
            goalBox(goal)
            .onTapGesture {
                editNoteView.attachGoal(addGoal: goal)
                dismiss()
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
