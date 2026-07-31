# Test-Spezifikation und Anwendungsfälle: SoloScout iOS-App
*Erstellt am 30. Juli 2026 | Rolle: Pax (Senior Research Specialist)*

---

## 1. Übersicht

Dieses Dokument definiert die funktionalen Anwendungsfälle (Use Cases, UCs) für das MVP der SoloScout-App. Es dient als bindende Vorgabe für die Entwicklung (Felix) zur Erstellung der Unit-Tests und für die Qualitätssicherung (Vera) zur Durchführung der Quality-Checks.

Jeder Anwendungsfall ist direkt mit Akzeptanzkriterien und konkreten Prüfmethoden verknüpft (Vier-Augen-Prinzip).

---

## 2. System-Fotomediathek-Integration & Tastatur-Eingabekonventionen

### 2.1 Anbindung System-Fotomediathek
Die Anbindung der iOS-Fotomediathek unterliegt den strikten Sicherheitsrichtlinien von Apple (iOS Sandbox):
*   **Feste System-Fotomediathek:** Unter iOS gibt es systemweit genau eine aktive *System-Fotomediathek* (konfiguriert in der iOS-Einstellungen-App unter *Fotos*). Apps können keine benutzerdefinierten `.photoslibrary`-Dateipfade auf dem Gerät wählen. Die App greift automatisch immer auf diese primäre Mediathek zu.
*   **Out-of-Process PhotosPicker:** Die App nutzt Apples nativen `PhotosPicker` (`PhotosUI`). Dieser läuft in einem isolierten Systemprozess. Der Benutzer wählt darin Bilder aus seiner System-Fotomediathek aus.
*   **Berechtigungskonzept:** Da der Picker außerhalb der App läuft, muss der Benutzer der App keinen globalen Vollzugriff auf seine gesamte Fotomediathek gewähren. Die App erhält nach der Auswahl einen sicheren Datenstrom (`loadTransferable`) des ausgewählten Bildes. Dies gewährleistet maximale Datensicherheit und reibungslose Funktion auch bei restriktiven Rechteeinstellungen.

### 2.2 Tastatur-Eingaben (Keine Autokorrektur / Autocomplete)
*   **Keine Wortvorschläge (No Autocomplete):** Alle Eingabefelder für Text (Titel des Fotospots, eigene Kategorien, eigene Ausrüstungsteile und Notizen) sind ohne Autokorrektur (`.autocorrectionDisabled(true)`) und ohne automatische Rechtschreibkorrektur-Vorschläge implementiert.
*   **Manuelle Volleingabe:** Fotografische Fachbegriffe, Marken- und Modellnamen oder persönliche Kürzel müssen vom Nutzer vollkommen manuell eingetippt und nicht vom iOS-System eigenmächtig abgeändert oder vorgeschlagen werden.

---

## 3. Funktionale Anwendungsfälle (Use Cases)

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
    1. Nutzer wählt in der App "Mediathek".
    2. Der iOS Photo Picker öffnet sich.
    3. Nach der Auswahl extrahiert die App die EXIF-Daten (GPS-Ort, Zeit, Brennweite) des ausgewählten Assets.
    4. Fehlen dem Bild GPS-Koordinaten, erhält der Nutzer die Möglichkeit, den Ort manuell auf einer Karte festzulegen (siehe UC-06).
    5. Die ermittelten/verorteten Werte werden eingetragen, ein neuer Spot wird erzeugt und das Bild verknüpft.
*   **Akzeptanzkriterien:**
    *   *AC-02.1:* Fehlen GPS-Daten im Bild, wird keine Fehlermeldung ausgegeben, sondern der Wechsel in die manuelle Kartenverortung (UC-06) ermöglicht.
    *   *AC-02.2:* Die extrahierten Werte (Koordinaten, Datum, Brennweite) stimmen exakt mit den Originaldateidaten überein.
*   **Prüfmethoden:**
    *   **Unit-Test (Felix):** `SoloScoutTests/UC02_LibraryImportTests.swift -> testEXIFExtractionFromAsset()` (Validiert EXIF-Parser mit Testbildern).
    *   **Manueller Check (Vera):** Import von Testbildern ohne GPS und Verifizieren, dass der Button „Ort auf Karte festlegen“ erscheint.

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

### UC-06: Manuelle Kartenplatzierung (Spot & Parkplatz)
*   **Beschreibung:** Der Nutzer legt den Standort eines verortungsfreien Bildes oder eines Parkplatz-Pins manuell auf einer interaktiven Karte fest.
*   **Ablauf:**
    1. Nutzer tippt auf „Ort auf Karte festlegen“ oder „Parkplatz auf Karte verorten“.
    2. Ein Karten-Sheet öffnet sich, zentriert auf die Koordinaten des letzten Spots (als regionaler Standardwert) bzw. auf den Spot selbst (für den Parkplatz).
    3. Der Nutzer tippt auf die Karte, um einen Pin zu setzen.
    4. Nach Bestätigung werden Breitengrad und Längengrad in die Erfassungsmaske übernommen.
