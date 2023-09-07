//
//  PersonListView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

import SwiftUI

struct PersonListView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    let alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W", "X","Y", "Z"]
    let alphabetString = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    @State private var showingEditPersonSheet = false
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)], animation: .default)
    private var fetchedPeople: FetchedResults<N40Person>
    
    var body: some View {
        
        NavigationView {
            ZStack {
                
                
                
                List{
                    let noLetterLastNames = fetchedPeople.filter { $0.lastName.uppercased().filter(alphabetString.contains) == ""}
                    if noLetterLastNames.count > 0 {
                        Section(header: Text("*")) {
                            ForEach(noLetterLastNames, id: \.self) { person in
                                NavigationLink(destination: PersonDetailView(selectedPerson: person)) {
                                    HStack {
                                        Text((person.title == "" ? "" : "\(person.title) ") + "\(person.firstName)")
                                        Text("\(person.lastName)").bold()
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    ForEach(alphabet, id: \.self) { letter in
                        let letterSet = fetchedPeople.filter { $0.lastName.hasPrefix(letter) }
                        if (letterSet.count > 0) {
                            Section(header: Text(letter)) {
                                ForEach(letterSet, id: \.self) { person in
                                    NavigationLink(destination: PersonDetailView(selectedPerson: person)) {
                                        HStack {
                                            Text((person.title == "" ? "" : "\(person.title) ") + "\(person.firstName)")
                                            Text("\(person.lastName)").bold()
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }.padding(.horizontal, 3)
                
                
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        Button(action: {showingEditPersonSheet.toggle()}) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .clipShape(Circle())
                                .frame(minWidth: 50, maxWidth: 50)
                                .padding(30)
                        }
                        .sheet(isPresented: $showingEditPersonSheet) {
                            EditPersonView(editPerson: nil)
                            
                        }
                    }
                }
                
                
            }
            .navigationTitle(Text("People"))
            .navigationBarTitleDisplayMode(.inline)
                
        }
        
        
    }
    
}

struct PersonListView_Previews: PreviewProvider {
    static var previews: some View {
        PersonListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
