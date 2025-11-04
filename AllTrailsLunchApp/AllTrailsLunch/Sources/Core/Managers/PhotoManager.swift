///
/// `PhotoManager.swift`
/// AllTrailsLunch
///
/// Manager for loading and caching restaurant photos from Google Places API.
///

import Foundation
import UIKit
import Observation

// MARK: - Photo Manager

/// High-level manager for photo operations with automatic caching.
/// Uses @Observable for SwiftUI integration.
@Observable
@MainActor
class PhotoManager {
    
    // MARK: - Properties
    
    private let loader: PhotoLoaderService
    private let cache: PhotoCacheService
    
    // Track loading states
    private var loadingTasks: [String: Task<UIImage?, Never>] = [:]
    
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
    /// - Returns: UIImage if successful, nil otherwise
    func loadPhoto(
        photoReference: String,
        maxWidth: Int = 400,
        maxHeight: Int = 400
    ) async -> UIImage? {
        let cacheKey = buildCacheKey(photoReference: photoReference, maxWidth: maxWidth, maxHeight: maxHeight)
        
        // Check if already loading
        if let existingTask = loadingTasks[cacheKey] {
            return await existingTask.value
        }
        
        // Create new loading task
        let task = Task<UIImage?, Never> {
            // Check cache first
            if let cachedImage = await cache.getCachedPhoto(for: cacheKey) {
                return cachedImage
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
                let image = try await loader.loadPhoto(from: url)
                
                // Cache the image
                await cache.cachePhoto(image, for: cacheKey)
                
                return image
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
    /// - Returns: UIImage if successful, nil otherwise
    func loadFirstPhoto(
        from photoReferences: [String],
        maxWidth: Int = 400,
        maxHeight: Int = 400
    ) async -> UIImage? {
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

