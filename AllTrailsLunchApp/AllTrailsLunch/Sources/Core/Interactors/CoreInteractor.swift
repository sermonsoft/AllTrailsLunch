///
/// `CoreInteractor.swift`
/// AllTrailsLunch
///
/// Core implementation of all Interactor protocols.
/// This class combines business logic from multiple managers and services.
///

import Foundation
import CoreLocation

/// Core implementation of all Interactor protocols
/// This is the production implementation that ViewModels will use
@MainActor
class CoreInteractor: DiscoveryInteractor, DetailInteractor {
    // MARK: - Dependencies
    
    private let restaurantManager: RestaurantManager
    private let favoritesManager: FavoritesManager
    private let locationManager: LocationManager
    
    // MARK: - Initialization
    
    init(
        restaurantManager: RestaurantManager,
        favoritesManager: FavoritesManager,
        locationManager: LocationManager
    ) {
        self.restaurantManager = restaurantManager
        self.favoritesManager = favoritesManager
        self.locationManager = locationManager
    }
    
    // MARK: - DiscoveryInteractor Implementation
    
    func requestLocationPermission() async throws -> CLLocationCoordinate2D {
        return try await locationManager.requestLocationPermission()
    }
    
    func searchNearby(
        location: CLLocationCoordinate2D,
        radius: Int = 1500,
        pageToken: String? = nil
    ) async throws -> (places: [Place], nextPageToken: String?) {
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
    ) async throws -> (places: [Place], nextPageToken: String?) {
        return try await restaurantManager.searchText(
            query: query,
            location: location,
            pageToken: pageToken
        )
    }
    
    func isFavorite(_ placeId: String) -> Bool {
        return favoritesManager.isFavorite(placeId)
    }
    
    func toggleFavorite(_ placeId: String) {
        favoritesManager.toggleFavorite(placeId)
    }
    
    func addFavorite(_ placeId: String) {
        favoritesManager.addFavorite(placeId)
    }
    
    func removeFavorite(_ placeId: String) {
        favoritesManager.removeFavorite(placeId)
    }
    
    func getFavoriteIds() -> Set<String> {
        return favoritesManager.favoriteIds
    }
    
    // MARK: - DetailInteractor Implementation
    
    func getPlaceDetails(placeId: String) async throws -> PlaceDetail {
        return try await restaurantManager.getPlaceDetails(placeId: placeId)
    }
    
    // Note: Favorites methods are shared between DiscoveryInteractor and DetailInteractor
    // They're already implemented above
}

