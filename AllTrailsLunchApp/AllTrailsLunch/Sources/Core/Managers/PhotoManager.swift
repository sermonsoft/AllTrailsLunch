//
//  PhotoManager.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 02/11/25.
//

import Foundation
import Observation

// MARK: - Photo Manager

/// High-level manager for photo operations with automatic caching.
/// Uses @Observable for SwiftUI integration.
/// Works with Data instead of UIImage for platform independence.
@Observable
@MainActor
class PhotoManager {

    // MARK: - Properties

    private let loader: PhotoLoaderService
    private let cache: PhotoCacheService

    // Track loading states
    private var loadingTasks: [String: Task<Data?, Never>] = [:]
    
    // MARK: - Initialization
    
    init(loader: PhotoLoaderService, cache: PhotoCacheService) {
        self.loader = loader
        self.cache = cache
    }
    
    // MARK: - Public API

    /// Load photo with automatic caching
    /// - Parameters:
    ///   - photoReference: Google Places photo reference
    ///   - maxWidth: Maximum width for the photo
    ///   - maxHeight: Maximum height for the photo
    /// - Returns: Image data if successful, nil otherwise
    func loadPhoto(
        photoReference: String,
        maxWidth: Int = 400,
        maxHeight: Int = 400
    ) async -> Data? {
        let cacheKey = buildCacheKey(photoReference: photoReference, maxWidth: maxWidth, maxHeight: maxHeight)

        // Check if already loading
        if let existingTask = loadingTasks[cacheKey] {
            return await existingTask.value
        }

        // Create new loading task
        let task = Task<Data?, Never> {
            // Check cache first
            if let cachedData = await cache.getCachedPhoto(for: cacheKey) {
                return cachedData
            }

            // Load from network
            guard let url = loader.buildPhotoURL(
                photoReference: photoReference,
                maxWidth: maxWidth,
                maxHeight: maxHeight
            ) else {
                return nil
            }

            do {
                let data = try await loader.loadPhoto(from: url)

                // Cache the data
                await cache.cachePhoto(data, for: cacheKey)

                return data
            } catch {
                print("❌ PhotoManager: Failed to load photo - \(error.localizedDescription)")
                return nil
            }
        }

        loadingTasks[cacheKey] = task

        let result = await task.value

        // Clean up task
        loadingTasks.removeValue(forKey: cacheKey)

        return result
    }
    
    /// Load first photo from a list of photo references
    /// - Parameters:
    ///   - photoReferences: Array of Google Places photo references
    ///   - maxWidth: Maximum width for the photo
    ///   - maxHeight: Maximum height for the photo
    /// - Returns: Image data if successful, nil otherwise
    func loadFirstPhoto(
        from photoReferences: [String],
        maxWidth: Int = 400,
        maxHeight: Int = 400
    ) async -> Data? {
        guard let firstReference = photoReferences.first else {
            return nil
        }

        return await loadPhoto(
            photoReference: firstReference,
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )
    }
    
    /// Preload photos for a list of photo references (background loading)
    /// - Parameters:
    ///   - photoReferences: Array of Google Places photo references
    ///   - maxWidth: Maximum width for the photo
    ///   - maxHeight: Maximum height for the photo
    func preloadPhotos(
        _ photoReferences: [String],
        maxWidth: Int = 400,
        maxHeight: Int = 400
    ) {
        Task {
            for reference in photoReferences {
                _ = await loadPhoto(
                    photoReference: reference,
                    maxWidth: maxWidth,
                    maxHeight: maxHeight
                )
            }
        }
    }
    
    /// Clear all cached photos
    func clearCache() async {
        await cache.clearCache()
    }
    
    /// Get cache statistics
    func getCacheStats() async -> PhotoCacheStats {
        await cache.getCacheStats()
    }
    
    // MARK: - Helper Methods
    
    private func buildCacheKey(photoReference: String, maxWidth: Int, maxHeight: Int) -> String {
        "\(photoReference)_\(maxWidth)x\(maxHeight)"
    }
}

