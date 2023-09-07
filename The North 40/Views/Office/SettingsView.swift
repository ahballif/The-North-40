//
//  SettingsView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/29/23.
//

import SwiftUI

struct SettingsView: View {
    
    @State private var smallestDivision = Int( 60 * DailyPlanner.minimumEventHeight / UserDefaults.standard.double(forKey: "hourHeight"))
    @State private var randomEventColor = UserDefaults.standard.bool(forKey: "randomEventColor")
    
    @State private var contactMethod = N40Event.CONTACT_OPTIONS[UserDefaults.standard.integer(forKey: "defaultContactMethod")]
    @State public var eventType: [String] = N40Event.EVENT_TYPE_OPTIONS[UserDefaults.standard.integer(forKey: "defaultCalendarEventType")]
    
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title2)
            
            Text("Calendar Settings").font(.title3).padding()
            HStack {
                Text("Calendar Resolution: \(smallestDivision) minutes")
                Spacer()
                Stepper("", value: $smallestDivision, in: 5...30, step: 5)
                    .onChange(of: smallestDivision)  { _ in
                        // minimumEventHeight / hourHeight == smallestDivision / 60
                        // SO hourHeight = 60 * minimumEventHeight / smallestDivision
                        // AND smallestDivision = Int( 60 * minimumEventHeight / hourHeight)
                        
                        let newHourHeight: Double = DailyPlanner.minimumEventHeight*60.0/Double(smallestDivision)
                        UserDefaults.standard.set(newHourHeight, forKey: "hourHeight")
                    }
                    .labelsHidden()
            }
            
            VStack {
                HStack {
                    Text("Default Event Type: ")
                    Spacer()
                }
                HStack {
                    Spacer()
                    Picker("Event Type: ", selection: $eventType) {
                        ForEach(N40Event.EVENT_TYPE_OPTIONS, id: \.self) {
                            Label($0[0], systemImage: $0[1])
                        }
                    }.onChange(of: eventType) {_ in
                        UserDefaults.standard.set(N40Event.EVENT_TYPE_OPTIONS.firstIndex(of: eventType) ?? 1, forKey: "defaultCalendarEventType")
                    }
                }
            }
            
            
            Text("Event Settings").font(.title3).padding()
            
            VStack {
                HStack {
                    Text("Default Contact Method: ")
                    Spacer()
                }
                HStack {
                    Spacer()
                    Picker("Contact Method: ", selection: $contactMethod) {
                        ForEach(N40Event.CONTACT_OPTIONS, id: \.self) {
                            Label($0[0], systemImage: $0[1])
                        }
                    }.onChange(of: contactMethod) {_ in
                        UserDefaults.standard.set(N40Event.CONTACT_OPTIONS.firstIndex(of: contactMethod) ?? 0, forKey: "defaultContactMethod")
                    }
                }
            }
            
            HStack {
                Text("Default Color Random: ")
                Spacer()
                Toggle("randomEventColor",isOn: $randomEventColor)
                    .onChange(of: randomEventColor) {_ in
                        UserDefaults.standard.set(randomEventColor, forKey: "randomEventColor")
                    }
                    .labelsHidden()
            }
            
            Spacer()
        }.padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
