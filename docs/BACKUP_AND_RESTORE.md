# SoloScout – Backup & Restore Guide (SPEC-04)

## Overview

SoloScout includes a native backup and export engine designed to safeguard user data across iOS installations, device changes, and developer profile certificate renewals.

---

## 1. Export Formats

### A. Full JSON Archive (`soloscout-backup-YYYY-MM-DD.json`)
The JSON backup is a complete data transfer format containing all spots, notes, coordinates, and photo metadata.

#### Sample JSON Structure:
```json
[
  {
    "id": "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
    "title": "Zugspitze Blick",
    "descriptionNotes": "Bester Spot auf dem Grat. Stativ zwingend erforderlich.",
    "creationDate": "2026-09-24T18:00:00.000Z",
    "categories": ["Landschaft", "Berge", "Goldene Stunde"],
    "latitude": 47.4211,
    "longitude": 10.9853,
    "hasParking": true,
    "parkingLatitude": 47.4100,
    "parkingLongitude": 10.9800,
    "requiredGear": ["Stativ", "ND1000 Filter", "Weitwinkel 16-35mm"],
    "bestSeasons": 7,
    "bestTimesOfDay": 8,
    "photos": [
      {
        "id": "F1E2D3C4-B5A6-0987-6543-21FEDCBA0987",
        "captureDate": "2026-09-24T17:30:00.000Z",
        "latitude": 47.4212,
        "longitude": 10.9854,
        "originalLensModel": "Sony FE 16-35mm F2.8 GM II",
        "focalLengthEquivalent": 24,
        "aperture": 8.0,
        "photoAssetIdentifier": "PHASSET-ID"
      }
    ]
  }
]
```

### B. Obsidian-Compatible Markdown (`soloscout-export-YYYY-MM-DD.md`)
Designed for direct integration with Personal Knowledge Management (PKM) vaults and Obsidian:
- Valid YAML Frontmatter.
- GPS coordinates and parking info table.
- Formatted scouting notes.
- EXIF and lens metadata summary table.

---

## 2. Step-by-Step Usage

### How to Create a Backup
1. In SoloScout, open the main list view.
2. Tap the **`...` (More Options)** menu in the top-left toolbar.
3. Tap **`JSON-Backup sichern`** or **`Als myPKA-Markdown exportieren`**.
4. Choose **Save to Files** (iCloud Drive / On My iPhone) or share via AirDrop/Mail.

### How to Restore a Backup
1. In SoloScout, open the main list view.
2. Tap the **`...` (More Options)** menu in the top-left toolbar.
3. Tap **`Backup wiederherstellen...`**.
4. Select your previously saved `.json` backup file from the document picker.
5. All spots, coordinates, and notes are instantly restored into the app database.
