//
//  ExportService.swift
//  SoloScout
//
//  Created by Felix & Silas on 24.09.2026.
//  Purpose: SPEC-04 JSON Backup and Obsidian-compatible Markdown Export Engine.
//  Module: Services
//

import Foundation
import SwiftData

// MARK: - Export Data Transfer Objects (Codable)

public struct PhotoExportDTO: Codable, Sendable {
    public let id: UUID
    public let captureDate: Date
    public let latitude: Double?
    public let longitude: Double?
    public let originalLensModel: String?
    public let focalLengthEquivalent: Int?
    public let aperture: Double?
    public let photoAssetIdentifier: String?
    
    public init(from photo: LocationPhoto) {
        self.id = photo.id
        self.captureDate = photo.captureDate
        self.latitude = photo.latitude
        self.longitude = photo.longitude
        self.originalLensModel = photo.originalLensModel
        self.focalLengthEquivalent = photo.focalLengthEquivalent
        self.aperture = photo.aperture
        self.photoAssetIdentifier = photo.photoAssetIdentifier
    }
}

public struct LocationExportDTO: Codable, Sendable {
    public let id: UUID
    public let title: String
    public let descriptionNotes: String
    public let creationDate: Date
    public let categories: [String]
    public let latitude: Double
    public let longitude: Double
    public let hasParking: Bool
    public let parkingLatitude: Double?
    public let parkingLongitude: Double?
    public let requiredGear: [String]
    public let bestSeasons: Int
    public let bestTimesOfDay: Int
    public let photos: [PhotoExportDTO]
    
    public init(from location: PhotoLocation) {
        self.id = location.id
        self.title = location.title
        self.descriptionNotes = location.descriptionNotes
        self.creationDate = location.creationDate
        self.categories = location.categories
        self.latitude = location.latitude
        self.longitude = location.longitude
        self.hasParking = location.hasParking
        self.parkingLatitude = location.parkingLatitude
        self.parkingLongitude = location.parkingLongitude
        self.requiredGear = location.requiredGear
        self.bestSeasons = location.bestSeasons
        self.bestTimesOfDay = location.bestTimesOfDay
        self.photos = location.photos.map { PhotoExportDTO(from: $0) }
    }
}

// MARK: - Export Service Engine

public enum ExportService {
    
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
    
    // MARK: - JSON Export & Backup
    
    public static func exportToJSON(locations: [PhotoLocation]) throws -> Data {
        let dtos = locations.map { LocationExportDTO(from: $0) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(dtos)
    }
    
    public static func exportToJSONString(locations: [PhotoLocation]) throws -> String {
        let data = try exportToJSON(locations: locations)
        return String(data: data, encoding: .utf8) ?? "[]"
    }
    
    public static func importFromJSON(data: Data) throws -> [LocationExportDTO] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([LocationExportDTO].self, from: data)
    }
    
    // MARK: - Obsidian-Compatible Markdown Export
    
    public static func exportSingleLocationToMarkdown(location: PhotoLocation) -> String {
        var md = ""
        
        // YAML Frontmatter (GL-002 compatible)
        md += "---\n"
        md += "title: \"\(location.title)\"\n"
        md += "type: PhotoLocation\n"
        md += "created: \(isoFormatter.string(from: location.creationDate))\n"
        md += "latitude: \(location.latitude)\n"
        md += "longitude: \(location.longitude)\n"
        if !location.categories.isEmpty {
            let tags = location.categories.map { "\"\($0)\"" }.joined(separator: ", ")
            md += "tags: [\(tags)]\n"
        }
        if location.hasParking, let pLat = location.parkingLatitude, let pLon = location.parkingLongitude {
            md += "parking_latitude: \(pLat)\n"
            md += "parking_longitude: \(pLon)\n"
        }
        md += "---\n\n"
        
        // Main Header
        md += "# \(location.title)\n\n"
        
        // Key Metadata Table
        md += "## Standort-Details\n\n"
        md += "| Eigenschaft | Wert |\n"
        md += "| :--- | :--- |\n"
        md += "| **Koordinaten** | `\(String(format: "%.6f", location.latitude)), \(String(format: "%.6f", location.longitude))` |\n"
        if location.hasParking, let pLat = location.parkingLatitude, let pLon = location.parkingLongitude {
            md += "| **Parkplatz** | `\(String(format: "%.6f", pLat)), \(String(format: "%.6f", pLon))` |\n"
        }
        if !location.categories.isEmpty {
            md += "| **Kategorien** | \(location.categories.joined(separator: ", ")) |\n"
        }
        if !location.requiredGear.isEmpty {
            md += "| **Empfohlene Ausrüstung** | \(location.requiredGear.joined(separator: ", ")) |\n"
        }
        md += "| **Erstellt am** | \(displayDateFormatter.string(from: location.creationDate)) |\n\n"
        
        // Notes Section
        md += "## Scouting-Notizen\n\n"
        if location.descriptionNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            md += "*Keine manuellen Notizen hinterlegt.*\n\n"
        } else {
            md += "\(location.descriptionNotes)\n\n"
        }
        
