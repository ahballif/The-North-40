//
//  PersonListView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

import SwiftUI

struct PersonListView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingEditPersonSheet = false
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Person.lastName, ascending: true)], animation: .default)
    private var fetchedPeople: FetchedResults<N40Person>
    
    var body: some View {
        
        NavigationView {
            ZStack {
                VStack {
                    
                    
                    List(fetchedPeople) {person in
                        NavigationLink(destination: PersonDetailView(selectedPerson: person)) {
                            Text("\(person.title) \(person.firstName) \(person.lastName)")
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
