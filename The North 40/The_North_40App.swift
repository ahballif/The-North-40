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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
