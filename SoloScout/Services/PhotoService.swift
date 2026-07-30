//
//  PhotoService.swift
//  SoloScout
//
//  Created by Felix on 30.07.2026.
//  Purpose: Handles PHPhotoLibrary access, thumbnail generation, and EXIF extraction.
//  Module: Services
//

import Foundation
import Photos
import UIKit
import Observation

@Observable
public final class PhotoService {
    public var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
    public init() {
        self.authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    public func requestAuthorization(completion: @escaping (PHAuthorizationStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
                completion(status)
            }
        }
    }
    
    /// Generates a small thumbnail from a PHAsset for database caching
    public func generateThumbnail(for asset: PHAsset, targetSize: CGSize = CGSize(width: 200, height: 200), completion: @escaping (Data?) -> Void) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
            guard let image = image else {
                completion(nil)
                return
            }
            let data = image.jpegData(compressionQuality: 0.7)
            completion(data)
        }
    }
    
    /// Parses EXIF metadata from a PHAsset
    public func extractMetadata(for asset: PHAsset, completion: @escaping (LocationPhotoMetadata) -> Void) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        
        manager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
            guard let data = data,
                  let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
                // Fallback to basic PHAsset details if full data load fails
                let fallback = LocationPhotoMetadata(
                    latitude: asset.location?.coordinate.latitude,
                    longitude: asset.location?.coordinate.longitude,
                    captureDate: asset.creationDate ?? Date(),
                    lensModel: nil,
                    focalLengthEquivalent: nil,
                    aperture: nil
                )
                completion(fallback)
                return
            }
            
            let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
            let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
            
            let lensModel = exif?[kCGImagePropertyExifLensModel] as? String
            let focalLength = exif?[kCGImagePropertyExifFocalLength] as? Double
            let aperture = exif?[kCGImagePropertyExifFNumber] as? Double
            
            // Map focal length to Full Frame Equivalent
            var focalLengthEquivalent: Int? = nil
            if let focalLength = focalLength {
                if let exifFocal35 = exif?[kCGImagePropertyExifFocalLenIn35mmFilm] as? Int {
                    focalLengthEquivalent = exifFocal35
                } else {
                    // Fallback heuristics based on focal length values
                    focalLengthEquivalent = self.calculateFocalLengthEquivalent(focalLength: focalLength, lensModel: lensModel)
                }
            }
            
            let metadata = LocationPhotoMetadata(
                latitude: asset.location?.coordinate.latitude,
                longitude: asset.location?.coordinate.longitude,
                captureDate: asset.creationDate ?? Date(),
                lensModel: lensModel ?? tiff?[kCGImagePropertyTIFFModel] as? String,
                focalLengthEquivalent: focalLengthEquivalent,
                aperture: aperture
            )
            completion(metadata)
        }
    }
    
    func calculateFocalLengthEquivalent(focalLength: Double, lensModel: String?) -> Int {
        if focalLength < 2.0 {
            return 13 // Ultra-wide
        } else if focalLength < 6.0 {
            return 24 // Standard Wide
        } else if focalLength < 10.0 {
            return 77 // 3x telephoto
        } else {
            return 120 // 5x telephoto
        }
    }
}

public struct LocationPhotoMetadata {
    public let latitude: Double?
    public let longitude: Double?
    public let captureDate: Date
    public let lensModel: String?
    public let focalLengthEquivalent: Int?
    public let aperture: Double?
}
