//
//  EditIndicatorView.swift
//  The North 40
//
//  Created by Addison Ballif on 5/27/24.
//

import SwiftUI
import CoreData

struct EditIndicatorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    
    @State public var editIndicator: N40Indicator?
    
    @State private var indicatorName = ""
    @State private var targetDate = Date()
    @State private var target = 0
    @State private var achieved = 0
    @State private var color: Color = Color(.white)
    
    @State private var showingColorPickerSheet = false
    @State private var isPresentingConfirm = false
    
    var body: some View {
        
        ScrollView {
            // scroll view because I want to have graphs and stuff at the bottom
            
            TextField("Indicator Name", text: $indicatorName)
                .font(.title2)
                .padding(.vertical,  5)
            
            DatePicker(selection: $targetDate, displayedComponents: .date) {
                Text("By: ")
            }
            
            HStack {
                Text("Target:")
                Spacer()
                
            }
            Picker("", selection: $target) {
                ForEach(1..<1001) {
                        Text("\($0) \(indicatorName)")
                    }
            }.pickerStyle(.wheel)
            
            HStack {
                Text("Achieved \(achieved)/\(target)")
                Spacer()
                Stepper("", value: $achieved, in: 0...1000)
            }
            
            HStack {
                Text("Color: ")
                Button {
                    showingColorPickerSheet.toggle()
                } label: {
                    Rectangle().frame(width:30, height: 20)
                        .foregroundColor(color)
                }.sheet(isPresented: $showingColorPickerSheet) {
                    ColorPickerView(selectedColor: $color)
                }
                Spacer()
            }
            
            // relationship adders
            
        }.padding()
        .onAppear {
            populateFields()
        }
        .toolbar{
            if editIndicator != nil {
                Button {
                    isPresentingConfirm.toggle()
                } label: {
                    Image(systemName: "trash")
                }.confirmationDialog("Delete this event?",
                                     isPresented: $isPresentingConfirm) {
                    Button("Delete", role: .destructive) {
                        viewContext.delete(editIndicator!)
                        do {
                            try viewContext.save()
                        } catch {
                            print("Error info: \(error)")
                        }
                        dismiss()
                    }
                } message: {
                    Text("Delete This Indicator?")
                }
            }
            Button("Update") {
                saveIndicator()
                dismiss()
            }
        }
         
    }
    
    private func populateFields() {
        if editIndicator != nil {
            indicatorName = editIndicator!.name
            targetDate = editIndicator!.targetDate
            achieved = Int(editIndicator!.achieved)
            target = Int(editIndicator!.target)
            color = Color(hex: editIndicator!.color) ?? getDefaultColor()
        } else {
            color = getDefaultColor()
        }
    }
    
    
    private func saveIndicator() {
        let newIndicator = editIndicator ?? N40Indicator(context: viewContext)
        
        newIndicator.name = indicatorName
        newIndicator.targetDate = targetDate
        newIndicator.target = Int16(target)
        newIndicator.achieved = Int16(achieved)
        newIndicator.color = color.toHex() ?? "#b30567"
        
        //here is where I update the datastring
        
        //add the relationships
        
        do {
            try viewContext.save()
        } catch {
            print("Error info: \(error)")
        }
        dismiss()
        
    }
    
    
    // a function to generate the random color
    private func getDefaultColor() -> Color {
        var chosenColor = Color(hex: UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))
        
        //uses the same code to choose event colors
        
        if UserDefaults.standard.bool(forKey: "randomEventColor") {
            chosenColor = Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 1.0)
        } else if UserDefaults.standard.bool(forKey: "randomFromColorScheme") {
            let fetchRequest: NSFetchRequest<N40ColorScheme> = N40ColorScheme.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priorityIndex", ascending: true)]
            
            do {
                // Peform Fetch Request
                let fetchedColorSchemes = try viewContext.fetch(fetchRequest)
                
                if fetchedColorSchemes.count > 0 {
                    let colorPalette = unpackColorsFromString(colorString: fetchedColorSchemes.first!.colorsString)
                    if colorPalette.count > 0 {
                        chosenColor = colorPalette.randomElement() ?? Color(hex: UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))
                        // (the default selected color is the optional argument)
                    } else {
                        //just use the default selected color
                        chosenColor = Color(hex: UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))
                    }
                } else {
                    //just use the default selected color
                    chosenColor = Color(hex: UserDefaults.standard.string(forKey: "defaultColor") ?? "#FF7051") ?? Color(.sRGB, red: 1, green: (112.0/255.0), blue: (81.0/255.0))
                }
                
                
            } catch let error as NSError {
                print("Couldn't fetch other recurring events. \(error), \(error.userInfo)")
            }
        }
        
        return chosenColor
    }
    
}



#Preview {
    EditIndicatorView()
}
