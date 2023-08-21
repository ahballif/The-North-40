//
//  EditEventView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/17/23.
//

import SwiftUI

struct EditEventView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State var editEvent: N40Event?
    
    
    private let contactOptions = [["In Person", "person.2.fill"],["Phone Call","phone.fill"],["Text Message","message"],["Social Media", "ellipsis.bubble"],["Email", "envelope"],["Other", "bubble.middle.top"]]
    
    private let eventTypeOptions = [["Reportable", "rectangle.and.pencil.and.ellipsis"], ["Non-Reportable","calendar.day.timeline.leading"], ["Radar Event", "dot.radiowaves.left.and.right"], ["To-Do", "checklist"]]
    
    @State private var eventTitle = ""
    @State private var location = ""
    
    @State private var information = "Event Description"
    private let placeholderString = "Event Description"
    
    @State private var isScheduled = true
    @State private var chosenStartDate = Date()
    @State private var duration = 0
    @State private var contactMethod = ["In Person", "person.2.fill"]
    @State private var eventType = ["Non-Reportable","calendar.day.timeline.leading"]
    
    
    var body: some View {
        VStack {
            
            if (editEvent == nil) {
                HStack{
                    Button("Cancel") {dismiss()}
                    Spacer()
                    Text(((editEvent == nil ? "Create New " : "Edit ") + (eventType != ["To-Do", "checklist"] ? "Event" : "To-Do")))
                    Spacer()
                    Button("Done") {
                        saveEvent()
                        dismiss()
                    }
                }
            }
            
            //Title of the event
            TextField("Event Title", text: $eventTitle).font(.title2)
            
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
            Toggle("Schedule Event", isOn: $isScheduled)
            
            DatePicker(selection: $chosenStartDate) {
                Text("When: ")
            }.disabled(!isScheduled)
            
            HStack {
                Text("Duration: \(duration) min")
                Spacer()
                Stepper("", value: $duration, in: 0...1440, step: 5)
            }
            
            HStack {
                Picker("Contact Method: ", selection: $contactMethod) {
                    ForEach(contactOptions, id: \.self) {
                        Label($0[0], systemImage: $0[1])
                    }
                }
                Spacer()
            }
            
            TextField("Location:", text: $location)
            
            
            HStack {
                Picker("Event Type: ", selection: $eventType) {
                    ForEach(eventTypeOptions, id: \.self) {
                        Label($0[0], systemImage: $0[1])
                    }
                }
                Spacer()
            }
            
            Spacer()
            
            
            
        }.padding()
            .onAppear { populateFields() }
            .toolbar {
                if (editEvent != nil) {
                    
                    ToolbarItemGroup {

                        Button("Done") {
                            saveEvent()
                            dismiss()
                        }
                    }
                    
                }
            }
        
            
        
        
    }
    
    private func populateFields() {
        
        eventTitle = editEvent?.name ?? ""
        self.location = editEvent?.location ?? ""
        
        self.information = editEvent?.information ?? "Event Description"
        
        self.isScheduled = editEvent?.isScheduled ?? true
        self.chosenStartDate = editEvent?.startDate ?? Date()
        self.duration = Int(editEvent?.duration ?? 0)
        self.contactMethod = contactOptions[Int(editEvent?.contactMethod ?? 0)]
        self.eventType = eventTypeOptions[Int(editEvent?.eventType ?? 0)]
    }
    
    private func saveEvent () {
        withAnimation {
            
            let toDoEvent = editEvent ?? N40Event(context: viewContext)
            
            
            toDoEvent.name = self.eventTitle
            if (self.eventTitle == "") {
                //This is where we would add up the attached people to figure out an event title name.
                
                //placeholder:
                toDoEvent.name = "Do Something"
            }
            
            toDoEvent.startDate = self.chosenStartDate
            toDoEvent.isScheduled = self.isScheduled
            toDoEvent.duration = Int16(self.duration)
            
            toDoEvent.location = self.location
            toDoEvent.information = self.information
            
            
            //finds the index representing the correct contact method and event type
            toDoEvent.contactMethod = Int16(self.contactOptions.firstIndex(of: contactMethod) ?? 0)
            toDoEvent.eventType = Int16(self.eventTypeOptions.firstIndex(of: eventType) ?? 1) //Make 1 the default for now
            
            
            toDoEvent.status = 0 // 0 represents hasn't been done yet
            
            
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
    
}


struct EditEvent_Previews: PreviewProvider {
    static var previews: some View {
        EditEventView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