*   **Akzeptanzkriterien:**
    *   *AC-06.1:* Die Karte öffnet sich zentriert in der Nähe bereits existierender Spots (Vermeidung von langwierigem Suchen auf der Weltkarte).
    *   *AC-06.2:* Der Benutzer kann den Marker per Tap präzise verschieben.
    *   *AC-06.3:* Die Koordinaten werden beim Speichern exakt in das Datenmodell übernommen.
*   **Prüfmethoden:**
    *   **Manueller Check (Vera):** Spot ohne GPS importieren $\rightarrow$ Karte öffnen $\rightarrow$ Pin setzen und verifizieren, dass die Koordinaten in den Textfeldern erscheinen.

---

### UC-07: Flexibles Kategorien- & Ausrüstungs-Management (Multi-Select & Custom Tags)
*   **Beschreibung:** Der Nutzer weist einem Spot mehrere Kategorien zu und ergänzt Ausrüstungsteile und Kategorien spontan. Zudem kann er falsch geschriebene Kategorien dauerhaft löschen.
*   **Ablauf:**
    1. Nutzer wählt in der Erfassungsmaske beliebig viele Kategorien (z. B. Natur + Abstrakt) aus einer Checkliste.
    2. Nutzer fügt über ein Eingabefeld eine neue Kategorie oder ein neues Ausrüstungsteil hinzu.
    3. Das neue Element erscheint sofort in der Auswahlliste und wird dem Spot zugeordnet.
    4. Möchte der Nutzer eine benutzerdefinierte Kategorie löschen, tippt er auf das rote Mülltonnen-Symbol.
    5. Ist die Kategorie bei anderen Spots in Benutzung, erscheint ein Bestätigungsdialog. Nach Bestätigung wird sie von allen betroffenen Spots in der Datenbank entfernt.
*   **Akzeptanzkriterien:**
    *   *AC-07.1:* Eigene Kategorien und Ausrüstungsteile werden dauerhaft in der Liste der Maske vorgehalten.
    *   *AC-07.2:* Nach dem Speichern werden in der Detailansicht des Spots ausschließlich die tatsächlich ausgewählten Ausrüstungsgegenstände angezeigt (keine leeren Checkboxen).
    *   *AC-07.3:* Das Löschen einer Kategorie entfernt sie global aus der Auswahlliste und allen bereits gespeicherten Spots.
*   **Prüfmethoden:**
    *   **Manueller Check (Vera):** Neue Kategorie „Langzeit“ und neue Ausrüstung „Graufilter“ anlegen $\rightarrow$ Auswählen $\rightarrow$ Spot speichern $\rightarrow$ Detailansicht prüfen.
    *   **Löschtest (Vera):** Kategorie auf Mülltonnen-Symbol klicken $\rightarrow$ Dialog bestätigen $\rightarrow$ Prüfen, ob die Kategorie überall entfernt wurde.

---

## 3. Zukünftige Anwendungsfälle (Priorität C - Post-MVP)

Diese Anwendungsfälle sind Ideen für spätere Entwicklungsstufen und müssen für das MVP noch nicht implementiert oder getestet werden. Sie dienen jedoch als architektonische Richtschnur.

### UC-08: GPX-Track-Synchronisation (Automatisches Geotagging)
*   **Beschreibung:** Der Nutzer lädt eine GPX-Datei hoch. Die App gleicht importierte Fotos ohne GPS-Daten über den Zeitstempel mit den GPX-Punkten ab und berechnet (interpoliert) die genaue Koordinate des Bildes.
*   **Zukünftige Akzeptanzkriterien:**
    *   *AC-08.1:* Erfolgreicher Import von `.gpx`-Dateien (XML-Standard).
    *   *AC-08.2:* Korrekte lineare Interpolation der Position, falls das Foto zeitlich zwischen zwei Trackpunkten liegt.

### UC-09: Zeitversatz-Korrektur (Time Sync Slider)
*   **Beschreibung:** Der Nutzer korrigiert eine asynchrone Kamerauhr, um eine korrekte Zuordnung zum GPX-Track zu ermöglichen.
*   **Zukünftige Akzeptanzkriterien:**
    *   *AC-09.1:* Der Nutzer kann über einen Regler einen zeitlichen Offset aufaddieren, bevor der GPX-Vergleich (UC-08) ausgeführt wird.


