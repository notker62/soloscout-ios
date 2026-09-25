//
//  GearManagementView.swift
//  SoloScout
//
//  Created by Felix & Linus on 25.09.2026.
//  Purpose: Centralized management hub for photo gear inventory with category filtering and cascade protection (SPEC-06).
//  Module: Views
//

import SwiftUI
import SwiftData

struct GearManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \GearItem.name) private var gearItems: [GearItem]
    @Query private var locations: [PhotoLocation]
    
    @State private var isShowingAddSheet = false
    @State private var newGearName = ""
    @State private var newGearCategory = "tripodAccessory"
    @State private var newGearIsFavorite = false
    
    @State private var gearToDelete: GearItem? = nil
    @State private var isShowingDeleteConfirmation = false
    @State private var affectedLocationsCount = 0
    
    let categories: [(id: String, label: String, icon: String)] = [
        ("tripodAccessory", "Stativ & Halterung", "tent.2.fill"),
        ("lens", "Objektiv", "camera.aperture"),
        ("drone", "Drohne & Luft", "airplane"),
        ("filter", "Filter (ND/Pol)", "circle.lefthalf.filled"),
        ("light", "Beleuchtung & Blitz", "flashlight.on.fill"),
        ("other", "Sonstiges Zubehör", "bag.fill")
    ]
    
    var body: some View {
        List {
            Section {
                ForEach(gearItems) { item in
                    HStack(spacing: 12) {
                        // Favorite Star Toggle
                        Button {
                            toggleFavorite(item)
                        } label: {
                            Image(systemName: item.isFavorite ? "star.fill" : "star")
                                .foregroundStyle(item.isFavorite ? .yellow : .secondary)
                                .font(.body)
                        }
                        .buttonStyle(.plain)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.body)
                            
                            let catLabel = categories.first(where: { $0.id == item.categoryRaw })?.label ?? "Ausrüstung"
                            Text(catLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        let usageCount = locations.filter { $0.requiredGear.contains(item.name) }.count
                        if usageCount > 0 {
                            Text("\(usageCount) Spot\(usageCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(.secondarySystemFill))
                                .clipShape(Capsule())
                        }
                        
                        if item.isDefault || CatalogSeedingService.defaultGear.contains(item.name) {
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
                        if !item.isDefault && !CatalogSeedingService.defaultGear.contains(item.name) {
                            Button(role: .destructive) {
                                initiateGearDeletion(item)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text("Ausrüstungskatalog (\(gearItems.count))")
            } footer: {
                Text("Standard-Equipment ist geschützt. Eigene Gegenstände können per Wischgeste gelöscht werden.")
            }
        }
        .navigationTitle("Ausrüstung verwalten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newGearName = ""
                    newGearCategory = "tripodAccessory"
                    newGearIsFavorite = false
                    isShowingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            NavigationStack {
                Form {
                    Section("Gerätedetails") {
                        TextField("Name (z.B. Sony 200-600mm)", text: $newGearName)
                            .autocorrectionDisabled(true)
                        
                        Picker("Kategorie", selection: $newGearCategory) {
                            ForEach(categories, id: \.id) { cat in
                                Label(cat.label, systemImage: cat.icon).tag(cat.id)
                            }
                        }
                        
                        Toggle("Zu Favoriten hinzufügen", isOn: $newGearIsFavorite)
                    }
                }
                .navigationTitle("Neues Equipment")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { isShowingAddSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            saveNewGear()
                            isShowingAddSheet = false
                        }
                        .disabled(newGearName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Ausrüstung löschen", isPresented: $isShowingDeleteConfirmation, presenting: gearToDelete) { item in
            Button("Abbrechen", role: .cancel) { }
            Button("Endgültig löschen", role: .destructive) {
                performCascadeGearDeletion(item)
            }
        } message: { item in
            if affectedLocationsCount > 0 {
                Text("Das Gerät „\(item.name)“ ist aktuell bei \(affectedLocationsCount) Fotospot(s) als benötigte Ausrüstung hinterlegt. Beim Löschen wird es aus dem Katalog und von allen Spots entfernt.")
            } else {
                Text("Möchtest du „\(item.name)“ wirklich aus deinem Ausrüstungskatalog entfernen?")
            }
        }
    }
    
    private func toggleFavorite(_ item: GearItem) {
        item.isFavorite.toggle()
        try? modelContext.save()
    }
    
    private func saveNewGear() {
        let trimmed = newGearName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if !gearItems.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
            let newGear = GearItem(
                name: trimmed,
                categoryRaw: newGearCategory,
                isFavorite: newGearIsFavorite,
                isDefault: false
            )
            modelContext.insert(newGear)
            try? modelContext.save()
        }
    }
    
    private func initiateGearDeletion(_ item: GearItem) {
        let count = locations.filter { $0.requiredGear.contains(item.name) }.count
        self.affectedLocationsCount = count
        self.gearToDelete = item
        self.isShowingDeleteConfirmation = true
    }
    
    private func performCascadeGearDeletion(_ item: GearItem) {
        let itemName = item.name
        
        // Clean up from all PhotoLocation instances
        for loc in locations {
            if loc.requiredGear.contains(itemName) {
                loc.requiredGear.removeAll { $0 == itemName }
            }
        }
        
        // Delete from GearItem table
        modelContext.delete(item)
        try? modelContext.save()
    }
}
