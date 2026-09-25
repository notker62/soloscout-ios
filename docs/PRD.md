# Product Requirement Document (PRD) — SoloScout iOS

**Produkt:** SoloScout (iOS Native Photo Location Scouting & Planning App)  
**Version:** 1.0.0 (MVP)  
**Datum:** 01. September 2026 (Zuletzt konsolidiert: 25. September 2026)  
**Status:** Genehmigt & Implementiert (Approved by Notker)  
**Autoren:** Larry (Orchestrator), Linus (Software Developer), Silas (Database Architect), Pax (Requirements Specialist), Vera (QA)  
**Projektpfad:** `/Users/notker/projects/soloscout-ios/`

---

## 1. Vision & Produktziel

**SoloScout** ist ein rein privates, hochperformantes und offline-fähiges iOS-Werkzeug für anspruchsvolle Fotografen. Die App löst das Problem, unterwegs entdeckte Fotospots im Vorbeigehen sekundenschnell mit präzisen GPS- und EXIF-Daten festzuhalten, logistische Details (Parkplatz, Zugang) zu notieren und den perfekten Zeitpunkt für die Rückkehr mit der professionellen Kameraausrüstung anhand mathematischer Sonnenstands- und Lichtberechnungen zu planen.

---

## 2. Bestätigte Kernentscheidungen & Architekturprinzipien

1. **Datenhaltung & Cloud-Sync:**  
   * SwiftData mit privatem **iCloud-Sync (CloudKit Database .private)** über dieselbe Apple-ID.
   * **Autarke Festspeicher-Garantie:** Auf Free-Apple-ID-Accounts („Personal Team“) ohne CloudKit-Entitlements greift die App vollautomatisch und verlustfrei auf den lokalen SQLite-Festspeicher auf der SSD zurück (kein Absturz, kein unbemerktes Umschalten auf flüchtigen RAM).
   * Keine fremden Server, keine Benutzerkonten, 100 % privat.
2. **Karten- & Offline-Strategie:**  
   * MVP: Natives **Apple MapKit** mit Unterstützung von systemweit heruntergeladenen iOS-Offline-Karten.
   * Architektur: Gekapseltes `MapProviderProtocol` zur einfachen Nachrüstung von OpenStreetMap-/Topokarten-Kacheln in Version 2.0.
3. **Medienspeicherung & Löschschutz-Integrität (Fotos-App):**  
   * Originalfotos verbleiben in der Apple Fotos-App im dedizierten Album **"SoloScout"**.
   * Die App speichert den `photoAssetIdentifier` und cacht ein hochauflösendes, ausreichend großes **Thumbnail (1024px JPEG)** direkt in SwiftData (`thumbnailData`) für verzögerungsfreie Offline-Darstellung.
   * **Integritäts-Check & Warnung:** Die App prüft beim Laden via `PHPhotoLibrary`, ob das Original-Asset noch in der Fotomediathek existiert. Wurde es vom Nutzer in iOS-Fotos gelöscht, wird das gecachte 1024px-Thumbnail als lokales Backup weitergeführt und ein dezent-deutliches Warn-Badge angezeigt (*„Original in iOS-Fotos gelöscht – Thumbnail als Backup verfügbar“*).
4. **Flache Spot-Architektur im MVP (Einfachheit):**  
   * Jeder Standpunkt ist im MVP ein eigenständiger, gleichwertiger `PhotoLocation`-Eintrag mit eigenem Pin, Titel, Notizen und GPS-Koordinaten.
   * Zusammengehörige Spots teilen sich dieselben Tags/Suchbegriffe (z. B. `#Neuschwanstein`), liegen aber im MVP nicht in verschachtelten Ordnerhierarchien *(Erweiterung für Sub-Blickwinkel siehe Roadmap)*.
5. **Such- & Filter-Prioritäten:**  
   * **Prio 1 (Hauptfilter):** Karten- und Umkreissuche (Radius um aktuellen Standort oder Kartenzentrum).
   * **Prio 2:** Kategorien / Tags (Multi-Tagging).
   * **Prio 3:** Licht- und Saison-Filter (Sonnenaufgang, Goldene Stunde, Jahreszeiten).
6. **Brennweiten-Erfassung:**  
   * Automatisches Auslesen des iPhone-Objektivs aus EXIF und Umrechnung in das **Vollformat-Äquivalent in Millimetern** (z. B. `24 mm KB`, `77 mm KB`). Darstellung als kompaktes Info-Badge.
7. **Zubehör-Katalog & Spot-Zuweisung:**  
   * **Globaler Katalog (Settings):** Der Nutzer pflegt in den App-Einstellungen seinen Ausrüstungs-Fuhrpark (z. B. Stativ, ND1000-Filter, Polfilter, Drohne, Teleobjektiv).
   * **Spot-Zuweisung:** Am konkreten Spot wird aus diesem Katalog das benötigte Zubehör angehakt. In der Spot-Ansicht/Galerie werden **nur die aktivierten/benötigten Teile** als kompakte Badges eingeblendet, um die UI sauber zu halten.
8. **Parkplatz & Logistik:**  
   * Ein dedizierter Parkplatz-Pin pro Location mit Ein-Klick-Routenstart in Apple Maps.
   * Freitext-Bemerkungsfeld für Wegbeschaffenheit und Ausrüstungsanforderungen (z. B. *"Wanderschuhe zwingend erforderlich, steiler Pfad"*).
9. **Licht-Engine (Mathematisch & 100 % Offline):**  
   * Vollständige Offline-Berechnung von Sonnenauf-/untergang, Goldener Stunde, Blauer Stunde und **Sonnenstands-Vektoren im 2-Stunden-Takt** auf der Karte.
