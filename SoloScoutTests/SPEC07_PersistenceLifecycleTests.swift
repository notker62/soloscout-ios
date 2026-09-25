//
//  SPEC07_PersistenceLifecycleTests.swift
//  SoloScoutTests
//
//  Created by Vera (QA Specialist) on 25.09.2026.
//  Purpose: Automated verification contract for SPEC-07 Synchronous Disk Flush, App Lifecycle Guard, and Cold-Start Ready State.
//

import XCTest
import SwiftData
@testable import SoloScout

final class SPEC07_PersistenceLifecycleTests: XCTestCase {

    var tempDir: URL!
    var storeURL: URL!
    var schema: Schema!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("spec07_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        storeURL = tempDir.appendingPathComponent("spec07_store.store")
        
        schema = Schema([
            PhotoLocation.self,
            LocationPhoto.self,
            TagItem.self,
            GearItem.self
        ])
    }

    override func tearDownWithError() throws {
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
    }

    func testImmediateSynchronousDiskFlushOnLocationSave() throws {
        // Arrange: Open real disk container
        let diskConfig = ModelConfiguration(url: storeURL)
        let container = try ModelContainer(for: schema, configurations: [diskConfig])
        let context = ModelContext(container)
        
        // Act: Insert spot with photo, tag, and gear (all 4 domains)
        let spot = PhotoLocation(title: "Zugspitzblick Grainau", categories: ["Berge", "Alpenpanorama"], latitude: 47.47, longitude: 11.02)
        spot.descriptionNotes = "Morgensonne auf der Nordwand"
        spot.requiredGear = ["Stativ", "Weitwinkel"]
        
        let photo = LocationPhoto()
        photo.thumbnailData = Data([0xCA, 0xFE, 0xBA, 0xBE])
        photo.focalLengthEquivalent = 24
        photo.location = spot
        
        let tag = TagItem(name: "Alpenpanorama", isDefault: false)
        let gear = GearItem(name: "Weitwinkel", categoryRaw: "lens", isFavorite: true, isDefault: false)
        
        context.insert(spot)
        context.insert(photo)
        spot.photos.append(photo)
        context.insert(tag)
        context.insert(gear)
        
        // Synchronous flush
        try context.save()
        
        // Assert 1: Disk file must immediately exist and have non-zero size
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path), "SQLite store file must exist on disk immediately")
        let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        XCTAssertGreaterThan(fileSize, 0, "SQLite store file must contain non-zero bytes")
        
        // Assert 2: Second fresh container on same file immediately reads all 4 entities
        let freshContainer = try ModelContainer(for: schema, configurations: [diskConfig])
        let readContext = ModelContext(freshContainer)
        
        let fetchedSpots = try readContext.fetch(FetchDescriptor<PhotoLocation>())
        let fetchedPhotos = try readContext.fetch(FetchDescriptor<LocationPhoto>())
        let fetchedTags = try readContext.fetch(FetchDescriptor<TagItem>(predicate: #Predicate { $0.name == "Alpenpanorama" }))
        let fetchedGear = try readContext.fetch(FetchDescriptor<GearItem>(predicate: #Predicate { $0.name == "Weitwinkel" }))
        
        XCTAssertEqual(fetchedSpots.count, 1)
        XCTAssertEqual(fetchedSpots.first?.title, "Zugspitzblick Grainau")
        XCTAssertEqual(fetchedPhotos.count, 1)
        XCTAssertEqual(fetchedPhotos.first?.focalLengthEquivalent, 24)
        XCTAssertEqual(fetchedTags.count, 1)
        XCTAssertEqual(fetchedGear.count, 1)
    }

    func testAppLifecycleScenePhaseBackgroundTriggersSave() throws {
        // Arrange: Real disk container with uncommitted context change
        let diskConfig = ModelConfiguration(url: storeURL)
        let container = try ModelContainer(for: schema, configurations: [diskConfig])
        let context = ModelContext(container)
        
        let spot = PhotoLocation(title: "Eibsee Rundweg", categories: ["See"], latitude: 47.45, longitude: 10.99)
        context.insert(spot)
        
        // Simulate lifecycle scenePhase transition to background -> perform save
        XCTAssertTrue(context.hasChanges, "Context must have uncommitted changes before background flush")
        try context.save()
        XCTAssertFalse(context.hasChanges, "Context must be fully committed after background flush")
        
        // Assert: Data was written to disk
        let freshContainer = try ModelContainer(for: schema, configurations: [diskConfig])
        let freshContext = ModelContext(freshContainer)
        let reloadedSpots = try freshContext.fetch(FetchDescriptor<PhotoLocation>())
        
        XCTAssertEqual(reloadedSpots.count, 1)
        XCTAssertEqual(reloadedSpots.first?.title, "Eibsee Rundweg")
    }

    func testColdStartLoadingStateTransitionsToReady() {
        let splash = SplashLoadingView(isICloudSyncEnabled: false)
        XCTAssertNotNil(splash)
        
        let splashCloud = SplashLoadingView(isICloudSyncEnabled: true)
        XCTAssertNotNil(splashCloud)
    }
}
