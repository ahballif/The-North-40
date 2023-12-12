//
//  EnvelopeView.swift
//  The North 40
//
//  Created by Addison Ballif on 9/2/23.
//

import SwiftUI

struct EnvelopeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    public var updater = RefreshView()
    
    
    @State public var selectedEnvelope: N40Envelope? = N40Envelope()
    
    @State private var showingConfirmDelete = false
    
    @State private var name = ""
    
    
    
    
    
    var body: some View {
        
        ZStack {
            
            VStack {
                HStack {
                    Text("Envelope:").bold()
                    Spacer()
                }
                
                HStack {
                    TextField("Envelope Name", text: $name).font(.title)
                    Spacer()
                }
                
                HStack {
                    Text(String(format: "Current Balance: $%.2f", selectedEnvelope?.currentBalance ?? 0.0))
                    Spacer()
                }
                
                HStack {
                    if selectedEnvelope != nil {
                        Text("Last calculated on: \(selectedEnvelope!.lastCalculation.formatToShortDate())")
                            .font(.footnote)
                    }
                    Spacer()
                    Button("Recalculate") {
                        if selectedEnvelope != nil {
                            selectedEnvelope!.calculateBalance()
                        }
                        updater.updater.toggle()
                        do {
                            try viewContext.save()
                        }
                        catch {
                            // Handle Error
                            print("Error info: \(error)")
                        }
                    }
                }
                
                ScrollView {
                    ForEach(selectedEnvelope?.getTransactions ?? [], id: \.self) {transaction in
                        NavigationLink(destination: EditTransactionView(editTransaction: transaction)) {
                            VStack {
                                HStack {
                                    Text(transaction.name)
                                    Spacer()
                                    Text(String(format: "$%.2f", transaction.amount))
                                        .foregroundColor((transaction.isIncome ? ((colorScheme == .dark) ? .white : .black) : .red))
                                }
                                HStack {
                                    Text("Date: ")
                                    Spacer()
                                    Text(transaction.date.formatToShortDate())
                                }
                            }.padding(.vertical, 3)
                        }.foregroundColor((transaction.date < Date() ? ((colorScheme == .dark) ? .white : .black) : .gray))
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray)
                    }
                    
                }
                
                
                Spacer()
                
            }
            
            
            //add transaction button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    NavigationLink(destination: EditTransactionView(editTransaction: nil, envelope: selectedEnvelope)) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(minWidth: 50, maxWidth: 50)
                            .padding(30)
                    }
                    
                }
            }
            
        }.padding()
        .onDisappear(perform: saveEnvelope)
        .onAppear {
            // populate fields here
            name = selectedEnvelope?.name ?? "no envelope selected"
        }
        .toolbar {
            ToolbarItem {
                Button {
                    showingConfirmDelete = true
                } label: {
                    Image(systemName: "trash")
                }.confirmationDialog("Delete Envelope", isPresented: $showingConfirmDelete) {
                    Button("Delete Envelope", role: .destructive) {
                        //delete the envelope and dismiss
                        
                        
                        if selectedEnvelope != nil {
                            viewContext.delete(selectedEnvelope!)
                            
                            do {
                                try viewContext.save()
                            }
                            catch {
                                // Handle Error
                                print("Error info: \(error)")
                            }
                        }
                        selectedEnvelope = nil
                        dismiss()
                    }
                } message: {
                    Text("Are you sure you want to delete this envelope?")
                }
            }
        }
    }
    
    
    func saveEnvelope () {
        if selectedEnvelope != nil {
            selectedEnvelope!.name = name
            
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