10. **Visuelles Design & UI/UX (NST-Consult Corporate Design Standard):**  
    * **Stil:** Native Apple Human Interface Guidelines (HIG) im exakten **NST-Consult Luxury-Dark-Design** (siehe [[GL-003-design-system]]):
      * **Canvas-Hintergrund:** `#060608` *(Ultra-dunkles Blau-Schwarz)*
      * **Karten- & Panel-Oberflächen:** `#0c0c12` *(Erhöhte Glass-Cards)*
      * **Akzent- & Highlight-Farbe:** `#d4af37` *(Champagner-Gold / RGB: `212, 175, 55` für aktive Pins, Sonnenvektoren, Filter-Chips und Highlights)*
      * **Primärer Text:** `#e4ece8` *(Sage White / weiches Minz-Weiß)*
      * **Sekundärer Text / EXIF-Labels:** `#8e8ea4` *(Muted Slate)*
      * **Rahmen & Border:** `rgba(212, 175, 55, 0.12)` *(1.5px dezente Goldrahmung aller Karten)*
      * **Glow- & Hover-Effekt:** Sanfter Gold-Glow (`rgba(212, 175, 55, 0.25)`) bei Interaktionen und aktiven Zuständen.
    * **Typografie-System:**
      * Titel & Header: Elegante Serif-Ästhetik (`Playfair Display` bzw. Apple System Serif `.serif`)
      * UI-Elemente, Metadaten & Fließtext: `Inter` bzw. Apple System Sans (`.default`)
      * Logo / Wortmarke: `Rubik` (Bold 700 / Light 300)
    * **Navigation:** iOS Tab-Bar mit 3 Hauptbereichen:
      * Tab 1: 🗺️ **Karte (Map View)** mit Umkreis-Slider und goldenen Sonnenvektoren.
      * Tab 2: 📋 **Spots (Listen- & Galerieansicht)** mit Live-Suche und Distanz-Sortierung.
      * Center-Action: 📸 **Kamera-Schnellerfassung** (Großer gold-gerahmter Button).
      * Tab 3: ⚙️ **Einstellungen & Zubehör-Katalog**.
11. **App-weites Lösch-Sicherheits-Gate (Zero Unconfirmed Deletion):**  
    * **Grundsatz:** Kein Datensatz, kein Foto, kein Tag und kein Ausrüstungsteil darf in der gesamten App ohne eine explizite Bestätigungsabfrage (nativer `.alert`-Dialog mit prominentem **„Abbrechen“**- und rotem **„Löschen“**-Button) entfernt werden.
    * Gilt universell in allen Ansichten: Spot-Übersicht (Swipe-to-Delete), Detailansicht (Toolbar-Löschen), Erfassungsdialog (Foto-Entfernung), Tag-Katalog und Ausrüstungs-Manager.

---

## 3. Explizite Non-Goals (Scope-Ausschluss für MVP)

* ❌ **Kein Social / Community Sharing:** Keine öffentlichen Feeds, kein Multi-User-Backend.
* ❌ **Keine Bildbearbeitung / RAW-Entwicklung:** Kein Zuschnitt, keine Filter.
* ❌ **Kein GPX-Kamera-Track-Sync im MVP:** Geotagging-Abgleich externer Kameras bleibt Phase 2 (Roadmap).
* ❌ **Kein externes Wetter-API im MVP:** Reine Offline-Berechnung der Sonnenbahn.

---

## 4. Datenmodell-Spezifikation (SwiftData)

Die Datenmodelle sind als native SwiftData-Entitäten ohne flüchtige Schemas oder inkompatible Unique-Attribute deklariert:

```swift
import Foundation
import SwiftData

@Model
public final class PhotoLocation {
    public var id: UUID = UUID()
    public var title: String = ""
    public var descriptionNotes: String = "" // Freitext: Wegbeschaffenheit, Schuhe etc.
    public var creationDate: Date = Date()
    public var categories: [String] = []     // z.B. ["Landschaft", "Wasserfall", "Burg"]
    
    // Standort-Geodaten des Fotospots
    public var latitude: Double = 0.0
    public var longitude: Double = 0.0
    
    // Parkplatz-Geodaten & Navigation
    public var hasParking: Bool = false
    public var parkingLatitude: Double?
    public var parkingLongitude: Double?
    
    // Logistik & Zubehör-Badges (Statistik)
    public var requiredGear: [String] = []   // z.B. ["Stativ", "ND-Filter", "Drohne"]
    public var bestSeasons: Int = 0          // Bitmask: Spring(1) | Summer(2) | Autumn(4) | Winter(8)
    public var bestTimesOfDay: Int = 0       // Bitmask: Morning(1) | Noon(2) | Evening(4) | Golden(8) | Blue(16)
    
    // 1-zu-n Beziehung: Fotos/Perspektiven an diesem Spot
    @Relationship(deleteRule: .cascade, inverse: \LocationPhoto.location)
    public var photos: [LocationPhoto] = []
    
    public init(title: String, categories: [String] = [], latitude: Double, longitude: Double) {
        self.id = UUID()
        self.title = title
        self.descriptionNotes = ""
        self.creationDate = Date()
        self.categories = categories
        self.latitude = latitude
        self.longitude = longitude
        self.hasParking = false
        self.requiredGear = []
        self.bestSeasons = 0
        self.bestTimesOfDay = 0
        self.photos = []
    }
}

@Model
public final class LocationPhoto {
    public var id: UUID = UUID()
    public var photoAssetIdentifier: String? // System reference to iOS PHAsset in Apple Fotos
    public var thumbnailData: Data?          // Gecachtes Thumbnail (1024px JPEG)
    public var captureDate: Date = Date()
    
    // Foto-spezifische GPS-Koordinaten
    public var latitude: Double?
    public var longitude: Double?
    
    // EXIF-Metadaten
    public var originalLensModel: String?
    public var focalLengthEquivalent: Int?   // Vollformat mm (z.B. 24, 77)
    public var aperture: Double?
    
    // Relation zurück zum Spot
    public var location: PhotoLocation?
    
    public init(captureDate: Date = Date()) {
        self.id = UUID()
        self.captureDate = captureDate
    }
}

@Model
public final class TagItem {
    public var id: UUID = UUID()
    public var name: String = ""
    public var isDefault: Bool = false       // True für geschützte System-Defaults
    public var creationDate: Date = Date()
    
    public init(name: String, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isDefault = isDefault
        self.creationDate = Date()
    }
}

@Model
public final class GearItem {
    public var id: UUID = UUID()
    public var name: String = ""
    public var categoryRaw: String = "tripodAccessory" // camera, lens, filter, tripodAccessory, drone, apparel
    public var isFavorite: Bool = false
    public var isDefault: Bool = false
    public var creationDate: Date = Date()
    
    public init(name: String, categoryRaw: String = "tripodAccessory", isFavorite: Bool = false, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.categoryRaw = categoryRaw
        self.isFavorite = isFavorite
        self.isDefault = isDefault
        self.creationDate = Date()
    }
}
```

