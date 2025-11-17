//
//  PhotoService.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 02/11/25.
//

import Foundation

// MARK: - Photo Cache Service Protocol

/// Protocol for caching photos in memory and on disk.
/// Allows easy mocking for unit tests.
protocol PhotoCacheService {
    /// Get cached photo data from memory or disk
    func getCachedPhoto(for key: String) async -> Data?

    /// Cache photo data in memory and disk
    func cachePhoto(_ data: Data, for key: String) async

    /// Remove photo from cache
    func removePhoto(for key: String) async

    /// Clear all cached photos
    func clearCache() async

    /// Get cache statistics
    func getCacheStats() async -> PhotoCacheStats
}

// MARK: - Photo Cache Stats

struct PhotoCacheStats {
    let memoryCount: Int
    let diskCount: Int
    let totalMemorySize: Int // in bytes
    let totalDiskSize: Int // in bytes
    
    var memorySizeMB: Double {
        Double(totalMemorySize) / 1_048_576.0
    }
    
    var diskSizeMB: Double {
        Double(totalDiskSize) / 1_048_576.0
    }
}

// MARK: - Photo Loader Service Protocol

/// Protocol for loading photos from Google Places API.
protocol PhotoLoaderService {
    /// Build photo URL from photo reference
    func buildPhotoURL(photoReference: String, maxWidth: Int, maxHeight: Int) -> URL?

    /// Load photo data from URL
    func loadPhoto(from url: URL) async throws -> Data
}

// MARK: - NSCache-based Photo Cache Implementation

actor NSCachePhotoCache: PhotoCacheService {
    private let memoryCache = NSCache<NSString, NSData>()
    private let diskCache: DiskPhotoCache
    private let maxMemoryCount = 100
    private let maxMemoryCost = 50 * 1024 * 1024 // 50 MB

    init(diskCache: DiskPhotoCache = DiskPhotoCache()) {
        self.diskCache = diskCache

        // Configure memory cache
        memoryCache.countLimit = maxMemoryCount
        memoryCache.totalCostLimit = maxMemoryCost
    }

    func getCachedPhoto(for key: String) async -> Data? {
        // Check memory cache first
        if let data = memoryCache.object(forKey: key as NSString) {
            return data as Data
        }

        // Check disk cache
        if let data = await diskCache.getPhoto(for: key) {
            // Promote to memory cache
            let cost = data.count
            memoryCache.setObject(data as NSData, forKey: key as NSString, cost: cost)
            return data
        }

        return nil
    }

    func cachePhoto(_ data: Data, for key: String) async {
        // Cache in memory
        let cost = data.count
        memoryCache.setObject(data as NSData, forKey: key as NSString, cost: cost)

        // Cache on disk
        await diskCache.savePhoto(data, for: key)
    }

    func removePhoto(for key: String) async {
        memoryCache.removeObject(forKey: key as NSString)
        await diskCache.removePhoto(for: key)
    }

    func clearCache() async {
        memoryCache.removeAllObjects()
        await diskCache.clearCache()
    }

    func getCacheStats() async -> PhotoCacheStats {
        let diskStats = await diskCache.getStats()

        // Estimate memory cache size (approximate)
        let memoryCount = memoryCache.countLimit
        let memorySize = memoryCache.totalCostLimit

        return PhotoCacheStats(
            memoryCount: memoryCount,
            diskCount: diskStats.count,
            totalMemorySize: memorySize,
            totalDiskSize: diskStats.totalSize
        )
    }
}

// MARK: - Disk Photo Cache

actor DiskPhotoCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxDiskSize = 100 * 1024 * 1024 // 100 MB

    init() {
        // Use caches directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cachesDirectory.appendingPathComponent("PhotoCache", isDirectory: true)

        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func getPhoto(for key: String) async -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)

        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        // Update access time
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileURL.path)

        return data
    }

    func savePhoto(_ data: Data, for key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        try? data.write(to: fileURL)

        // Check cache size and evict if needed
        await evictOldFilesIfNeeded()
    }
    
    func removePhoto(for key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        try? fileManager.removeItem(at: fileURL)
    }
    
    func clearCache() async {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }
    
    func getStats() async -> (count: Int, totalSize: Int) {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return (0, 0)
        }
        
        var totalSize = 0
        for file in files {
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let fileSize = attributes[.size] as? Int {
                totalSize += fileSize
            }
        }
        
        return (files.count, totalSize)
    }
    
    // MARK: - Cache Eviction
    
    private func evictOldFilesIfNeeded() async {
        let stats = await getStats()
        
        guard stats.totalSize > maxDiskSize else { return }
        
        // Get all files with modification dates
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else {
            return
        }
        
        // Sort by modification date (oldest first)
        let sortedFiles = files.sorted { file1, file2 in
            let date1 = (try? file1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            let date2 = (try? file2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            return date1 < date2
        }
        
        // Remove oldest files until under limit
        var currentSize = stats.totalSize
        for file in sortedFiles {
            guard currentSize > maxDiskSize else { break }
            
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let fileSize = attributes[.size] as? Int {
                try? fileManager.removeItem(at: file)
                currentSize -= fileSize
            }
        }
    }
}

// MARK: - Google Places Photo Loader

class GooglePlacesPhotoLoader: PhotoLoaderService {
    private let apiKey: String
    private let session: URLSession
    private static let baseURL = "https://maps.googleapis.com/maps/api/place/photo"

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func buildPhotoURL(photoReference: String, maxWidth: Int = 400, maxHeight: Int = 400) -> URL? {
        var components = URLComponents(string: Self.baseURL)
        components?.queryItems = [
            URLQueryItem(name: "photoreference", value: photoReference),
            URLQueryItem(name: "maxwidth", value: "\(maxWidth)"),
            URLQueryItem(name: "maxheight", value: "\(maxHeight)"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        return components?.url
    }

    func loadPhoto(from url: URL) async throws -> Data {
        // Use simulated network in development builds
        #if DEV
        let (data, response) = try await session.simulatedData(from: url)
        #else
        let (data, response) = try await session.data(from: url)
        #endif

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PhotoError.invalidResponse
        }

        // Return raw data - validation will happen at display time
        return data
    }
}

// MARK: - Photo Error

enum PhotoError: Error, LocalizedError {
    case invalidResponse
    case invalidImageData
    case cacheError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from photo service"
        case .invalidImageData:
            return "Unable to decode image data"
        case .cacheError:
            return "Photo cache error"
        }
    }
}

// MARK: - String MD5 Extension

extension String {
    var md5Hash: String {
        // Simple hash for cache keys (use CryptoKit in production)
        let hash = self.utf8.reduce(0) { ($0 &+ UInt64($1)) &* 31 }
        return String(format: "%016llx", hash)
    }
}

