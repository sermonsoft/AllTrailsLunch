//
//  MockDiscoveryInteractor.swift
//  AllTrailsLunchAppTests
//
//  Created by Tri Le on 03/11/25.
//

import Foundation
import CoreLocation
import Combine
@testable import AllTrailsLunchApp

@MainActor
final class MockDiscoveryInteractor: DiscoveryInteractor {

    // MARK: - Private Dependencies (Not exposed to ViewModels)

    private let container: DependencyContainer
    private let favoritesManager: FavoritesManager
    private let networkMonitor: NetworkMonitor

    // MARK: - Mock Configuration

    var shouldFailLocationPermission = false
    var shouldFailSearch = false
    var locationToReturn: CLLocationCoordinate2D?
    var placesToReturn: [Place] = []
    var nextPageTokenToReturn: String?
    var errorToThrow: PlacesError?
    var placeDetailsToReturn: PlaceDetail?

    // MARK: - Initialization

    init(favoritesManager: FavoritesManager? = nil, container: DependencyContainer? = nil) {
        self.favoritesManager = favoritesManager ?? AppConfiguration.shared.createFavoritesManager()
        self.container = container ?? AppConfiguration.shared.createDependencyContainer()
        self.networkMonitor = self.container.networkMonitor
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
    ) async throws -> (places: [Place], nextPageToken: String?, isFromCache: Bool) {
        searchNearbyCallCount += 1
        lastSearchNearbyLocation = location
        lastSearchNearbyRadius = Double(radius)
        lastSearchNearbyPageToken = pageToken

        if shouldFailSearch {
            throw errorToThrow ?? PlacesError.networkUnavailable
        }

        return (placesToReturn, nextPageTokenToReturn, false)
    }