---

## 5. Modulare Zerlegung für lokale AIs (Graph Architecture)

Das Projekt wird in **atomare, unabhängig testbare Module** zerlegt:

```
SoloScout Architecture Graph:
[MOD-01: Data Core & Persistence] ──> [MOD-02: Photos & EXIF Service] ──> [MOD-05: UI Views & Navigation]
           │                                      │                                 ▲
           ▼                                      ▼                                 │
[MOD-03: Sun & Light Calculation] ──> [MOD-04: MapKit & Geo Engine] ────────────────┤
           │                                                                        │
           └──> [MOD-06: GearManagement] ──> [MOD-07: TagManagement] ──────────────┤
                                                                                    │
                                        [MOD-08: MapExplorer & Gesture Engine] ─────┘
```

| Modul-ID | Name | Scope & Zuständigkeit | Exit Criteria (Test) |
| :--- | :--- | :--- | :--- |
| **MOD-01** | `DataCore` | SwiftData Schema, Migrationen, Festspeicher-Garantie, synchrone Persistenz & CloudKit-Fallback. | `testRealDiskSQLitePersistenceRoundTrip()` -> `PASS` |
| **MOD-02** | `PhotoService` | PhotosKit-Integration, Album `"SoloScout"`, EXIF-Auslesung, Brennweiten-Umrechnung, Thumbnail-Caching (1024px). | `testFocalLengthHeuristics()` -> `PASS` |
| **MOD-03** | `SunCalculation` | Reine mathematische Offline-Berechnung von Sonnenposition, Azimut, Elevation, Sonnenauf-/untergang und 2h-Vektoren. | `testSolarNoonAzimuthAndElevation()` -> `PASS` |
| **MOD-04** | `MapEngine` | MapKit-Komponenten, `MapProviderProtocol`, Radius-Filterung, Annotation-Clustering, Zeichnen von Sonnenvektoren auf der Karte. | `testLocationPhotoMetadataIntegrity()` -> `PASS` |
| **MOD-05** | `AppUI` | SwiftUI Views (Tab-Bar, MapView, SpotListView, LocationCaptureView, SettingsView) im NST-Consult Luxury-Gold & Sage-White Dark-Design. | `testColdStartLoadingStateTransitionsToReady()` -> `PASS` |
| **MOD-06** | `GearManagement` | Dedizierte Ausrüstungs-Verwaltung (`GearItem`), Stammdaten-Pflege in Settings, Favoriten & Kaskaden-Löschschutz. | `testGearManagementAddAndCascadeDeletion()` -> `PASS` |
| **MOD-07** | `TagManagement` | Zentrales Tag-Inventar (`TagItem`), Pflege in Settings, Default-Schutz & kaskadierende Bereinigung verknüpfter Spots. | `testTagManagementAddAndCascadeDeletion()` -> `PASS` |
| **MOD-08** | `MapExplorer` | Interaktiver Vollbild-Karten-Explorer mit nativer Gestensteuerung, Live-Standort, NST-Gold Pins und Distanzanzeige. | `testDistanceFormatting()` -> `PASS` |

---

## 6. Zukünftige Erweiterungen & Roadmap (Post-MVP / Priorität C)

Diese Funktionen sind als optionale Erweiterungen für spätere Releases konzipiert. Die modulare Architektur und das relationale SwiftData-Modell sind bereits so aufgebaut, dass diese Features nahtlos nachgerüstet werden können:

### 6.1 Hierarchische Spot-Strukturen (Sub-Blickwinkel / Detaillierte Perspektiven) — *Priorität C*
* **Konzept:** Zu einem übergeordneten Hauptspot (z. B. *"Burgruine Neuschwanstein"*) können mehrere untergeordnete, spezifische Blickwinkel oder Aufnahmepunkte angelegt werden.
* **Nutzen:** Der Hauptspot behält die allgemeinen logistischen Daten (Parkplatz, Zuwegung), während die Sub-Perspektiven ihre eigenen Fein-Koordinaten, Brennweiten und optimalen Sonnenzeiten speichern.

### 6.2 GPX-Track-Synchronisation & Auto-Geotagging für DSLMs — *Priorität C*
* **Konzept:** Import einer Standard-`.gpx`-Aufzeichnungsdatei in die App.
* **Funktion:** SoloScout gleicht die Aufnahmezeitpunkte von extern importierten DSLM-Fotos mit den Zeit- und Standortdaten des GPX-Tracks ab, interpoliert die Koordinaten und verortet die Bilder automatisch auf der Karte.

