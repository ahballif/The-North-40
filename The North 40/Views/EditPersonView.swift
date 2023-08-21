//
//  AddPersonView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

import SwiftUI

struct EditPersonView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State var editPerson: N40Person?
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var title: String = ""
    
    @State private var address: String = ""
    
    @State private var phoneNumber1: String = ""
    @State private var phoneNumber2: String = ""
    @State private var email1: String = ""
    @State private var email2: String = ""
    @State private var socialMedia1: String = ""
    @State private var socialMedia2: String = ""
    
    
    var body: some View {
        VStack {
            
            Button("Load from Contacts", action: loadFromContacts)
            
            if (editPerson == nil) {
                HStack{
                    Button("Cancel") {dismiss()}
                    Spacer()
                    Text("Add Person")
                    Spacer()
                    Button("Done") {
                        savePerson()
                        dismiss()
                    }
                }
            }
            
            //photo line
            HStack {
                
                
                
                
                Spacer()
                Text("(Picture of someone)")
            }.padding()
            
            // Information Lines
            VStack {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                
                TextField("Title", text: $title)
            }.padding()
            
            TextField("Address", text: $address).padding()
            
            VStack {
                
                TextField("Phone Number 1", text: $phoneNumber1)
                TextField("Phone Number 2", text: $phoneNumber2)
                TextField("Email 1", text: $email1)
                TextField("Email 2", text: $email2)
                TextField("Social Media 1", text: $socialMedia1)
                TextField("Social Media 2", text: $socialMedia2)
            
                
                
            }.padding()
            
            
            Spacer()
            
            
        }.padding()
            .onAppear { populateFields() }
            .toolbar {
                if (editPerson != nil) {
                    
                    ToolbarItemGroup {
                        Text("Edit Person")
                        Spacer()
                        Button("Done") {
                            savePerson()
                            dismiss()
                        }
                    }
                    
                }
            }
    }
    
    private func loadFromContacts () {
        
    }
    
    
    private func savePerson () {
        withAnimation {
            
            let newPerson = editPerson ?? N40Person(context: viewContext)
            
            newPerson.firstName = firstName
            newPerson.lastName = lastName
            newPerson.title = title
            
            newPerson.address = address
            
            newPerson.phoneNumber1 = phoneNumber1
            newPerson.phoneNumber2 = phoneNumber2
            newPerson.email1 = email1
            newPerson.email2 = email2
            newPerson.socialMedia1 = socialMedia1
            newPerson.socialMedia2 = socialMedia2
            
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
        
        firstName = editPerson?.firstName ?? ""
        lastName = editPerson?.lastName ?? ""
        title = editPerson?.title ?? ""
        
        address = editPerson?.address ?? ""
        
        phoneNumber1 = editPerson?.phoneNumber1 ?? ""
        phoneNumber2 = editPerson?.phoneNumber2 ?? ""
        email1 = editPerson?.email1 ?? ""
        email2 = editPerson?.email2 ?? ""
        socialMedia1 = editPerson?.socialMedia1 ?? ""
        socialMedia2 = editPerson?.socialMedia2 ?? ""
        
        
    }
    
    
}

struct AddPersonView_Previews: PreviewProvider {
    static var previews: some View {
        EditPersonView()
    }
}



