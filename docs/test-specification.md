# Test-Spezifikation und Anwendungsfälle: SoloScout iOS-App
*Erstellt am 30. Juli 2026 | Rolle: Pax (Senior Research Specialist)*

---

## 1. Übersicht

Dieses Dokument definiert die funktionalen Anwendungsfälle (Use Cases, UCs) für das MVP der SoloScout-App. Es dient als bindende Vorgabe für die Entwicklung (Felix) zur Erstellung der Unit-Tests und für die Qualitätssicherung (Vera) zur Durchführung der Quality-Checks.

Jeder Anwendungsfall ist direkt mit Akzeptanzkriterien und konkreten Prüfmethoden verknüpft (Vier-Augen-Prinzip).

---

## 2. Funktionale Anwendungsfälle (Use Cases)

### UC-01: Erfassung im Vorbeigehen (On-the-go Capture)
*   **Beschreibung:** Der Nutzer möchte an einem aktuellen physischen Standort direkt ein Foto aufnehmen und den Spot anlegen.
*   **Ablauf:**
    1. Nutzer öffnet die App und klickt auf "Kamera öffnen".
    2. Das Foto wird geschossen und bestätigt.
    3. Das Originalbild wird im Hintergrund im iOS-Fotoalbum `"SoloScout"` abgespeichert.
    4. Die App generiert ein lokales Thumbnail (Cache) und liest GPS-Koordinaten sowie die Aufnahme-Uhrzeit aus.
    5. Die App leitet den Nutzer direkt in die Detail-Erfassungsmaske weiter.
*   **Akzeptanzkriterien (Prüfbedingungen):**
    *   *AC-01.1:* Die Systemkamera öffnet sich ohne Absturz.
    *   *AC-01.2:* Das aufgenommene Bild wird physisch in der iOS Fotos-App unter dem Album `"SoloScout"` abgelegt (Vermeidung von Datenverlust).
    *   *AC-01.3:* Die ermittelten GPS-Koordinaten entsprechen dem aktuellen Gerätestandort.
*   **Prüfmethoden:**
    *   **Unit-Test (Felix):** `SoloScoutTests/UC01_CameraImportTests.swift -> testCameraMetadataExtraction()` (Prüft, ob ein Mock-Kamerabild korrekt in EXIF-Daten zerlegt wird).
    *   **UI-Test (Vera):** `SoloScoutUITests/UC01_OnTheGoFlow.swift` (Simuliert Klick auf Kamera und Weiterleitung zur Detailansicht).
    *   **Manueller Check (Vera):** Prüfung in der echten iOS Fotos-App, ob das Album `"SoloScout"` angelegt wurde und das Bild enthält.

---

### UC-02: Erfassung im Nachgang (Post-Scouting)
*   **Beschreibung:** Der Nutzer importiert ein bereits aufgenommenes Foto aus seiner iOS-Bibliothek, um es als Spot zu katalogisieren.
*   **Ablauf:**
    1. Nutzer wählt in der App "Bild importieren".
    2. Der iOS Photo Picker öffnet sich.
    3. Nach der Auswahl extrahiert die App die EXIF-Daten (GPS-Ort, Zeit, Brennweite) des ausgewählten Assets.
    4. Ein neuer Spot-Eintrag wird erzeugt und das Bild mit dem Spot verknüpft.
*   **Akzeptanzkriterien:**
    *   *AC-02.1:* Der Photo Picker filtert nur Bilder mit gültigen EXIF-Ortungsdaten oder gibt eine Warnung aus, falls keine GPS-Daten vorhanden sind.
    *   *AC-02.2:* Die extrahierten Werte (Koordinaten, Datum, Brennweite) stimmen exakt mit den Originaldateidaten überein.
*   **Prüfmethoden:**
    *   **Unit-Test (Felix):** `SoloScoutTests/UC02_LibraryImportTests.swift -> testEXIFExtractionFromAsset()` (Validiert EXIF-Parser mit Testbildern).
    *   **Manueller Check (Vera):** Import von 3 Testbildern mit bekannten GPS-Koordinaten und Brennweiten (Weitwinkel, Tele) und Abgleich mit der Detailanzeige in der App.

---

### UC-03: Offline-Lichtwinkel und 2-Stunden-Sonnenlaufbahn
*   **Beschreibung:** Der Nutzer prüft den Sonnenstand für einen Spot, um Lichtbedingungen einzuschätzen.
*   **Ablauf:**
    1. Nutzer öffnet die Detailansicht eines Spots und wählt ein Datum.
    2. Die App berechnet offline die goldene/blaue Stunde sowie den Sonnenverlauf.
    3. Die Karte zeichnet die Sonnenaufgangs- (orange) und Untergangsrichtung (rot).
    4. Über einen Schieberegler wird die Position der Sonne im 2-Stunden-Takt auf der Karte projiziert.
*   **Akzeptanzkriterien:**
    *   *AC-03.1:* Die Berechnungen laufen ohne Internetverbindung (Flugmodus-Test).
    *   *AC-03.2:* Der berechnete Sonnenwinkel weicht maximal um 1 Grad von offiziellen astronomischen Tabellen ab.
    *   *AC-03.3:* Die Vektoren verändern sich korrekt bei Datumsänderungen (z. B. Winter- vs. Sommersonnenwende).
