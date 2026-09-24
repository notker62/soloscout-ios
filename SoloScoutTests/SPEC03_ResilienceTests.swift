//
//  SPEC03_ResilienceTests.swift
//  SoloScoutTests
//
//  Created by Vera (QA Specialist) on 24.09.2026.
//  Purpose: Verifies SPEC-03 ModelContainer resilience, schema integrity, and crash-prevention.
//  Module: Tests
//

import XCTest
import SwiftData
@testable import SoloScout

final class SPEC03_ResilienceTests: XCTestCase {

    func testModelContainerFactoryCreation() throws {
        // Test that the app container can be initialized in-memory without fatalError
        let container = SoloScoutApp.createModelContainer(inMemory: true)
        XCTAssertNotNil(container, "ModelContainer must initialize cleanly without fatalError")
        
        let context = ModelContext(container)
        let location = PhotoLocation(
            title: "Alpenpanorama Test",
            categories: ["Landschaft", "Berge"],
            latitude: 47.4211,
            longitude: 10.9853
        )
        context.insert(location)
        try context.save()
        
        let descriptor = FetchDescriptor<PhotoLocation>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Alpenpanorama Test")
        XCTAssertEqual(results.first?.categories, ["Landschaft", "Berge"])
    }

    func testLocationPhotoMetadataIntegrity() throws {
        let container = SoloScoutApp.createModelContainer(inMemory: true)
        let context = ModelContext(container)
        
        let location = PhotoLocation(
            title: "Königssee",
            categories: ["Wasser", "Natur"],
            latitude: 47.5562,
            longitude: 12.9733
        )
        context.insert(location)
        
        let photo = LocationPhoto()
        photo.focalLengthEquivalent = 35
        photo.originalLensModel = "iPhone Main Camera"
        location.photos.append(photo)
        
        try context.save()
        
        let descriptor = FetchDescriptor<PhotoLocation>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.first?.photos.count, 1)
        XCTAssertEqual(results.first?.photos.first?.focalLengthEquivalent, 35)
    }
}
