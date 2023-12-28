//
//  PersonView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/22/23.
//

import SwiftUI

struct PersonDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    public var updater = RefreshView()
    
    @State var selectedPerson: N40Person
    @State private var selectedView = 0 //for diy tab view
    
    @State private var showingWhatToCreateConfirm = false
    @State private var editEventEventType = N40Event.NON_REPORTABLE_TYPE
    @State private var showingEditEventSheet = false
    @State private var showingEditNoteSheet = false
    
    
    @State private var photo: UIImage?
    @State private var showingFullImageSheet = false
    
    @State private var showingEditPersonSheet = false
    
    var body: some View {
        
        VStack {
            
            HStack {
                if photo != nil {
                    let croppedImage: UIImage = cropImageToSquare(image: photo!) ?? photo!
                    let photoImage: Image = Image(uiImage: croppedImage)
                    Button {
                        showingFullImageSheet.toggle()
                    } label: {
                        photoImage
                            .resizable()
                            .frame(width:75, height: 75)
                            .clipShape(Circle())
                    }.sheet(isPresented: $showingFullImageSheet) {
                        Image(uiImage: photo!) // don't crop it on the sheet
                            .resizable()
                            .scaledToFit()
                    }
                }
                Text(("\(selectedPerson.title) \(selectedPerson.firstName) \(selectedPerson.lastName) \(selectedPerson.company)").trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.title)
                Spacer()
                Button {
                    showingEditPersonSheet.toggle()
                } label: {
                    Image(systemName: "square.and.pencil.circle.fill")
                }.sheet(isPresented: $showingEditPersonSheet, onDismiss: loadImage) {
                    EditPersonView(editPerson: selectedPerson)
                }
            }
            .padding()
            .onAppear {
                loadImage()
            }
            .if(selectedPerson.hasFavoriteColor) {view in
                view.background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: selectedPerson.favoriteColor) ?? .clear)
                        .opacity(0.5)
                )
            }
            
            HStack {
                
                if (selectedView == 0) {
                    Button {
                        selectedView = 0
                    } label: {
                        Text("Info")
                            .frame(maxWidth: .infinity)
                    }
                    .font(.title2)
                    .buttonStyle(.borderedProminent)
                    
                } else {
                    Button {
                        selectedView = 0
                    } label: {
                        Text("Info")
                            .frame(maxWidth: .infinity)
                    }
                    .font(.title2)
                    .buttonStyle(.bordered)
                }
                
                
                if (selectedView == 1) {
                    Button {
                        selectedView = 1
                    } label: {
                        Text("Timeline")
                            .frame(maxWidth: .infinity)
                    }
                    .font(.title2)
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        selectedView = 1
                    } label: {
                        Text("Timeline")
                            .frame(maxWidth: .infinity)
                    }
                    .font(.title2)
                    .buttonStyle(.bordered)
                }
                
                
                
            }
            .padding()
            .frame(maxWidth: .infinity)
            
            
            if (selectedView==0) {
                PersonInfoView(selectedPerson: selectedPerson)
            } else if (selectedView==1) {
                ZStack {
                    TimelineView(person: selectedPerson).environmentObject(updater)
                    
                    
                    //The Add Button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            Button(action: {showingWhatToCreateConfirm.toggle()}) {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(Circle())
                                    .frame(minWidth: 50, maxWidth: 50)
                                    .padding(30)
                            }.confirmationDialog("chooseWhatToCreate", isPresented: $showingWhatToCreateConfirm) {
                                Button {
                                    //New TODO Item
                                    editEventEventType = N40Event.TODO_TYPE
                                    showingEditEventSheet.toggle()
                                } label: {
                                    let type = N40Event.EVENT_TYPE_OPTIONS[N40Event.TODO_TYPE]
                                    Label(type[0], systemImage: type[1])
                                }
                                Button {
                                    //("New Reportable Event")
                                    editEventEventType = N40Event.REPORTABLE_TYPE
                                    showingEditEventSheet.toggle()
                                } label: {
                                    let type = N40Event.EVENT_TYPE_OPTIONS[N40Event.REPORTABLE_TYPE]
                                    Label(type[0], systemImage: type[1])
                                }
                                Button {
                                    //("New Unreportable Event")
                                    editEventEventType = N40Event.NON_REPORTABLE_TYPE
                                    showingEditEventSheet.toggle()
                                } label: {
                                    let type = N40Event.EVENT_TYPE_OPTIONS[N40Event.NON_REPORTABLE_TYPE]
                                    Label(type[0], systemImage: type[1])
                                }
                                Button {
                                    //("New Note")
                                    showingEditNoteSheet.toggle()
                                } label: {
                                    Label("New Note", systemImage: "note.text.badge.plus")
                                }
                            } message: {
                                Text("What would you like to add?")
                            }
                            .sheet(isPresented: $showingEditEventSheet, onDismiss: {updater.updater.toggle()}) {
                                EditEventView(isScheduled: selectedView==1, eventType: N40Event.EVENT_TYPE_OPTIONS[editEventEventType], attachingPerson: selectedPerson)
                            }
                            .sheet(isPresented: $showingEditNoteSheet, onDismiss: {updater.updater.toggle()}) {
                                EditNoteView(attachingPerson: selectedPerson)
                            }
                            
                        }
                    }
                }
            }
            
            
            Spacer()
        }.if(selectedPerson.hasFavoriteColor) {view in
            view.background(Color(hex: selectedPerson.favoriteColor)?.opacity(0.25))
        }
        
        
    }
    
    private func loadImage() {
        //Load the image from data
        if selectedPerson.photo != nil {
            if let uiImage = UIImage(data: selectedPerson.photo!) {
                photo = uiImage
            } else {
                photo = nil
                print("Could not import contact photo")
            }
        } else {
            photo = nil
        }
    }
}

