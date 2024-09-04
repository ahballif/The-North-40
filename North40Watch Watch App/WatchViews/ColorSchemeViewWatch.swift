//
//  ColorSchemeViewWatch.swift
//  North40Watch Watch App
//
//  Created by Addison Ballif on 9/3/24.
//

import SwiftUI
import PhotosUI



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


struct ColorPickerViewWatch: View {
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40ColorScheme.priorityIndex, ascending: true)], animation: .default)
    private var colorSchemes: FetchedResults<N40ColorScheme>
    
    @Binding var selectedColor: Color
    
    var body: some View {
        VStack {
            ScrollView {
            
                ForEach(colorSchemes) {colorScheme in
                    VStack{
                        Text(colorScheme.name).font(.caption)
                        let schemeColors = unpackColorsFromString(colorString: colorScheme.colorsString)
                        
                        ForEach(Array(schemeColors.enumerated()), id: \.element) { index, element in
                            if index % 3 == 0 {
                                HStack{
                                    
                                    Button {
                                        // do something
                                        selectedColor = schemeColors[index]
                                        dismiss()
                                    } label: {
                                        Rectangle().foregroundColor(schemeColors[index])
                                            .frame(width: 50, height:30)
                                    }.buttonStyle(.borderless)
                                    
                                    if index < schemeColors.count-1 {
                                        Button {
                                            // do something
                                            selectedColor = schemeColors[index + 1]
                                            dismiss()
                                        } label: {
                                            Rectangle().foregroundColor(schemeColors[index + 1])
                                                .frame(width: 50, height:30)
                                        }.buttonStyle(.borderless)
                                    } else {
                                        Rectangle()
                                            .foregroundStyle(.clear)
                                            .frame(width: 50,  height: 30)
                                    }
                                    
                                    if index < schemeColors.count-2 {
                                        Button {
                                            // do something
                                            selectedColor = schemeColors[index + 2]
                                            dismiss()
                                        } label: {
                                            Rectangle().foregroundColor(schemeColors[index + 2])
                                                .frame(width: 50, height:30)
                                        }.buttonStyle(.borderless)
                                    } else {
                                        Rectangle()
                                            .foregroundStyle(.clear)
                                            .frame(width: 50,  height: 30)
                                    }
                                    
                                }
                            }
                        }
                    }.padding()
                    
                }
                
            }
        }
    }
}
