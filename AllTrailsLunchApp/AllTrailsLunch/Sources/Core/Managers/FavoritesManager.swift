//
//  FavoritesManager.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 02/11/25.
//

import Foundation
import Combine

/// Manager for favorites business logic.
/// Returns data via async/await - does NOT use @Observable.
/// ViewModels are responsible for managing observable state.
///
/// Combine Integration:
/// - Publishes favorite changes for reactive pipelines
/// - Thread-safe updates on MainActor
/// - Supports both async/await and Combine patterns
@MainActor
class FavoritesManager {
    private let service: FavoritesService

    // Internal cache for performance (not observable)
    private var favoriteIdsCache: Set<String> = []

    // MARK: - Combine Publishers

    /// Published favorite IDs for Combine pipelines
    @Published private(set) var favoriteIds: Set<String> = []

    /// Subject for favorite change events
    private let favoriteChangedSubject = PassthroughSubject<FavoriteChange, Never>()

    /// Publisher for favorite change events
    var favoriteChangedPublisher: AnyPublisher<FavoriteChange, Never> {
        favoriteChangedSubject.eraseToAnyPublisher()
    }

    init(service: FavoritesService) {
        self.service = service
        self.favoriteIdsCache = service.getFavoriteIds()
        self.favoriteIds = favoriteIdsCache
    }

    // MARK: - Public Methods

    /// Get all favorite IDs
    func getFavoriteIds() -> Set<String> {
        return favoriteIdsCache
    }

    /// Check if a place is favorited
    func isFavorite(_ placeId: String) -> Bool {
        return favoriteIdsCache.contains(placeId)
    }

    /// Toggle favorite status for a place
    /// Returns the new favorite status
    func toggleFavorite(_ placeId: String) async throws -> Bool {
        let isFavorited = favoriteIdsCache.contains(placeId)

        if isFavorited {
            favoriteIdsCache.remove(placeId)
            try service.removeFavorite(placeId)
            favoriteIds = favoriteIdsCache
            favoriteChangedSubject.send(.removed(placeId))
            return false
        } else {
            favoriteIdsCache.insert(placeId)
            try service.addFavorite(placeId)
            favoriteIds = favoriteIdsCache
            favoriteChangedSubject.send(.added(placeId))
            return true
        }
    }

    /// Toggle favorite status for a place with full place data (for SwiftData)
    /// Returns the new favorite status
    func toggleFavorite(_ place: Place) async throws -> Bool {
        let isFavorited = favoriteIdsCache.contains(place.id)

        if isFavorited {
            favoriteIdsCache.remove(place.id)
            try service.removeFavorite(place.id)
            favoriteIds = favoriteIdsCache
            favoriteChangedSubject.send(.removed(place.id))
            return false
        } else {
            favoriteIdsCache.insert(place.id)
            // Try to use SwiftData service's enhanced method if available
            if let swiftDataService = service as? SwiftDataFavoritesService {
                try swiftDataService.addFavorite(place)
            } else {
                try service.addFavorite(place.id)
            }
            favoriteIds = favoriteIdsCache
            favoriteChangedSubject.send(.added(place.id))
            return true
        }
    }

    /// Add a place to favorites
    func addFavorite(_ placeId: String) async throws {
        guard !favoriteIdsCache.contains(placeId) else { return }
        favoriteIdsCache.insert(placeId)
        try service.addFavorite(placeId)
        favoriteIds = favoriteIdsCache
        favoriteChangedSubject.send(.added(placeId))
    }

    /// Add a place to favorites with full place data (for SwiftData)
    func addFavorite(_ place: Place) async throws {
        guard !favoriteIdsCache.contains(place.id) else { return }
        favoriteIdsCache.insert(place.id)

        // Try to use SwiftData service's enhanced method if available
        if let swiftDataService = service as? SwiftDataFavoritesService {
            try swiftDataService.addFavorite(place)
        } else {
            try service.addFavorite(place.id)
        }
        favoriteIds = favoriteIdsCache
        favoriteChangedSubject.send(.added(place.id))
    }

    /// Remove a place from favorites
    func removeFavorite(_ placeId: String) async throws {
        guard favoriteIdsCache.contains(placeId) else { return }
        favoriteIdsCache.remove(placeId)
        try service.removeFavorite(placeId)
        favoriteIds = favoriteIdsCache
        favoriteChangedSubject.send(.removed(placeId))
    }

    /// Clear all favorites
    func clearAllFavorites() async throws {
        favoriteIdsCache.removeAll()
        try service.clearAllFavorites()
        favoriteIds = favoriteIdsCache
        favoriteChangedSubject.send(.cleared)
    }

    /// Apply favorite status to a list of places
    /// This is a helper method used by RestaurantManager
    func applyFavoriteStatus(to places: [Place]) -> [Place] {
        places.map { place in
            var updatedPlace = place
            updatedPlace.isFavorite = isFavorite(place.id)
            return updatedPlace
        }
    }
}

// MARK: - Supporting Types

/// Favorite change event for Combine pipelines
enum FavoriteChange {
    case added(String)
    case removed(String)
    case cleared
}

