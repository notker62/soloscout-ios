//
//  CatalogSeedingService.swift
//  SoloScout
//
//  Created by Felix & Linus on 25.09.2026.
//  Purpose: Idempotent database seeder for default tags and photo gear catalog (SPEC-05).
//  Module: Services
//

import Foundation
import SwiftData

public struct CatalogSeedingService {
    
    public static let defaultTags = [
        "Landschaft",
        "Natur",
        "Architektur",
        "Street",
        "Astro",
        "Makro",
        "Langzeitbelichtung"
    ]
    
    public static let defaultGear = [
        "Stativ",
        "ND-Filter",
        "Polfilter",
        "Drohne",
        "Fernauslöser",
        "Stirnlampe"
    ]
    
    /// Seeds default tags and gear items if none exist yet (strictly idempotent)
    public static func seedDefaultsIfNeeded(context: ModelContext) {
        // 1. Seed Tags if table is empty
        let tagDescriptor = FetchDescriptor<TagItem>()
        if let existingTags = try? context.fetch(tagDescriptor), existingTags.isEmpty {
            for tagName in defaultTags {
                let tag = TagItem(name: tagName, isDefault: true)
                context.insert(tag)
            }
        }
        
        // 2. Seed Gear if table is empty
        let gearDescriptor = FetchDescriptor<GearItem>()
        if let existingGear = try? context.fetch(gearDescriptor), existingGear.isEmpty {
            for gearName in defaultGear {
                let gear = GearItem(name: gearName, categoryRaw: "tripodAccessory", isFavorite: false, isDefault: true)
                context.insert(gear)
            }
        }
        
        // Persist seeding changes
        try? context.save()
    }
}
