///
/// `PlacesService.swift`
/// AllTrailsLunch
///
/// Service protocols for Places API operations.
/// Inspired by VIPER architecture from lesson_151_starter_project.
///

import Foundation
import CoreLocation

// MARK: - Remote Places Service Protocol

/// Protocol for remote Places API operations.
/// Allows easy mocking for unit tests.
protocol RemotePlacesService {
    /// Search for nearby restaurants
    func searchNearby(
        latitude: Double,
        longitude: Double,
        radius: Int,
        pageToken: String?
    ) async throws -> (results: [PlaceDTO], nextPageToken: String?)
    
    /// Search for restaurants by text query
    func searchText(
        query: String,
        latitude: Double?,
        longitude: Double?,
        pageToken: String?
    ) async throws -> (results: [PlaceDTO], nextPageToken: String?)
    
    /// Get detailed information about a place
    func getPlaceDetails(placeId: String) async throws -> PlaceDetailsDTO
}

// MARK: - Local Places Cache Protocol

/// Protocol for local caching of places.
/// Optional - can be nil if caching is not needed.
protocol LocalPlacesCache {
    /// Get cached places for a location
    func getCachedPlaces(
        location: CLLocationCoordinate2D,
        radius: Int
    ) throws -> [Place]?
    
    /// Cache places for a location
    func cachePlaces(
        _ places: [Place],
        location: CLLocationCoordinate2D,
        radius: Int
    ) throws
    
    /// Clear all cached data
    func clearCache()
}

// MARK: - Favorites Service Protocol

/// Protocol for favorites persistence.
/// Separates storage mechanism from business logic.
protocol FavoritesService {
    /// Get all favorite place IDs
    func getFavoriteIds() -> Set<String>
    
    /// Save favorite place IDs
    func saveFavoriteIds(_ ids: Set<String>) throws
    
    /// Check if a place is favorited
    func isFavorite(_ placeId: String) -> Bool
    
    /// Add a place to favorites
    func addFavorite(_ placeId: String) throws
    
    /// Remove a place from favorites
    func removeFavorite(_ placeId: String) throws
    
    /// Clear all favorites
    func clearAllFavorites() throws
}

