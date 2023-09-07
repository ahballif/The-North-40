//
//  FinanceView.swift
//  The North 40
//
//  Created by Addison Ballif on 9/2/23.
//

import SwiftUI

struct FinanceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Envelope.name, ascending: true)])
    private var fetchedEnvelopes: FetchedResults<N40Envelope>
    
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("My Finances").font(.title)
                    Spacer()
                    Button {
                        //Envelope Transfer Button
                        
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                    }
                }.padding()
                
                ScrollView {
                    
                    ForEach(fetchedEnvelopes) {eachEnvelope in
                        envelopeCell(eachEnvelope)
                    }
                    
                }
            }
         
            
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {addEnvelope()}) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(minWidth: 50, maxWidth: 50)
                            .padding(30)
                    }
                    
                }
            }
            
        }
    }
    
    
    
    func envelopeCell (_ envelope: N40Envelope) -> some View {
        
        NavigationLink(destination: EnvelopeView(selectedEnvelope: envelope)) {
            
            ZStack {
                
                Rectangle()
                    .foregroundColor(((colorScheme == .dark) ? .black : .white))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(((colorScheme == .dark) ? .white : .black), lineWidth: 5)
                    )
                VStack {
                    HStack {
                        Text(envelope.name).bold()
                        Spacer()
                    }
                    HStack {
                        Text(String(format: "Current Balance: $%.2f", envelope.currentBalance))
                        Spacer()
                    }
                    
                    HStack {
                        
                        Text("Last Calculated: \(envelope.lastCalculation.formatToShortDate())")
                        Spacer()
                    }
                    Spacer()
                }.padding()
                
                
            }.frame(height: 100.0)
                .padding()
            
        }.buttonStyle(.plain)
    }
    
    
    
    private func addEnvelope() {
        withAnimation {
            let newEnvelope = N40Envelope(context: viewContext)
            
            newEnvelope.name = "New Envelope"
            newEnvelope.currentBalance = 0.0
            newEnvelope.lastCalculation = Date()
            
            do {
                try viewContext.save()
            }
            catch {
                // Handle Error
                print("Error info: \(error)")
            }
            
            
        }
    }
}


fileprivate extension Date {
    
    func formatToShortDate () -> String {
        let dateFormatter = DateFormatter()

        
        dateFormatter.dateFormat = "M/d/YY, h:mm a"
        
        // Convert Date to String
        return dateFormatter.string(from: self)
    }
    
}
