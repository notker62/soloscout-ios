//
//  SPEC05_PersistentCatalogTests.swift
//  SoloScoutTests
//
//  Created by Vera (QA Specialist) on 25.09.2026.
//  Purpose: Automated verification contract for SPEC-04 (iCloud toggle persistence) and SPEC-05 (Tag/Gear Catalog & Data Persistence).
//

import XCTest
import SwiftData
@testable import SoloScout

final class SPEC05_PersistentCatalogTests: XCTestCase {

    var modelContainer: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([
            PhotoLocation.self,
            LocationPhoto.self,
            TagItem.self,
            GearItem.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(modelContainer)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        context = nil
    }

    func testCatalogSeedingIdempotency() throws {
        // Run seeding on an empty context
        CatalogSeedingService.seedDefaultsIfNeeded(context: context)
        
        let initialTags = try context.fetch(FetchDescriptor<TagItem>())
        let initialGear = try context.fetch(FetchDescriptor<GearItem>())
        
        XCTAssertEqual(initialTags.count, 7, "Default seed should insert exactly 7 TagItem entities")
        XCTAssertEqual(initialGear.count, 6, "Default seed should insert exactly 6 GearItem entities")
        
        // Run seeding a second time - must be strictly idempotent
        CatalogSeedingService.seedDefaultsIfNeeded(context: context)
        
        let tagsAfterSecondSeed = try context.fetch(FetchDescriptor<TagItem>())
        let gearAfterSecondSeed = try context.fetch(FetchDescriptor<GearItem>())
        
        XCTAssertEqual(tagsAfterSecondSeed.count, 7, "Subsequent seed calls must not duplicate tags")
        XCTAssertEqual(gearAfterSecondSeed.count, 6, "Subsequent seed calls must not duplicate gear")
    }

    func testCustomTagPersistenceAndRetrieval() throws {
        // Insert custom tag
        let customTag = TagItem(name: "Astrofotografie", isDefault: false)
        context.insert(customTag)
        try context.save()
        
        let fetchDesc = FetchDescriptor<TagItem>(predicate: #Predicate { $0.name == "Astrofotografie" })
        let results = try context.fetch(fetchDesc)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Astrofotografie")
        XCTAssertFalse(results.first?.isDefault ?? true)
    }

    func testCustomGearPersistenceAndRetrieval() throws {
        // Insert custom gear item
        let customGear = GearItem(name: "Sony FE 200-600mm G OSS", categoryRaw: "lens", isFavorite: true, isDefault: false)
        context.insert(customGear)
        try context.save()
        
        let fetchDesc = FetchDescriptor<GearItem>(predicate: #Predicate { $0.name == "Sony FE 200-600mm G OSS" })
        let results = try context.fetch(fetchDesc)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Sony FE 200-600mm G OSS")
        XCTAssertEqual(results.first?.categoryRaw, "lens")
        XCTAssertTrue(results.first?.isFavorite ?? false)
        XCTAssertFalse(results.first?.isDefault ?? true)
    }

    func testSettingsICloudToggleUserDefaultsStorage() {
        let defaultsKey = "isICloudSyncEnabled"
        let previousValue = UserDefaults.standard.bool(forKey: defaultsKey)
        
        // Toggle on
        UserDefaults.standard.set(true, forKey: defaultsKey)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: defaultsKey))
        
        // Toggle off
        UserDefaults.standard.set(false, forKey: defaultsKey)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: defaultsKey))
        
        // Restore previous value
        UserDefaults.standard.set(previousValue, forKey: defaultsKey)
    }

    func testPhotoLocationWithCustomTagsAndGearIntegrity() throws {
        let location = PhotoLocation(
            title: "Dolomiten Drei Zinnen",
            categories: ["Landschaft", "Berge", "Astrofotografie"],
            latitude: 46.6186,
            longitude: 12.3028
        )
        location.requiredGear = ["Stativ", "Fernauslöser", "Sony FE 14mm F1.8 GM"]
        
        context.insert(location)
        try context.save()
        
        let fetchDesc = FetchDescriptor<PhotoLocation>(predicate: #Predicate { $0.title == "Dolomiten Drei Zinnen" })
        let results = try context.fetch(fetchDesc)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.categories.count, 3)
        XCTAssertTrue(results.first?.categories.contains("Astrofotografie") ?? false)
        XCTAssertTrue(results.first?.requiredGear.contains("Sony FE 14mm F1.8 GM") ?? false)
    }
}
