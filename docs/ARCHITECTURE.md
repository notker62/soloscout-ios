# SoloScout iOS – Architecture & Technical Design

## 1. System Overview & Core Principles

SoloScout is built on four fundamental design principles:

1. **Offline-First & Local Storage:**
   - All core capabilities (GPS geotagging, Sun position calculations, spot categorization, notes, and local photo thumbnail caching) operate with zero network dependency.
2. **Apple Ecosystem Harmony (PHAsset Integration):**
   - High-resolution original photos remain inside the system Apple Photos library (`PHAsset`), avoiding data duplication and sandbox bloating while preserving original capture quality.
3. **Resilient Data Core:**
   - SwiftData stores are protected by self-healing initialization routines preventing `fatalError` launch crashes during schema upgrades.
4. **Interoperable Knowledge Bridge (myPKA / Obsidian):**
   - One-click native exports to Obsidian-compatible Markdown and structured JSON backups.

---

## 2. Module & Graph Architecture

```text
SoloScout Architecture Graph:
[Data Core & SwiftData] ───────> [Photo & EXIF Service] ───────> [UI Views & Navigation]
           │                               │                                ▲
           ▼                               ▼                                │
[Sun Calculation Engine] ──────> [MapKit & Geo Engine] ─────────────────────┤
           │                                                                │
           └───────────────────> [Export & Backup Engine] ──────────────────┘
```

| Module | Responsibility | Key Classes / Files |
|---|---|---|
| **Data Core** | Schema definition, persistent store initialization, crash prevention | `SoloScoutApp.swift`, `PhotoLocation.swift`, `LocationPhoto.swift` |
| **Photo & EXIF** | PhotosKit integration, EXIF metadata extraction, lens focal length mapping | `PhotoService.swift` |
| **Geo & Sun** | Offline NOAA sun position math, daylight vector timelines, MapKit annotations | `LocationService.swift`, MapKit integrations |
| **Export & Backup** | JSON archive serialization/deserialization, Obsidian Markdown generation | `ExportService.swift` |
| **UI & Experience** | SwiftUI views, MapExplorer, LocationCapture, Detail sheets | `LocationListView.swift`, `LocationDetailView.swift`, `LocationCaptureView.swift` |

---

## 3. Data Models & Relational Schema (SwiftData)

### `PhotoLocation` (Parent Entity)
- `@Attribute(.unique) id: UUID`
- `title: String`
- `descriptionNotes: String`
- `creationDate: Date`
- `categories: [String]`
- `latitude: Double`, `longitude: Double`
- `hasParking: Bool`, `parkingLatitude: Double?`, `parkingLongitude: Double?`
- `requiredGear: [String]`
- `bestSeasons: Int` (Bitmask)
- `bestTimesOfDay: Int` (Bitmask)
- `@Relationship(deleteRule: .cascade, inverse: \LocationPhoto.location) photos: [LocationPhoto]`

### `LocationPhoto` (Child Entity)
- `@Attribute(.unique) id: UUID`
- `photoAssetIdentifier: String?` (Pointer to iOS `PHAsset`)
- `thumbnailData: Data?` (1024px downscaled local cache)
- `captureDate: Date`
- `latitude: Double?`, `longitude: Double?`
- `originalLensModel: String?`
- `focalLengthEquivalent: Int?` (Full-frame equivalent in mm)
- `aperture: Double?`
- `location: PhotoLocation?`

---

## 4. Resilience & Self-Healing Pattern (SPEC-03)

To prevent launch crashes when opening legacy or corrupted local SQLite stores across iOS updates, `SoloScoutApp.swift` utilizes an isolated fallback factory:

```swift
static func createModelContainer(inMemory: Bool = false) -> ModelContainer {
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
    do {
        return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
        print("⚠️ Persistent ModelContainer initialization failed: \(error.localizedDescription)")
        let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [fallbackConfig])
        } catch {
            fatalError("Critical SwiftData engine failure: \(error.localizedDescription)")
        }
    }
}
```

---

## 5. Backup & Export Engine (SPEC-04)

`ExportService` enables complete data preservation:

1. **JSON Backup Archive (`soloscout-backup-YYYY-MM-DD.json`):**
   - Serializes all spots, relations, notes, parking coordinates, gear lists, and photo metadata into a clean JSON structure.
   - Built-in `restoreFromJSON(data:context:)` imports and reconstructs complete databases.
2. **Obsidian-Compatible Markdown (`soloscout-export-YYYY-MM-DD.md`):**
   - Formatted with standard YAML frontmatter (`title`, `type`, `created`, `latitude`, `longitude`, `tags`), metadata tables, notes sections, and EXIF summary tables.
