//
//  SettingsView.swift
//  SoloScout
//
//  Created by Felix & Linus on 25.09.2026.
//  Purpose: Settings screen providing iCloud synchronization toggle and storage status (SPEC-04).
//  Module: Views
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("isICloudSyncEnabled") private var isICloudSyncEnabled: Bool = false
    
    @Query private var locations: [PhotoLocation]
    @Query private var tags: [TagItem]
    @Query private var gear: [GearItem]
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: iCloud Synchronization (SPEC-04)
                Section {
                    Toggle(isOn: $isICloudSyncEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "icloud.fill")
                                .font(.title3)
                                .foregroundStyle(isICloudSyncEnabled ? .blue : .secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Mit iCloud synchronisieren")
                                    .font(.headline)
                                
                                Text(isICloudSyncEnabled ? "Automatische CloudKit-Synchronisation aktiv" : "Nur lokaler Festspeicher auf diesem Gerät")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(.blue)
                } header: {
                    Text("iCloud & Datensicherung")
                } footer: {
                    Text("Synchronisiert deine Fotospots, Bilder, Metadaten, Tags und dein Equipment automatisch und verschlüsselt über deine persönliche Apple-ID mit all deinen iOS-, iPadOS- und macOS-Geräten. Daten verbleiben zu 100 % in deinem privaten Apple CloudKit-Speicher.")
                }
                
                // Section 2: Storage Statistics
                Section("Lokaler Datenbestand") {
                    HStack {
                        Label("Gespeicherte Fotospots", systemImage: "mappin.and.ellipse")
                        Spacer()
                        Text("\(locations.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Verfügbare Tags", systemImage: "tag.fill")
                        Spacer()
                        Text("\(tags.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Ausrüstungsgegenstände", systemImage: "camera.fill")
                        Spacer()
                        Text("\(gear.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Section 3: App Information
                Section("Über SoloScout") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.2.0 (Build 2026.09)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Datenschutz")
                        Spacer()
                        Text("100 % Private CloudKit")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [PhotoLocation.self, LocationPhoto.self, TagItem.self, GearItem.self], inMemory: true)
}
