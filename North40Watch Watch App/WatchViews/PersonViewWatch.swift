//
//  PersonViewWatch.swift
//  North40Watch Watch App
//
//  Created by Addison Ballif on 9/4/24.
//

import SwiftUI
import Contacts
import PhotosUI

struct PersonViewWatch: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State var editPerson: N40Person?
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \N40Group.priorityIndex, ascending: false)], animation: .default)
    private var fetchedGroups: FetchedResults<N40Group>
    
    @State private var loadedContact = false
    
    @State private var name: String = ""

    @State private var address: String = ""
    
    @State private var phoneNumber1: String = ""
    @State private var phoneNumber2: String = ""
    @State private var email1: String = ""
    @State private var email2: String = ""
    @State private var socialMedia1: String = ""
    @State private var socialMedia2: String = ""
    
    @State private var notes: String = ""
    
    @State private var birthday: Date = Date()
    @State private var hasBirthday: Bool = false
    
    @State private var favoriteColor: Color = (Color(hex: "#FF7051") ?? Color.red)
    @State private var hasFavoriteColor: Bool = false
    
    @State private var isPresentingDeleteConfirm = false
    
    @State private var showingColorPickerSheet = false
    
    @State private var showingContactPickerSheet = false
    @State private var selectedContact: CNContact? = nil
    
    @State private var photoItem: PhotosPickerItem?
    @State private var photoImage: Image?
    @State private var photoData: Data?
    private let photoWidth = 512
    
    @State private var makeCalendarForThisPerson = false
    
    @State private var selectedGroups: [N40Group] = []
    @State private var removeFromGroup: [N40Group] = []
    
    var body: some View {
        VStack {
            ScrollView {
                
                //photo line
                VStack {
                    
                    if photoImage != nil {
                        photoImage!
                            .resizable()
                            .scaledToFit()
                    }
                    HStack {
                        PhotosPicker("Add Image", selection: $photoItem, matching: .images)
                            .onChange(of: photoItem) { _ in
                                Task {
                                    if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                                        
                                        if let uiImage = UIImage(data: data) {
                                            let newImage = uiImage
                                            //newImage = cropImageToSquare(image: newImage) ?? newImage
                                            //newImage = resizeImage(image: newImage, targetSize: CGSize(width: photoWidth, height: photoWidth)) ?? newImage
                                            photoData = newImage.pngData()
                                            photoImage = Image(uiImage: newImage)
                                            return
                                        }
                                    }
                                    
                                    print("Failed")
                                }
                            }
                        if (photoImage != nil) {
                            Button("Remove Photo") {
                                photoItem = nil
                                photoData = nil
                                photoImage = nil
                            }
                        }
                    }
                    
                }.padding()
                
                TextField("Name", text: $name)
                
                TextField("Address", text: $address).padding()
                
                VStack {
                    
                    TextField("Phone Number 1", text: $phoneNumber1)
                        .onChange(of: phoneNumber1) {_ in
                            if phoneNumber1.filter("1234567890".contains).count == 10 {
                                phoneNumber1 = formatPhoneNumber(inputString: phoneNumber1)
                            } else if phoneNumber1.filter("1234567890".contains).count == 11 {
                                phoneNumber1 = formatPhoneNumber11(inputString: phoneNumber1)
                            } else {
                                phoneNumber1 = phoneNumber1.filter("1234567890".contains)
                            }
                        }
                    TextField("Phone Number 2", text: $phoneNumber2)
                        .onChange(of: phoneNumber2) {_ in
                            if phoneNumber2.filter("1234567890".contains).count == 10 {
                                phoneNumber2 = formatPhoneNumber(inputString: phoneNumber2)
                            } else if phoneNumber2.filter("1234567890".contains).count == 11 {
                                phoneNumber2 = formatPhoneNumber11(inputString: phoneNumber2)
                            } else {
                                phoneNumber2 = phoneNumber2.filter("1234567890".contains)
                            }
                        }
                    TextField("Email 1", text: $email1)
                    TextField("Email 2", text: $email2)
                    TextField("Social Media 1", text: $socialMedia1)
                    TextField("Social Media 2", text: $socialMedia2)
                    
                    
                    
                }.padding()
                
                Toggle("Has Birthday: ", isOn: $hasBirthday)
                if hasBirthday {
                    DatePicker("", selection: $birthday, in: Calendar.current.date(byAdding: .year, value: -120, to: Date())!...Date(), displayedComponents: .date)
                        .frame(height: 50.0)
                }
                
                if notes != "" {
                    // Show notes if there are some but don't worry about making it editable
                    VStack {
                        HStack {
                            Text("Person Information: ").bold()
                            Spacer()
                        }
                        Text(notes)
                    }
                }
                
//                VStack {
//                    //Add to group buttons
//                    HStack {
//                        Text("Person Groups: ").font(.title3)
//                        Spacer()
//                    }
//                    ForEach(fetchedGroups) {personGroup in
//                        HStack {
//                            Text(personGroup.name)
//                            Spacer()
//                            Button {
//                                if selectedGroups.contains(personGroup) && selectedGroups.firstIndex(of: personGroup) != nil {
//                                    //remove the group
//                                    selectedGroups.remove(at: selectedGroups.firstIndex(of: personGroup)!)
//                                    removeFromGroup.append(personGroup)
//                                } else {
//                                    //add the group
//                                    selectedGroups.append(personGroup)
//                                }
//                            } label: {
//                                if selectedGroups.contains(personGroup) {
//                                    Image(systemName: "checkmark.square.fill")
//                                } else {
//                                    Image(systemName: "square")
//                                }
//                            }
//                        }.padding(3)
//                    }
//                }.padding()
                
                
                
                if (editPerson != nil) {
                    Button(role: .destructive, action: {
                        isPresentingDeleteConfirm = true
                    }, label: {
                        Text("Delete Person")
                    }).confirmationDialog("Are you sure you want to delete this person?",
                                          isPresented: $isPresentingDeleteConfirm) {
                         Button("Delete Person", role: .destructive) {
                             viewContext.delete(editPerson!)
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
                         Text("Are you sure you want to delete this person?")
                     }
                }
                
            }.padding()
            
            
            
        }
            .onAppear { populateFields() }
            .toolbar {
                
                    
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        savePerson()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark.circle")
                    }
                }
                    
                
            }
        
    }
    
    private func splitString(_ input: String) -> (String, String) {
        // Trim any whitespace or newline characters
        let trimmedString = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find the range of the last space in the string
        if let lastSpaceRange = trimmedString.range(of: " ", options: .backwards) {
            // Separate the last word and the remaining string
            let firstPart = String(trimmedString[..<lastSpaceRange.lowerBound])
            let lastWord = String(trimmedString[lastSpaceRange.upperBound...])
            return (firstPart, lastWord)
        } else {
            // If there's no space, return the entire string as the last word and an empty string for the first part
            return ("", trimmedString)
        }
    }
    
    
    private func savePerson () {
        withAnimation {
            
            let newPerson = editPerson ?? N40Person(context: viewContext)
            
            let (firstPart, lastWord) = splitString(name)
            
            newPerson.firstName = firstPart
            newPerson.lastName = lastWord
            
            newPerson.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
            
            newPerson.hasBirthday = hasBirthday
            newPerson.birthday = birthday
            newPerson.birthdayDay = Int16(birthday.get(.day))
            newPerson.birthdayMonth = Int16(birthday.get(.month))
            
            newPerson.notes = notes
            
            newPerson.phoneNumber1 = phoneNumber1
            newPerson.phoneNumber2 = phoneNumber2
            newPerson.email1 = email1
            newPerson.email2 = email2
            newPerson.socialMedia1 = socialMedia1
            newPerson.socialMedia2 = socialMedia2
            
            newPerson.sharedToCalendar = makeCalendarForThisPerson
            
            newPerson.hasFavoriteColor = hasFavoriteColor
            newPerson.favoriteColor = favoriteColor.toHex() ?? "#FF7051"
            
            newPerson.photo = photoData
            
            for eachGroup in selectedGroups {
                eachGroup.addToPeople(newPerson)
            }
            for eachGroup in removeFromGroup {
                if eachGroup.getPeople.contains(newPerson) {
                    eachGroup.removeFromPeople(newPerson)
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
    
    func populateFields() {
        
        name = ((editPerson?.firstName ?? "") + " " + (editPerson?.lastName ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
        
        address = editPerson?.address ?? ""
        
        hasBirthday = editPerson?.hasBirthday ?? false
        birthday = editPerson?.birthday ?? Date()
        
        notes = editPerson?.notes ?? ""
        
        phoneNumber1 = editPerson?.phoneNumber1 ?? ""
        phoneNumber2 = editPerson?.phoneNumber2 ?? ""
        email1 = editPerson?.email1 ?? ""
        email2 = editPerson?.email2 ?? ""
        socialMedia1 = editPerson?.socialMedia1 ?? ""
        socialMedia2 = editPerson?.socialMedia2 ?? ""
        
        makeCalendarForThisPerson = editPerson?.sharedToCalendar ?? false
        
        hasFavoriteColor = editPerson?.hasFavoriteColor ?? false
        favoriteColor = Color(hex: editPerson?.favoriteColor ?? "#FF7051") ?? Color.red
        
        if editPerson != nil {
            if editPerson!.photo != nil {
                photoData = editPerson!.photo!
                if let uiImage = UIImage(data: editPerson!.photo!) {
                    photoImage = Image(uiImage: uiImage)
                } else {
                    print("Could not import contact photo")
                }
            }
        }
        
        selectedGroups = editPerson?.getGroups ?? []
        
    }
}


// ----------- for formatting phone numbers
public func formatPhoneNumber(inputString: String) -> String {
    var pn = inputString.filter("0123456789".contains)
    if (pn.count == 10) {
        let pnIn = pn.split(separator: "")
        pn = "("+pnIn[0]+pnIn[1]+pnIn[2]+") "
        pn += pnIn[3]+pnIn[4]+pnIn[5]+"-"
        pn += pnIn[6]+pnIn[7]+pnIn[8]+pnIn[9]
    }
    return pn
}

public func formatPhoneNumber11(inputString: String) -> String {
    var pn = inputString.filter("0123456789".contains)
    if (pn.count == 11) {
        let pnIn = pn.split(separator: "")
        pn = pnIn[0]+" ("+pnIn[1]+pnIn[2]+pnIn[3]+") "
        pn += pnIn[4]+pnIn[5]+pnIn[6]+"-"
        pn += pnIn[7]+pnIn[8]+pnIn[9]+pnIn[10]
    }
    return pn
}


func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
    //let size = image.size
    
//    let widthRatio  = targetSize.width  / size.width
//    let heightRatio = targetSize.height / size.height
//
//    // Figure out what our orientation is, and use that to form the rectangle
//    var newSize: CGSize
//    if(widthRatio > heightRatio) {
//        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
//    } else {
//        newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
//    }
    let newSize = targetSize
    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(origin: .zero, size: newSize)
    
    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
}

func cropImageToSquare(image: UIImage) -> UIImage? {
    var imageHeight = image.size.height
    var imageWidth = image.size.width

    if imageHeight > imageWidth {
        imageHeight = imageWidth
    }
    else {
        imageWidth = imageHeight
    }

    let size = CGSize(width: imageWidth, height: imageHeight)

    let refWidth : CGFloat = CGFloat(image.cgImage!.width)
    let refHeight : CGFloat = CGFloat(image.cgImage!.height)

    let x = (refWidth - size.width) / 2
    let y = (refHeight - size.height) / 2

    let cropRect = CGRect(x: x, y: y, width: size.height, height: size.width)
    if let imageRef = image.cgImage!.cropping(to: cropRect) {
        return UIImage(cgImage: imageRef, scale: 0, orientation: image.imageOrientation)
    }

    return nil
}
