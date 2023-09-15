//
//  EnvelopeTransferView.swift
//  The North 40
//
//  Created by Addison Ballif on 9/7/23.
//

import SwiftUI

struct EnvelopeTransferView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    private let repeatOptions = ["No Repeat", "Every Day", "Every Week", "Every Two Weeks", "Monthly (Day of Month)", "Monthly (Week of Month)"]
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Envelope.lastCalculation, ascending: false)])
    private var fetchedEnvelopes: FetchedResults<N40Envelope>
    
    @State private var date = Date()
    @State private var notes = ""
    
    @State private var amountString: String = "0.00"
    @State private var amount: Double = 0.0
    
    @State private var isAlreadyRepeating = false
    @State private var repeatOptionSelected = "No Repeat"
    @State private var numberOfRepeats = 3 //in months
    
    @State private var selectedFromEnvelope: N40Envelope? = nil
    @State private var selectedToEnvelope: N40Envelope? = nil
    
    @State private var showingSelectToAndFromAlert = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Envelope Transfer").font(.title2)
                Spacer()
                Button("Save") {
                    saveTransactions()
                    //don't dismiss here. We'll do it in the saveTransactions function
                }.alert("Please select an envelope to transfer to and from. ",
                        isPresented: $showingSelectToAndFromAlert) {
                      }
            }
            
            
            ScrollView {
                
                
                
                HStack{
                    Text("Amount: $")
                    TextField("Enter Amount", text: $amountString)
                        .keyboardType(.decimalPad)
                        .labelsHidden()
                        .onSubmit {
                            amountString = amountString.filter("0123456789.".contains)
                            amount = Double(amountString.filter("1234567890.".contains)) ?? 0.0
                            amountString = String(format: "%.2f", amount)
                        }.onTapGesture {
                            amountString = ""
                        }
                    
                    Spacer()
                }
                
                VStack {
                    
                    
                    DatePicker(selection: $date) {
                        Text("Date: ")
                    }
                    
                    HStack {
                        
                        Spacer()
                        
                        Button("Set to Now") {
                            date = Date()
                        }
                        
                    }
                    
                    
                    
                }
                
                VStack {
                    HStack {
                        Text("Envelopes: ").font(.title3)
                        Spacer()
                    }
                    
                    HStack {
                        Text("From: ").bold()
                        Spacer()
                        Picker("", selection: $selectedFromEnvelope) {
                            Text("Select Envelope").tag(nil as N40Envelope?)
                            ForEach(fetchedEnvelopes) { envelope in
                                Text(envelope.name).tag(envelope as N40Envelope?)
                            }
                        }
                    }
                    HStack {
                        Text("To: ").bold()
                        Spacer()
                        Picker("", selection: $selectedToEnvelope) {
                            Text("Select Envelope").tag(nil as N40Envelope?)
                            ForEach(fetchedEnvelopes) { envelope in
                                Text(envelope.name).tag(envelope as N40Envelope?)
                            }
                        }
                    }
                    
                }
                
                VStack {
                    VStack {
                        HStack {
                            Text("Repeat transaction: ")
                            if (!isAlreadyRepeating) {
                                Picker("", selection: $repeatOptionSelected) {
                                    ForEach(repeatOptions, id: \.self) { option in
                                        Text(option)
                                    }
                                }
                                
                                Spacer()
                                
                                
                            } else {
                                Text("This is a repeating transaction. ")
                                
                                Spacer()
                            }
                        }
                        if (!isAlreadyRepeating) {
                            HStack {
                                Text("For \(numberOfRepeats) Months")
                                Stepper("", value: $numberOfRepeats, in: 1...12)
                            }
                        }
                    }.padding()
                }.border(.gray)
                
                
                
                VStack {
                    HStack {
                        Text("Transaction Notes: ")
                        Spacer()
                    }
                    TextEditor(text: $notes)
                        .padding(.horizontal)
                        .shadow(color: .gray, radius: 5)
                        .frame(minHeight: 100)
                    
                    
                }
                
                
            }
        }.padding()
    }
    
    private func saveTransactions () {
        if selectedToEnvelope != nil && selectedFromEnvelope != nil {
            let fromTransaction = N40Transaction(context: viewContext)
            let toTransaction = N40Transaction(context: viewContext)
            
            fromTransaction.name = "Transfer to \(selectedToEnvelope!.name)"
            toTransaction.name = "Transfer from \(selectedFromEnvelope!.name)"
            
            fromTransaction.date = date
            toTransaction.date = date
            
            fromTransaction.isIncome = false
            toTransaction.isIncome = true
            
            fromTransaction.notes = notes
            toTransaction.notes = notes
            
            amount = Double(amountString.filter("1234567890.".contains)) ?? 0.0
            fromTransaction.amount = amount
            toTransaction.amount = amount
            
            fromTransaction.addToEnvelope(selectedFromEnvelope!)
            toTransaction.addToEnvelope(selectedToEnvelope!)
            
            fromTransaction.isPartOfEnvelopeTransfer = true
            toTransaction.isPartOfEnvelopeTransfer = true
            
            //making recurring events
            if repeatOptionSelected != repeatOptions[0] {
                
                fromTransaction.recurringTag = UUID().uuidString
                toTransaction.recurringTag = UUID().uuidString
                
                if repeatOptionSelected == "Every Day" {
                    //Repeat Daily
                    for i in 1...30*numberOfRepeats {
                        duplicateN40Transaction(originalTransaction: fromTransaction, newDate: Calendar.current.date(byAdding: .day, value: i, to: date)!)
                        duplicateN40Transaction(originalTransaction: toTransaction, newDate: Calendar.current.date(byAdding: .day, value: i, to: date)!)
                    }
                    
                } else if repeatOptionSelected == "Every Week" {
                    //Repeat Weekly
                    for i in 1...Int(Double(numberOfRepeats)/12.0*52.0) {
                        duplicateN40Transaction(originalTransaction: fromTransaction, newDate: Calendar.current.date(byAdding: .day, value: i*7, to: date)!)
                        duplicateN40Transaction(originalTransaction: toTransaction, newDate: Calendar.current.date(byAdding: .day, value: i*7, to: date)!)
                        
                    }
                    
                } else if repeatOptionSelected == "Every Two Weeks" {
                    for i in 1...Int(Double(numberOfRepeats)/12.0*52.0/2.0) {
                        duplicateN40Transaction(originalTransaction: fromTransaction, newDate: Calendar.current.date(byAdding: .day, value: i*14, to: date)!)
                        duplicateN40Transaction(originalTransaction: toTransaction, newDate: Calendar.current.date(byAdding: .day, value: i*14, to: date)!)
                    }
                } else if repeatOptionSelected == "Monthly (Day of Month)" {
                    //Repeat Monthly
                    for i in 1...numberOfRepeats {
                        duplicateN40Transaction(originalTransaction: fromTransaction, newDate: Calendar.current.date(byAdding: .month, value: i, to: date)!)
                        duplicateN40Transaction(originalTransaction: toTransaction, newDate: Calendar.current.date(byAdding: .month, value: i, to: date)!)
                    }
                } else if repeatOptionSelected == "Monthly (Week of Month)" {
                    // Repeat monthly keeping the day of week
                    var repeatsMade = 1 // the first is the original event.
                    
                    var repeatDate = date
                    var lastCreatedDate = date
                    
                    //determine the week of month
                    var weekOfMonth = 1
                    var indexWeek = Calendar.current.date(byAdding: .day, value: -7, to: date)!
                    
                    while Calendar.current.component(.month, from: date) == Calendar.current.component(.month, from: indexWeek) {
                        
                        weekOfMonth += 1
                        indexWeek = Calendar.current.date(byAdding: .day, value: -7, to: indexWeek)!
                        //subtract a week and see if it's still in the month
                    }
                    //now we know what week of the month the event is in.
                    
                    while repeatsMade < numberOfRepeats {
                        
                        //While the next date is in the same month as the last created date
                        while Calendar.current.component(.month, from: lastCreatedDate) == Calendar.current.component(.month, from: repeatDate) {
                            //add a week to the next date until it crosses over to the next month
                            repeatDate = Calendar.current.date(byAdding: .day, value: 7, to: repeatDate) ?? repeatDate
                        }
                        //Now the repeat date should be in the next month,
                        // ex. if doing first sunday of the month, it should be the next first sunday
                        
                        //now make it the right week of the month
                        repeatDate = Calendar.current.date(byAdding: .day, value: (weekOfMonth-1)*7, to: repeatDate) ?? repeatDate
                        
                        
                        duplicateN40Transaction(originalTransaction:  fromTransaction, newDate: repeatDate)
                        duplicateN40Transaction(originalTransaction:  toTransaction, newDate: repeatDate)
                        lastCreatedDate = repeatDate
                        repeatsMade += 1
                    }
                    
                }
                
            }
            
            // To save the new entity to the persistent store, call
            // save on the context
            do {
                try viewContext.save()
            }
            catch {
                // Handle Error
                print("Error info: \(error)")
                
            }
     
            dismiss()
            
        } else {
            //produce dialog
            //cannot make transfer
            showingSelectToAndFromAlert.toggle()
        }
    }
    
    
    
    private func duplicateN40Transaction (originalTransaction: N40Transaction, newDate: Date) {
        
        let newTransaction = N40Transaction(context: viewContext)
        newTransaction.name = originalTransaction.name
        newTransaction.date = newDate
        newTransaction.isIncome = originalTransaction.isIncome
        newTransaction.notes = originalTransaction.notes
        
        newTransaction.amount = originalTransaction.amount
        
        newTransaction.addToEnvelope(originalTransaction.getEnvelope()!)
        newTransaction.recurringTag = originalTransaction.recurringTag
        
        
        //don't save cuz it's only used for the repeating events and we save after that.
        
        
        
    }
    
}

struct EnvelopeTransferView_Previews: PreviewProvider {
    static var previews: some View {
        EnvelopeTransferView()
    }
}
