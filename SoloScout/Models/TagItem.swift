//
//  TagItem.swift
//  SoloScout
//
//  Created by Felix & Linus on 25.09.2026.
//  Purpose: SwiftData Model for persistent photo spot tags and categories (SPEC-05).
//  Module: Models
//

import Foundation
import SwiftData

@Model
public final class TagItem {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var isDefault: Bool
    public var creationDate: Date
    
    public init(name: String, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isDefault = isDefault
        self.creationDate = Date()
    }
}
