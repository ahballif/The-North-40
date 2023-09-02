//
//  The_North_40App.swift
//  The North 40
//
//  Created by Addison Ballif on 8/7/23.
//

import SwiftUI

@main
struct The_North_40App: App {
    let persistenceController = PersistenceController.shared

    init() {
        UserDefaults.standard.register(defaults: [
            "hourHeight": 100.0,
            "randomEventColor": true
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
