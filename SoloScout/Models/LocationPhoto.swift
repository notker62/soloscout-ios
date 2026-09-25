//
//  LocationPhoto.swift
//  SoloScout
//
//  Created by Felix on 30.07.2026.
//  Purpose: SwiftData Model for individual photos associated with a location.
//  Module: Models
//

import Foundation
import SwiftData

@Model
public final class LocationPhoto {
    public var id: UUID = UUID()
    public var photoAssetIdentifier: String? // System reference to iOS PHAsset
    public var thumbnailData: Data? // Local Cache thumbnail data
    public var captureDate: Date = Date()
    
    // Photo-specific GPS Coordinates (can drift slightly from parent spot)
    public var latitude: Double?
    public var longitude: Double?
    
    // EXIF metadata extracted from import
    public var originalLensModel: String?
    public var focalLengthEquivalent: Int? // Full Frame Equivalent in mm
    public var aperture: Double?
    
    // Relation back to the parent Location
    public var location: PhotoLocation?
    
    public init(captureDate: Date = Date()) {
        self.id = UUID()
        self.captureDate = captureDate
    }
}
