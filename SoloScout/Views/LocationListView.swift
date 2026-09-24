//
//  LocationListView.swift
//  SoloScout
//
//  Created by Felix on 31.07.2026.
//  Purpose: Dashboard listing all photo spots with filtering, search, and focal length badges.
//  Module: Views
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct LocationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PhotoLocation.creationDate, order: .reverse) private var locations: [PhotoLocation]
    
    @State private var searchText = ""
    @State private var isShowingCaptureSheet = false
    @State private var isShowingFileImporter = false
    @State private var importStatusMessage: String?
    @State private var isShowingStatusAlert = false
    
    private var exportDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    var filteredLocations: [PhotoLocation] {
        if searchText.isEmpty {
            return locations
        } else {
            return locations.filter { location in
                location.title.localizedCaseInsensitiveContains(searchText) ||
                location.categories.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) ||
                location.descriptionNotes.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredLocations.isEmpty {
                    if locations.isEmpty {
                        ContentUnavailableView(
                            "Keine Fotospots erfasst",
                            systemImage: "camera.macro",
                            description: Text("Tippe auf das Plus-Symbol oben rechts, um deinen ersten Fotospot per Live-Kamera oder Galerie-Import anzulegen.")
                        )
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                } else {
                    List {
                        ForEach(filteredLocations) { location in
                            NavigationLink(destination: LocationDetailView(location: location)) {
                                LocationRowCard(location: location)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteLocations)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("SoloScout")
            .searchable(text: $searchText, prompt: "Fotospots durchsuchen...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Section("Sicherung & Export") {
                            ShareLink(
                                item: ExportFileItem(
                                    content: (try? ExportService.exportToJSONString(locations: locations)) ?? "[]",
                                    filename: "soloscout-backup-\(exportDateString).json"
                                ),
                                preview: SharePreview("SoloScout JSON-Backup", image: Image(systemName: "externaldrive.badge.icloud"))
                            ) {
                                Label("JSON-Backup sichern", systemImage: "arrow.down.doc.fill")
                            }
                            .disabled(locations.isEmpty)
                            
                            ShareLink(
                                item: ExportFileItem(
                                    content: ExportService.exportToMarkdown(locations: locations),
                                    filename: "soloscout-export-\(exportDateString).md"
                                ),
                                preview: SharePreview("SoloScout myPKA-Dossier", image: Image(systemName: "doc.plaintext"))
                            ) {
                                Label("Als myPKA-Markdown exportieren", systemImage: "doc.text.fill")
                            }
                            .disabled(locations.isEmpty)
                        }
                        
                        Section("Wiederherstellung") {
                            Button {
                                isShowingFileImporter = true
                            } label: {
                                Label("Backup wiederherstellen...", systemImage: "arrow.counterclockwise.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingCaptureSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $isShowingCaptureSheet) {
                LocationCaptureView()
            }
            .fileImporter(
                isPresented: $isShowingFileImporter,
                allowedContentTypes: [.json, .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let selectedURL = urls.first else { return }
                    if selectedURL.startAccessingSecurityScopedResource() {
                        defer { selectedURL.stopAccessingSecurityScopedResource() }
                        do {
                            let data = try Data(contentsOf: selectedURL)
                            let count = try ExportService.restoreFromJSON(data: data, context: modelContext)
                            importStatusMessage = "Erfolgreich \(count) Fotospots aus Backup wiederhergestellt."
                            isShowingStatusAlert = true
                        } catch {
                            importStatusMessage = "Fehler beim Einlesen des Backups: \(error.localizedDescription)"
                            isShowingStatusAlert = true
                        }
                    }
                case .failure(let error):
                    importStatusMessage = "Import abgebrochen: \(error.localizedDescription)"
                    isShowingStatusAlert = true
                }
            }
            .alert("Backup-Status", isPresented: $isShowingStatusAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importStatusMessage ?? "")
            }
        }
    }
    
    private func deleteLocations(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredLocations[index])
            }
            try? modelContext.save()
        }
    }
}

// Custom Row Card for visual excellence
struct LocationRowCard: View {
    var location: PhotoLocation
    
    var body: some View {
        HStack(spacing: 16) {
            // Representative Thumbnail from relation
            if let firstPhoto = location.photos.first,
               let data = firstPhoto.thumbnailData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemFill))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "camera")
                            .foregroundStyle(.secondary)
                    }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(location.title)
                    .font(.headline)
                    .lineLimit(1)
                
                if !location.categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(location.categories, id: \.self) { category in
                                Text(category)
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.accentColor.opacity(0.12))
                                    .foregroundStyle(Color.accentColor)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                Text(String(format: "GPS: %.4f, %.4f", location.latitude, location.longitude))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Erfasst am: \(location.creationDate.formatted(date: .numeric, time: .omitted))")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                
                // Focal Length Badges of all perspectives
                if !location.photos.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(location.photos.prefix(4)) { photo in
                            if let focal = photo.focalLengthEquivalent {
                                Text("\(focal)mm")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    LocationListView()
        .modelContainer(for: PhotoLocation.self, inMemory: true)
}