    func searchText(
        query: String,
        location: CLLocationCoordinate2D?,
        pageToken: String?
    ) async throws -> (places: [Place], nextPageToken: String?, isFromCache: Bool) {
        searchTextCallCount += 1
        lastSearchTextQuery = query
        lastSearchTextLocation = location
        lastSearchTextPageToken = pageToken

        if shouldFailSearch {
            throw errorToThrow ?? PlacesError.networkUnavailable
        }

        return (placesToReturn, nextPageTokenToReturn, false)
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

    // MARK: - Favorites

    func isFavorite(_ placeId: String) -> Bool {
        return false
    }

    func toggleFavorite(_ placeId: String) async throws {
        toggleFavoriteCallCount += 1
        lastToggledPlaceId = placeId
    }

    func toggleFavorite(_ place: Place) async throws -> Bool {
        toggleFavoriteCallCount += 1
        lastToggledPlace = place
        lastToggledPlaceId = place.id
        return true
    }

    func addFavorite(_ placeId: String) async throws {
        // No-op for mock
    }

    func addFavorite(_ place: Place) async throws {
        // No-op for mock
    }

    func removeFavorite(_ placeId: String) async throws {
        // No-op for mock
    }

    func getFavoriteIds() -> Set<String> {
        return []
    }

    var favoriteIdsPublisher: AnyPublisher<Set<String>, Never> {
        return favoritesManager.$favoriteIds.eraseToAnyPublisher()
    }

    // MARK: - Photo Loading

    nonisolated func loadPhoto(
        photoReference: String,
        maxWidth: Int,
        maxHeight: Int
    ) async -> Data? {
        // Return nil for mock - tests don't need actual images
        return nil
    }

    nonisolated func loadFirstPhoto(
        from photoReferences: [String],
        maxWidth: Int,
        maxHeight: Int
    ) async -> Data? {
        // Return nil for mock - tests don't need actual images
        return nil
    }

    // MARK: - Event Logging

    func logEvent(_ event: LoggableEvent) {
        // Delegate to container's event logger so tests can verify events
        container.eventLogger.log(event)
    }

    func logScreenView(screenName: String, screenClass: String?) {
        // Delegate to container's event logger so tests can verify events
        container.eventLogger.logScreenView(screenName: screenName, screenClass: screenClass)
    }

    func logCustomEvent(name: String, parameters: [String: Any]?) {
        // Delegate to container's event logger so tests can verify events
        container.eventLogger.logEvent(name: name, parameters: parameters)
    }

    // MARK: - Network Status

    func isNetworkConnected() -> Bool {
        return networkMonitor.isConnected
    }

    func getConnectionType() -> NetworkMonitor.ConnectionType {
        return networkMonitor.connectionType
    }

    // MARK: - Filter Management

    func getFilters() -> SearchFilters {
        return container.filterPreferencesManager.getFilters()
    }

    func saveFilters(_ filters: SearchFilters) async throws {
        try await container.filterPreferencesManager.saveFilters(filters)
    }

    func loadFilters() -> SearchFilters {
        return container.filterPreferencesManager.loadFilters()
    }

    func resetFilters() async throws {
        try await container.filterPreferencesManager.clearFilters()
    }

    // MARK: - Saved Search Management

    func getAllSavedSearches() async throws -> [SavedSearch] {
        return try await container.savedSearchManager.getAllSavedSearches()
    }

    func getSavedSearch(id: UUID) async throws -> SavedSearch? {
        return try await container.savedSearchManager.getSavedSearch(id: id)
    }

    func saveSearch(_ search: SavedSearch) async throws {
        try await container.savedSearchManager.saveSearch(search)
    }

    func deleteSearch(id: UUID) async throws {
        try await container.savedSearchManager.deleteSearch(id: id)
    }

    func deleteSearch(_ search: SavedSearch) async throws {
        try await container.savedSearchManager.deleteSearch(search)
    }

    func updateLastUsed(id: UUID) async throws {
        try await container.savedSearchManager.updateLastUsed(id: id)
    }

    func findDuplicateSearch(query: String, latitude: Double?, longitude: Double?, filters: SearchFilters) async throws -> SavedSearch? {
        return try await container.savedSearchManager.findDuplicateSearch(query: query, latitude: latitude, longitude: longitude, filters: filters)
    }

    func clearAllSavedSearches() async throws {
        try await container.savedSearchManager.clearAllSavedSearches()
    }

    // MARK: - ReactivePipelineInteractor Implementation

    func executePipeline(
        query: String?,
        radius: Int = 1500
    ) -> AnyPublisher<[Place], Never> {
        // Return mock data as publisher
        return Just(placesToReturn).eraseToAnyPublisher()
    }

    func createDebouncedSearchPipeline(
        queryPublisher: AnyPublisher<String, Never>,
        debounceInterval: TimeInterval = 0.5
    ) -> AnyPublisher<[Place], Never> {
        // Return empty publisher that never emits (mock doesn't need to emit)
        // This prevents immediate completion which could cause issues in tests
        return Empty<[Place], Never>().eraseToAnyPublisher()
    }

    func createThrottledLocationPipeline(
        throttleInterval: TimeInterval = 2.0
    ) -> AnyPublisher<CLLocationCoordinate2D, Never> {
        // Return empty publisher that never emits (mock doesn't need to emit)
        // This prevents immediate completion which could cause issues in tests
        return Empty<CLLocationCoordinate2D, Never>().eraseToAnyPublisher()
    }

    var pipelineStatusPublisher: AnyPublisher<PipelineStatus, Never> {
        return Just(.idle).eraseToAnyPublisher()
    }

    var mergedResultsPublisher: AnyPublisher<[Place], Never> {
        return Empty<[Place], Never>().eraseToAnyPublisher()
    }

    var pipelineErrorsPublisher: AnyPublisher<[PipelineError], Never> {
        return Empty<[PipelineError], Never>().eraseToAnyPublisher()
    }

    func cancelAllPipelines() {
        // No-op for mock
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

