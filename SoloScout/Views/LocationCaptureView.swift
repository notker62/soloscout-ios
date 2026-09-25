//
//  LocationCaptureView.swift
//  SoloScout
//
//  Created by Felix on 31.07.2026.
//  Purpose: Form view handling camera capture, Photos library selection, metadata parsing, interactive map geotagging, and location creation.
//  Module: Views
//

import SwiftUI
import SwiftData
import PhotosUI
import CoreLocation
import MapKit

struct LocationCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var locationToEdit: PhotoLocation? = nil
    
    // Query existing spots to find nearby coordinate default matching
    @Query(sort: \PhotoLocation.creationDate, order: .reverse) private var locations: [PhotoLocation]
    @Query(sort: \TagItem.name) private var tagItems: [TagItem]
    @Query(sort: \GearItem.name) private var gearItems: [GearItem]
    
    // Services
    @State private var locationService = LocationService()
    @State private var photoService = PhotoService()
    
    // Input Fields
    @State private var title = ""
    @State private var selectedCategories: [String] = ["Landschaft"]
    @State private var newCategoryName = ""
    @State private var notes = ""
    
    // Coordinates
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var addParking = false
    @State private var parkingLatitude = ""
    @State private var parkingLongitude = ""
    
    // Gear selections
    @State private var selectedGear: [String] = []
    @State private var newGearName = ""
    
    // Image Selection States
    @State private var photosPickerItem: PhotosPickerItem? = nil
    @State private var cameraImage: UIImage? = nil
    @State private var isShowingCamera = false
    
    // Extracted EXIF details
    @State private var selectedImageThumbnail: Data? = nil
    @State private var extractedLensModel: String? = nil
    @State private var extractedFocalLength: Int? = nil
    @State private var extractedAperture: Double? = nil
    @State private var currentPHAsset: PHAsset? = nil
    
    // Alert feedback states for validation/denied permissions
    @State private var isShowingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Interactive Map Sheets trigger states
    @State private var isShowingMapPicker = false
    @State private var isShowingParkingMapPicker = false
    
    // Keyboard focus state
    @FocusState private var isInputActive: Bool
    
    var availableCategories: [String] {
        let tagNames = tagItems.map(\.name)
        let dbCats = locations.flatMap { $0.categories }
        let allCats = Set(tagNames + dbCats)
        return allCats.sorted()
    }
    
    var availableGear: [String] {
        let gearNames = gearItems.map(\.name)
        let dbGear = locations.flatMap { $0.requiredGear }
        let allGear = Set(gearNames + dbGear)
        return allGear.sorted()
    }
    
    var lastSavedCoordinate: CLLocationCoordinate2D {
        if let last = locations.first {
            return CLLocationCoordinate2D(latitude: last.latitude, longitude: last.longitude)
        }
        // Default to Frankfurt, Germany
        return CLLocationCoordinate2D(latitude: 50.1109, longitude: 8.6821)
    }
    
    // Clean helper computed property to resolve Swift compile complexity checks
    var parkingInitialCenter: CLLocationCoordinate2D {
        if let latVal = Double(latitude), let lonVal = Double(longitude) {
            return CLLocationCoordinate2D(latitude: latVal, longitude: lonVal)
        }
        return lastSavedCoordinate
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Prominent Image Preview at the very top (Conditional)
                if let thumbnailData = selectedImageThumbnail, let uiImage = UIImage(data: thumbnailData) {
                    Section("Importiertes Foto & EXIF-Daten") {
                        HStack(spacing: 16) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if let focal = extractedFocalLength {
                                    Text("Brennweite: \(focal) mm (KB)")
                                        .font(.caption)
                                        .bold()
                                }
                                if let lens = extractedLensModel {
                                    Text("Objektiv: \(lens)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                if let ap = extractedAperture {
                                    Text("Blende: f/\(String(format: "%.2f", ap))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                if !latitude.isEmpty && !longitude.isEmpty {
                                    Text("GPS extrahiert: \(latitude), \(longitude)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Section 2: Media Import
                Section("Foto erfassen") {
                    HStack(spacing: 20) {
                        // Live Camera Button
                        Button {
                            #if targetEnvironment(simulator)
                            alertTitle = "Kamera nicht verfügbar"
                            alertMessage = "Die Kamera kann im iOS-Simulator nicht verwendet werden."
                            isShowingAlert = true
                            #else
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                isShowingCamera = true
                            } else {
                                alertTitle = "Kamera nicht verfügbar"
                                alertMessage = "Es ist keine Kamera auf diesem Gerät vorhanden oder der Zugriff wurde eingeschränkt."
                                isShowingAlert = true
                            }
                            #endif
                        } label: {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                Text("Kamera")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Photo Picker Button
                        PhotosPicker(selection: $photosPickerItem, matching: .images) {
                            VStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2)
                                Text("Mediathek")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                // Section 3: General Details
                Section("Allgemein") {
                    TextField("Titel des Fotospots", text: $title)
                        .focused($isInputActive)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.words)
                }
                
                // Section 4: Multiple Categories Checklist + Add Custom Category
                Section("Kategorien (Mehrfachauswahl)") {
                    ForEach(availableCategories, id: \.self) { cat in
                        HStack {
                            Text(cat)
                            Spacer()
                            
                            if selectedCategories.contains(cat) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedCategories.contains(cat) {
                                selectedCategories.removeAll { $0 == cat }
                            } else {
                                selectedCategories.append(cat)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Eigene Kategorie hinzufügen", text: $newCategoryName)
                            .focused($isInputActive)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                        Button {
                            let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                if !tagItems.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
                                    let newTag = TagItem(name: trimmed, isDefault: false)
                                    modelContext.insert(newTag)
                                    try? modelContext.save()
                                }
                                if !selectedCategories.contains(trimmed) {
                                    selectedCategories.append(trimmed)
                                }
                                newCategoryName = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                // Section 5: Geolocation Details + Map Geotagging
                Section("Geodaten (Fotospot)") {
                    HStack {
                        TextField("Breitengrad (Lat)", text: $latitude)
                            .keyboardType(.decimalPad)
                            .focused($isInputActive)
                        TextField("Längengrad (Lon)", text: $longitude)
                            .keyboardType(.decimalPad)
                            .focused($isInputActive)
                    }
                    
                    Button {
                        locationService.requestAuthorization()
                        locationService.startUpdatingLocation()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            if let coord = locationService.currentCoordinate {
                                self.latitude = String(format: "%.6f", coord.latitude)
                                self.longitude = String(format: "%.6f", coord.longitude)
                            } else {
                                alertTitle = "Standortabfrage fehlgeschlagen"
                                alertMessage = "Der Standort konnte nicht ermittelt werden. Bitte stelle sicher, dass die Ortungsdienste aktiviert sind."
                                isShowingAlert = true
                            }
                            locationService.stopUpdatingLocation()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "location.circle.fill")
                            Text("Aktuellen Standort abfragen")
                        }
                    }
                    
                    Button {
                        isShowingMapPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Ort auf Karte festlegen")
                        }
                    }
                }
                
                // Section 6: Parking details + Parking map picker
                Section("Parkplatz hinzufügen") {
                    Toggle("Separater Parkplatz-Pin", isOn: $addParking)
                    
                    if addParking {
                        HStack {
                            TextField("Parkplatz Lat", text: $parkingLatitude)
                                .keyboardType(.decimalPad)
                                .focused($isInputActive)
                            TextField("Parkplatz Lon", text: $parkingLongitude)
                                .keyboardType(.decimalPad)
                                .focused($isInputActive)
                        }
                        
                        Button {
                            isShowingParkingMapPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "car.fill")
                                Text("Parkplatz auf Karte verorten")
                            }
                        }
                    }
                }
                
                // Section 7: Gear Checklist + Add Custom Gear
                Section("Benötigte Ausrüstung") {
                    ForEach(availableGear, id: \.self) { gear in
                        HStack {
                            Text(gear)
                            Spacer()
                            if selectedGear.contains(gear) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedGear.contains(gear) {
                                selectedGear.removeAll { $0 == gear }
                            } else {
                                selectedGear.append(gear)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Eigene Ausrüstung hinzufügen", text: $newGearName)
                            .focused($isInputActive)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                        Button {
                            let trimmed = newGearName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                if !gearItems.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
                                    let newGear = GearItem(name: trimmed, categoryRaw: "tripodAccessory", isFavorite: false, isDefault: false)
                                    modelContext.insert(newGear)
                                    try? modelContext.save()
                                }
                                if !selectedGear.contains(trimmed) {
                                    selectedGear.append(trimmed)
                                }
                                newGearName = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .disabled(newGearName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                // Section 8: Notes
                Section("Anmerkungen / Tipps") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .focused($isInputActive)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.sentences)
                }
            }
            .navigationTitle(locationToEdit == nil ? "Fotospot anlegen" : "Fotospot bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveLocation()
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        isInputActive = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker(isPresented: $isShowingCamera, capturedImage: $cameraImage)
            }
            // Parse metadata when picking a photo from Library
            .onChange(of: photosPickerItem) { _, newItem in
                Task {
                    guard let item = newItem else { return }
                    
                    do {
                        if let data = try await item.loadTransferable(type: Data.self) {
                            if let thumbnail = photoService.resizeImageData(data: data) {
                                self.selectedImageThumbnail = thumbnail
                            } else {
                                self.selectedImageThumbnail = data
                            }
                            
                            // Extract EXIF details directly from raw Data bytes
                            let meta = photoService.extractMetadata(from: data)
                            self.extractedLensModel = meta.lensModel
                            self.extractedFocalLength = meta.focalLengthEquivalent
                            self.extractedAperture = meta.aperture
                            
                            if let lat = meta.latitude, let lon = meta.longitude {
                                self.latitude = String(format: "%.6f", lat)
                                self.longitude = String(format: "%.6f", lon)
                            }
                        }
                    } catch {
                        alertTitle = "Fehler beim Laden"
                        alertMessage = "Das Bild konnte nicht aus der Mediathek geladen werden."
                        isShowingAlert = true
                    }
                }
            }
            // Generate metadata when capturing a new image from Camera
            .onChange(of: cameraImage) { _, image in
                guard let image = image else { return }
                
                if let data = image.jpegData(compressionQuality: 0.6) {
                    if let thumbnail = photoService.resizeImageData(data: data) {
                        self.selectedImageThumbnail = thumbnail
                    } else {
                        self.selectedImageThumbnail = data
                    }
                }
                
                self.extractedFocalLength = 24
                self.extractedLensModel = "iPhone Camera"
                self.extractedAperture = 1.78
                
                locationService.requestAuthorization()
                locationService.startUpdatingLocation()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    if let coord = locationService.currentCoordinate {
                        self.latitude = String(format: "%.6f", coord.latitude)
                        self.longitude = String(format: "%.6f", coord.longitude)
                    }
                    locationService.stopUpdatingLocation()
                }
            }
            .alert(alertTitle, isPresented: $isShowingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            // Map picker sheets
            .sheet(isPresented: $isShowingMapPicker) {
                LocationPickerMapSheet(
                    latitude: $latitude,
                    longitude: $longitude,
                    initialCenter: lastSavedCoordinate
                )
            }
            .sheet(isPresented: $isShowingParkingMapPicker) {
                LocationPickerMapSheet(
                    latitude: $parkingLatitude,
                    longitude: $parkingLongitude,
                    initialCenter: parkingInitialCenter
                )
            }
            .onAppear {
                if let loc = locationToEdit {
                    title = loc.title
                    selectedCategories = loc.categories
                    notes = loc.descriptionNotes
                    latitude = String(format: "%.6f", loc.latitude)
                    longitude = String(format: "%.6f", loc.longitude)
                    selectedGear = loc.requiredGear
                    if loc.hasParking, let pLat = loc.parkingLatitude, let pLon = loc.parkingLongitude {
                        addParking = true
                        parkingLatitude = String(format: "%.6f", pLat)
                        parkingLongitude = String(format: "%.6f", pLon)
                    }
                    if let firstPhoto = loc.photos.first {
                        selectedImageThumbnail = firstPhoto.thumbnailData
                        extractedFocalLength = firstPhoto.focalLengthEquivalent
                        extractedLensModel = firstPhoto.originalLensModel
                        extractedAperture = firstPhoto.aperture
                    }
                }
            }
        }
    }
    
    private func saveLocation() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            alertTitle = "Titel fehlt"
            alertMessage = "Bitte gib einen Namen/Titel für den Fotospot an."
            isShowingAlert = true
            return
        }
        
        guard let latVal = Double(latitude), let lonVal = Double(longitude) else {
            alertTitle = "Geodaten fehlen"
            alertMessage = "Der Fotospot benötigt Koordinaten. Bitte ermittle deinen aktuellen Standort oder setze ihn auf der Karte fest."
            isShowingAlert = true
            return
        }
        
        if let loc = locationToEdit {
            // Edit mode: Update existing PhotoLocation properties
            loc.title = trimmedTitle
            loc.categories = selectedCategories
            loc.latitude = latVal
            loc.longitude = lonVal
            loc.descriptionNotes = notes
            loc.requiredGear = selectedGear
            
            if addParking, let pLat = Double(parkingLatitude), let pLon = Double(parkingLongitude) {
                loc.hasParking = true
                loc.parkingLatitude = pLat
                loc.parkingLongitude = pLon
            } else {
                loc.hasParking = false
                loc.parkingLatitude = nil
                loc.parkingLongitude = nil
            }
            
            // Only add a new photo if a new one was actually picked or shot
            if currentPHAsset != nil || cameraImage != nil || selectedImageThumbnail != nil {
                let newPhoto = LocationPhoto()
                newPhoto.thumbnailData = selectedImageThumbnail
                newPhoto.focalLengthEquivalent = extractedFocalLength
                newPhoto.originalLensModel = extractedLensModel
                newPhoto.aperture = extractedAperture
                newPhoto.latitude = latVal
                newPhoto.longitude = lonVal
                newPhoto.location = loc
                
                if let asset = currentPHAsset {
                     newPhoto.photoAssetIdentifier = asset.localIdentifier
                     addPhotoToSystemAlbum(asset: asset)
                } else if let uiImage = cameraImage {
                     saveImageToPhotosLibrary(image: uiImage) { identifier in
                         if let identifier = identifier {
                             newPhoto.photoAssetIdentifier = identifier
                         }
                     }
                }
                modelContext.insert(newPhoto)
                loc.photos.append(newPhoto)
            }
            
            do {
                try modelContext.save()
                dismiss()
            } catch {
                alertTitle = "Speicherfehler"
                alertMessage = "Der Fotospot konnte nicht auf der SSD gespeichert werden: \(error.localizedDescription)"
                isShowingAlert = true
            }
        } else {
            // Create mode: Create and insert new PhotoLocation
            let newLocation = PhotoLocation(
                title: trimmedTitle,
                categories: selectedCategories,
                latitude: latVal,
                longitude: lonVal
            )
            newLocation.descriptionNotes = notes
            newLocation.requiredGear = selectedGear
            
            if addParking, let pLat = Double(parkingLatitude), let pLon = Double(parkingLongitude) {
                newLocation.hasParking = true
                newLocation.parkingLatitude = pLat
                newLocation.parkingLongitude = pLon
            }
            
            modelContext.insert(newLocation)
            
            if selectedImageThumbnail != nil || cameraImage != nil || currentPHAsset != nil {
                let newPhoto = LocationPhoto()
                newPhoto.thumbnailData = selectedImageThumbnail
                newPhoto.focalLengthEquivalent = extractedFocalLength
                newPhoto.originalLensModel = extractedLensModel
                newPhoto.aperture = extractedAperture
                newPhoto.latitude = latVal
                newPhoto.longitude = lonVal
                newPhoto.location = newLocation
                
                if let asset = currentPHAsset {
                    newPhoto.photoAssetIdentifier = asset.localIdentifier
                    addPhotoToSystemAlbum(asset: asset)
                } else if let uiImage = cameraImage {
                    saveImageToPhotosLibrary(image: uiImage) { identifier in
                        if let identifier = identifier {
                            newPhoto.photoAssetIdentifier = identifier
                        }
                    }
                }
                
                modelContext.insert(newPhoto)
                newLocation.photos.append(newPhoto)
            }
            
            do {
                try modelContext.save()
                dismiss()
            } catch {
                alertTitle = "Speicherfehler"
                alertMessage = "Der Fotospot konnte nicht auf der SSD gespeichert werden: \(error.localizedDescription)"
                isShowingAlert = true
            }
        }
    }
    
    private func addPhotoToSystemAlbum(asset: PHAsset) {
        let albumName = "SoloScout"
        fetchOrCreateAlbum(named: albumName) { album in
            guard let album = album else { return }
            PHPhotoLibrary.shared().performChanges({
                let addRequest = PHAssetCollectionChangeRequest(for: album)
                addRequest?.addAssets([asset] as NSArray)
            })
        }
    }
    
    private func saveImageToPhotosLibrary(image: UIImage, completion: @escaping (String?) -> Void) {
        var localId: String? = nil
        PHPhotoLibrary.shared().performChanges({
            let createRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            localId = createRequest.placeholderForCreatedAsset?.localIdentifier
        }, completionHandler: { success, error in
            if success, let id = localId {
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
                if let asset = fetchResult.firstObject {
                    self.addPhotoToSystemAlbum(asset: asset)
                }
                completion(id)
            } else {
                completion(nil)
            }
        })
    }
    
    private func fetchOrCreateAlbum(named title: String, completion: @escaping (PHAssetCollection?) -> Void) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", title)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let firstObject = collections.firstObject {
            completion(firstObject)
        } else {
            var placeholder: PHObjectPlaceholder? = nil
            PHPhotoLibrary.shared().performChanges({
                let createRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
                placeholder = createRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { success, error in
                if success, let placeholder = placeholder {
                    let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                    completion(collections.firstObject)
                } else {
                    completion(nil)
                }
            })
        }
    }
}

// Camera Helper Wrapper for UIKit UIImagePickerController
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var capturedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// Reusable Map Picker Sheet using modern iOS 17 MapKit
struct LocationPickerMapSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var latitude: String
    @Binding var longitude: String
    var initialCenter: CLLocationCoordinate2D
    
    @State private var pickedCoordinate: CLLocationCoordinate2D? = nil
    @State private var position: MapCameraPosition = .automatic
    
    init(latitude: Binding<String>, longitude: Binding<String>, initialCenter: CLLocationCoordinate2D) {
        self._latitude = latitude
        self._longitude = longitude
        self.initialCenter = initialCenter
        
        if let latVal = Double(latitude.wrappedValue), let lonVal = Double(longitude.wrappedValue) {
            let coord = CLLocationCoordinate2D(latitude: latVal, longitude: lonVal)
            self._pickedCoordinate = State(initialValue: coord)
            self._position = State(initialValue: .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )))
        } else {
            self._position = State(initialValue: .region(MKCoordinateRegion(
                center: initialCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )))
        }
    }
    
    var body: some View {
        NavigationStack {
            MapReader { reader in
                Map(position: $position, interactionModes: .all) {
                    if let coord = pickedCoordinate {
                        Marker("Ausgewählter Ort", systemImage: "mappin.and.ellipse", coordinate: coord)
                            .tint(.red)
                    }
                }
                .onTapGesture { screenPosition in
                    if let coord = reader.convert(screenPosition, from: .local) {
                        pickedCoordinate = coord
                    }
                }
            }
            .navigationTitle("Ort auf Karte festlegen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Übernehmen") {
                        if let coord = pickedCoordinate {
                            latitude = String(format: "%.6f", coord.latitude)
                            longitude = String(format: "%.6f", coord.longitude)
                        }
                        dismiss()
                    }
                    .disabled(pickedCoordinate == nil)
                }
            }
        }
    }
}