### 6.3 Kamera-Uhr-Abgleich (Time-Sync Slider & Screen-Foto-Erkennung) — *Priorität C*
* **Konzept:** Korrektur von asynchronen Kamerauhren bei externen DSLMs.
* **Funktion:** 
  * *Manuell:* Zeitschieber zur Festlegung eines konstanten Zeitversatzes ($\pm \text{hh:mm:ss}$).
  * *Automatisch (Screen-Foto):* Abfotografieren der SoloScout-Sync-Uhranzeige mit der Systemkamera. Die App errechnet den Offset beim Import vollautomatisch und wendet ihn vor dem GPX-Matching an.

### 6.4 Manuelle Kartenplatzierung (Drag & Drop) — *Priorität C*
* **Konzept:** Fallback für verortungsfreie Fotos oder historische Scans ohne GPS und ohne GPX-Track.
* **Funktion:** Der Nutzer kann ein Foto direkt per Drag & Drop auf der interaktiven Karte positionieren.

### 6.5 Erweiterte Wetter- & Himmelsdaten (Astro / WeatherKit) — *Priorität C*
* **Konzept:** Integration von Apple WeatherKit für Vor-Ort-Wetterprognosen, Wolkenbedeckung sowie Astro-Daten (Mondphasen, Milchstraßen-Sichtbarkeit und astronomische Dämmerung).

---

## 7. QA Test-Matrix & Verifikations-Protokoll (Vera)

**Test-Framework:** XCTest & SwiftData Persistent/In-Memory Test Harnesses  
**Status:** ✅ **100 % Bestanden (24/24 Unit- & Integrationstests)**  
**Letzter Testlauf:** 2026-09-25 11:31:00 CEST (`iPhone Notker` / `generic/platform=iOS`)

| Test-Suite | Testfall | Spezifikation & Prüfgegenstand | Status |
| :--- | :--- | :--- | :--- |
| **`SPEC07_PersistenceLifecycleTests`** | `testImmediateSynchronousDiskFlushOnLocationSave` | SPEC-07.1: Sofortiger synchroner SSD-Persistenz-Flush beim Speichern | ✅ PASSED |
| **`SPEC07_PersistenceLifecycleTests`** | `testAppLifecycleScenePhaseBackgroundTriggersSave` | SPEC-07.2: Automatischer Save beim App-Hintergrund-Wechsel (ScenePhase) | ✅ PASSED |
| **`SPEC07_PersistenceLifecycleTests`** | `testColdStartLoadingStateTransitionsToReady` | SPEC-07.3: Pulsierender Kaltstart-Ladescreen wechselt nach Initial-Read auf Ready | ✅ PASSED |
| **`SPEC06_CatalogManagementTests`** | `testTagManagementAddAndCascadeDeletion` | SPEC-06.3: Kaskadierendes Löschen von Tags bereinigt referenzierende Spots | ✅ PASSED |
| **`SPEC06_CatalogManagementTests`** | `testGearManagementAddAndCascadeDeletion` | SPEC-06.4: Kaskadierendes Löschen von Ausrüstung bereinigt referenzierende Spots | ✅ PASSED |
| **`SPEC06_CatalogManagementTests`** | `testSpotCaptureSelectionDoesNotMutateCatalog` | SPEC-06.1: Auswahl in der Erfassungsmaske modifiziert den globalen Katalog nicht | ✅ PASSED |
| **`SPEC06_CatalogManagementTests`** | `testDefaultTagsAndGearProtected` | SPEC-06.3/4: Standard-Tags und Standard-Ausrüstung sind vor Löschung geschützt | ✅ PASSED |
| **`SPEC05_PersistentCatalogTests`** | `testCatalogSeedingIdempotency` | SPEC-05.2: Idempotentes Seeding der Standard-Kataloge bei leerem Speicher | ✅ PASSED |
| **`SPEC05_PersistentCatalogTests`** | `testCustomTagPersistenceAndRetrieval` | SPEC-05.3: Persistente Speicherung benutzerdefinierter Tags | ✅ PASSED |
| **`SPEC05_PersistentCatalogTests`** | `testCustomGearPersistenceAndRetrieval` | SPEC-05.3: Persistente Speicherung benutzerdefinierter Ausrüstung | ✅ PASSED |
| **`SPEC05_PersistentCatalogTests`** | `testSettingsICloudToggleUserDefaultsStorage` | SPEC-04.2: Persistente Speicherung des iCloud-Sync-Umschalters in UserDefaults | ✅ PASSED |
| **`SPEC05_PersistentCatalogTests`** | `testPhotoLocationWithCustomTagsAndGearIntegrity` | SPEC-05.3: Beziehungs- und Verknüpfungsintegrität von Spots mit Custom-Tags | ✅ PASSED |
| **`SPEC05_PersistentCatalogTests`** | `testRealDiskSQLitePersistenceRoundTrip` | SPEC-05.4: Non-Volatile SQLite-Festspeicher-Garantie auf physischer SSD | ✅ PASSED |
| **`SPEC05_PersistentCatalogTests`** | `testCloudKitFailureGracefullyFallsBackToDiskSSDNotRAM` | SPEC-05.4: Graceful Fallback von CloudKit auf lokale SSD (kein RAM-Fallback) | ✅ PASSED |
| **`SPEC04_ExportBackupTests`** | `testJSONExportSerializationAndRoundTrip` | SPEC-04.4: Vollständige JSON-Serialisierung und Wiederherstellung | ✅ PASSED |
| **`SPEC04_ExportBackupTests`** | `testMarkdownExportObsidianFormatting` | SPEC-04.4: Obsidian-kompatibler Markdown-Export mit Frontmatter | ✅ PASSED |
| **`SPEC04_ExportBackupTests`** | `testEmptyLocationExportHandlesGracefully` | SPEC-04.4: Fehlerfreie Behandlung von leeren/minimalen Standorten beim Export | ✅ PASSED |
| **`SPEC04_ExportBackupTests`** | `testRestoreFromJSONInsertsEntitiesIntoModelContext` | SPEC-04.4: Transaktionssicherer Re-Import von JSON-Backups in SwiftData | ✅ PASSED |
| **`SPEC03_ResilienceTests`** | `testModelContainerFactoryCreation` | SPEC-03.1: Resiliente ModelContainer-Erstellung ohne fatalError-Crashes | ✅ PASSED |
| **`SPEC03_ResilienceTests`** | `testLocationPhotoMetadataIntegrity` | SPEC-03.3: Robuste Speicherung von EXIF- und GPS-Metadaten | ✅ PASSED |
| **`UC02_PhotoServiceTests`** | `testFocalLengthHeuristics` | MOD-02: Vollformat-Äquivalenz-Umrechnung aus EXIF-Brennweiten | ✅ PASSED |
| **`UC04_DatabaseRelationTests`** | `testAddMultiplePhotosToLocation` | MOD-01: 1-zu-n Beziehung zwischen Location und Fotos | ✅ PASSED |
| **`UC04_DatabaseRelationTests`** | `testDeleteSinglePhotoPreservesParent` | MOD-01: Löschen einzelner Fotos erhält die übergeordnete Location | ✅ PASSED |
| **`UC04_DatabaseRelationTests`** | `testDeleteParentCascadesToPhotos` | MOD-01: Kaskadierende Löschung aller verknüpften Fotos beim Löschen des Spots | ✅ PASSED |

