//
//  UC02_PhotoServiceTests.swift
//  SoloScoutTests
//
//  Created by Felix on 30.07.2026.
//  Purpose: Unit tests for PhotoService and focal length mapping heuristics.
//  Module: Tests
//

import XCTest
@testable import SoloScout

final class UC02_PhotoServiceTests: XCTestCase {
    var photoService: PhotoService!

    override func setUpWithError() throws {
        photoService = PhotoService()
    }

    override func tearDownWithError() throws {
        photoService = nil
    }

    /// Tests the lens mapping logic of PhotoService (heuristics for iPhone standard lenses).
    func testFocalLengthHeuristics() throws {
        // Test ultra-wide (approx 1.54mm real focal length -> 13mm equivalent)
        let ultraWide = photoService.calculateFocalLengthEquivalent(focalLength: 1.54, lensModel: "iPhone 15 Pro Back Camera")
        XCTAssertEqual(ultraWide, 13)
        
        // Test wide (approx 6.86mm real focal length -> 24mm equivalent)
        let standardWide = photoService.calculateFocalLengthEquivalent(focalLength: 5.9, lensModel: "iPhone 15 Pro Back Camera")
        XCTAssertEqual(standardWide, 24)
        
        // Test tele 3x (approx 9.0mm real focal length -> 77mm equivalent)
        let tele3x = photoService.calculateFocalLengthEquivalent(focalLength: 9.0, lensModel: "iPhone 13 Pro Back Camera")
        XCTAssertEqual(tele3x, 77)
        
        // Test tele 5x (approx 15.0mm real focal length -> 120mm equivalent)
        let tele5x = photoService.calculateFocalLengthEquivalent(focalLength: 15.3, lensModel: "iPhone 15 Pro Max Back Camera")
        XCTAssertEqual(tele5x, 120)
    }
}
