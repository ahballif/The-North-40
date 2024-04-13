//
//  ColorSchemeView.swift
//  The North 40
//
//  Created by Addison Ballif on 4/12/24.
//

import SwiftUI
import PhotosUI

struct ColorSchemeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40ColorScheme.priorityIndex, ascending: true)], animation: .default)
    private var colorSchemes: FetchedResults<N40ColorScheme>
    
    
    
    
    var body: some View {
        VStack{
            Text("My Color Schemes").font(.title).padding()
            List {
                ForEach(colorSchemes) {colorScheme in
                    let schemeColors = unpackColorsFromString(colorString: colorScheme.colorsString)
                    NavigationLink (destination: ColorSchemeEditor(editScheme: colorScheme)) {
                        VStack {
                            HStack{
                                Text(colorScheme.name)
                                Spacer()
                            }
                            HStack {
                                ForEach(schemeColors, id: \.self) { color in
                                    Rectangle().foregroundColor(color)
                                }
                            }
                        }
                    }
                }.onMove { from, to in
                    var arrayForm = colorSchemes.sorted(by: {$0.priorityIndex < $1.priorityIndex})
                    arrayForm.move(fromOffsets: from, toOffset: to)
                    var idx = 0
                    for colorScheme in arrayForm {
                        colorScheme.priorityIndex = Int16(idx)
                        idx += 1
                    }
                    do {
                        try viewContext.save()
                    }
                    catch {
                        // Handle Error
                        print("Error info: \(error)")
                    }
                }.listStyle(.grouped)
            }
            Button {
                createNewColorScheme()
            } label: {
                Text("Add Color Scheme")
            }
            
        }
        
        
    }
    
    private func createNewColorScheme() {
        let newColorScheme = N40ColorScheme(context: viewContext)
        
        newColorScheme.name = "New Color Scheme"
        newColorScheme.priorityIndex = Int16(colorSchemes.count)
        newColorScheme.colorsString = ""
        
        do {
            try viewContext.save()
        }
        catch {
            // Handle Error
            print("Error info: \(error)")
        }
    }
}

