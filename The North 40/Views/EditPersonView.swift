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
    
    @State private var notes: String = ""
    
    @State private var birthday: Date = Date()
    @State private var hasBirthday: Bool = false
    
    @State private var isPresentingDeleteConfirm = false
    
    
    var body: some View {
        VStack {
            
            
            
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
            
            
            ScrollView {
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
                    
                    TextField("Phone Number 1", text: $phoneNumber1).keyboardType(.phonePad)
                        .onChange(of: phoneNumber1) {_ in
                            if phoneNumber1.filter("1234567890".contains).count == 10 {
                                phoneNumber1 = formatPhoneNumber(inputString: phoneNumber1)
                            } else if phoneNumber1.filter("1234567890".contains).count == 11 {
                                phoneNumber1 = formatPhoneNumber11(inputString: phoneNumber1)
                            } else {
                                phoneNumber1 = phoneNumber1.filter("1234567890".contains)
                            }
                        }
                    TextField("Phone Number 2", text: $phoneNumber2).keyboardType(.phonePad)
                        .onChange(of: phoneNumber2) {_ in
                            if phoneNumber2.filter("1234567890".contains).count == 10 {
                                phoneNumber2 = formatPhoneNumber(inputString: phoneNumber2)
                            } else if phoneNumber2.filter("1234567890".contains).count == 11 {
                                phoneNumber2 = formatPhoneNumber11(inputString: phoneNumber2)
                            } else {
                                phoneNumber2 = phoneNumber2.filter("1234567890".contains)
                            }
                        }
                    TextField("Email 1", text: $email1).keyboardType(.emailAddress)
                    TextField("Email 2", text: $email2).keyboardType(.emailAddress)
                    TextField("Social Media 1", text: $socialMedia1)
                    TextField("Social Media 2", text: $socialMedia2)
                    
                    
                    
                }.padding()
                
                HStack {
                    Text("Birthday: ")
                    Spacer()
                    if (!hasBirthday) {
                        Button {
                            hasBirthday = true
                        } label: {
                            Label("Add Birthday", systemImage: "plus")
                        }
                    } else {
                        DatePicker("", selection: $birthday, displayedComponents: .date)
                        Button(role: .destructive){
                            hasBirthday = false
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }.padding()
                
                VStack {
                    HStack {
                        Text("Event Description: ")
                        Spacer()
                    }
                    TextEditor(text: $notes)
                        .padding(.horizontal)
                        .shadow(color: .gray, radius: 5)
                        .frame(minHeight: 100)
                    
                    
                }
                
                
                
                if (editPerson != nil) {
                    Button(role: .destructive, action: {
                        isPresentingDeleteConfirm = true
                    }, label: {
                        Text("Delete Person")
                    }).confirmationDialog("Are you sure you want to delete this person?",
                                          isPresented: $isPresentingDeleteConfirm) {
                         Button("Delete Person", role: .destructive) {
                             viewContext.delete(editPerson!)
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
                         Text("Are you sure you want to delete this person?")
                     }
                }
                
            }
            
            
            
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
    
    
    private func savePerson () {
        withAnimation {
            
            let newPerson = editPerson ?? N40Person(context: viewContext)
            
            newPerson.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            newPerson.lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
            newPerson.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            
            newPerson.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
            
            newPerson.hasBirthday = hasBirthday
            newPerson.birthday = birthday
            newPerson.birthdayDay = Int16(birthday.get(.day))
            newPerson.birthdayMonth = Int16(birthday.get(.month))
            
            newPerson.notes = notes
            
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
        
        hasBirthday = editPerson?.hasBirthday ?? false
        birthday = editPerson?.birthday ?? Date()
        
        notes = editPerson?.notes ?? ""
        
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

// ----------- for formatting phone numbers
public func formatPhoneNumber(inputString: String) -> String {
    var pn = inputString.filter("0123456789".contains)
    if (pn.count == 10) {
        let pnIn = pn.split(separator: "")
        pn = "("+pnIn[0]+pnIn[1]+pnIn[2]+") "
        pn += pnIn[3]+pnIn[4]+pnIn[5]+"-"
        pn += pnIn[6]+pnIn[7]+pnIn[8]+pnIn[9]
    }
    return pn
}

public func formatPhoneNumber11(inputString: String) -> String {
    var pn = inputString.filter("0123456789".contains)
    if (pn.count == 11) {
        let pnIn = pn.split(separator: "")
        pn = pnIn[0]+" ("+pnIn[1]+pnIn[2]+pnIn[3]+") "
        pn += pnIn[4]+pnIn[5]+pnIn[6]+"-"
        pn += pnIn[7]+pnIn[8]+pnIn[9]+pnIn[10]
    }
    return pn
}
