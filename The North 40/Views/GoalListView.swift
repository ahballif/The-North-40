//
//  GoalListView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/13/23.
//

import SwiftUI

struct GoalListView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingEditGoalSheet = false
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Goal.deadline, ascending: true)], animation: .default)
    private var fetchedGoals: FetchedResults<N40Goal>
    
    var body: some View {
        
        NavigationView {
            ZStack {
                VStack {
                    
                    
                    List(fetchedGoals) {goal in
                        NavigationLink(destination: EditGoalView(editGoal: goal)) {
                            HStack {
                                Text(goal.name)
                                if (goal.hasDeadline) {
                                    Spacer()
                                    Text(("By " + formatDate(dateToFormat: goal.deadline)))
                                }
                            }
                        }
                        
                        
                    }
                    
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        Button(action: {showingEditGoalSheet.toggle()}) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .clipShape(Circle())
                                .frame(minWidth: 50, maxWidth: 50)
                                .padding(30)
                        }
                        .sheet(isPresented: $showingEditGoalSheet) {
                            EditGoalView(editGoal: nil)
                            
                        }
                    }
                }
                
                
            }
            .navigationTitle(Text("Goals"))
            .navigationBarTitleDisplayMode(.inline)
                
        }
        
        
    }
    
    private func formatDate(dateToFormat: Date) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return dateFormatter.string(from: dateToFormat)
    }
}

struct GoalListView_Previews: PreviewProvider {
    static var previews: some View {
        GoalListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
