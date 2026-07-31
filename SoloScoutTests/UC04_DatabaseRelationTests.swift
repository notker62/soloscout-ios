//
//  UC04_DatabaseRelationTests.swift
//  SoloScoutTests
//
//  Created by Felix on 30.07.2026.
//  Purpose: Unit tests for UC-04 (1-to-N database relations, cascade deletion, and metadata alignment).
//  Module: Tests
//

import XCTest
import SwiftData
@testable import SoloScout

final class UC04_DatabaseRelationTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        // Initialize an in-memory database container for clean unit testing
        let schema = Schema([
            PhotoLocation.self,
            LocationPhoto.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    /// Test AC-04.1: Multiple photos can be added to a single location, preserving individual metadata and location drift.
    func testAddMultiplePhotosToLocation() throws {
        // 1. Create a parent location
        let location = PhotoLocation(title: "Castle Ruins", categories: ["Architecture"], latitude: 48.1351, longitude: 11.5820)
        context.insert(location)

        // 2. Create the first perspective shot (Wide Angle)
        let photo1 = LocationPhoto()
        photo1.focalLengthEquivalent = 24
        photo1.latitude = 48.1352 // Slight location drift
        photo1.longitude = 11.5821
        photo1.originalLensModel = "iPhone 15 Pro Wide Lens"
        location.photos.append(photo1)

        // 3. Create the second perspective shot (Telephoto)
        let photo2 = LocationPhoto()
        photo2.focalLengthEquivalent = 120
        photo2.latitude = 48.1350
        photo2.longitude = 11.5819
        photo2.originalLensModel = "iPhone 15 Pro Telephoto Lens"
        location.photos.append(photo2)

        try context.save()

        // 4. Fetch and verify
        let descriptor = FetchDescriptor<PhotoLocation>()
        let results = try context.fetch(descriptor)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.photos.count, 2)

        let sortedPhotos = results.first?.photos.sorted { ($0.focalLengthEquivalent ?? 0) < ($1.focalLengthEquivalent ?? 0) }
        XCTAssertEqual(sortedPhotos?[0].focalLengthEquivalent, 24)
        XCTAssertEqual(sortedPhotos?[1].focalLengthEquivalent, 120)
        XCTAssertEqual(sortedPhotos?[0].originalLensModel, "iPhone 15 Pro Wide Lens")
        XCTAssertEqual(sortedPhotos?[1].originalLensModel, "iPhone 15 Pro Telephoto Lens")
    }

    /// Test AC-04.2: Deleting a single photo from a location does not delete the parent location or other sibling photos.
    func testDeleteSinglePhotoPreservesParent() throws {
        let location = PhotoLocation(title: "Lake Side", categories: ["Nature"], latitude: 47.1234, longitude: 12.3456)
        context.insert(location)

        let photo1 = LocationPhoto()
        photo1.focalLengthEquivalent = 50
        location.photos.append(photo1)

        let photo2 = LocationPhoto()
        photo2.focalLengthEquivalent = 85
        location.photos.append(photo2)

        try context.save()

        // Delete photo1
        context.delete(photo1)
        try context.save()

        // Verify photo1 is gone, but photo2 and parent location remain
        let fetchedLocations = try context.fetch(FetchDescriptor<PhotoLocation>())
        XCTAssertEqual(fetchedLocations.count, 1)
        XCTAssertEqual(fetchedLocations.first?.photos.count, 1)
        XCTAssertEqual(fetchedLocations.first?.photos.first?.focalLengthEquivalent, 85)
    }

    /// Test AC-04.3: Deleting the parent location cascades and automatically purges all associated photos.
    func testDeleteParentCascadesToPhotos() throws {
        let location = PhotoLocation(title: "Street View", categories: ["Street"], latitude: 52.5200, longitude: 13.4050)
        context.insert(location)

        let photo = LocationPhoto()
        location.photos.append(photo)

        try context.save()

        // Verify objects are in DB
        let fetchedPhotosBefore = try context.fetch(FetchDescriptor<LocationPhoto>())
        XCTAssertEqual(fetchedPhotosBefore.count, 1)

        // Delete parent location
        context.delete(location)
        try context.save()

        // Verify both location and child photos are cascading deleted
        let fetchedLocationsAfter = try context.fetch(FetchDescriptor<PhotoLocation>())
        let fetchedPhotosAfter = try context.fetch(FetchDescriptor<LocationPhoto>())

        XCTAssertEqual(fetchedLocationsAfter.count, 0)
        XCTAssertEqual(fetchedPhotosAfter.count, 0)
    }
}
