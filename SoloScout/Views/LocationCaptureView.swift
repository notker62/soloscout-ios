//
//  LocationCaptureView.swift
//  SoloScout
//
//  Created by Felix on 31.07.2026.
//  Purpose: Form view handling camera capture, Photos library selection, metadata parsing, and location creation.
//  Module: Views
//

import SwiftUI
import SwiftData
import PhotosUI
import CoreLocation

struct LocationCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Services
    @State private var locationService = LocationService()
    @State private var photoService = PhotoService()
    
    // Input Fields
    @State private var title = ""
    @State private var category = "Natur"
    @State private var notes = ""
    @State private var difficulty = "Easy"
    
    // Coordinates
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var addParking = false
    @State private var parkingLatitude = ""
    @State private var parkingLongitude = ""
    
    // Customizable gear checklist (loaded from setting defaults)
    @State private var availableGear = ["Stativ", "ND-Filter", "Polfilter", "Drohne", "Fernauslöser"]
    @State private var selectedGear: [String] = []
    
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
    
    // Alert feedback states for denied permissions or hardware errors
    @State private var isShowingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var categories = ["Natur", "Architektur", "Street", "Abstrakt"]
    var difficulties = ["Easy", "Medium", "Hard"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Media Import
                Section("Foto erfassen") {
                    HStack(spacing: 20) {
                        // Live Camera Button with availability check
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
                    
                    // Preview selected image and metadata
                    if let thumbnailData = selectedImageThumbnail, let uiImage = UIImage(data: thumbnailData) {
                        HStack(spacing: 16) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if let focal = extractedFocalLength {
                                    Text("Brennweite: \(focal) mm (Vollformat)")
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
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Section 2: General Details
                Section("Allgemein") {
                    TextField("Titel des Fotospots", text: $title)
                    
                    Picker("Kategorie", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat)
                        }
                    }
                    
                    Picker("Schwierigkeit", selection: $difficulty) {
                        ForEach(difficulties, id: \.self) { diff in
                            Text(diff)
                        }
                    }
                }
                
                // Section 3: Geolocation Details
                Section("Geodaten (Fotospot)") {
                    HStack {
                        TextField("Breitengrad (Lat)", text: $latitude)
                            .keyboardType(.decimalPad)
                        TextField("Längengrad (Lon)", text: $longitude)
                            .keyboardType(.decimalPad)
                    }
                    
                    Button {
                        locationService.requestAuthorization()
                        locationService.startUpdatingLocation()
                        
                        // Wait shortly for coordinate fetch
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            if let coord = locationService.currentCoordinate {
                                self.latitude = String(format: "%.6f", coord.latitude)
                                self.longitude = String(format: "%.6f", coord.longitude)
                            } else {
                                alertTitle = "Standortabfrage fehlgeschlagen"
                                alertMessage = "Der Standort konnte nicht ermittelt werden. Bitte stelle sicher, dass die Ortungsdienste auf deinem Gerät aktiviert sind und der Zugriff erlaubt wurde."
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
                }
                
                // Section 4: Parking details
                Section("Parkplatz hinzufügen") {
                    Toggle("Separater Parkplatz-Pin", isOn: $addParking)
                    
                    if addParking {
                        HStack {
                            TextField("Parkplatz Lat", text: $parkingLatitude)
                                .keyboardType(.decimalPad)
                            TextField("Parkplatz Lon", text: $parkingLongitude)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                
                // Section 5: Gear Checklist
                Section("Ausrüstung") {
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
                }
                
                // Section 6: Notes
                Section("Anmerkungen / Tipps") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Fotospot anlegen")
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
                    .disabled(title.isEmpty || latitude.isEmpty || longitude.isEmpty)
                }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker(isPresented: $isShowingCamera, capturedImage: $cameraImage)
            }
            // Parse metadata when picking a photo from Library
            .onChange(of: photosPickerItem) { _, newItem in
                Task {
                    guard let item = newItem else { return }
                    
                    // Request library permissions
                    photoService.requestAuthorization { status in
                        if status == .authorized || status == .limited {
                            // Extract PHAsset local identifier
                            if let localId = item.itemIdentifier {
                                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
                                if let asset = fetchResult.firstObject {
                                    self.currentPHAsset = asset
                                    
                                    // Extract GPS Coordinates from photo if present
                                    if let location = asset.location {
                                        self.latitude = String(format: "%.6f", location.coordinate.latitude)
                                        self.longitude = String(format: "%.6f", location.coordinate.longitude)
                                    }
                                    
                                    // Generate Thumbnail
                                    photoService.generateThumbnail(for: asset) { data in
                                        self.selectedImageThumbnail = data
                                    }
                                    
                                    // Extract EXIF metadata
                                    photoService.extractMetadata(for: asset) { meta in
                                        self.extractedLensModel = meta.lensModel
                                        self.extractedFocalLength = meta.focalLengthEquivalent
                                        self.extractedAperture = meta.aperture
                                    }
                                }
                            }
                        } else {
                            alertTitle = "Fotomediathek-Zugriff verweigert"
                            alertMessage = "Der Zugriff auf deine Fotomediathek wurde abgelehnt. Bitte aktiviere den Zugriff in den iOS-Einstellungen, damit wir Metadaten wie Brennweite und GPS direkt aus deinen Bildern auslesen können."
                            isShowingAlert = true
                        }
                    }
                }
            }
            // Generate metadata when capturing a new image from Camera
            .onChange(of: cameraImage) { _, image in
                guard let image = image else { return }
                
                // Generate Thumbnail directly
                if let data = image.jpegData(compressionQuality: 0.6) {
                    self.selectedImageThumbnail = data
                }
                
                // Camera capture uses default iPhone main lens metadata approximation for MVP
                self.extractedFocalLength = 24
                self.extractedLensModel = "iPhone Camera"
                self.extractedAperture = 1.78
                
                // Ask Location Services for GPS coordinates since camera raw UIImage does not hold location
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
        }
    }
    
    private func saveLocation() {
        guard let latVal = Double(latitude), let lonVal = Double(longitude) else { return }
        
        let newLocation = PhotoLocation(
            title: title,
            category: category,
            latitude: latVal,
            longitude: lonVal
        )
        newLocation.descriptionNotes = notes
        newLocation.difficulty = difficulty
        newLocation.requiredGear = selectedGear
        
        if addParking, let pLat = Double(parkingLatitude), let pLon = Double(parkingLongitude) {
            newLocation.hasParking = true
            newLocation.parkingLatitude = pLat
            newLocation.parkingLongitude = pLon
        }
        
        // Create associated photo relation (1-to-N)
        let newPhoto = LocationPhoto()
        newPhoto.thumbnailData = selectedImageThumbnail
        newPhoto.focalLengthEquivalent = extractedFocalLength
        newPhoto.originalLensModel = extractedLensModel
        newPhoto.aperture = extractedAperture
        newPhoto.latitude = latVal
        newPhoto.longitude = lonVal
        
        if let asset = currentPHAsset {
            newPhoto.photoAssetIdentifier = asset.localIdentifier
            
            // Add to system "SoloScout" album for deletion protection
            addPhotoToSystemAlbum(asset: asset)
        } else if let uiImage = cameraImage {
            // If shot live, write to system library first, then get identifier
            saveImageToPhotosLibrary(image: uiImage) { identifier in
                if let identifier = identifier {
                    newPhoto.photoAssetIdentifier = identifier
                }
            }
        }
        
        newLocation.photos.append(newPhoto)
        modelContext.insert(newLocation)
        
        try? modelContext.save()
        dismiss()
    }
    
    // Core PhotosKit integration for Album organisation
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
                // Also add to custom album
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
