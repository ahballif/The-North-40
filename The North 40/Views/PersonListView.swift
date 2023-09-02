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
        
    
    @State private var showingEditPersonSheet = false
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)], animation: .default)
    private var fetchedPeople: FetchedResults<N40Person>
    
    var body: some View {
        
        NavigationView {
            ZStack {
                
                
                
                ScrollView {
                    ScrollViewReader { value in
                        ZStack{
                            List{
                                ForEach(alphabet, id: \.self) { letter in
                                    let letterSet = fetchedPeople.filter { $0.lastName.hasPrefix(letter) }
                                    if (letterSet.count > 0) {
                                        Section(header: Text(letter)) {
                                            ForEach(letterSet, id: \.self) { person in
                                                NavigationLink(destination: PersonDetailView(selectedPerson: person)) {
                                                    Text("\(person.title) \(person.firstName) \(person.lastName)")
                                                        .id("\(person.title) \(person.firstName) \(person.lastName)")
                                                }
                                            }
                                        }.id(letter)
                                    }
                                }
                            }
                            
                            //scroll to letter.
                            HStack{
                                Spacer()
                                VStack {
                                    ForEach(0..<alphabet.count, id: \.self) { idx in
                                        Button(action: {
                                            withAnimation {
                                                value.scrollTo(alphabet[idx])
                                            }
                                        }, label: {
                                            Text(idx % 2 == 0 ? alphabet[idx] : "\u{2022}")
                                        })
                                    }
                                }
                            }
                        }
                    }
                }
                
                
                
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