---

## 8. Spezifikation SPEC-03: SwiftData Resilience & iOS 26 Toolchain Hardening (2026-09-24)

### 8.1 Problemstellung
- **Symptom:** App bricht auf iOS-Geräten bei veralteten SQLite-Schemas via `fatalError` in `SoloScoutApp.swift` ab; fehlende statische Linter-Baseline nach [[GL-009-code-quality-and-linting-standards]].

### 8.2 Funktionale & Technische Anforderungen (SPEC-03)
1. **SPEC-03.1 (Resilienter ModelContainer):**
   - In `SoloScoutApp.swift` wird die Initialisierung des `ModelContainer` in eine robuste Factory ausgelagert.
   - Tritt beim Öffnen des SQLite-Stores ein Schema- oder Migrationsfehler auf, wird der Fehler protokolliert, ein automatisches Self-Healing/Fallback initiiert und ein `fatalError`-App-Crash verhindert.
2. **SPEC-03.2 (SwiftLint Baseline nach GL-009):**
   - Bereitstellung von `.swiftlint.yml` im Projekt-Root.
   - 0 Linter-Fehler und 0 Warnungen unter `swiftlint --strict`.
3. **SPEC-03.3 (iOS 26 / Xcode 27 Kompatibilität & Test-Integrität):**
   - Verifikation aller Views und Services gegen das aktuelle iOS 26 SDK.
   - 100 % Bestehensrate der Testsuite via `xcodebuild test`.

---

## 9. Spezifikation SPEC-04: Native iCloud-Synchronisation (CloudKit Private DB) & SettingsView mit Zahnrad-Navigation (2026-09-25)

### 9.1 Problemstellung & Bereinigung
- **Beseitigung verwirrender Export-Menüs:** Die bisherigen manuellen Datei-Export-Dialoge (JSON-Backup & myPKA-Markdown-Share-Sheets) in der Haupt-Toolbar werden vollständig aus der Benutzeroberfläche entfernt, da sie den Nutzer mit Dateisystemen belasten und die UX überfrachten.
- **Ziel:** Vollautomatische, geräteübergreifende Synchronisation aller Fotospots, Bilder, Metadaten, Tags und Ausrüstungsgegenstände über die native Apple iCloud des Nutzers (CloudKit).

### 9.2 Funktionale & Technische Anforderungen (SPEC-04)
1. **SPEC-04.1 (Settings-Button & Toolbar-Bereinigung):**
   - In der Hauptnavigationsleiste von `LocationListView` wird das Drei-Punkte-Menü entfernt.
   - Anstelle des Export-Menüs wird oben links ein intuitives **Zahnrad-Symbol (`gearshape.fill`)** platziert, das die `SettingsView` als Modal-Sheet öffnet.
2. **SPEC-04.2 (SettingsView & Opt-In iCloud Sync Toggle):**
   - `SettingsView` bietet eine klare Sektion *„iCloud & Synchronisation“* mit einem Umschalter:
     - `@AppStorage("isICloudSyncEnabled") private var isICloudSyncEnabled: Bool = false`
     - **Toggle:** *„Mit iCloud synchronisieren“*
     - **Erklärungstext:** *„Synchronisiert deine Fotospots, Bilder, Metadaten, Tags und dein Equipment automatisch und verschlüsselt über deine persönliche Apple-ID mit all deinen iOS-, iPadOS- und macOS-Geräten.“*
     - **Status-Badge:** Grün (*„iCloud-Sync aktiv“*) bzw. Grau (*„Nur lokaler Festspeicher“*).
