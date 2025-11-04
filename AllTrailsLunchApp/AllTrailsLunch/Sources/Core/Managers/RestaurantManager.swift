///
/// `RestaurantManager.swift`
/// AllTrailsLunch
///
/// High-level manager for restaurant operations.
/// Combines remote service, caching, and favorites.
/// Inspired by VIPER architecture from lesson_151_starter_project.
///

import Foundation
import CoreLocation

/// Manager for restaurant data operations.
/// This is the high-level API that combines multiple services.
@MainActor
@Observable
class RestaurantManager {
    private let remote: RemotePlacesService
    private let cache: LocalPlacesCache?
    private let favorites: FavoritesManager
    
    init(
        remote: RemotePlacesService,
        cache: LocalPlacesCache? = nil,
        favorites: FavoritesManager
    ) {
        self.remote = remote
        self.cache = cache
        self.favorites = favorites
    }
    
    // MARK: - Search Operations
    
    /// Search for nearby restaurants
    func searchNearby(
        location: CLLocationCoordinate2D,
        radius: Int = 1500,
        pageToken: String? = nil
    ) async throws -> (places: [Place], nextPageToken: String?) {
        // Check cache first (if available)
        if pageToken == nil, // Only use cache for first page
           let cached = try? cache?.getCachedPlaces(location: location, radius: radius) {
            return (cached, nil)
        }
        
        // Fetch from remote
        let (dtos, nextToken) = try await remote.searchNearby(
            latitude: location.latitude,
            longitude: location.longitude,
            radius: radius,
            pageToken: pageToken
        )
        
        // Convert DTOs to domain models
        let places = dtos.map { Place(from: $0) }
        
        // Apply favorite status
        let placesWithFavorites = favorites.applyFavoriteStatus(to: places)
        
        // Cache results (first page only)
        if pageToken == nil {
            try? cache?.cachePlaces(placesWithFavorites, location: location, radius: radius)
        }
        
        return (placesWithFavorites, nextToken)
    }
    
    /// Search for restaurants by text query
    func searchText(
        query: String,
        location: CLLocationCoordinate2D? = nil,
        pageToken: String? = nil
    ) async throws -> (places: [Place], nextPageToken: String?) {
        let (dtos, nextToken) = try await remote.searchText(
            query: query,
            latitude: location?.latitude,
            longitude: location?.longitude,
            pageToken: pageToken
        )
        
        // Convert DTOs to domain models
        let places = dtos.map { Place(from: $0) }
        
        // Apply favorite status
        let placesWithFavorites = favorites.applyFavoriteStatus(to: places)
        
        return (placesWithFavorites, nextToken)
    }
    
    /// Get detailed information about a place
    func getPlaceDetails(placeId: String) async throws -> PlaceDetail {
        let dto = try await remote.getPlaceDetails(placeId: placeId)
        
        // Create a Place from the details
        let place = Place(
            id: placeId,
            name: dto.name,
            rating: dto.rating,
            userRatingsTotal: nil,
            priceLevel: nil,
            latitude: 0,
            longitude: 0,
            address: dto.formattedAddress,
            photoReferences: [],
            isFavorite: favorites.isFavorite(placeId)
        )
        
        return PlaceDetail(place: place, from: dto)
    }
    
    // MARK: - Cache Management
    
    /// Clear all cached data
    func clearCache() {
        cache?.clearCache()
    }
}

