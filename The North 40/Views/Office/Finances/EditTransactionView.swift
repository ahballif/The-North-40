//
//  TransactionView.swift
//  The North 40
//
//  Created by Addison Ballif on 9/2/23.
//

import SwiftUI
import CoreData

struct EditTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @State public var editTransaction: N40Transaction? = nil
    @State public var envelope: N40Envelope? = nil
    
    private let repeatOptions = ["No Repeat", "Every Day", "Every Week", "Every Two Weeks", "Monthly (Day of Month)", "Monthly (Week of Month)"]
    
    
    
    @State private var name = ""
    @State private var date = Date()
    @State private var isIncome = false
    @State private var notes = ""
    
    @State private var amountString: String = "0.00"
    @State private var amount: Double = 0.0
    
    @State private var isAlreadyRepeating = false
    @State private var repeatOptionSelected = "No Repeat"
    @State private var numberOfRepeats = 3 // in months
    @State private var isShowingEditAllConfirm: Bool = false
    
    
    //for the delete button
    @State private var isPresentingConfirm: Bool = false
    @State private var isPresentingRecurringDeleteConfirm: Bool = false
    
    @State private var isShowingAlertForTransactionAffiliation = false
    @State private var warned = false
    
    var body: some View {
        ScrollView {
            VStack {
                TextField("Transaction Name", text: $name).font(.title2)
                
                
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
                    }.onChange(of: date, perform: {_ in
                        allConfirmsFalse()
                    })
                    
                    HStack {
                        
                        Spacer()
                        
                        Button("Set to Now") {
                            date = Date()
                        }
                        
                    }
                    
                    
                    
                }
                
                HStack {
                    Text("Income: ")
                    Toggle("income: ", isOn: $isIncome)
                        .labelsHidden()
                    Spacer()
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
                
                //add envelope
                Text("Attached Envelope: \(envelope?.name ?? "no-envelope")")
                
            }.padding()
            
        }.onAppear {
            populateFields()
            if (editTransaction?.isPartOfEnvelopeTransfer ?? false && !warned) {
                isShowingAlertForTransactionAffiliation.toggle()
                warned = true
            }
        }
        .toolbar {
            ToolbarItemGroup {
                if (editTransaction != nil ) {
                    if ((editTransaction!.recurringTag) != "") {
                        Button {
                            isPresentingRecurringDeleteConfirm.toggle()
                        } label: {
                            Image(systemName: "trash")
                        }.confirmationDialog("Delete this transaction?",
                                             isPresented: $isPresentingRecurringDeleteConfirm) {
                            Button("Just this transaction", role: .destructive) {
                                
                                deleteTransaction()
                                
                                dismiss()
                                
                            }
                            Button("Delete all upcoming transactions", role: .destructive) {
                                
                                deleteAllRecurringTransactions()
                                
                                dismiss()
                            }
                        } message: {
                            Text("Delete this transaction and all following?")
                        }
                        
                        
                        Button("Save") {
                            isShowingEditAllConfirm.toggle()
                        }.confirmationDialog("Save To All Occurances?", isPresented: $isShowingEditAllConfirm) {
                            Button("Just this one") {
                                saveTransaction()
                                
                                dismiss()
                            }
                            Button("Change all upcoming") {
                                saveAllRecurringTransactions()
                                
                                dismiss()
                            }
                        } message: {
                            Text("Affect all upcoming occurances?")
                        }
                        
                        
                    } else {
                        
                            
                            
                        Button {
                            isPresentingConfirm.toggle()
                        } label: {
                            Image(systemName: "trash")
                        }.confirmationDialog("Delete this transaction?",
                                             isPresented: $isPresentingConfirm) {
                            Button("Delete", role: .destructive) {
                                deleteTransaction()
                                
                                dismiss()
                                
                            }
                        } message: {
                            Text("Delete This Transaction?")
                        }
                        
                        Button("Update") {
                            saveTransaction()
                            dismiss()
                        }
                        
                    }
                } else {
                    Button("Save") {
                        saveTransaction()
                        dismiss()
                    }
                }
                
            }
        }
        .alert("This transaction was part of an envelope transfer. Deleting or changing this transaction will not change the corresponding transactions in the other envelopes. Make sure to change the others as well to prevent an imbalance.",
                isPresented: $isShowingAlertForTransactionAffiliation) {
              }

        
    }
    
    private func populateFields() {
        if editTransaction != nil {
            name = editTransaction?.name ?? ""
            date = editTransaction?.date ?? Date()
            isIncome = editTransaction?.isIncome ?? false
            notes = editTransaction?.notes ?? ""
            
            amount = editTransaction?.amount ?? 0.0
            amountString = String(format: "%.2f", amount)
            
            isAlreadyRepeating = (editTransaction?.recurringTag ?? "") != ""
            
            envelope = editTransaction?.getEnvelope()
            
        }
    }
    
    private func allConfirmsFalse() {
        isShowingEditAllConfirm = false
        isPresentingConfirm = false
        isPresentingRecurringDeleteConfirm = false
    }
    
    private func saveTransaction ( saveAsCopy: Bool = false) {
        withAnimation {
            
            var newTransaction = editTransaction ?? N40Transaction(context: viewContext)
            if saveAsCopy {
                //if duplicate is set to true, remove the reference to the old editTransaction so that it creates a new one.
                newTransaction = N40Transaction(context: viewContext)
            }
            
            newTransaction.name = name
            if name == "" {
                newTransaction.name = "Untitled transaction on  \(date.dateOnlyToString())"
            }
            
            newTransaction.date = date
            newTransaction.isIncome = isIncome
            newTransaction.notes = notes
            
            amount = Double(amountString.filter("1234567890.".contains)) ?? 0.0
            newTransaction.amount = amount
            
            if newTransaction.getEnvelope() == nil && envelope != nil {
                newTransaction.addToEnvelope(envelope!)
            }
            
            
            //Making recurring events
            if repeatOptionSelected != repeatOptions[0] {
                let recurringTag = UUID().uuidString
                newTransaction.recurringTag = recurringTag
                
                if repeatOptionSelected == "Every Day" {
                    //Repeat Daily
                    for i in 1...30*numberOfRepeats {
                        duplicateN40Transaction(originalTransaction: newTransaction, newDate: Calendar.current.date(byAdding: .day, value: i, to: newTransaction.date)!)
                    }
                    
                } else if repeatOptionSelected == "Every Week" {
                    //Repeat Weekly
                    for i in 1...Int(Double(numberOfRepeats)/12.0*52.0) {
                        duplicateN40Transaction(originalTransaction: newTransaction, newDate: Calendar.current.date(byAdding: .day, value: i*7, to: newTransaction.date)!)
                    }
                    
                } else if repeatOptionSelected == "Every Two Weeks" {
                    for i in 1...Int(Double(numberOfRepeats)/12.0*52.0/2.0) {
                        duplicateN40Transaction(originalTransaction: newTransaction, newDate: Calendar.current.date(byAdding: .day, value: i*14, to: newTransaction.date)!)
                    }
                } else if repeatOptionSelected == "Monthly (Day of Month)" {
                    //Repeat Monthly
                    for i in 1...numberOfRepeats {
                        duplicateN40Transaction(originalTransaction: newTransaction, newDate: Calendar.current.date(byAdding: .month, value: i, to: newTransaction.date)!)
                    }
                } else if repeatOptionSelected == "Monthly (Week of Month)" {
                    // Repeat monthly keeping the day of week
                    var repeatsMade = 1 // the first is the original event.
                    
                    var repeatDate = newTransaction.date
                    var lastCreatedDate = newTransaction.date
                    
                    //determine the week of month
                    var weekOfMonth = 1
                    var indexWeek = Calendar.current.date(byAdding: .day, value: -7, to: newTransaction.date)!
                    
                    while Calendar.current.component(.month, from: newTransaction.date) == Calendar.current.component(.month, from: indexWeek) {
                        
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
                        
                        
                        duplicateN40Transaction(originalTransaction:  newTransaction, newDate: repeatDate)
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
     
            
            
        }
    }
    
    private func saveAllRecurringTransactions () {
        if editTransaction != nil {
            
            let fetchRequest: NSFetchRequest<N40Transaction> = N40Transaction.fetchRequest()
            
            let isFuturePredicate = NSPredicate(format: "date >= %@", ((editTransaction?.date ?? Date()) as CVarArg)) //will include this event
            let sameTagPredicate = NSPredicate(format: "recurringTag == %@", (editTransaction!.recurringTag))
            
            let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [isFuturePredicate, sameTagPredicate])
            fetchRequest.predicate = compoundPredicate
            
            do {
                // Peform Fetch Request
                let fetchedTransactions = try viewContext.fetch(fetchRequest)
                
                fetchedTransactions.forEach { recurringTransaction in
                    
                    recurringTransaction.name = name
                    if name == "" {
                        recurringTransaction.name = "Untitled transaction on  \(date.dateOnlyToString())"
                    }
                    
                    
                    let hour = Calendar.current.component(.hour, from: date)
                    let minute = Calendar.current.component(.minute, from: date)
                    recurringTransaction.date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: recurringTransaction.date) ?? recurringTransaction.date
                    
                    
                    recurringTransaction.isIncome = isIncome
                    recurringTransaction.notes = notes
                    
                    amount = Double(amountString.filter("1234567890.".contains)) ?? 0.0
                    recurringTransaction.amount = amount
                    
                    if recurringTransaction.getEnvelope() == nil && envelope != nil {
                        recurringTransaction.addToEnvelope(envelope!)
                    }
                    
                }
                
                // To save the entities to the persistent store, call
                // save on the context
                do {
                    try viewContext.save()
                }
                catch {
                    // Handle Error
                    print("Error info: \(error)")
                    
                }
                
                
            } catch let error as NSError {
                print("Couldn't fetch other recurring events. \(error), \(error.userInfo)")
            }
        
        }
    }
        
    private func deleteTransaction () {
        if (editTransaction != nil) {
            viewContext.delete(editTransaction!)
            
            do {
                try viewContext.save()
            }
            catch {
                // Handle Error
                print("Error info: \(error)")
            }
        } else {
            print("Cannot delete event because it has not been created yet. ")
        }
    }
    
    private func deleteAllRecurringTransactions() {
        if editTransaction != nil {
            let fetchRequest: NSFetchRequest<N40Transaction> = N40Transaction.fetchRequest()
            
            let isFuturePredicate = NSPredicate(format: "date >= %@", ((editTransaction?.date ?? Date()) as CVarArg)) //will include this event
            let sameTagPredicate = NSPredicate(format: "recurringTag == %@", (editTransaction!.recurringTag))
            
            let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [isFuturePredicate, sameTagPredicate])
            fetchRequest.predicate = compoundPredicate
            
            do {
                // Peform Fetch Request
                let fetchedEvents = try viewContext.fetch(fetchRequest)
                
                fetchedEvents.forEach { recurringEvent in
                    viewContext.delete(recurringEvent)
                }
                
                // To save the entities to the persistent store, call
                // save on the context
                do {
                    try viewContext.save()
                }
                catch {
                    // Handle Error
                    print("Error info: \(error)")
                    
                }
                
                
            } catch let error as NSError {
                print("Couldn't fetch other recurring events. \(error), \(error.userInfo)")
            }
        } else {
            print("Cannot delete recurring events because they have not been created yet. ")
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
        
        
        do {
            try viewContext.save()
        }
        catch {
            // Handle Error
            print("Error info: \(error)")
            
        }
        
    }
}

struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        EditTransactionView()
    }
}
