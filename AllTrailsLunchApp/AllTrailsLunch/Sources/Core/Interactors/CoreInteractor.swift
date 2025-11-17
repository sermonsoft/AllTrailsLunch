//
//  CoreInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation
import CoreLocation

/// Core implementation of all Interactor protocols
/// This is the production implementation that ViewModels will use
/// ViewModels should ONLY call methods on this interactor, never access managers directly
@MainActor
class CoreInteractor: DiscoveryInteractor, DetailInteractor {
    // MARK: - Dependencies

    // NOTE: container is internal for testing purposes only
    // ViewModels should NEVER access this directly - use protocol methods instead
    let container: DependencyContainer

    // Convenience accessors - all managers are resolved from container
    var favoritesManager: FavoritesManager {
        container.favoritesManager
    }

    private var restaurantManager: RestaurantManager {
        container.restaurantManager
    }

    private var locationManager: LocationManager {
        container.locationManager
    }

    private var networkMonitor: NetworkMonitor {
        container.networkMonitor
    }

    private var filterPreferencesManager: FilterPreferencesManager {
        container.filterPreferencesManager
    }

    private var savedSearchManager: SavedSearchManager {
        container.savedSearchManager
    }

    // MARK: - Initialization

    init(container: DependencyContainer) {
        self.container = container
    }
    
    // MARK: - DiscoveryInteractor Implementation
    
    func requestLocationPermission() async throws -> CLLocationCoordinate2D {
        return try await locationManager.requestLocationPermission()
    }
    
    func searchNearby(
        location: CLLocationCoordinate2D,
        radius: Int = 1500,
        pageToken: String? = nil
    ) async throws -> (places: [Place], nextPageToken: String?, isFromCache: Bool) {
        return try await restaurantManager.searchNearby(
            location: location,
            radius: radius,
            pageToken: pageToken
        )
    }

    func searchText(
        query: String,
        location: CLLocationCoordinate2D? = nil,
        pageToken: String? = nil
    ) async throws -> (places: [Place], nextPageToken: String?, isFromCache: Bool) {
        return try await restaurantManager.searchText(
            query: query,
            location: location,
            pageToken: pageToken
        )
    }
    
    func isFavorite(_ placeId: String) -> Bool {
        return favoritesManager.isFavorite(placeId)
    }

    func toggleFavorite(_ placeId: String) async throws {
        _ = try await favoritesManager.toggleFavorite(placeId)
    }

    func toggleFavorite(_ place: Place) async throws -> Bool {
        return try await favoritesManager.toggleFavorite(place)
    }

    func addFavorite(_ placeId: String) async throws {
        try await favoritesManager.addFavorite(placeId)
    }

    func addFavorite(_ place: Place) async throws {
        try await favoritesManager.addFavorite(place)
    }

    func removeFavorite(_ placeId: String) async throws {
        try await favoritesManager.removeFavorite(placeId)
    }

    func getFavoriteIds() -> Set<String> {
        return favoritesManager.getFavoriteIds()
    }

    // MARK: - Network Monitoring

    func getNetworkMonitor() -> NetworkMonitor {
        return networkMonitor
    }

    // MARK: - Event Logging

    func getEventLogger() -> EventLogger {
        return container.eventLogger
    }

    // MARK: - Filter Preferences

    func getFilterPreferencesManager() -> FilterPreferencesManager {
        return filterPreferencesManager
    }

    // MARK: - Saved Searches

    func getSavedSearchManager() -> SavedSearchManager {
        return savedSearchManager
    }

    // MARK: - Photo Loading

    nonisolated func loadPhoto(
        photoReference: String,
        maxWidth: Int,
        maxHeight: Int
    ) async -> Data? {
        return await container.photoManager.loadPhoto(
            photoReference: photoReference,
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )
    }

    nonisolated func loadFirstPhoto(
        from photoReferences: [String],
        maxWidth: Int,
        maxHeight: Int
    ) async -> Data? {
        return await container.photoManager.loadFirstPhoto(
            from: photoReferences,
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )
    }

    // MARK: - DetailInteractor Implementation
    
    func getPlaceDetails(placeId: String) async throws -> PlaceDetail {
        return try await restaurantManager.getPlaceDetails(placeId: placeId)
    }
    
    // Note: Favorites methods are shared between DiscoveryInteractor and DetailInteractor
    // They're already implemented above
}

