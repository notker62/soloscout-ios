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
    
    /// Resilient ModelContainer factory with guaranteed SSD persistence and optional CloudKit sync
    static func createModelContainer(inMemory: Bool = false, enableCloudKit: Bool = false) -> ModelContainer {
        if inMemory {
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            if let container = try? ModelContainer(for: schema, configurations: [memoryConfig]) {
                CatalogSeedingService.seedDefaultsIfNeeded(context: container.mainContext)
                return container
            }
        }
        
        // 1. Try persistent container with CloudKit if enabled
        if enableCloudKit {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            if let container = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
                print("✅ [SoloScoutApp] Initialized persistent ModelContainer with CloudKit sync.")
                CatalogSeedingService.seedDefaultsIfNeeded(context: container.mainContext)
                return container
            } else {
                print("⚠️ [SoloScoutApp] CloudKit container init failed (no active CloudKit entitlement). Falling back to persistent local SSD store.")
            }
        }
        
        // 2. Persistent container locally (SSD SQLite database)
        let localConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [localConfig])
            print("✅ [SoloScoutApp] Initialized persistent local SSD ModelContainer.")
            CatalogSeedingService.seedDefaultsIfNeeded(context: container.mainContext)
            return container
        } catch {
            print("⚠️ [SoloScoutApp] Local ModelContainer load failed with error: \(error). Performing clean store reset to preserve SSD persistence...")
            
            // Re-create a clean persistent store file
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            if let storeURL = appSupport?.appendingPathComponent("default.store") {
                try? FileManager.default.removeItem(at: storeURL)
                let shmURL = appSupport?.appendingPathComponent("default.store-shm")
                let walURL = appSupport?.appendingPathComponent("default.store-wal")
                if let shmURL = shmURL { try? FileManager.default.removeItem(at: shmURL) }
                if let walURL = walURL { try? FileManager.default.removeItem(at: walURL) }
            }
            
            do {
                let freshContainer = try ModelContainer(for: schema, configurations: [localConfig])
                print("✅ [SoloScoutApp] Re-created clean persistent local SSD ModelContainer.")
                CatalogSeedingService.seedDefaultsIfNeeded(context: freshContainer.mainContext)
                return freshContainer
            } catch {
                print("❌ [SoloScoutApp] Critical failure: \(error.localizedDescription)")
                fatalError("Fatal: SwiftData database initialization failed: \(error.localizedDescription)")
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

