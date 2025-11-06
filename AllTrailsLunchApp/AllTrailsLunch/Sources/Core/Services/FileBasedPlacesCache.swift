//
//  FileBasedPlacesCache.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 01/11/25.
//

import Foundation
import CoreLocation

// MARK: - Cache Entry

/// Represents a cached search result with metadata
struct CachedPlacesEntry: Codable {
    let places: [CachedPlace]
    let location: CachedLocation
    let radius: Int
    let timestamp: Date
    let expirationDate: Date
    
    var isExpired: Bool {
        Date() > expirationDate
    }
}

/// Codable version of Place for caching
struct CachedPlace: Codable {
    let id: String
    let name: String
    let rating: Double?
    let userRatingsTotal: Int?
    let priceLevel: Int?
    let latitude: Double
    let longitude: Double
    let address: String?
    let photoReferences: [String]
    let isFavorite: Bool
    
    init(from place: Place) {
        self.id = place.id
        self.name = place.name
        self.rating = place.rating
        self.userRatingsTotal = place.userRatingsTotal
        self.priceLevel = place.priceLevel
        self.latitude = place.latitude
        self.longitude = place.longitude
        self.address = place.address
        self.photoReferences = place.photoReferences
        self.isFavorite = place.isFavorite
    }
    
    func toPlace() -> Place {
        Place(
            id: id,
            name: name,
            rating: rating,
            userRatingsTotal: userRatingsTotal,
            priceLevel: priceLevel,
            latitude: latitude,
            longitude: longitude,
            address: address,
            photoReferences: photoReferences,
            isFavorite: isFavorite
        )
    }
}

/// Codable version of CLLocationCoordinate2D
struct CachedLocation: Codable {
    let latitude: Double
    let longitude: Double
    
    init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    func toCoordinate() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - File-Based Places Cache

/// File-based implementation of LocalPlacesCache.
/// Stores search results in the caches directory with expiration.
class FileBasedPlacesCache: LocalPlacesCache {
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let cacheExpiration: TimeInterval
    private let maxCacheSize: Int
    
    // MARK: - Constants
    
    private static let defaultExpiration: TimeInterval = 24 * 60 * 60 // 24 hours
    private static let maxCacheEntries = 50
    
    // MARK: - Initialization
    
    init(
        cacheExpiration: TimeInterval = defaultExpiration,
        maxCacheSize: Int = maxCacheEntries
    ) {
        // Use caches directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cachesDirectory.appendingPathComponent("PlacesCache", isDirectory: true)
        self.cacheExpiration = cacheExpiration
        self.maxCacheSize = maxCacheSize
        
        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Clean up expired entries on init
        cleanupExpiredEntries()
    }
    
    // MARK: - LocalPlacesCache Protocol
    
    func getCachedPlaces(
        location: CLLocationCoordinate2D,
        radius: Int
    ) throws -> [Place]? {
        let cacheKey = buildCacheKey(location: location, radius: radius)
        let fileURL = cacheDirectory.appendingPathComponent(cacheKey)
        
        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        // Load and decode
        let data = try Data(contentsOf: fileURL)
        let entry = try JSONDecoder().decode(CachedPlacesEntry.self, from: data)
        
        // Check if expired
        if entry.isExpired {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
        
        // Update access time
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileURL.path)
        
        print("✅ PlacesCache: Loaded \(entry.places.count) places from cache")
        return entry.places.map { $0.toPlace() }
    }
    
    func cachePlaces(
        _ places: [Place],
        location: CLLocationCoordinate2D,
        radius: Int
    ) throws {
        let cacheKey = buildCacheKey(location: location, radius: radius)
        let fileURL = cacheDirectory.appendingPathComponent(cacheKey)
        
        // Create cache entry
        let entry = CachedPlacesEntry(
            places: places.map { CachedPlace(from: $0) },
            location: CachedLocation(from: location),
            radius: radius,
            timestamp: Date(),
            expirationDate: Date().addingTimeInterval(cacheExpiration)
        )
        
        // Encode and save
        let data = try JSONEncoder().encode(entry)
        try data.write(to: fileURL)
        
        print("✅ PlacesCache: Cached \(places.count) places")
        
        // Cleanup old entries if needed
        evictOldEntriesIfNeeded()
    }
    
    func clearCache() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try? fileManager.removeItem(at: file)
            }
            print("✅ PlacesCache: Cleared all cache")
        } catch {
            print("❌ PlacesCache: Failed to clear cache - \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func buildCacheKey(location: CLLocationCoordinate2D, radius: Int) -> String {
        // Round coordinates to 4 decimal places (~11m precision)
        let lat = String(format: "%.4f", location.latitude)
        let lng = String(format: "%.4f", location.longitude)
        return "nearby_\(lat)_\(lng)_\(radius).json"
    }
    
    private func cleanupExpiredEntries() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            for file in files {
                guard let data = try? Data(contentsOf: file),
                      let entry = try? JSONDecoder().decode(CachedPlacesEntry.self, from: data) else {
                    continue
                }
                
                if entry.isExpired {
                    try? fileManager.removeItem(at: file)
                    print("🗑️ PlacesCache: Removed expired entry")
                }
            }
        } catch {
            print("❌ PlacesCache: Failed to cleanup expired entries - \(error.localizedDescription)")
        }
    }
    
    private func evictOldEntriesIfNeeded() {
        do {
            let files = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey]
            )
            
            guard files.count > maxCacheSize else { return }
            
            // Sort by modification date (oldest first)
            let sortedFiles = files.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                return date1 < date2
            }
            
            // Remove oldest entries
            let filesToRemove = sortedFiles.prefix(files.count - maxCacheSize)
            for file in filesToRemove {
                try? fileManager.removeItem(at: file)
                print("🗑️ PlacesCache: Evicted old entry")
            }
        } catch {
            print("❌ PlacesCache: Failed to evict old entries - \(error.localizedDescription)")
        }
    }
}

