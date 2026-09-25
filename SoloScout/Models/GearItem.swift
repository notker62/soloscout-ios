//
//  GearItem.swift
//  SoloScout
//
//  Created by Felix & Linus on 25.09.2026.
//  Purpose: SwiftData Model for persistent photo equipment items (SPEC-05).
//  Module: Models
//

import Foundation
import SwiftData

@Model
public final class GearItem {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var categoryRaw: String
    public var isFavorite: Bool
    public var isDefault: Bool
    public var creationDate: Date
    
    public init(name: String, categoryRaw: String = "tripodAccessory", isFavorite: Bool = false, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.categoryRaw = categoryRaw
        self.isFavorite = isFavorite
        self.isDefault = isDefault
        self.creationDate = Date()
    }
}
