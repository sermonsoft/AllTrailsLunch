///
/// `FavoritesManager.swift`
/// AllTrailsLunch
///
/// High-level manager for favorites operations.
/// Uses @Observable macro for modern SwiftUI state management.
/// Inspired by VIPER architecture from lesson_151_starter_project.
///

import Foundation

/// Manager for favorites with observable state.
/// Uses the new @Observable macro instead of @Published for better performance.
@MainActor
@Observable
class FavoritesManager {
    private let service: FavoritesService
    
    // Observable state - automatically triggers UI updates
    private(set) var favoriteIds: Set<String> = []
    
    init(service: FavoritesService) {
        self.service = service
        self.favoriteIds = service.getFavoriteIds()
    }
    
    // MARK: - Public Methods
    
    /// Check if a place is favorited
    func isFavorite(_ placeId: String) -> Bool {
        favoriteIds.contains(placeId)
    }
    
    /// Toggle favorite status for a place
    func toggleFavorite(_ placeId: String) {
        if favoriteIds.contains(placeId) {
            favoriteIds.remove(placeId)
            try? service.removeFavorite(placeId)
        } else {
            favoriteIds.insert(placeId)
            try? service.addFavorite(placeId)
        }
    }
    
    /// Add a place to favorites
    func addFavorite(_ placeId: String) {
        guard !favoriteIds.contains(placeId) else { return }
        favoriteIds.insert(placeId)
        try? service.addFavorite(placeId)
    }
    
    /// Remove a place from favorites
    func removeFavorite(_ placeId: String) {
        guard favoriteIds.contains(placeId) else { return }
        favoriteIds.remove(placeId)
        try? service.removeFavorite(placeId)
    }
    
    /// Clear all favorites
    func clearAllFavorites() {
        favoriteIds.removeAll()
        try? service.clearAllFavorites()
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

