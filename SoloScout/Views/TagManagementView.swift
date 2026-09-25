//
//  TagManagementView.swift
//  SoloScout
//
//  Created by Felix & Linus on 25.09.2026.
//  Purpose: Centralized management hub for photo spot tags and categories with cascade protection (SPEC-06).
//  Module: Views
//

import SwiftUI
import SwiftData

struct TagManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \TagItem.name) private var tags: [TagItem]
    @Query private var locations: [PhotoLocation]
    
    @State private var isShowingAddTagAlert = false
    @State private var newTagName = ""
    
    @State private var tagToDelete: TagItem? = nil
    @State private var isShowingDeleteConfirmation = false
    @State private var affectedLocationsCount = 0
    
    var body: some View {
        List {
            Section {
                ForEach(tags) { tag in
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(Color.accentColor)
                            .font(.subheadline)
                        
                        Text(tag.name)
                            .font(.body)
                        
                        Spacer()
                        
                        let usageCount = locations.filter { $0.categories.contains(tag.name) }.count
                        if usageCount > 0 {
                            Text("\(usageCount) Spot\(usageCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(.secondarySystemFill))
                                .clipShape(Capsule())
                        }
                        
                        if tag.isDefault || CatalogSeedingService.defaultTags.contains(tag.name) {
                            Text("Standard")
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !tag.isDefault && !CatalogSeedingService.defaultTags.contains(tag.name) {
                            Button(role: .destructive) {
                                initiateTagDeletion(tag)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text("Katalog-Tags (\(tags.count))")
            } footer: {
                Text("Standard-Tags sind geschützt. Eigene Tags können per Wischgeste gelöscht werden.")
            }
        }
        .navigationTitle("Tags verwalten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newTagName = ""
                    isShowingAddTagAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Neuen Tag anlegen", isPresented: $isShowingAddTagAlert) {
            TextField("Tag-Name (z.B. Makro, Drohne)", text: $newTagName)
                .autocorrectionDisabled(true)
            Button("Abbrechen", role: .cancel) { }
            Button("Speichern") {
                saveNewTag()
            }
            .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Gib den Namen für den neuen Kategorie-Tag ein.")
        }
        .alert("Tag löschen", isPresented: $isShowingDeleteConfirmation, presenting: tagToDelete) { tag in
            Button("Abbrechen", role: .cancel) { }
            Button("Endgültig löschen", role: .destructive) {
                performCascadeTagDeletion(tag)
            }
        } message: { tag in
            if affectedLocationsCount > 0 {
                Text("Der Tag „\(tag.name)“ wird aktuell von \(affectedLocationsCount) Fotospot(s) verwendet. Beim Löschen wird er aus dem Katalog und von allen betroffenen Spots entfernt.")
            } else {
                Text("Möchtest du den Tag „\(tag.name)“ wirklich aus dem Katalog entfernen?")
            }
        }
    }
    
    private func saveNewTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if !tags.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
            let newTag = TagItem(name: trimmed, isDefault: false)
            modelContext.insert(newTag)
            try? modelContext.save()
        }
    }
    
    private func initiateTagDeletion(_ tag: TagItem) {
        let count = locations.filter { $0.categories.contains(tag.name) }.count
        self.affectedLocationsCount = count
        self.tagToDelete = tag
        self.isShowingDeleteConfirmation = true
    }
    
    private func performCascadeTagDeletion(_ tag: TagItem) {
        let tagName = tag.name
        
        // Clean up from all PhotoLocation instances
        for loc in locations {
            if loc.categories.contains(tagName) {
                loc.categories.removeAll { $0 == tagName }
            }
        }
        
        // Delete from TagItem table
        modelContext.delete(tag)
        try? modelContext.save()
    }
}
