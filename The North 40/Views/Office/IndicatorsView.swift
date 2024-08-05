//
//  IndicatorsView.swift
//  The North 40
//
//  Created by Addison Ballif on 5/27/24.
//

import SwiftUI

struct IndicatorsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Indicator.targetDate, ascending: false)])
    private var fetchedIndicators: FetchedResults<N40Indicator>
    
    @State private var selectedIndicator: N40Indicator? = nil
    
    var body: some View {
        VStack {
            IndicatorViewer()
        }.toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink("Add", destination: EditIndicatorView())
            }
        }
    }
    
    
    
    
    
    
    
    
}


struct IndicatorViewer: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Indicator.targetDate, ascending: true)])
    private var fetchedIndicators: FetchedResults<N40Indicator>
    
    
    var body: some View {
        VStack {
            ForEach(fetchedIndicators) {myIndicator in
                indicatorCell(myIndicator)
            }
            Spacer()
        }
    }
    
    
    private func indicatorCell(_ myIndicator: N40Indicator) -> some View {
        return GeometryReader {geometry in
            ZStack {
                Rectangle()
                    .fill(Color(hex: myIndicator.color) ?? DEFAULT_EVENT_COLOR)
                    .opacity(0.5)
                VStack{
                    // The progress bar at the bottom
                    Spacer()
                    HStack{
                        let barWidth = CGFloat(geometry.size.width)*CGFloat(myIndicator.achieved)/CGFloat(myIndicator.target)
                        if barWidth < geometry.size.width {
                            Rectangle()
                                .fill(Color(hex: myIndicator.color) ?? DEFAULT_EVENT_COLOR)
                                .frame(width: barWidth, height:5)
                            Spacer()
                        } else {
                            Rectangle()
                                .fill(Color(hex: myIndicator.color) ?? DEFAULT_EVENT_COLOR)
                                .frame(height:5)
                        }
                        
                    }
                }
                
                VStack {
                    HStack{
                        Text(myIndicator.targetDate.dateOnlyToString())
                            .font(.caption)
                        Spacer()
                    }
                    HStack{
                        Text(myIndicator.name)
                            .padding(.leading)
                        Spacer()
                        
                        Stepper("", onIncrement: {
                            saveIncrement(myIndicator, by: 1)
                        }, onDecrement: {
                            saveIncrement(myIndicator, by: -1)
                        })
                        
                        Text("\(myIndicator.achieved)/\(myIndicator.target)")
                        NavigationLink {
                            EditIndicatorView(editIndicator: myIndicator)
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }.padding(.trailing)
                    }
                    
                    
                }
                
                
            }
            
        }.frame(height: 50)
    }
    
    
    private func saveIncrement(_ myIndicator: N40Indicator, by: Int16) {
        myIndicator.achieved += by
        //save data string
        do {
            try viewContext.save()
        } catch {
            print("Error info: \(error)")
        }
    }
    
}
