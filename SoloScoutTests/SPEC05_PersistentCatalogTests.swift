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

    // MARK: - Rainy Day Test Suite (TEST-05.6 & TEST-05.7)

    func testRealDiskSQLitePersistenceRoundTrip() throws {
        // Arrange: Create a dedicated temporary disk SQLite database
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let storeURL = tempDir.appendingPathComponent("test_real_disk.store")
        
        let schema = Schema([
            PhotoLocation.self,
            LocationPhoto.self,
            TagItem.self,
            GearItem.self
        ])
        let diskConfig = ModelConfiguration(url: storeURL)
        
        // Act 1: Open container 1, insert spot with photo and gear, save and destroy container
        do {
            let container1 = try ModelContainer(for: schema, configurations: [diskConfig])
            let ctx1 = ModelContext(container1)
            
            let spot = PhotoLocation(title: "Walchensee Herzogstand", categories: ["Berge", "See"], latitude: 47.604, longitude: 11.311)
            spot.descriptionNotes = "Sonnenaufgang über dem See"
            spot.requiredGear = ["Stativ", "Graufilter"]
            
            let photo = LocationPhoto()
            photo.originalLensModel = "FE 24-70mm F2.8 GM II"
            photo.focalLengthEquivalent = 35
            photo.thumbnailData = Data([0xDE, 0xAD, 0xBE, 0xEF])
            photo.location = spot
            
            let tag = TagItem(name: "Herbststimmung", isDefault: false)
            let gear = GearItem(name: "Gimbal Ronin-S", categoryRaw: "gimbal", isFavorite: true, isDefault: false)
            
            ctx1.insert(spot)
            ctx1.insert(photo)
            spot.photos.append(photo)
            ctx1.insert(tag)
            ctx1.insert(gear)
            
            try ctx1.save()
        }
        
        // Assert & Act 2: Verify physical SQLite file exists on SSD
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path), "Physical SQLite database file must exist on SSD")
        
        // Act 3: Open brand new container 2 pointing to the same disk file
        let container2 = try ModelContainer(for: schema, configurations: [diskConfig])
        let ctx2 = ModelContext(container2)
        
        let loadedSpots = try ctx2.fetch(FetchDescriptor<PhotoLocation>())
        let loadedPhotos = try ctx2.fetch(FetchDescriptor<LocationPhoto>())
        let loadedTags = try ctx2.fetch(FetchDescriptor<TagItem>(predicate: #Predicate { $0.name == "Herbststimmung" }))
        let loadedGear = try ctx2.fetch(FetchDescriptor<GearItem>(predicate: #Predicate { $0.name == "Gimbal Ronin-S" }))
        
        XCTAssertEqual(loadedSpots.count, 1, "Must persist spot across container reloads on SSD")
        XCTAssertEqual(loadedSpots.first?.title, "Walchensee Herzogstand")
        XCTAssertEqual(loadedSpots.first?.requiredGear, ["Stativ", "Graufilter"])
        XCTAssertEqual(loadedPhotos.count, 1, "Must persist associated photo across container reloads on SSD")
        XCTAssertEqual(loadedPhotos.first?.focalLengthEquivalent, 35)
        XCTAssertEqual(loadedPhotos.first?.thumbnailData, Data([0xDE, 0xAD, 0xBE, 0xEF]))
        XCTAssertEqual(loadedTags.count, 1, "Must persist custom tag across container reloads on SSD")
        XCTAssertEqual(loadedGear.count, 1, "Must persist custom gear across container reloads on SSD")
        
        // Clean up
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testCloudKitFailureGracefullyFallsBackToDiskSSDNotRAM() {
        // When CloudKit is requested in an environment without provisioned CloudKit container,
        // createModelContainer must fallback to persistent local SSD, NOT volatile RAM.
        let container = SoloScoutApp.createModelContainer(inMemory: false, enableCloudKit: true)
        
        XCTAssertFalse(container.configurations.first?.isStoredInMemoryOnly ?? true,
                       "Production container must NEVER silently degrade to in-memory RAM mode on CloudKit failure")
    }
}
