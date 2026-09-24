//
//  SPEC04_ExportBackupTests.swift
//  SoloScoutTests
//
//  Created by Vera (QA Specialist) on 24.09.2026.
//  Purpose: Automated verification contract for SPEC-04 JSON Backup & Markdown Export Engine.
//

import XCTest
import SwiftData
@testable import SoloScout

final class SPEC04_ExportBackupTests: XCTestCase {

    var modelContainer: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([PhotoLocation.self, LocationPhoto.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(modelContainer)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        context = nil
    }

    func testJSONExportSerializationAndRoundTrip() throws {
        // Arrange: Create a spot with notes, coordinates, and photo metadata
        let location = PhotoLocation(
            title: "Zugspitze Blick",
            categories: ["Landschaft", "Berge", "Goldene Stunde"],
            latitude: 47.4211,
            longitude: 10.9853
        )
        location.descriptionNotes = "Bester Spot auf dem Grat. Stativ zwingend erforderlich."
        location.hasParking = true
        location.parkingLatitude = 47.4100
        location.parkingLongitude = 10.9800
        location.requiredGear = ["Stativ", "ND1000 Filter", "Weitwinkel 16-35mm"]
        
        let photo = LocationPhoto(captureDate: Date(timeIntervalSince1970: 1727190000))
        photo.originalLensModel = "Sony FE 16-35mm F2.8 GM II"
        photo.focalLengthEquivalent = 24
        photo.aperture = 8.0
        photo.latitude = 47.4212
        photo.longitude = 10.9854
        photo.photoAssetIdentifier = "TEST-PHASSET-12345"
        
        location.photos.append(photo)
        context.insert(location)
        try context.save()

        // Act: Export to JSON
        let jsonData = try ExportService.exportToJSON(locations: [location])
        XCTAssertFalse(jsonData.isEmpty, "Exported JSON data must not be empty")

        // Assert: Parse back and verify integrity
        let imported = try ExportService.importFromJSON(data: jsonData)
        XCTAssertEqual(imported.count, 1)
        
        let importedSpot = imported[0]
        XCTAssertEqual(importedSpot.title, "Zugspitze Blick")
        XCTAssertEqual(importedSpot.descriptionNotes, "Bester Spot auf dem Grat. Stativ zwingend erforderlich.")
        XCTAssertEqual(importedSpot.latitude, 47.4211, accuracy: 0.0001)
        XCTAssertEqual(importedSpot.longitude, 10.9853, accuracy: 0.0001)
        XCTAssertTrue(importedSpot.hasParking)
        XCTAssertEqual(importedSpot.parkingLatitude, 47.4100)
        XCTAssertEqual(importedSpot.categories, ["Landschaft", "Berge", "Goldene Stunde"])
        XCTAssertEqual(importedSpot.requiredGear, ["Stativ", "ND1000 Filter", "Weitwinkel 16-35mm"])
        XCTAssertEqual(importedSpot.photos.count, 1)
        XCTAssertEqual(importedSpot.photos[0].originalLensModel, "Sony FE 16-35mm F2.8 GM II")
        XCTAssertEqual(importedSpot.photos[0].focalLengthEquivalent, 24)
        XCTAssertEqual(importedSpot.photos[0].aperture, 8.0)
    }

    func testMarkdownExportObsidianFormatting() throws {
        // Arrange
        let location = PhotoLocation(
            title: "Königssee Malerwinkel",
            categories: ["Wasser", "Alpen"],
            latitude: 47.5930,
            longitude: 12.9870
        )
        location.descriptionNotes = "Morgens vor 07:00 Uhr windstill für perfekte Wasserspiegelung."
        
        let photo = LocationPhoto()
        photo.originalLensModel = "24-70mm F2.8"
        photo.focalLengthEquivalent = 35
        photo.aperture = 5.6
        location.photos.append(photo)

        // Act
        let markdown = ExportService.exportSingleLocationToMarkdown(location: location)

        // Assert: Check YAML Frontmatter & Sections
        XCTAssertTrue(markdown.contains("---"), "Markdown must contain YAML frontmatter")
        XCTAssertTrue(markdown.contains("title: \"Königssee Malerwinkel\""))
        XCTAssertTrue(markdown.contains("latitude: 47.593"))
        XCTAssertTrue(markdown.contains("longitude: 12.987"))
        XCTAssertTrue(markdown.contains("## Scouting-Notizen"))
        XCTAssertTrue(markdown.contains("Morgens vor 07:00 Uhr windstill"))
        XCTAssertTrue(markdown.contains("24-70mm F2.8"))
        XCTAssertTrue(markdown.contains("35 mm"))
    }

    func testEmptyLocationExportHandlesGracefully() throws {
        let emptyJSON = try ExportService.exportToJSON(locations: [])
        let decoded = try ExportService.importFromJSON(data: emptyJSON)
        XCTAssertEqual(decoded.count, 0)
        
        let emptyMarkdown = ExportService.exportToMarkdown(locations: [])
        XCTAssertTrue(emptyMarkdown.contains("Keine Fotospots zum Exportieren"))
    }

    func testRestoreFromJSONInsertsEntitiesIntoModelContext() throws {
        // Arrange
        let originalLocation = PhotoLocation(
            title: "Watzmann Hocheck",
            categories: ["Hochtour", "Panorama"],
            latitude: 47.5539,
            longitude: 12.9219
        )
        originalLocation.descriptionNotes = "Aufstieg ab Wimbachbrücke 4h."
        originalLocation.hasParking = true
        originalLocation.parkingLatitude = 47.5800
        originalLocation.parkingLongitude = 12.9100
        
        let jsonData = try ExportService.exportToJSON(locations: [originalLocation])

        // Create a fresh clean context
        let freshSchema = Schema([PhotoLocation.self, LocationPhoto.self])
        let freshConfig = ModelConfiguration(schema: freshSchema, isStoredInMemoryOnly: true)
        let freshContainer = try ModelContainer(for: freshSchema, configurations: [freshConfig])
        let freshContext = ModelContext(freshContainer)

        // Act: Restore into fresh context
        let restoredCount = try ExportService.restoreFromJSON(data: jsonData, context: freshContext)
        XCTAssertEqual(restoredCount, 1)

        // Assert: Query fresh context
        let fetchDescriptor = FetchDescriptor<PhotoLocation>()
        let fetchedLocations = try freshContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedLocations.count, 1)
        XCTAssertEqual(fetchedLocations[0].title, "Watzmann Hocheck")
        XCTAssertEqual(fetchedLocations[0].descriptionNotes, "Aufstieg ab Wimbachbrücke 4h.")
        XCTAssertEqual(fetchedLocations[0].categories, ["Hochtour", "Panorama"])
        XCTAssertTrue(fetchedLocations[0].hasParking)
    }
}
