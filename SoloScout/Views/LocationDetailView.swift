//
//  LocationDetailView.swift
//  SoloScout
//
//  Created by Felix on 31.07.2026.
//  Purpose: Detail screen displaying map, notes, gear check-list, and photo galleries.
//  Module: Views
//

import SwiftUI
import SwiftData
import MapKit

struct LocationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var location: PhotoLocation
    
    // Map state using iOS 17 MapKit APIs
    @State private var position: MapCameraPosition
    @State private var selectedDate = Date()
    @State private var sunTimeSlider = 12.0 // Hours for 2-hour sun path visualization
    
    init(location: PhotoLocation) {
        self.location = location
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Map View with Spot and Parking pin
                Map(position: $position) {
                    Marker(location.title, systemImage: "camera.fill", coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                        .tint(.red)
                    
                    if location.hasParking, let pLat = location.parkingLatitude, let pLon = location.parkingLongitude {
                        Marker("Parkplatz", systemImage: "car.fill", coordinate: CLLocationCoordinate2D(latitude: pLat, longitude: pLon))
                            .tint(.blue)
                    }
                }
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                        withAnimation {
                            position = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .padding(10)
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Header Title
                    // Header Title & Categories
                    VStack(alignment: .leading, spacing: 8) {
                        Text(location.title)
                            .font(.title)
                            .bold()
                        
                        Text("Erstellt am \(location.creationDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if !location.categories.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(location.categories, id: \.self) { cat in
                                        Text(cat)
                                            .font(.caption)
                                            .bold()
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.accentColor.opacity(0.12))
                                            .foregroundStyle(Color.accentColor)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    
                    Divider()
                    
                    // Coordinates & Logistical Data
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("STANDORT")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.4f, %.4f", location.latitude, location.longitude))
                                .font(.body)
                        }
                        
                        if location.hasParking, let pLat = location.parkingLatitude, let pLon = location.parkingLongitude {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PARKPLATZ")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.4f, %.4f", pLat, pLon))
                                    .font(.body)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Associated Photos Carousel (1-to-N)
                    Text("Perspektiven & Brennweiten (\(location.photos.count))")
                        .font(.headline)
                    
                    if location.photos.isEmpty {
                        ContentUnavailableView("Keine Fotos hinterlegt", systemImage: "photo.on.rectangle", description: Text("Füge diesem Spot Fotos hinzu."))
                            .frame(height: 120)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(location.photos) { photo in
                                    VStack(alignment: .leading, spacing: 8) {
                                        if let data = photo.thumbnailData, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 140, height: 140)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.secondarySystemFill))
                                                .frame(width: 140, height: 140)
                                                .overlay {
                                                    Image(systemName: "photo")
                                                        .foregroundStyle(.secondary)
                                                }
                                        }
                                        
                                        // Lens & Focal Length Info
                                        if let focalLength = photo.focalLengthEquivalent {
                                            Text("\(focalLength) mm KB")
                                                .font(.caption)
                                                .bold()
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color(.systemFill))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Notes
                    if !location.descriptionNotes.isEmpty {
                        Text("Anmerkungen")
                            .font(.headline)
                        Text(location.descriptionNotes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Divider()
                    }
                    
                    // Required Gear Check-list (Dynamically only showing active ones)
                    if !location.requiredGear.isEmpty {
                        Text("Benötigte Ausrüstung")
                            .font(.headline)
                        
                        ForEach(location.requiredGear, id: \.self) { gear in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(gear)
                                    .font(.body)
                            }
                        }
                        Divider()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("Löschen", role: .destructive) {
                    modelContext.delete(location)
                    try? modelContext.save()
                    dismiss()
                }
                .foregroundStyle(.red)
            }
        }
    }
}
