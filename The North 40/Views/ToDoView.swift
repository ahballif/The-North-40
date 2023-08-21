//
//  ToDoView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/17/23.
//

import SwiftUI

struct ToDoView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingEditEventSheet = false
    @State private var includeCompletedToDos = false
    //Only finds events that are to-do type (eventType == 3) and that are not fully completed (status == 3)
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Toggle("Included Completed To-Do's", isOn: $includeCompletedToDos).padding(.horizontal)
                    
                    SortedToDoList(showingAll: includeCompletedToDos)
                    
                }
                
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
                            EditEventView()
                        }
                    }
                }
                
                
            }
            .navigationTitle(Text("All To-Do Items"))
            .navigationBarTitleDisplayMode(.inline)
                
        }
        
    }
    
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, h:mma"
    return formatter
}()


struct ToDoView_Previews: PreviewProvider {
    static var previews: some View {
        ToDoView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}




struct SortedToDoList: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest var fetchedToDos: FetchedResults<N40Event>
    
    
    var body: some View {
        List {
            ForEach(fetchedToDos) { todo in
                
                HStack {
                    
                    //Button to check off the to-do
                    Button(action: { completeToDoEvent(toDo: todo) }) {
                        Image(systemName: (todo.status == 0) ? "square" : "checkmark.square")
                            .disabled((todo.status != 0))
                    }.buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: EditEventView(editEvent: todo), label: {
                        HStack {
                            Text(todo.name)
                            
                            Spacer()
                            if (todo.isScheduled) {
                                Text(todo.startDate, formatter: itemFormatter)
                            }
                        }
                    })
                }
            }.onDelete(perform: self.deleteToDoEvent)
        }.scrollContentBackground(.hidden)
    }
    
    init (showingAll: Bool) {
        var predicates: [NSPredicate] = []
        predicates.append(NSPredicate(format: "eventType == %i", 3))
        if (!showingAll) {
            predicates.append(NSPredicate(format: "status != %i", 3))
        }
        
        _fetchedToDos = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Event.startDate, ascending: true)],predicate: NSCompoundPredicate(type: .and, subpredicates: predicates), animation: .default)
    }
    
    private func completeToDoEvent (toDo: N40Event) {
        //checks off to do items or unchecks them
        
        if (toDo.status == 0) {
            toDo.status = 2
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                //Wait 2 seconds to change from attempted to completed so it doesn't disappear too quickly
                if (toDo.status == 2) {
                    //This means it was checked off but hasn't been finally hidden
                    toDo.status = 3
                    
                    do {
                        try viewContext.save()
                    } catch {
                        // handle error
                    }
                }
            }
        } else {
            toDo.status = 0
            
            do {
                try viewContext.save()
            } catch {
                // handle error
            }
        }
    }
    
    private func deleteToDoEvent(offsets: IndexSet) {
        // deletes list items
        
        withAnimation {
            offsets.map { fetchedToDos[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // handle error
            }
        }
    }
}
