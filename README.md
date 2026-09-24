# SoloScout iOS

> **The Private, Offline-First Spot Scouting App for Landscape Photographers.**

SoloScout is a native iOS application designed for landscape and outdoor photographers to discover, document, and plan photography locations. It enables rapid on-site photo capture, automatic GPS and EXIF extraction (focal length, aperture, lens profile), offline sun-position calculations (golden hour / blue hour), and seamless integration with personal knowledge management systems (Markdown / JSON).

---

## Key Features

- 📍 **Offline-First Geotagging & Spot Memory:** Capture photo spots with precise GPS coordinates, dedicated parking tags, and manual scouting notes without cellular reception.
- 📷 **EXIF Intelligence & Lens Profiling:** Automatic extraction of camera model, full-frame equivalent focal length, and aperture from live captures or imported iOS Photos.
- ☀️ **Sun & Light Calculation Engine:** Native mathematical computation of solar azimuth, elevation, golden hour, and daylight vector timelines.
- 🗺️ **Interactive Map Explorer:** Fullscreen Apple Maps integration with custom spot markers, live distance calculations, and instant switching between map and list views.
- 🎒 **Gear Checklist & Categorization:** Assign recommended gear (tripod, filters, lenses) and custom seasonal/time-of-day tags to each location.
- 🛡️ **Self-Healing SwiftData Core (SPEC-03):** Robust initialization logic preventing launch crashes during schema upgrades and certificate renewals.
- 💾 **1-Click Backup & Obsidian Markdown Bridge (SPEC-04):** Export full JSON database backups or format complete spot catalogs into Obsidian-compatible Markdown dossiers with YAML frontmatter.

---

## Technology Stack

| Layer | Technology |
|---|---|
| **Language** | Swift 5.10+ / Swift 6 Compatible |
| **UI Framework** | SwiftUI (iOS 17+) |
| **Data & Persistence** | SwiftData (Local SQLite with CloudKit schema readiness) |
| **Mapping & Location** | MapKit (`MapCameraPosition`, `Marker`, `UserAnnotation`), CoreLocation |
| **Media & EXIF** | PhotosKit (`PHAsset`, `PhotosPicker`), ImageIO, CoreGraphics |
| **Quality & Linting** | SwiftLint (`GL-009` baseline), XCTest (100% automated test coverage) |

---

## Project Structure

```text
soloscout-ios/
├── README.md                      # Project overview & quickstart
├── .swiftlint.yml                 # Code quality and architecture rules
├── docs/
│   ├── PRD.md                     # Product Requirement Document & Specifications (SPEC-01 to SPEC-05)
│   ├── ARCHITECTURE.md            # System architecture, SwiftData schema & graph
│   └── BACKUP_AND_RESTORE.md      # JSON & Markdown export specifications
├── SoloScout/
│   ├── SoloScoutApp.swift         # Resilient App entry point
│   ├── Assets.xcassets/           # App Icon (Aperture Horizon) and color assets
│   ├── Models/                    # SwiftData database entities (PhotoLocation, LocationPhoto)
│   ├── Services/                  # Business logic (PhotoService, LocationService, ExportService)
│   └── Views/                     # SwiftUI views (ListView, DetailView, CaptureView, MapExplorer)
└── SoloScoutTests/                # Automated unit & integration tests
    ├── SPEC03_ResilienceTests.swift
    ├── SPEC04_ExportBackupTests.swift
    ├── UC02_PhotoServiceTests.swift
    └── UC04_DatabaseRelationTests.swift
```

---

## Documentation Links

- 📄 **[Product Requirement Document (PRD)](docs/PRD.md):** Complete functional specification, Use Cases (UC-01 to UC-08), and Acceptance Criteria.
- 🏗️ **[Technical Architecture](docs/ARCHITECTURE.md):** SwiftData relational model, resilience patterns, and service interactions.
- 💾 **[Backup & Restore Guide](docs/BACKUP_AND_RESTORE.md):** JSON schema, Obsidian Markdown export, and import instructions.

---

## Getting Started & Development

### Prerequisites
- macOS 14+ (Sonoma) / macOS 15+ (Sequoia)
- Xcode 16.0+ / Xcode 27+
- iOS 17.0+ deployment target

### Building and Testing via CLI
```bash
# Run all automated unit and integration tests
xcodebuild -project SoloScout.xcodeproj -scheme SoloScout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Run code style linter
swiftlint lint --strict
```

---

## License & Credits

- **Author:** Notker Steigerwald
- **Engineering & Architecture:** myPKA Software Factory (Larry, Felix, Vera, Silas, Iris, Pixel)
- **License:** Proprietary / Private Use
