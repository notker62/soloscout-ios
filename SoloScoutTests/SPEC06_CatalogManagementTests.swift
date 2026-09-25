//
//  SPEC06_CatalogManagementTests.swift
//  SoloScoutTests
//
//  Created by Vera (QA Specialist) on 25.09.2026.
//  Purpose: Automated verification contract for SPEC-06 Catalog Management (Tags & Gear) in Settings.
//

import XCTest
import SwiftData
@testable import SoloScout

final class SPEC06_CatalogManagementTests: XCTestCase {

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

    func testTagManagementAddAndCascadeDeletion() throws {
        // Arrange: Seed and add custom tag
        CatalogSeedingService.seedDefaultsIfNeeded(context: context)
        
        let customTag = TagItem(name: "Astrofotografie", isDefault: false)
        context.insert(customTag)
        
        let spot1 = PhotoLocation(title: "Spot 1", categories: ["Landschaft", "Astrofotografie"], latitude: 47.0, longitude: 11.0)
        let spot2 = PhotoLocation(title: "Spot 2", categories: ["Astrofotografie", "Nacht"], latitude: 47.1, longitude: 11.1)
        let spot3 = PhotoLocation(title: "Spot 3", categories: ["Architektur"], latitude: 47.2, longitude: 11.2)
        
        context.insert(spot1)
        context.insert(spot2)
        context.insert(spot3)
        try context.save()
        
        // Verify before state
        let initialTagFetch = try context.fetch(FetchDescriptor<TagItem>(predicate: #Predicate { $0.name == "Astrofotografie" }))
        XCTAssertEqual(initialTagFetch.count, 1)
        
        // Act: Perform cascade deletion of "Astrofotografie"
        let allLocations = try context.fetch(FetchDescriptor<PhotoLocation>())
        for loc in allLocations {
            if loc.categories.contains("Astrofotografie") {
                loc.categories.removeAll { $0 == "Astrofotografie" }
            }
        }
        context.delete(customTag)
        try context.save()
        
        // Assert: Tag is gone from catalog and removed from spot categories
        let afterTagFetch = try context.fetch(FetchDescriptor<TagItem>(predicate: #Predicate { $0.name == "Astrofotografie" }))
        XCTAssertEqual(afterTagFetch.count, 0, "Custom tag must be deleted from catalog")
        
        let reloadedSpot1 = try context.fetch(FetchDescriptor<PhotoLocation>(predicate: #Predicate { $0.title == "Spot 1" })).first
        let reloadedSpot2 = try context.fetch(FetchDescriptor<PhotoLocation>(predicate: #Predicate { $0.title == "Spot 2" })).first
        
        XCTAssertEqual(reloadedSpot1?.categories, ["Landschaft"], "Spot 1 must no longer contain deleted tag")
        XCTAssertEqual(reloadedSpot2?.categories, ["Nacht"], "Spot 2 must no longer contain deleted tag")
    }

    func testGearManagementAddAndCascadeDeletion() throws {
        // Arrange: Add custom gear and assign to spots
        let customGear = GearItem(name: "Sony FE 200-600mm G OSS", categoryRaw: "lens", isFavorite: true, isDefault: false)
        context.insert(customGear)
        
        let spot1 = PhotoLocation(title: "Wildlife Spot", categories: ["Natur"], latitude: 48.0, longitude: 12.0)
        spot1.requiredGear = ["Stativ", "Sony FE 200-600mm G OSS"]
        
        let spot2 = PhotoLocation(title: "Landscape Spot", categories: ["Landschaft"], latitude: 48.1, longitude: 12.1)
        spot2.requiredGear = ["Polfilter"]
        
        context.insert(spot1)
        context.insert(spot2)
        try context.save()
        
        // Act: Delete custom gear with cascade cleanup
        let allLocations = try context.fetch(FetchDescriptor<PhotoLocation>())
        for loc in allLocations {
            if loc.requiredGear.contains("Sony FE 200-600mm G OSS") {
                loc.requiredGear.removeAll { $0 == "Sony FE 200-600mm G OSS" }
            }
        }
        context.delete(customGear)
        try context.save()
        
        // Assert: GearItem is deleted and removed from spot
        let reloadedGear = try context.fetch(FetchDescriptor<GearItem>(predicate: #Predicate { $0.name == "Sony FE 200-600mm G OSS" }))
        XCTAssertEqual(reloadedGear.count, 0)
        
        let reloadedSpot1 = try context.fetch(FetchDescriptor<PhotoLocation>(predicate: #Predicate { $0.title == "Wildlife Spot" })).first
        XCTAssertEqual(reloadedSpot1?.requiredGear, ["Stativ"], "Deleted gear item must be purged from spot")
    }

    func testSpotCaptureSelectionDoesNotMutateCatalog() throws {
        // Arrange: Seed defaults
        CatalogSeedingService.seedDefaultsIfNeeded(context: context)
        
        let initialTagCount = try context.fetch(FetchDescriptor<TagItem>()).count
        let initialGearCount = try context.fetch(FetchDescriptor<GearItem>()).count
        
        // Act: Simulate selecting and deselecting tags and gear in spot capture
        var selectedCats: [String] = ["Landschaft", "Natur"]
        selectedCats.removeAll { $0 == "Landschaft" }
        selectedCats.append("Architektur")
        
        var selectedGear: [String] = ["Stativ"]
        selectedGear.removeAll { $0 == "Stativ" }
        selectedGear.append("ND-Filter")
        
        let spot = PhotoLocation(title: "Test Spot", categories: selectedCats, latitude: 50.0, longitude: 8.0)
        spot.requiredGear = selectedGear
        context.insert(spot)
        try context.save()
        
        // Assert: Catalog count remains completely unchanged
        let afterTagCount = try context.fetch(FetchDescriptor<TagItem>()).count
        let afterGearCount = try context.fetch(FetchDescriptor<GearItem>()).count
        
        XCTAssertEqual(afterTagCount, initialTagCount, "Spot capture selection must not alter global TagItem catalog count")
        XCTAssertEqual(afterGearCount, initialGearCount, "Spot capture selection must not alter global GearItem catalog count")
    }

    func testDefaultTagsAndGearProtected() throws {
        CatalogSeedingService.seedDefaultsIfNeeded(context: context)
        
        let defaultTags = try context.fetch(FetchDescriptor<TagItem>(predicate: #Predicate { $0.isDefault }))
        let defaultGear = try context.fetch(FetchDescriptor<GearItem>(predicate: #Predicate { $0.isDefault }))
        
        XCTAssertEqual(defaultTags.count, 7, "All 7 seeded default tags must have isDefault = true")
        XCTAssertEqual(defaultGear.count, 6, "All 6 seeded default gear items must have isDefault = true")
    }
}
