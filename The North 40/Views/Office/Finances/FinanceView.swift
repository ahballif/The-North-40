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
    
    @State private var isShowingTransferSheet = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("My Finances").font(.title)
                    Spacer()
                    Button {
                        //Envelope Transfer Button
                        isShowingTransferSheet.toggle()
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                    }.sheet(isPresented: $isShowingTransferSheet) {
                        EnvelopeTransferView()
                    }
                }.padding(.horizontal)
                HStack {
                    Text(String(format: "Total: $%.2f", getTotal()))
                    Spacer()
                }.padding(.horizontal)  
                
                ScrollView {
                    
                    ForEach(fetchedEnvelopes) {eachEnvelope in
                        envelopeCell(eachEnvelope)
                    }
                    
                }
            }.toolbar {
                Button("Calculate All") {
                    for envelope in fetchedEnvelopes {
                        envelope.calculateBalance()
                    }
                    do {
                        try viewContext.save()
                    }
                    catch {
                        // Handle Error
                        print("Error info: \(error)")
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
    
    private func getTotal () -> Double {
        var sum = 0.0
        for envelope in fetchedEnvelopes {
            sum += envelope.currentBalance
        }
        return sum
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
                .padding(3)
            
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