*   **Prüfmethoden:**
    *   **Unit-Test (Felix):** `SoloScoutTests/UC03_SunPositionTests.swift` (Abgleich der berechneten Winkel für bekannte Koordinaten und Daten mit astronomischen Referenzwerten).
    *   **Manueller Check (Vera):** Simulation von Sommer- und Wintersonnenwende im Simulator und Sichtprüfung der Vektorwinkel auf der Karte.

---

### UC-04: Mehrfach-Bilder pro Fotospot (1-zu-n)
*   **Beschreibung:** Der Nutzer fügt einem bestehenden Fotospot ein weiteres Foto hinzu, z. B. mit einer anderen Brennweite.
*   **Ablauf:**
    1. Nutzer öffnet einen existierenden Spot und wählt "Weiteres Foto hinzufügen".
    2. Das neue Foto wird mit eigener Brennweite und individuellem GPS-Punkt erfasst.
    3. Das Foto wird unter der übergeordneten ID des Spots gruppiert.
*   **Akzeptanzkriterien:**
    *   *AC-04.1:* Jedes Bild behält seine individuellen GPS-Daten und Brennweiten.
    *   *AC-04.2:* Das Löschen eines einzelnen Bildes löscht nicht den gesamten Spot.
    *   *AC-04.3:* Das Löschen des Spots löscht (Cascading Delete) alle verknüpften Bilder in der App-Datenbank.
*   **Prüfmethoden:**
    *   **Unit-Test (Felix):** `SoloScoutTests/UC04_DatabaseRelationTests.swift` (Prüft Kaskadierung und relationale Integrität in SwiftData).
    *   **Manueller Check (Vera):** Spot anlegen $\rightarrow$ 3 Bilder mit unterschiedlichen Winkeln hinzufügen $\rightarrow$ Einzelnes Bild löschen $\rightarrow$ Verifizieren, dass der Spot und die verbleibenden 2 Bilder intakt sind.

---

### UC-05: Löschschutz & Asset-Synchronisationsprüfung
*   **Beschreibung:** Umgang mit Bildern, die vom Nutzer in der iOS Fotos-App gelöscht wurden.
*   **Ablauf:**
    1. Beim Laden eines Spots prüft die App die Existenz des PHAssets über die gespeicherte `localIdentifier`.
    2. Existiert das Original nicht mehr, wird das lokale Cache-Thumbnail weiterhin angezeigt, aber ein roter Warnhinweis eingeblendet.
*   **Akzeptanzkriterien:**
    *   *AC-05.1:* Kein Absturz, wenn das Originalbild physisch fehlt.
    *   *AC-05.2:* Der Warnhinweis wird sofort und unmissverständlich in der Detailansicht angezeigt.
*   **Prüfmethoden:**
    *   **Unit-Test (Felix):** Mock-Objekt für `PHPhotoLibrary` bereitstellen, das bei einer bestimmten ID ein Fehlen simuliert.
    *   **Manueller Check (Vera):** Spot importieren $\rightarrow$ Bild in der Apple Fotos-App löschen $\rightarrow$ App starten $\rightarrow$ Warnhinweis verifizieren.

---

## 3. Zukünftige Anwendungsfälle (Priorität C - Post-MVP)

Diese Anwendungsfälle sind Ideen für spätere Entwicklungsstufen und müssen für das MVP noch nicht implementiert oder getestet werden. Sie dienen jedoch als architektonische Richtschnur.

### UC-06: GPX-Track-Synchronisation (Automatisches Geotagging)
*   **Beschreibung:** Der Nutzer lädt eine GPX-Datei hoch. Die App gleicht importierte Fotos ohne GPS-Daten über den Zeitstempel mit den GPX-Punkten ab und berechnet (interpoliert) die genaue Koordinate des Bildes.
*   **Zukünftige Akzeptanzkriterien:**
    *   *AC-06.1:* Erfolgreicher Import von `.gpx`-Dateien (XML-Standard).
    *   *AC-06.2:* Korrekte lineare Interpolation der Position, falls das Foto zeitlich zwischen zwei Trackpunkten liegt.

### UC-07: Zeitversatz-Korrektur (Time Sync Slider)
*   **Beschreibung:** Der Nutzer korrigiert eine asynchrone Kamerauhr, um eine korrekte Zuordnung zum GPX-Track zu ermöglichen.
*   **Zukünftige Akzeptanzkriterien:**
    *   *AC-07.1:* Der Nutzer kann über einen Regler oder ein Eingabefeld einen zeitlichen Offset ($+/-$ Stunden, Minuten, Sekunden) angeben.
    *   *AC-07.2:* Der Offset wird temporär auf die Foto-Aufnahmezeit aufaddiert, bevor der GPX-Vergleich (UC-06) ausgeführt wird.

### UC-08: Manuelle Kartenplatzierung (Drag & Drop)
*   **Beschreibung:** Der Nutzer platziert verortungsfreie Fotos manuell auf der Karte.
*   **Zukünftige Akzeptanzkriterien:**
    *   *AC-08.1:* Drag & Drop eines Fotomarkers auf der Karte aktualisiert die GPS-Koordinaten des `LocationPhoto`-Objekts in der Datenbank.