3. **SPEC-04.3 (Dynamische SwiftData CloudKit-Anbindung & Fallback-Resilienz):**
   - Die `ModelContainer`-Initialisierung in `SoloScoutApp.swift` bindet die CloudKit-Konfiguration dynamisch ein:
     - `isICloudSyncEnabled == true` $\rightarrow$ Versucht Anbindung an `cloudKitDatabase: .private("iCloud.de.nstconsult.SoloScout")`.
     - `isICloudSyncEnabled == false` oder fehlende CloudKit-Entitlements (z. B. Free-Apple-ID) $\rightarrow$ Automatischer, transparenter Fallback auf `cloudKitDatabase: .none` mit 100 % lokaler SQLite-SSD-Speicherung.
4. **SPEC-04.4 (Datenschutz & Zero-Vendor-Lock-in):**
   - Daten verbleiben zu 100 % im privaten CloudKit-Container des Nutzers bzw. auf der lokalen SSD. Es existieren keine externen Backend-Server oder Third-Party-Tracking-Dienste.

---

## 10. Spezifikation SPEC-05: Persistenter Tag- & Gear-Katalog, Daten-Seeding und Festspeicher-Garantie (Non-Volatile Persistence) (2026-09-25)

### 10.1 Problemstellung & Fehlerbild
1. **Flüchtige UI-Zustände:** Benutzerdefinierte Kategorien/Tags (z. B. *"Landschaft"*) und neues Foto-Equipment wurden in `LocationCaptureView` zuvor nur in temporären `@State`-Arrays gehalten und beim Schließen des Views gelöscht.
2. **Fehlende Entitäts-Implementierung:** `TagItem` und `GearItem` müssen als vollwertige SwiftData-Entitäten im Schema registriert sein.
3. **Beseitigung von lautlosen RAM-Fallbacks:** Bei Schema-Inkompatibilitäten darf die Initialisierung niemals unbemerkt auf `isStoredInMemoryOnly: true` umschalten.

---

### 10.2 Datenstruktur-Spezifikation (SwiftData Models)

#### A. TagItem (@Model)
```swift
@Model
public final class TagItem {
    public var id: UUID = UUID()
    public var name: String = ""
    public var isDefault: Bool = false      // True für System-Defaults (nicht löschbar)
    public var creationDate: Date = Date()

    public init(name: String, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isDefault = isDefault
        self.creationDate = Date()
    }
}
```

#### B. GearItem (@Model)
```swift
@Model
public final class GearItem {
    public var id: UUID = UUID()
    public var name: String = ""
    public var categoryRaw: String = "tripodAccessory"  // camera, lens, filter, tripodAccessory, drone, apparel
    public var isFavorite: Bool = false
    public var isDefault: Bool = false
    public var creationDate: Date = Date()

    public init(name: String, categoryRaw: String = "tripodAccessory", isFavorite: Bool = false, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.categoryRaw = categoryRaw
        self.isFavorite = isFavorite
        self.isDefault = isDefault
        self.creationDate = Date()
    }
}
```

---

### 10.3 Funktionale & Technische Anforderungen (SPEC-05)

1. **SPEC-05.1 (Dauerhafte Schema-Registrierung):**
   - Das SwiftData `Schema` in `SoloScoutApp.swift` bindet verbindlich alle 4 Entitäten ein: `[PhotoLocation.self, LocationPhoto.self, TagItem.self, GearItem.self]`.

2. **SPEC-05.2 (Idempotenter CatalogSeedingService beim App-Start):**
   - Ein dedizierter Service `CatalogSeedingService.seedDefaultsIfNeeded(context:)` wird beim App-Launch ausgeführt.
   - **Tag-Defaults:** Falls keine Tags existieren, werden initial angelegt: `["Landschaft", "Natur", "Architektur", "Street", "Astro", "Makro", "Langzeitbelichtung"]` (`isDefault = true`).
   - **Gear-Defaults:** Falls kein Equipment existiert, werden initial angelegt: `["Stativ", "ND-Filter", "Polfilter", "Drohne", "Fernauslöser", "Stirnlampe"]` (`isDefault = true`).
   - Das Seeding ist strikt **idempotent** (wird nur bei leerem Bestand ausgeführt, überschreibt niemals bestehende Nutzerdaten).

3. **SPEC-05.3 (Dynamische Persistenz in UI-Views):**
   - `LocationCaptureView` und `LocationDetailView` laden verfügbare Tags und Ausrüstung direkt per SwiftData-Query:  
     `@Query(sort: \TagItem.name) private var availableTags: [TagItem]`  
     `@Query(sort: \GearItem.name) private var availableGear: [GearItem]`
   - Das Anlegen eines neuen Tags oder Ausrüstungsgegenstands erzeugt sofort eine persistente SwiftData-Instanz, führt `modelContext.insert()` und `modelContext.save()` aus.
   - Der neue Tag / das neue Gerät ist sofort und dauerhaft app-weit auf der SSD (und bei aktivem Sync in iCloud) gespeichert.

4. **SPEC-05.4 (Festspeicher-Garantie & Beseitigung stiller Fallbacks):**
   - Im regulären App-Betrieb wird der `ModelContainer` zwingend mit `isStoredInMemoryOnly: false` auf der SSD initialisiert.
   - Der In-Memory-Modus ist ausschließlich für Previews (`#Preview`) und isolierte Unit-Tests (`SoloScoutTests`) zulässig.

---

### 10.4 Prüfbarkeit & Test-Kontrakt (Vera QA Matrix)

