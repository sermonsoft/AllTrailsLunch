///
/// `RestaurantRepository.swift`
/// AllTrailsLunch
///
/// Repository for restaurant data operations.
///

import Foundation
import CoreLocation

class RestaurantRepository {
    private let placesClient: PlacesClient
    private let favoritesStore: FavoritesStore
    
    init(placesClient: PlacesClient, favoritesStore: FavoritesStore) {
        self.placesClient = placesClient
        self.favoritesStore = favoritesStore
    }
    
    // MARK: - Search Operations
    
    func searchNearby(
        latitude: Double,
        longitude: Double,
        radius: Int = 1500,
        pageToken: String? = nil
    ) async throws -> (places: [Place], nextPageToken: String?) {
        let url = try placesClient.buildNearbySearchURL(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            pageToken: pageToken
        )
        
        let request = try PlacesRequestBuilder()
            .setURL(url)
            .setMethod(.get)
            .build()
        
        let response: NearbySearchResponse = try await placesClient.execute(request)
        
        guard response.status == "OK" || response.status == "ZERO_RESULTS" else {
            throw PlacesError.invalidResponse("API returned status: \(response.status)")
        }
        
        let places = await applyFavoriteStatus(to: response.results.map { Place(from: $0) })
        
        return (places, response.nextPageToken)
    }
    
    func searchText(
        query: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        pageToken: String? = nil
    ) async throws -> (places: [Place], nextPageToken: String?) {
        let url = try placesClient.buildTextSearchURL(
            query: query,
            latitude: latitude,
            longitude: longitude,
            pageToken: pageToken
        )
        
        let request = try PlacesRequestBuilder()
            .setURL(url)
            .setMethod(.get)
            .build()
        
        let response: TextSearchResponse = try await placesClient.execute(request)
        
        guard response.status == "OK" || response.status == "ZERO_RESULTS" else {
            throw PlacesError.invalidResponse("API returned status: \(response.status)")
        }
        
        let places = await applyFavoriteStatus(to: response.results.map { Place(from: $0) })
        
        return (places, response.nextPageToken)
    }
    
    func getPlaceDetails(placeId: String) async throws -> PlaceDetail {
        let url = try placesClient.buildDetailsURL(placeId: placeId)
        
        let request = try PlacesRequestBuilder()
            .setURL(url)
            .setMethod(.get)
            .build()
        
        let response: PlaceDetailsResponse = try await placesClient.execute(request)
        
        guard response.status == "OK" else {
            throw PlacesError.invalidResponse("API returned status: \(response.status)")
        }
        
        // Get favorite status on main actor
        let isFavorite = await MainActor.run {
            favoritesStore.isFavorite(placeId)
        }
        
        // Create a Place from the details
        let place = Place(
            id: placeId,
            name: response.result.name,
            rating: response.result.rating,
            userRatingsTotal: nil,
            priceLevel: nil,
            latitude: 0,
            longitude: 0,
            address: response.result.formattedAddress,
            photoReferences: [],
            isFavorite: isFavorite
        )
        
        return PlaceDetail(place: place, from: response.result)
    }
    
    // MARK: - Private Helpers
    
    private func applyFavoriteStatus(to places: [Place]) async -> [Place] {
        await MainActor.run {
            places.map { place in
                var updatedPlace = place
                updatedPlace.isFavorite = favoritesStore.isFavorite(place.id)
                return updatedPlace
            }
        }
    }
}