struct PersonInfoView: View {
    
    @ObservedObject var selectedPerson: N40Person
    
    
    
    var body: some View {
        VStack {
            ScrollView {
                
                
                
                if (selectedPerson.address != "") {
                    addressBar(contactInfoValue: selectedPerson.address, selectedPerson: selectedPerson)
                }
                if (selectedPerson.phoneNumber1 != "") {
                    phoneNumberBar(contactInfoValue: selectedPerson.phoneNumber1, selectedPerson: selectedPerson)
                }
                if (selectedPerson.phoneNumber2 != "") {
                    phoneNumberBar(contactInfoValue: selectedPerson.phoneNumber2, selectedPerson: selectedPerson)
                }
                if (selectedPerson.email1 != "") {
                    emailBar(contactInfoValue: selectedPerson.email1, selectedPerson: selectedPerson)
                }
                if (selectedPerson.email2 != "") {
                    emailBar(contactInfoValue: selectedPerson.email2, selectedPerson: selectedPerson)
                }
                if (selectedPerson.socialMedia1 != "") {
                    socialMediaBar(contactInfoValue: selectedPerson.socialMedia1, selectedPerson: selectedPerson)
                }
                if (selectedPerson.socialMedia2 != "") {
                    socialMediaBar(contactInfoValue: selectedPerson.socialMedia2, selectedPerson: selectedPerson)
                }
                
                if (selectedPerson.hasBirthday) {
                    HStack {
                        Text("\(selectedPerson.firstName)'s Birthday is \(selectedPerson.birthday.getMonthAndDayString())")
                        Spacer()
                    }.padding()
                }
                
                if (selectedPerson.notes != "") {
                    HStack {
                        Text(selectedPerson.notes)
                        Spacer()
                    }.padding()
                }
                
                if (selectedPerson.getGroups.count > 0) {
                    VStack {
                        HStack {
                            Text("Groups with this person: ").font(.title3)
                            Spacer()
                        }.padding(.vertical, 3)
                        ForEach(selectedPerson.getGroups) {eachGroup in
                            HStack {
                                Text(eachGroup.name)
                                Spacer()
                            }.padding(.vertical, 3)
                                .padding(.horizontal)
                        }
                    }.padding()
                }
                
            }
            
        }
        
        
    }
    
}

// *************** CONTACT BARS *******************
// For displaying and opening contact information.

private struct phoneNumberBar: View {
    var contactInfoValue: String
    var selectedPerson: N40Person
    @State private var showingAddContactSheet = false
    @State private var texting = false
    
