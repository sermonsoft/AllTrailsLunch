///
/// `RestaurantRepository.swift`
/// AllTrailsLunch
///
/// Repository for restaurant data operations.
/// DEPRECATED: Use RestaurantManager directly for new code.
/// This class is kept for backward compatibility during migration.
///

import Foundation
import CoreLocation

class RestaurantRepository {
    private let manager: RestaurantManager

    @MainActor
    init(placesClient: PlacesClient, favoritesStore: FavoritesStore) {
        // Create manager with services
        let remote = GooglePlacesService(client: placesClient)
        let favoritesService = UserDefaultsFavoritesService()
        let favoritesManager = FavoritesManager(service: favoritesService)

        self.manager = RestaurantManager(
            remote: remote,
            cache: nil,
            favorites: favoritesManager
        )
    }
    
    // MARK: - Search Operations

    func searchNearby(
        latitude: Double,
        longitude: Double,
        radius: Int = 1500,
        pageToken: String? = nil
    ) async throws -> (places: [Place], nextPageToken: String?) {
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return try await manager.searchNearby(
            location: location,
            radius: radius,
            pageToken: pageToken
        )
    }
    
    func searchText(
        query: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        pageToken: String? = nil
    ) async throws -> (places: [Place], nextPageToken: String?) {
        let location: CLLocationCoordinate2D? = {
            guard let lat = latitude, let lng = longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }()

        return try await manager.searchText(
            query: query,
            location: location,
            pageToken: pageToken
        )
    }
    
    func getPlaceDetails(placeId: String) async throws -> PlaceDetail {
        return try await manager.getPlaceDetails(placeId: placeId)
    }
}