struct ColorSchemeEditor: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State public var editScheme: N40ColorScheme
    @State public var name: String
    @State public var colors: [Color]
    @State private var rawColors: [Color] //The colors from the image
    
    
    @State private var pickerColor: Color = Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 1.0)
    
    @State private var similarityThreshold = 0.2
    @State private var saturationValue = 1.0
    @State private var brightnessValue = 1.0
    
    @State private var photoItem: PhotosPickerItem?
    @State private var rawImage: Image?
    @State private var scaledImage: Image?
    @State private var photoData: Data?
    private let photoWidth = 512
    
    private static let MAX_THINK_AMOUNT = 200
    
    @State private var numberOfPhotoColors = 4
    
    @State private var showingDeleteConfirm = false
    
    init(editScheme: N40ColorScheme) {
        _editScheme = State(initialValue: editScheme)
        _name = State(initialValue: editScheme.name)
        
        
        let savedColors = unpackColorsFromString(colorString: editScheme.colorsString)
        
        _colors = State(initialValue: savedColors)
        _rawColors = State(initialValue: savedColors)
        
        if editScheme.photo != nil {
            _photoData = State(initialValue: editScheme.photo!)
            if let uiImage = UIImage(data: editScheme.photo!) {
                _rawImage = State(initialValue: Image(uiImage: uiImage))
                _scaledImage = State(initialValue: Image(uiImage: uiImage))
            } else {
                print("Could not import contact photo")
            }
        }
        
        if editScheme.photo != nil && savedColors.count > 1 {
            _numberOfPhotoColors = State(initialValue: savedColors.count)
        }
    }
    
    var body: some View {
        NavigationStack{
//            ScrollView {
                VStack{
                    TextField("Color Scheme Name", text: $name).font(.title).padding()
                    
                    HStack {
                        PhotosPicker(photoData == nil ? "Create with Image" : "Different Image", selection: $photoItem, matching: .images)
                            .onChange(of: photoItem) { _ in
                                Task {
                                    if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                                        
                                        if let uiImage = UIImage(data: data) {
                                            let newImage = uiImage
                                            photoData = newImage.pngData()
                                            rawImage = Image(uiImage: newImage)
                                            scaledImage = scaledImage
                                            return
                                        }
                                    }
                                    
                                    print("Failed")
                                }
                            }
                        if (photoData != nil) {
                            Button("Remove Photo") {
                                photoItem = nil
                                photoData = nil
                                rawImage = nil
                                scaledImage = nil
                            }
                        }
                    }
                    
                    if photoData != nil {
                        // Then we're using a picture
                        
                        HStack{
                            //If it's just a picture then just show the colors on the top
                            ForEach(colors, id: \.self) { color in
                                Rectangle().foregroundColor(color)
                                    .frame(height: 50)
                            }
                        }
                        
                        VStack {

                            if rawImage != nil && scaledImage != nil {
                                HStack {
                                    rawImage!
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                    scaledImage!
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                            
                            if photoData != nil {
                                Stepper {
                                    Text("Number of Picture Colors: \(numberOfPhotoColors)")
                                } onIncrement: {
                                    if numberOfPhotoColors < 6 {
                                        numberOfPhotoColors += 1
                                    }
                                    calculateImageColors()
                                } onDecrement: {
                                    if numberOfPhotoColors > 3 {
                                        numberOfPhotoColors -= 1
                                    }
                                    calculateImageColors()
                                }
                                VStack {
    //                                Text("Similarity")
    //                                Slider(value: $similarityThreshold, in: 0.01...0.65)
    //                                    .onChange(of: similarityThreshold) {_ in
    //                                        calculateImageColors()
    //                                    }
                                    Text("Saturation")
                                    Slider(value:$saturationValue, in: 0.01...2.0)
                                        .onChange(of: saturationValue) {_ in
                                            colors = scaleColorsSatBri(rawColors)
                                        }
                                    Text("Brightness")
                                    Slider(value:$brightnessValue, in: 0.01...2.0)
                                        .onChange(of: brightnessValue) {_ in
                                            colors = scaleColorsSatBri(rawColors)
                                        }
                                }
                            }
                        }.padding()
                        Spacer()
                    } else {
                        //Make it custom
                        HStack{
                            //If it's just a picture then just show the colors on the top
                            ForEach(colors, id: \.self) { color in
                                VStack {
                                    Rectangle().foregroundColor(color)
                                        .frame(height: 50)
                                    Button {
                                        //remove the color
                                        if let rmvIdx: Int = colors.firstIndex(of: color) {
                                            colors.remove(at: rmvIdx)
                                        }
                                    } label : {
                                        Image(systemName: "x.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }.padding()
                        
                        HStack{
                            ColorPicker("NewColor", selection: $pickerColor)
                                .labelsHidden()
                            Spacer()
                            Button("Add Color") {
                                colors.append(pickerColor)
                            }
                        }.padding()
                        
                        
                        
                        
                    }
                    
                    Spacer()
//                }
            }
        }.toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingDeleteConfirm.toggle()
                } label: {
                    Image(systemName: "trash")
                }.confirmationDialog("Delete this Color Scheme?",
                                     isPresented: $showingDeleteConfirm) {
                    Button("Delete", role: .destructive) {
                        viewContext.delete(editScheme)
                        do {
                            try viewContext.save()
                        }
                        catch {
                            // Handle Error
                            print("Error info: \(error)")
                        }
                        
                        dismiss()
                        
                    }
                } message: {
                    Text("Delete this Color Scheme?")
                }
                
                Button("Save") {
                    
                    editScheme.colorsString = packColorsToString(colors: colors)
                    editScheme.name = name
                    editScheme.photo = photoData
                    
                    
                    do {
                        try viewContext.save()
                    }
                    catch {
                        // Handle Error
                        print("Error info: \(error)")
                    }
                    dismiss()
                }
            }
        }
    }
    
    private func calculateImageColors() {
        if photoData != nil {
            var currentWorkingColors:[Color] = []
            var newW = 1
            var newH = 1
            var thoughts = 0
            while currentWorkingColors.count < numberOfPhotoColors && thoughts < ColorSchemeEditor.MAX_THINK_AMOUNT {
                thoughts += 1
                if let originalImage: UIImage = UIImage(data: photoData!) {
                    //step 1 increment the image size
                    if Double(newW)/Double(newH) < Double(originalImage.size.width/originalImage.size.height) {
                        newW += 1
                    } else {
                        newH += 1
                    }
                    let newSize = CGSize(width: newW, height: newH)
                    let resizedImage = (resizeImage(image: originalImage, targetSize: newSize) ?? originalImage)
                    scaledImage = Image(uiImage: resizedImage)
                    currentWorkingColors = filterSimilarColors(resizedImage.getColors())
                }
                
            }
            while currentWorkingColors.count > numberOfPhotoColors {
                //remove the last one
                currentWorkingColors.removeLast()
            }
            rawColors = currentWorkingColors
            colors = scaleColorsSatBri(rawColors)
        }
    }
    
    private func filterSimilarColors(_ inColors: [Color]) -> [Color] {
        // This function removes colors from the list if they are similar to any others.
        var outColors: [Color] = []
        for inColor in inColors {
            var similar = false
            //see if it is similar to any of the colors already added
            for outColor in outColors {
                //get distance by taking a dot product
                let distance = sqrt(pow(inColor.components.red-outColor.components.red, 2) + pow(inColor.components.blue - outColor.components.blue, 2) + pow(inColor.components.green - outColor.components.green, 2))
                if distance < similarityThreshold {
                    similar = true
                }
            }
            if !similar {
                outColors.append(inColor)
            }
        }
        
        
        return outColors
    }
    
    private func scaleColorsSatBri(_ inColors: [Color]) -> [Color] {
        // This function scales the saturation and brightness of a color
        var outColors:[Color] = []
        for color in inColors {
            var components = color.hsvComponents
            components.sat *= saturationValue
            if components.sat > 1 {
                components.sat = 1
            }
            components.bri *= brightnessValue
            if components.bri > 1 {
                components.bri = 1
            }
            let newcolor = Color(hue: components.hue, saturation: components.sat, brightness: components.bri)
            outColors.append(newcolor)
        }
        return outColors
    }
     
}


private func packColorsToString(colors: [Color]) -> String {
    var answerString = ""
    for color in colors {
        answerString += color.toHex() ?? ""
        if colors.lastIndex(of: color) != colors.count - 1 {
            answerString += ","
        }
    }
    return answerString
}

func unpackColorsFromString(colorString: String) -> [Color] {
    let colorStrings = colorString.components(separatedBy: ",")
    var colors: [Color] = []
    if colorString == "" {
        return []
    } else {
        for eachStringPiece in colorStrings {
            colors.append((Color(hex: eachStringPiece) ?? Color(hex: "#FF7051"))!)
        }
    return colors
    }
}

fileprivate extension UIImage {
    func getColors() -> [Color] {
        
        var colors: [Color] = []
        
        for x in 0..<Int(size.width) {
            for y in 0..<Int(size.height) {
                guard x >= 0 && x < Int(size.width) && y >= 0 && y < Int(size.height),
                    let cgImage = cgImage,
                    let provider = cgImage.dataProvider,
                    let providerData = provider.data,
                    let data = CFDataGetBytePtr(providerData) else {
                    return []
                }
                
                let numberOfComponents = 4
                let pixelData = x*numberOfComponents + y*cgImage.bytesPerRow

                let b = CGFloat(data[pixelData]) / 255.0
                let g = CGFloat(data[pixelData + 1]) / 255.0
                let r = CGFloat(data[pixelData + 2]) / 255.0
                //let a = CGFloat(data[pixelData + 3]) / 255.0
                
                colors.append(Color(red: r, green: g, blue: b))
            }
        }
        
        return colors
    }
}




extension Color {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {

        typealias NativeColor = UIColor
        

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0

        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &o) else {
            // You can handle the failure here as you want
            return (0, 0, 0, 0)
        }

        return (r, g, b, o)
    }
    
    var hsvComponents: (hue: CGFloat, sat: CGFloat, bri: CGFloat) {

        typealias NativeColor = UIColor
        
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0
        
        guard NativeColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &o) else {
            return (0, 0, 0)
        }
        
        return (h, s, b)
        
    }
}


struct ColorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40ColorScheme.priorityIndex, ascending: true)], animation: .default)
    private var colorSchemes: FetchedResults<N40ColorScheme>
    
    @Binding var selectedColor: Color
    
    var body: some View {
        VStack {
            HStack {
                Button("Close") {
                    dismiss()
                }
                Spacer()
            }.padding()
            ScrollView {
                ForEach(colorSchemes) {colorScheme in
                    VStack{
                        Text(colorScheme.name).font(.caption)
                        HStack {
                            let schemeColors = unpackColorsFromString(colorString: colorScheme.colorsString)
                            ForEach(schemeColors, id: \.self) {color in
                                Button {
                                    // do something
                                    selectedColor = color
                                    dismiss()
                                } label: {
                                    Rectangle().foregroundColor(color)
                                        .frame(height:30)
                                }
                            }
                        }
                    }.padding()
                    
                }
                HStack{
                    Text("Or pick custom color: ")
                    Spacer()
                    ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                        .labelsHidden()
                }.padding()
            }
        }
    }
}
