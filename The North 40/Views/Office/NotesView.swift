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
    
    @State private var sortBy: SortByOptions = .alphabetical
    enum SortByOptions: Hashable {
        case alphabetical, date
    }
    
    var body: some View {
        VStack {
            ZStack {
                
                List {
                    let sortedNotes = sortBy == .date ? fetchedNotes.sorted {$0.date < $1.date} : fetchedNotes.sorted{$0.title < $1.title}
                    
                    ForEach(sortedNotes) {note in
                        Button(note.title) {
                            editNoteItem = note
                        }.foregroundColor(((colorScheme == .dark) ? .white : .black))
                            .swipeActions {
                                Button(role: .destructive) {
                                    note.archived = true
                                    
                                    do {
                                        try viewContext.save()
                                    }
                                    catch {
                                        // Handle Error
                                        print("Error info: \(error)")
                                    }
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }.tint(.purple)
                            }
                            .contextMenu {
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
                                    Label("Archive", systemImage: "archivebox")
                                }
                            }
                    }.sheet(item: $editNoteItem) {item in
                        EditNoteView(editNote: item)
                    }
                }
                
                //The add goal button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        Button(action: {showingCreateSheet.toggle()}) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .clipShape(Circle())
                                .frame(minWidth: 50, maxWidth: 50)
                                .padding(30)
                        }
                        .sheet(isPresented: $showingCreateSheet) {
                            EditNoteView()
                        }
                    }
                }
                .navigationTitle("Notes")
                
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    
                    Button {
                        showingArchivedNotesSheet.toggle()
                    } label: {
                        Label("Archived", systemImage: "archivebox")
                    }.sheet(isPresented: $showingArchivedNotesSheet) {
                        NavigationView {
                            VStack {
                                HStack {
                                    Text("Archived Notes").font(.title2)
                                    Spacer()
                                    Button {
                                        if sortBy == .date {
                                            sortBy = .alphabetical
                                        } else {
                                            sortBy = .date
                                        }
                                    } label: {
                                        if sortBy == .date {
                                            Image(systemName: "a.square")
                                        }  else {
                                            Image(systemName: "calendar.badge.clock")
                                        }
                                    }
                                }.padding()
                                List {
                                    let sortedArchivedNotes = sortBy == .date ? fetchedArchivedNotes.sorted {$0.date < $1.date} : fetchedArchivedNotes.sorted{$0.title < $1.title}
                                    
                                    ForEach(sortedArchivedNotes) {archiveNote in
                                        NavigationLink(destination: EditNoteView(editNote: archiveNote)) {
                                            HStack {
                                                Text(archiveNote.title)
                                                Spacer()
                                                Text(archiveNote.date.dateOnlyToString())
                                            }
                                        }
                                        .swipeActions {
                                            Button(role: .destructive) {
                                                archiveNote.archived = false
                                            } label: {
                                                Label("Unarchive", systemImage: "arrowshape.left.fill")
                                            }.tint(.green)
                                        }
                                        .contextMenu {
                                            Button {
                                                archiveNote.archived = false
                                            } label: {
                                                Label("Unarchive", systemImage: "arrowshape.left.fill")
                                            }.foregroundColor(.black)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    
                    Button {
                        if sortBy == .date {
                            sortBy = .alphabetical
                        } else {
                            sortBy = .date
                        }
                    } label: {
                        if sortBy == .date {
                            Image(systemName: "a.square")
                        }  else {
                            Image(systemName: "calendar.badge.clock")
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
    
    public var attachingPerson: N40Person?
    public var attachingGoal: N40Goal?
    
    @State private var title = ""
    @State private var information = ""
    @State private var date = Date()
    
    @State private var attachedPeople: [N40Person] = []
    @State private var attachedGoals: [N40Goal] = []
    
    @State private var showingAttachPeopleSheet = false
    @State private var showingAttachGoalSheet = false
    
    @State private var showingOptionsSheet = false
    
    @State private var showingConfirmDelete = false
    
    @FocusState private var focusedField: FocusField?
    enum FocusField: Hashable {
        case title, body
    }
    
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
                    .focused($focusedField, equals: .title)
                              
                Spacer()
            }
            HStack {
                
                DatePicker(selection: $date) {
                    Text("Date: ")
                }
                Spacer()
            }
            
            TextEditor(text: $information)
                .focused($focusedField, equals: .body)
                          
                //.shadow(color: .gray, radius: 5)
            
            
            
            
        }
        .padding()
            .onAppear {
                populateFields()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.51) {  /// Anything over 0.5 seems to work
                    if editNote == nil {
                        self.focusedField = .title
                    } // else { //I didn't like having it auto focus when the note was already created
//                        if title == "" {
//                            self.focusedField = .title
//                        } else {
//                            self.focusedField = .body
//                        }
//                    }
                }
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
        
        if editNote == nil {
            //This is for if you create an event from a timeline view.
            if attachingGoal != nil {
                attachedGoals.append(attachingGoal!)
            }
            if attachingPerson != nil {
                attachedPeople.append(attachingPerson!)
            }
 
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
            
            editNote?.removeFromAttachedPeople(removedPerson)
            
        }
    }
    
    public func setSelectedPeople(selectedPeople: [N40Person]) {
        //just resets the list to a new value
        attachedPeople = selectedPeople
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
                    SelectPeopleView(editNoteView: self, selectedPeopleList: attachedPeople)
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
        }.padding()
    }
    
}
