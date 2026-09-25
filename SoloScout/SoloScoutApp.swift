//
//  SoloScoutApp.swift
//  SoloScout
//
//  Created by Felix on 30.07.2026.
//  Updated by Linus on 25.09.2026 (SPEC-04 iCloud Sync & SPEC-05 Persistent Catalog).
//  Purpose: Entry point for the SwiftUI application with resilient ModelContainer factory and automatic seeding.
//  Module: Main
//

import SwiftUI
import SwiftData

@main
struct SoloScoutApp: App {
    
    @AppStorage("isICloudSyncEnabled") private var isICloudSyncEnabled: Bool = false
    
    /// Canonical SwiftData schema definition containing all 4 core entities
    static let schema = Schema([
        PhotoLocation.self,
        LocationPhoto.self,
        TagItem.self,
        GearItem.self
    ])
    
    /// Resilient ModelContainer factory with graceful fallback and optional iCloud sync
    static func createModelContainer(inMemory: Bool = false, enableCloudKit: Bool = false) -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if enableCloudKit {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.de.nstconsult.SoloScout")
            )
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
        }
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            CatalogSeedingService.seedDefaultsIfNeeded(context: container.mainContext)
            return container
        } catch {
            print("⚠️ [SoloScoutApp] Persistent ModelContainer initialization failed: \(error.localizedDescription)")
            print("🔄 [SoloScoutApp] Attempting fallback to isolated in-memory container to prevent app crash...")
            
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                let fallbackContainer = try ModelContainer(for: schema, configurations: [fallbackConfig])
                CatalogSeedingService.seedDefaultsIfNeeded(context: fallbackContainer.mainContext)
                return fallbackContainer
            } catch {
                print("❌ [SoloScoutApp] Fallback container failed: \(error.localizedDescription)")
                fatalError("Fatal: Critical SwiftData engine failure: \(error.localizedDescription)")
            }
        }
    }
    
    var sharedModelContainer: ModelContainer
    
    init() {
        let isSyncEnabled = UserDefaults.standard.bool(forKey: "isICloudSyncEnabled")
        self.sharedModelContainer = SoloScoutApp.createModelContainer(inMemory: false, enableCloudKit: isSyncEnabled)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

