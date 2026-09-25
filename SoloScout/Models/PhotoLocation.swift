//
//  PhotoLocation.swift
//  SoloScout
//
//  Created by Felix on 30.07.2026.
//  Purpose: SwiftData Model for the parent photo location entity.
//  Module: Models
//

import Foundation
import SwiftData

@Model
public final class PhotoLocation {
    public var id: UUID = UUID()
    public var title: String = ""
    public var descriptionNotes: String = ""
    public var creationDate: Date = Date()
    public var categories: [String] = []
    
    // GPS Coordinates of the spot
    public var latitude: Double = 0.0
    public var longitude: Double = 0.0
    
    // Optional parking coordinates
    public var hasParking: Bool = false
    public var parkingLatitude: Double?
    public var parkingLongitude: Double?
    
    // Customized required gear and times of day/season
    public var requiredGear: [String] = []
    public var bestSeasons: Int = 0 // Bitmask: Spring(1) | Summer(2) | Autumn(4) | Winter(8)
    public var bestTimesOfDay: Int = 0 // Bitmask: Morning(1) | Noon(2) | Evening(4) | Golden(8) | Blue(16)
    
    // One-to-many relationship: One spot has many photos
    @Relationship(deleteRule: .cascade, inverse: \LocationPhoto.location)
    public var photos: [LocationPhoto] = []
    
    public init(title: String, categories: [String] = [], latitude: Double, longitude: Double) {
        self.id = UUID()
        self.title = title
        self.descriptionNotes = ""
        self.creationDate = Date()
        self.categories = categories
        self.latitude = latitude
        self.longitude = longitude
        self.hasParking = false
        self.requiredGear = []
        self.bestSeasons = 0
        self.bestTimesOfDay = 0
        self.photos = []
    }
}
