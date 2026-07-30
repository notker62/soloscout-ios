# SoloScout

SoloScout is a private, offline-first iOS application designed for photographers to capture, organize, and plan photography locations. It enables you to take quick reference photos with your iPhone, automatically extracts location, time, and focal length equivalent details, and helps you determine the best time to return with your professional camera gear.

---

## Folder Structure

```text
soloscout-ios/
├── README.md                  # Project overview and architecture
├── docs/
│   ├── test-specification.md  # Use Cases, Acceptance Criteria and QA workflow (Pax & Vera)
│   └── user-manual.md         # User Guide (written by Vera)
├── SoloScout/
│   ├── SoloScoutApp.swift     # App entry point
│   ├── Models/                # SwiftData database entities
│   ├── Services/              # Core logic modules (Photos, Location, Sun calculations)
│   ├── Views/                 # SwiftUI Screens & Components
│   └── Resources/             # Assets, Colors & Icons
└── SoloScoutTests/            # Unit & Integration tests (Felix)
```

---

## Technology Stack

*   **Language:** Swift 5.10+
*   **UI Framework:** SwiftUI
*   **Database:** SwiftData (local SQLite)
*   **Map Engine:** MapKit (native Apple Maps with system offline support)
*   **Media Access:** PhotosKit (`PHPhotoLibrary` / `PhotosUI`)
*   **Camera Integration:** `AVFoundation` / `UIImagePickerController`

---

## Development Workflow & Quality Gate

To maintain code quality and long-term sustainability, this project implements a strict separation of concerns (Four-Eyes Principle):

1.  **Specification (Pax):** High-level Use Cases are documented in [docs/test-specification.md](file:///Users/notker/Projekte/soloscout-ios/docs/test-specification.md).
2.  **Quality Gates (Vera):** Acceptance criteria and verification checklists are established by Vera.
3.  **Implementation (Felix):** Code is written modularly, and Unit/Integration tests are built under `SoloScoutTests/` to satisfy the specification.
4.  **Security Audit (Vex):** Validates permissions, sandbox constraints, and credentials.
5.  **Validation (Vera):** Re-runs tests, verifies manual quality checks, and writes the `user-manual.md` upon successful verification.
6.  **Integration (Larry):** Performs the code-review and merges changes.