| Test-ID | Testfall | Spezifikation & Prüfkriterium |
| :--- | :--- | :--- |
| **TEST-05.1** | `testCustomTagPersistenceAndRetrieval()` | Legt ein neues `TagItem` an, speichert, zerstört den Context, lädt neu aus dem persistenten Store $\rightarrow$ Tag muss unverändert vorhanden sein. |
| **TEST-05.2** | `testCustomGearPersistenceAndRetrieval()` | Legt ein neues `GearItem` an, speichert, lädt neu $\rightarrow$ Item muss vorhanden sein. |
| **TEST-05.3** | `testCatalogSeedingIdempotency()` | Führt `seedDefaultsIfNeeded()` 3x hintereinander aus $\rightarrow$ Tag- und Gear-Anzahl darf sich nicht vervielfachen. |
| **TEST-05.4** | `testPhotoLocationWithCustomTagsAndGearIntegrity()` | Verknüpft eine `PhotoLocation` mit einem benutzerdefinierten Tag $\rightarrow$ Nach Reload des ModelContainers muss `location.categories` diesen Tag korrekt referenzieren. |
| **TEST-05.5** | `testSettingsICloudToggleUserDefaultsStorage()` | Prüft das Speichern und Laden des `isICloudSyncEnabled` Zustandswerts via `@AppStorage`. |
| **TEST-05.6 (Rainy Day)** | `testRealDiskSQLitePersistenceRoundTrip()` | Initialisiert `ModelContainer` auf einer echten SQLite-Datei auf der SSD (`isStoredInMemoryOnly: false`), schreibt Daten, schließt den Container, initialisiert neuen Container auf derselben Datei $\rightarrow$ Daten müssen zu 100 % erhalten bleiben. |
| **TEST-05.7 (Rainy Day)** | `testCloudKitFailureGracefullyFallsBackToDiskSSDNotRAM()` | Simuliert fehlende CloudKit-Entitlements bei `enableCloudKit: true` $\rightarrow$ `createModelContainer` MUSS auf den lokalen SSD-SQLite-Store zurückfallen und darf NIEMALS stillschweigend einen flüchtigen RAM-Store (`isStoredInMemoryOnly: true`) erzeugen. |

---

## 11. SPEC-06 – Stammdaten- und Katalogverwaltung (Tags & Ausrüstung)

### 11.1 Zweck & User Story
- **Zweck:** Strikte architektonische Trennung zwischen Einzelspot-Erfassung (`LocationCaptureView`) und globaler Stammdatenverwaltung (`TagManagementView`, `GearManagementView`).
- **User Story:** Als Fotograf möchte ich meine globalen Tags und Ausrüstungsgegenstände an einem zentralen Ort in den Einstellungen pflegen (hinzufügen, umbenennen, löschen), ohne Gefahr zu laufen, beim Bearbeiten eines einzelnen Spots versehentlich globale Katalogdaten oder Verknüpfungen anderer Spots destruktiv zu löschen.

---

### 11.2 Funktionale Anforderungen

1. **SPEC-06.1 (Bereinigung der Spot-Erfassungsmaske `LocationCaptureView`):**
   - Entfernung aller Lösch-Icons (Mülleimer) und kaskadierenden Lösch-Dialoge aus der Erfassungsmaske `LocationCaptureView`.
   - Das Antippen eines Tags oder Ausrüstungsgegenstands schaltet ausschließlich die Auswahl (`selectedCategories`, `selectedGear`) für den aktuell bearbeiteten Spot um.
   - Die Quick-Add-Eingabezeile bleibt erhalten, fügt neue Einträge persistent zum Katalog hinzu und wählt sie direkt für den aktuellen Spot aus.

2. **SPEC-06.2 (Katalog-Sektion in den Einstellungen `SettingsView`):**
   - Ergänzung der Sektion *„Katalog & Stammdaten“* in `SettingsView`:
     - NavigationLink `Tags verwalten` mit Icon `tag.fill` und Badge-Zähler der aktiven Tags.
     - NavigationLink `Ausrüstung verwalten` mit Icon `camera.fill` und Badge-Zähler der Ausrüstungsgegenstände.

3. **SPEC-06.3 (Tag-Verwaltung `TagManagementView`):**
   - Listet alle `TagItem`-Entitäten alphabetisch auf.
   - Standard-Tags (`isDefault = true`) sind schreibgeschützt und können nicht gelöscht werden.
   - Benutzerdefinierte Tags (`isDefault = false`) können per Swipe-to-Delete gelöscht werden.
   - **Kaskadierungs-Schutz:** Vor dem Löschen wird geprüft, ob der Tag von $N$ bestehenden Fotospots genutzt wird.
     - Falls $N > 0$: Sicherheits-Alert mit Abfrage: *„Der Tag ‚[Name]‘ wird von N Spot(s) verwendet. Soll er aus dem Katalog und von allen Spots entfernt werden?“*
   - Toolbar-Button `+` zum gezielten Anlegen neuer Tags.

4. **SPEC-06.4 (Ausrüstungs-Verwaltung `GearManagementView`):**
   - Listet alle `GearItem`-Entitäten alphabetisch oder nach Kategorie gruppiert auf.
   - Favoriten-Stern (`isFavorite`) zum schnellen Umschalten von Top-Ausrüstung.
   - Standard-Equipment (`isDefault = true`) ist vor Löschung geschützt.
   - Benutzerdefinierte Ausrüstung kann per Swipe-to-Delete mit identischem Kaskadierungs-Schutz gelöscht werden.
   - Toolbar-Button `+` zum Hinzufügen mit Namen und Kategorie-Auswahl (`lens`, `tripodAccessory`, `drone`, `filters`, `light`, `other`).

---

### 11.3 Prüfbarkeit & Test-Kontrakt (Vera QA Matrix)