        // Photos / EXIF Section
        if !location.photos.isEmpty {
            md += "## Verknüpfte Fotos & EXIF-Daten\n\n"
            md += "| # | Datum | Objektiv | Brennweite | Blende | GPS |\n"
            md += "| :--- | :--- | :--- | :--- | :--- | :--- |\n"
            for (index, photo) in location.photos.enumerated() {
                let dateStr = displayDateFormatter.string(from: photo.captureDate)
                let lensStr = photo.originalLensModel ?? "Unbekannt"
                let focalStr = photo.focalLengthEquivalent != nil ? "\(photo.focalLengthEquivalent!) mm" : "-"
                let apertureStr = photo.aperture != nil ? "f/\(String(format: "%.1f", photo.aperture!))" : "-"
                let gpsStr: String
                if let lat = photo.latitude, let lon = photo.longitude {
                    gpsStr = "`\(String(format: "%.4f", lat)), \(String(format: "%.4f", lon))`"
                } else {
                    gpsStr = "-"
                }
                md += "| \(index + 1) | \(dateStr) | \(lensStr) | \(focalStr) | \(apertureStr) | \(gpsStr) |\n"
            }
            md += "\n"
        }
        
        return md
    }
    
    public static func exportToMarkdown(locations: [PhotoLocation]) -> String {
        guard !locations.isEmpty else {
            return "# SoloScout Export\n\n*Keine Fotospots zum Exportieren vorhanden.*"
        }
        
        var fullExport = "# SoloScout – Fotospot Katalog\n\n"
        fullExport += "- **Export-Datum:** \(displayDateFormatter.string(from: Date()))\n"
        fullExport += "- **Anzahl Spots:** \(locations.count)\n\n"
        fullExport += "---\n\n"
        
        for location in locations {
            fullExport += exportSingleLocationToMarkdown(location: location)
            fullExport += "\n---\n\n"
        }
        
        return fullExport
    }
    
    // MARK: - JSON Restore & Ingestion
    
    @discardableResult
    public static func restoreFromJSON(data: Data, context: ModelContext) throws -> Int {
        let dtos = try importFromJSON(data: data)
        for dto in dtos {
            let location = PhotoLocation(
                title: dto.title,
                categories: dto.categories,
                latitude: dto.latitude,
                longitude: dto.longitude
            )
            location.descriptionNotes = dto.descriptionNotes
            location.creationDate = dto.creationDate
            location.hasParking = dto.hasParking
            location.parkingLatitude = dto.parkingLatitude
            location.parkingLongitude = dto.parkingLongitude
            location.requiredGear = dto.requiredGear
            location.bestSeasons = dto.bestSeasons
            location.bestTimesOfDay = dto.bestTimesOfDay
            
            for pDto in dto.photos {
                let photo = LocationPhoto(captureDate: pDto.captureDate)
                photo.latitude = pDto.latitude
                photo.longitude = pDto.longitude
                photo.originalLensModel = pDto.originalLensModel
                photo.focalLengthEquivalent = pDto.focalLengthEquivalent
                photo.aperture = pDto.aperture
                photo.photoAssetIdentifier = pDto.photoAssetIdentifier
                location.photos.append(photo)
            }
            
            context.insert(location)
        }
        try context.save()
        return dtos.count
    }
}

// MARK: - SwiftUI Transferable Support

import CoreTransferable
import UniformTypeIdentifiers

public struct ExportFileItem: Transferable {
    public let content: String
    public let filename: String
    public let contentType: UTType
    
    public init(content: String, filename: String, contentType: UTType = .plainText) {
        self.content = content
        self.filename = filename
        self.contentType = contentType
    }
    
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .plainText) { item in
            Data(item.content.utf8)
        }
        .suggestedFileName { item in
            item.filename
        }
    }
}