    var body: some View {
        HStack {
            Text(contactInfoValue)
            Spacer()
            
            Button(action: {
                if UserDefaults.standard.bool(forKey: "addContactOnCall") {
                    texting = false
                    showingAddContactSheet.toggle()
                }
                guard let number = URL(string: "tel://" + contactInfoValue.filter("0123456789".contains)) else { return }
                UIApplication.shared.open(number)
            }){
                Label("", systemImage: "phone.fill")
            }
            Button(action: {
                if UserDefaults.standard.bool(forKey: "addContactOnCall") {
                    texting = true
                    showingAddContactSheet.toggle()
                }
                guard let number = URL(string: "sms://" + contactInfoValue.filter("0123456789".contains)) else { return }
                UIApplication.shared.open(number)
            }){
                Label("", systemImage: "message.fill")
            }
        }.padding()
            .sheet(isPresented: $showingAddContactSheet) {  [texting] in
                let method = texting ? ["Text Message","message"] : ["Phone Call","phone.fill"]
                EditEventView(contactMethod: method, eventType: N40Event.EVENT_TYPE_OPTIONS[N40Event.REPORTABLE_TYPE], attachingPerson: selectedPerson)
            }
    }
}

private struct emailBar: View {
    var contactInfoValue: String
    var selectedPerson: N40Person
    @State private var showingAddContactSheet = false
    
    var body: some View {
        HStack {
            Text(contactInfoValue)
            Spacer()
            
            Button(action: {
                if UserDefaults.standard.bool(forKey: "addContactOnCall") {
                    showingAddContactSheet.toggle()
                }
                guard let email = URL(string: "mailto:" + contactInfoValue) else { return }
                UIApplication.shared.open(email)
            }){
                Label("", systemImage: "envelope.fill")
            }
        }.padding()
            .sheet(isPresented: $showingAddContactSheet) {
                EditEventView(contactMethod: ["Email", "envelope"], eventType: N40Event.EVENT_TYPE_OPTIONS[N40Event.REPORTABLE_TYPE], attachingPerson: selectedPerson)
            }
    }
}

private struct socialMediaBar: View {
    var contactInfoValue: String
    var selectedPerson: N40Person
    @State private var showingAddContactSheet = false
    
    var body: some View {
        HStack {
            Text(contactInfoValue)
            Spacer()
            
            Button(action: {
                if UserDefaults.standard.bool(forKey: "addContactOnCall") {
                    showingAddContactSheet.toggle()
                }
                guard let social = URL(string: contactInfoValue) else { return }
                UIApplication.shared.open(social)
            }){
                Label("", systemImage: "ellipsis.bubble")
                
            }
        }.padding()
            .sheet(isPresented: $showingAddContactSheet) {
                EditEventView(contactMethod: ["Social Media", "ellipsis.bubble"], eventType: N40Event.EVENT_TYPE_OPTIONS[N40Event.REPORTABLE_TYPE], attachingPerson: selectedPerson)
            }
    }
}

private struct addressBar: View {
    var contactInfoValue: String
    var selectedPerson: N40Person
    @State private var showingAddContactSheet = false
    
    var body: some View {
        HStack {
            Text(contactInfoValue)
            Spacer()
            
            Button(action: {
                if UserDefaults.standard.bool(forKey: "addContactOnCall") {
                    showingAddContactSheet.toggle()
                }
                guard let address = URL(string: "https://www.google.com/maps/place/\(contactInfoValue.replacingOccurrences(of: " ", with: "+"))") else { return }
                UIApplication.shared.open(address)
            }) {
                Label("", systemImage: "map.fill")
            }
        }.padding()
            .sheet(isPresented: $showingAddContactSheet) {
                EditEventView(contactMethod: ["In Person", "person.2.fill"], eventType: N40Event.EVENT_TYPE_OPTIONS[N40Event.REPORTABLE_TYPE], attachingPerson: selectedPerson)
            }
    }
}



fileprivate extension Date {
    func getMonthAndDayString () -> String {
        
        // Create Date Formatter
        let dateFormatter = DateFormatter()
        
        // Set Date Format
        dateFormatter.dateFormat = "MMM d"
        
        // Convert Date to String
        return dateFormatter.string(from: self)
        
    }
}
