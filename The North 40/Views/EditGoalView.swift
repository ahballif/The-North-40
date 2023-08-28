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
        
        
    }
}

struct EditGoalView_Previews: PreviewProvider {
    static var previews: some View {
        EditGoalView(editGoal: nil)
    }
}
