//
//  MockDiscoveryInteractor.swift
//  AllTrailsLunchAppTests
//
//  Created by Tri Le on 03/11/25.
//

import Foundation
import CoreLocation
@testable import AllTrailsLunchApp

@MainActor
final class MockDiscoveryInteractor: DiscoveryInteractor {

    // MARK: - FavoritesManager Access

    let favoritesManager: FavoritesManager

    // MARK: - Mock Configuration

    var shouldFailLocationPermission = false
    var shouldFailSearch = false
    var locationToReturn: CLLocationCoordinate2D?
    var placesToReturn: [Place] = []
    var nextPageTokenToReturn: String?
    var errorToThrow: PlacesError?
    var placeDetailsToReturn: PlaceDetail?

    // MARK: - Initialization

    init(favoritesManager: FavoritesManager? = nil) {
        self.favoritesManager = favoritesManager ?? AppConfiguration.shared.createFavoritesManager()
    }
    
    // MARK: - Call Tracking
    
    var requestLocationPermissionCallCount = 0
    var searchNearbyCallCount = 0
    var searchTextCallCount = 0
    var getPlaceDetailsCallCount = 0
    var toggleFavoriteCallCount = 0
    
    var lastSearchNearbyLocation: CLLocationCoordinate2D?
    var lastSearchNearbyRadius: Double?
    var lastSearchNearbyPageToken: String?
    
    var lastSearchTextQuery: String?
    var lastSearchTextLocation: CLLocationCoordinate2D?
    var lastSearchTextPageToken: String?
    
    var lastPlaceDetailsId: String?
    var lastToggledPlace: Place?
    var lastToggledPlaceId: String?

    // MARK: - DiscoveryInteractor Protocol
    
    func requestLocationPermission() async throws -> CLLocationCoordinate2D {
        requestLocationPermissionCallCount += 1
        
        if shouldFailLocationPermission {
            throw errorToThrow ?? PlacesError.locationPermissionDenied
        }
        
        return locationToReturn ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }
    
    func searchNearby(
        location: CLLocationCoordinate2D,
        radius: Int,
        pageToken: String?
    ) async throws -> (places: [Place], nextPageToken: String?) {
        searchNearbyCallCount += 1
        lastSearchNearbyLocation = location
        lastSearchNearbyRadius = Double(radius)
        lastSearchNearbyPageToken = pageToken

        if shouldFailSearch {
            throw errorToThrow ?? PlacesError.networkUnavailable
        }

        return (placesToReturn, nextPageTokenToReturn)
    }

    func searchText(
        query: String,
        location: CLLocationCoordinate2D?,
        pageToken: String?
    ) async throws -> (places: [Place], nextPageToken: String?) {
        searchTextCallCount += 1
        lastSearchTextQuery = query
        lastSearchTextLocation = location
        lastSearchTextPageToken = pageToken

        if shouldFailSearch {
            throw errorToThrow ?? PlacesError.networkUnavailable
        }

        return (placesToReturn, nextPageTokenToReturn)
    }

    func getPlaceDetails(placeId: String) async throws -> PlaceDetail {
        getPlaceDetailsCallCount += 1
        lastPlaceDetailsId = placeId

        if shouldFailSearch {
            throw errorToThrow ?? PlacesError.networkUnavailable
        }

        guard let details = placeDetailsToReturn else {
            throw PlacesError.invalidResponse("No details configured")
        }

        return details
    }
    
    func toggleFavorite(_ place: Place) {
        toggleFavoriteCallCount += 1
        lastToggledPlace = place
    }

    func isFavorite(_ placeId: String) -> Bool {
        return false
    }

    func toggleFavorite(_ placeId: String) {
        toggleFavoriteCallCount += 1
        lastToggledPlaceId = placeId
    }

    func addFavorite(_ placeId: String) {
        // No-op for mock
    }

    func removeFavorite(_ placeId: String) {
        // No-op for mock
    }

    func getFavoriteIds() -> Set<String> {
        return []
    }

    // MARK: - Test Helpers
    
    func reset() {
        shouldFailLocationPermission = false
        shouldFailSearch = false
        locationToReturn = nil
        placesToReturn = []
        nextPageTokenToReturn = nil
        errorToThrow = nil
        placeDetailsToReturn = nil
        
        requestLocationPermissionCallCount = 0
        searchNearbyCallCount = 0
        searchTextCallCount = 0
        getPlaceDetailsCallCount = 0
        toggleFavoriteCallCount = 0
        
        lastSearchNearbyLocation = nil
        lastSearchNearbyRadius = nil
        lastSearchNearbyPageToken = nil
        
        lastSearchTextQuery = nil
        lastSearchTextLocation = nil
        lastSearchTextPageToken = nil
        
        lastPlaceDetailsId = nil
        lastToggledPlace = nil
        lastToggledPlaceId = nil
    }
}

