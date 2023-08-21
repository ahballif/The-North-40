//
//  AddPersonView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

import SwiftUI

struct AddPersonView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var title: String = ""
    
    @State private var phoneNumber: [String] = [""]
    
    
    var body: some View {
        VStack {
            //top bar
            HStack (alignment: .top){
                Button(action: emptyFunction) {
                    Text("Cancel")
                }
                Spacer()
                Text("Add New Person")
                Spacer()
                Button(action: emptyFunction) {
                    Text("Done")
                }
            }.frame(maxWidth: .infinity).padding()
            
            //photo line
            HStack {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .frame(minWidth: 100, maxWidth: 100)
                Spacer()
                Text("Picture of someone")
            }.padding()
            
            // Information Lines
            VStack {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                Spacer()
                TextField("Phone Number", text: $phoneNumber[0]).onSubmit {
                    phoneNumber[0] = formatPhoneNumber(inputString: phoneNumber[0])
                    phoneNumber.append("")
                }
            }.padding()
            
            Spacer()
        }
    }
    
    
    private func createN40Person () {
        
    }
    
    
}

private func emptyFunction () {
    
}

struct AddPersonView_Previews: PreviewProvider {
    static var previews: some View {
        AddPersonView()
    }
}
