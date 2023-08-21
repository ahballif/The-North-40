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
    @State var selectedView = 0 //for diy tab view
    
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
                    PersonTimelineView(selectedPerson: selectedPerson)
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

struct PersonTimelineView: View {
    
    var selectedPerson: N40Person
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(selectedPerson.getTimelineEvents) { eachEvent in
                    eventDisplayBoxView(myEvent: eachEvent)
                }
            }
        }
    }
}

private struct eventDisplayBoxView: View {
    
    @State var myEvent: N40Event
    
    var body: some View {
        NavigationLink(destination: EditEventView(editEvent: myEvent)) {
            ZStack {
                
                VStack {
                    HStack {
                        Text(formatDateToString(date: myEvent.startDate))
                        Spacer()
                    }
                    HStack {
                        Text(myEvent.name)
                        Spacer()
                    }
                }
                
            }.font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
                .frame(alignment: .top)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: myEvent.color) ?? DEFAULT_EVENT_COLOR).opacity(0.5)
                )
                .padding(.trailing, 30)
            //.offset(x: 30, y: offset + hourHeight/2)
        }
    }
    
    
    private func formatDateToString(date: Date) -> String {
        // Create Date Formatter
        let dateFormatter = DateFormatter()

        // Set Date/Time Style
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short

        // Convert Date to String
        return dateFormatter.string(from: date) // April 19, 2023 at 4:42 PM
    }
}


struct PersonView_Previews: PreviewProvider {
    static var previews: some View {
        
        let viewContext = PersistenceController.shared.container.viewContext
        
        let mikey = N40Person(entity: N40Person.entity(), insertInto: viewContext)
        
        mikey.firstName = "Mikey"
        mikey.lastName = "Saunders"
        
        mikey.phoneNumber1 = "(208) 294-2002"
        mikey.email1 = "mikey@hmail.com"
        
        
        
        return PersonDetailView(selectedPerson: mikey).environment(\.managedObjectContext, viewContext)
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



