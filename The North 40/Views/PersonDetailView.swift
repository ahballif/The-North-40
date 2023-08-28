//
//  PersonView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/22/23.
//

import SwiftUI

struct PersonDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var selectedPerson: N40Person
    @State private var selectedView = 0 //for diy tab view
    
    @State private var showingEditEventSheet = false
    
    var body: some View {
        
        NavigationView {
            VStack {
                
                ZStack {
                    Text(("\(selectedPerson.title) " + "\(selectedPerson.firstName) \(selectedPerson.lastName)"))
                        .font(.title)
                    HStack {
                        Spacer()
                        NavigationLink(destination: EditPersonView(editPerson: selectedPerson)) {
                            Label("", systemImage: "pencil")
                        }
                    }.padding()
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
                        TimelineView(events: selectedPerson.getTimelineEvents)
                        
                        
                        //The Add Button
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                
                                Button(action: {showingEditEventSheet.toggle()}) {
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(Circle())
                                        .frame(minWidth: 50, maxWidth: 50)
                                        .padding(30)
                                }
                                .sheet(isPresented: $showingEditEventSheet) {
                                    EditEventView(attachingPerson: selectedPerson)
                                }
                            }
                        }
                    }
                }
                
                
                Spacer()
            }
            
        }
    }
}

struct PersonInfoView: View {
    
    @ObservedObject var selectedPerson: N40Person
    
    
    
    var body: some View {
        VStack {
            ScrollView {
                if (selectedPerson.address != "") {
                    addressBar(contactInfoValue: selectedPerson.address)
                }
                if (selectedPerson.phoneNumber1 != "") {
                    phoneNumberBar(contactInfoValue: selectedPerson.phoneNumber1)
                }
                if (selectedPerson.phoneNumber2 != "") {
                    phoneNumberBar(contactInfoValue: selectedPerson.phoneNumber2)
                }
                if (selectedPerson.email1 != "") {
                    emailBar(contactInfoValue: selectedPerson.email1)
                }
                if (selectedPerson.email2 != "") {
                    emailBar(contactInfoValue: selectedPerson.email2)
                }
                if (selectedPerson.socialMedia1 != "") {
                    socialMediaBar(contactInfoValue: selectedPerson.socialMedia1)
                }
                if (selectedPerson.socialMedia2 != "") {
                    socialMediaBar(contactInfoValue: selectedPerson.socialMedia2)
                }
            }
            
        }
        
        
    }
    
}

// *************** CONTACT BARS *******************
// For displaying and opening contact information.

private struct phoneNumberBar: View {
    var contactInfoValue: String
    
    var body: some View {
        HStack {
            Text(contactInfoValue)
            Spacer()
            
            Button(action: {
                guard let number = URL(string: "tel://" + contactInfoValue.filter("0123456789".contains)) else { return }
                UIApplication.shared.open(number)
            }){
                Label("", systemImage: "phone.fill")
            }
            Button(action: {
                guard let number = URL(string: "sms://" + contactInfoValue.filter("0123456789".contains)) else { return }
                UIApplication.shared.open(number)
            }){
                Label("", systemImage: "message.fill")
            }
        }.padding()
    }
}

private struct emailBar: View {
    var contactInfoValue: String
    
    var body: some View {
        HStack {
            Text(contactInfoValue)
            Spacer()
            
            Button(action: {
                guard let email = URL(string: "mailto:" + contactInfoValue) else { return }
                UIApplication.shared.open(email)
            }){
                Label("", systemImage: "envelope.fill")
            }
        }.padding()
    }
}

private struct socialMediaBar: View {
    var contactInfoValue: String
    
    var body: some View {
        HStack {
            Text(contactInfoValue)
            Spacer()
            
            Button(action: {
                guard let social = URL(string: contactInfoValue) else { return }
                UIApplication.shared.open(social)
            }){
                Label("", systemImage: "ellipsis.bubble")
                
            }
        }.padding()
    }
}

private struct addressBar: View {
    var contactInfoValue: String
    
    var body: some View {
        HStack {
            Text(contactInfoValue)
            Spacer()
            
            Button(action: {
                guard let address = URL(string: "https://www.google.com/maps/place/\(contactInfoValue.replacingOccurrences(of: " ", with: "+"))") else { return }
                UIApplication.shared.open(address)
            }) {
                Label("", systemImage: "map.fill")
            }
        }.padding()
    }
}



