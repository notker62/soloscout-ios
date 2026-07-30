//
//  SoloScoutApp.swift
//  SoloScout
//
//  Created by Felix on 30.07.2026.
//  Purpose: Entry point for the SwiftUI application.
//  Module: Main
//

import SwiftUI
import SwiftData

@main
struct SoloScoutApp: App {
    // Configure SwiftData database container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PhotoLocation.self,
            LocationPhoto.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