| Test-ID | Testfall | Spezifikation & Prüfkriterium |
| :--- | :--- | :--- |
| **TEST-06.1** | `testTagManagementAddAndCascadeDeletion()` | Löschen eines Tags in `TagManagementView` entfernt das `TagItem` aus dem Katalog und bereinigt die `categories`-Listen aller verknüpften `PhotoLocation`-Instanzen. |
| **TEST-06.2** | `testGearManagementAddAndCascadeDeletion()` | Löschen eines Geräts in `GearManagementView` entfernt das `GearItem` und bereinigt die `requiredGear`-Listen der betroffenen Spots. |
| **TEST-06.3** | `testSpotCaptureSelectionDoesNotMutateCatalog()` | An- und Abwählen von Tags/Gear in `LocationCaptureView` modifiziert ausschließlich den aktuellen Spot; der globale Katalogbestand (`TagItem`/`GearItem`) bleibt unverändert. |
| **TEST-06.4** | `testDefaultTagsAndGearProtected()` | Standard-Tags und Standard-Ausrüstung (`isDefault = true`) können nicht im Stammdatenkatalog gelöscht werden. |

---

## 12. SPEC-07 – Atomare Festspeicher-Persistenz, Lifecycle-Flush & Komoot-Style Cold-Start Ladescreen

### 12.1 Zweck & User Story
- **Zweck:** Beseitigung jeglicher Verzögerungen beim Schreiben auf die physische SSD, Schutz vor Datenverlust bei abruptem App-Schließen (*App-Kill*) und Bereitstellung eines flüssigen, transparenten Lade-Erlebnisses beim Start der App.
- **User Story:** 
  - Als Fotograf möchte ich sicher sein, dass ein gespeicherter Spot sofort unumstößlich auf der SSD meines iPhones abgelegt ist, selbst wenn ich die App eine Millisekunde nach dem Speichern per Wisch beende.
  - Als Fotograf möchte ich beim Öffnen der App sofort ein vertrautes, pulsierendes SoloScout-Markenicon mit Statustext sehen (wie bei Komoot), das die Daten im Hintergrund lädt und erst nach vollständigem Einlesen die Fotospot-Liste anzeigt.

---

### 12.2 Funktionale & Technische Anforderungen

1. **SPEC-07.1 (Sofortiger synchroner SSD-Persistenz-Flush beim Speichern):**
   - Beim Erstellen oder Ändern eines Spots, Fotos, Tags oder Ausrüstungsgegenstands (`LocationCaptureView`, `SettingsView`, `TagManagementView`, `GearManagementView`) wird nach dem `modelContext.insert()` sofort ein synchroner, transaktionssicherer Aufruf von `try modelContext.save()` ausgeführt.
   - **Ganzheitliche Datensatz-Garantie:** Dies gilt holistisch für alle vier Datenbereiche: Jeder neue Fotospot (`PhotoLocation`), jedes neue Bild mit EXIF-Metadaten (`LocationPhoto`), jeder neu angelegte Tag (`TagItem`) und jedes neue Ausrüstungsgerät (`GearItem`) wird beim Drücken von „Speichern“ nicht nur im RAM gehalten, sondern in derselben atomaren Transaktion direkt und dauerhaft auf die physische SSD geschrieben.
   - Der Abschluss der UI-Aktion (`dismiss()`) erfolgt erst, nachdem `modelContext.save()` ohne Fehler quittiert wurde.
   - Keine asynchronen Verzögerungen oder ungeflushten Schreib-Caches.

2. **SPEC-07.2 (App-Lifecycle ScenePhase-Wächter gegen App-Kills):**
   - Auf App-Hauptebene (`SoloScoutApp` / `ContentView`) wird der iOS-Lebenszyklus via `@Environment(\.scenePhase)` überwacht.
   - Bei jedem Übergang in den Zustand `.background` oder `.inactive` (z. B. Wisch nach oben im App-Switcher, Sperren des Bildschirms) wird automatisch ein finaler `try? modelContext.save()` ausgeführt, um alle offenen Speicherpuffer zwingend auf die SSD zu schreiben.

3. **SPEC-07.3 (Komoot-Style Cold-Start Ladescreen & Ready-State):**
   - Beim Kaltstart der App (`ContentView`) startet die App im Zustand `.loading`.
   - Die `SplashLoadingView` zeigt ein zentriertes SoloScout-Icon (`camera.aperture` oder App-Logo), das mit einer harmonischen SwiftUI-Pulsanimation (Größen- und Deckkraft-Oszillation im 1,2-Sekunden-Takt) animiert wird.
   - Ein dezenter Statustext informiert: *„Lade Fotospots & Ausrüstung...“* (bzw. *„Mit iCloud synchronisieren...“* bei aktivem Cloud-Sync).
   - Sobald die SwiftData-Container-Initialisierung abgeschlossen ist und die Abfrage bereitsteht, schaltet der Zustand auf `.ready` um und blendet die Ladeansicht mit einem weichen Fade-Out über.

---

### 12.3 Prüfbarkeit & Test-Kontrakt (Vera QA Matrix)

| Test-ID | Testfall | Spezifikation & Prüfkriterium |
| :--- | :--- | :--- |
| **TEST-07.1** | `testImmediateSynchronousDiskFlushOnLocationSave()` | Speichert einen Spot und verifiziert, dass die physische SQLite-Datei auf der SSD sofort nach Rückkehr von `saveLocation()` die neuen Daten enthält, ohne auf Hintergrund-Timer zu warten. |
| **TEST-07.2** | `testAppLifecycleScenePhaseBackgroundTriggersSave()` | Simuliert den Szenen-Wechsel von `.active` zu `.background` und verifiziert, dass ungespeicherte Kontextänderungen automatisch persistent auf die SSD geschrieben werden. |
| **TEST-07.3** | `testColdStartLoadingStateTransitionsToReady()` | Verifiziert die Zustandsmaschine der Startansicht von `.loading` mit Puls-Animation zu `.ready` nach Bereitstellung der Daten. |
