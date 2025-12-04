//
//  SwiftDataFavoritesService.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 01/11/25.
//

import Foundation
import SwiftData

// MARK: - SwiftData Favorites Service

/// SwiftData-based implementation of FavoritesService.
/// Stores favorite places with full metadata for better querying and offline access.
///
/// This service is @MainActor isolated because ModelContext requires main actor access.
/// This is safe because FavoritesManager (the caller) is also @MainActor.
@MainActor
class SwiftDataFavoritesService: FavoritesService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - FavoritesService Protocol

    // Note: These methods are marked nonisolated to satisfy the protocol requirement.
    // They use MainActor.assumeIsolated to safely access ModelContext which requires MainActor.
    // This is safe because:
    // 1. The class is @MainActor, so the modelContext is always on MainActor
    // 2. FavoritesManager (the caller) is also @MainActor
    // 3. MainActor.assumeIsolated provides compile-time verification

    nonisolated func getFavoriteIds() -> Set<String> {
        MainActor.assumeIsolated {
            let descriptor = FetchDescriptor<FavoritePlace>()
            guard let favorites = try? modelContext.fetch(descriptor) else {
                return []
            }
            return Set(favorites.map { $0.placeId })
        }
    }

    nonisolated func saveFavoriteIds(_ ids: Set<String>) throws {
        try MainActor.assumeIsolated {
            // This method is not ideal for SwiftData since we want to store full Place objects
            // For compatibility, we'll keep existing favorites and remove ones not in the set
            let descriptor = FetchDescriptor<FavoritePlace>()
            let existingFavorites = try modelContext.fetch(descriptor)

            // Remove favorites not in the new set
            for favorite in existingFavorites {
                if !ids.contains(favorite.placeId) {
                    modelContext.delete(favorite)
                }
            }

            try modelContext.save()
        }
    }

    nonisolated func isFavorite(_ placeId: String) -> Bool {
        MainActor.assumeIsolated {
            let predicate = #Predicate<FavoritePlace> { favorite in
                favorite.placeId == placeId
            }
            let descriptor = FetchDescriptor<FavoritePlace>(predicate: predicate)

            guard let count = try? modelContext.fetchCount(descriptor) else {
                return false
            }
            return count > 0
        }
    }

    nonisolated func addFavorite(_ placeId: String) throws {
        try MainActor.assumeIsolated {
            // Check if already exists
            guard !isFavorite(placeId) else { return }

            // Create a minimal favorite (we'll enhance this later to accept full Place objects)
            let favorite = FavoritePlace(
                placeId: placeId,
                name: "Unknown", // Placeholder - should be updated with full place data
                latitude: 0,
                longitude: 0
            )

            modelContext.insert(favorite)
            try modelContext.save()
        }
    }

    nonisolated func removeFavorite(_ placeId: String) throws {
        try MainActor.assumeIsolated {
            let predicate = #Predicate<FavoritePlace> { favorite in
                favorite.placeId == placeId
            }
            let descriptor = FetchDescriptor<FavoritePlace>(predicate: predicate)

            guard let favorites = try? modelContext.fetch(descriptor) else {
                return
            }

            for favorite in favorites {
                modelContext.delete(favorite)
            }

            try modelContext.save()
        }
    }

    nonisolated func clearAllFavorites() throws {
        try MainActor.assumeIsolated {
            let descriptor = FetchDescriptor<FavoritePlace>()
            let favorites = try modelContext.fetch(descriptor)

            for favorite in favorites {
                modelContext.delete(favorite)
            }

            try modelContext.save()
        }
    }

    // MARK: - Enhanced Methods (SwiftData-specific)

    /// Add a favorite with full place data
    func addFavorite(_ place: Place) throws {
        // Check if already exists
        if isFavorite(place.id) {
            // Update existing favorite
            try updateFavorite(place)
            return
        }

        let favorite = FavoritePlace(from: place)
        modelContext.insert(favorite)
        try modelContext.save()
    }

    /// Update an existing favorite with new data
    func updateFavorite(_ place: Place) throws {
        let placeId = place.id // Capture in local variable for predicate
        let predicate = #Predicate<FavoritePlace> { favorite in
            favorite.placeId == placeId
        }
        let descriptor = FetchDescriptor<FavoritePlace>(predicate: predicate)

        guard let favorites = try? modelContext.fetch(descriptor),
              let favorite = favorites.first else {
            return
        }

        // Update properties
        favorite.name = place.name
        favorite.address = place.address
        favorite.rating = place.rating
        favorite.priceLevel = place.priceLevel
        favorite.latitude = place.latitude
        favorite.longitude = place.longitude
        favorite.photoReferences = place.photoReferences

        try modelContext.save()
    }

    /// Get all favorite places with full data
    func getAllFavorites() throws -> [FavoritePlace] {
        let descriptor = FetchDescriptor<FavoritePlace>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get favorites sorted by rating
    func getFavoritesSortedByRating() throws -> [FavoritePlace] {
        let descriptor = FetchDescriptor<FavoritePlace>(
            sortBy: [SortDescriptor(\.rating, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get favorites within a distance from a location
    func getFavoritesNear(latitude: Double, longitude: Double, radiusInMeters: Double) throws -> [FavoritePlace] {
        let allFavorites = try getAllFavorites()

        return allFavorites.filter { favorite in
            let distance = calculateDistance(
                lat1: latitude,
                lon1: longitude,
                lat2: favorite.latitude,
                lon2: favorite.longitude
            )
            return distance <= radiusInMeters
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate distance between two coordinates using Haversine formula
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius = 6371000.0 // meters
        
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon / 2) * sin(dLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
}

