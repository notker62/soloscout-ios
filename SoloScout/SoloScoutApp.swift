//
//  SoloScoutApp.swift
//  SoloScout
//
//  Created by Felix on 30.07.2026.
//  Updated by Linus on 24.09.2026 (SPEC-03 SwiftData Resilience & Recovery).
//  Purpose: Entry point for the SwiftUI application with resilient ModelContainer factory.
//  Module: Main
//

import SwiftUI
import SwiftData

@main
struct SoloScoutApp: App {
    
    /// Canonical SwiftData schema definition
    static let schema = Schema([
        PhotoLocation.self,
        LocationPhoto.self
    ])
    
    /// Resilient ModelContainer factory with graceful fallback and crash prevention (SPEC-03)
    static func createModelContainer(inMemory: Bool = false) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            print("⚠️ [SoloScoutApp] Persistent ModelContainer initialization failed: \(error.localizedDescription)")
            print("🔄 [SoloScoutApp] Attempting fallback to isolated in-memory container to prevent app crash...")
            
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                print("❌ [SoloScoutApp] Fallback container failed: \(error.localizedDescription)")
                fatalError("Fatal: Critical SwiftData engine failure: \(error.localizedDescription)")
            }
        }
    }
    
    // Configure SwiftData database container via resilient factory
    var sharedModelContainer: ModelContainer = SoloScoutApp.createModelContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
