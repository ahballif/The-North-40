//
//  SettingsView.swift
//  The North 40
//
//  Created by Addison Ballif on 8/29/23.
//

import SwiftUI

struct SettingsView: View {
    
    @State private var smallestDivision = 15 // in minutes
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title2)
            
            Text("Calendar").font(.title3)
            HStack {
                Text("Calendar Resolution: \(smallestDivision) minutes")
                    .onAppear {
                        smallestDivision = Int( 60 * DailyPlanner.minimumEventHeight / UserDefaults.standard.double(forKey: "hourHeight"))
                    }
                Stepper("", value: $smallestDivision, in: 5...30, step: 5)
                    .onChange(of: smallestDivision)  { _ in
                        // minimumEventHeight / hourHeight == smallestDivision / 60
                        // SO hourHeight = 60 * minimumEventHeight / smallestDivision
                        // AND smallestDivision = Int( 60 * minimumEventHeight / hourHeight)
                        
                        let newHourHeight: Double = DailyPlanner.minimumEventHeight*60.0/Double(smallestDivision)
                        UserDefaults.standard.set(newHourHeight, forKey: "hourHeight")
                    }
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
