//
//  CoreInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation
import CoreLocation
import Combine

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

    private var pipelineCoordinator: DataPipelineCoordinator {
        container.dataPipelineCoordinator
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

    var favoriteIdsPublisher: AnyPublisher<Set<String>, Never> {
        return favoritesManager.$favoriteIds.eraseToAnyPublisher()
    }

    // MARK: - NetworkStatusInteractor Implementation

    func isNetworkConnected() -> Bool {
        return networkMonitor.isConnected
    }

    func getConnectionType() -> NetworkMonitor.ConnectionType {
        return networkMonitor.connectionType
    }

    // MARK: - EventLoggingInteractor Implementation

    func logEvent(_ event: LoggableEvent) {
        container.eventLogger.log(event)
    }

    func logScreenView(screenName: String, screenClass: String?) {
        container.eventLogger.logScreenView(screenName: screenName, screenClass: screenClass)
    }

    func logCustomEvent(name: String, parameters: [String: Any]?) {
        container.eventLogger.logEvent(name: name, parameters: parameters)
    }

    // MARK: - FilterManagementInteractor Implementation

    func getFilters() -> SearchFilters {
        return filterPreferencesManager.getFilters()
    }

    func saveFilters(_ filters: SearchFilters) async throws {
        try await filterPreferencesManager.saveFilters(filters)
    }

    func loadFilters() -> SearchFilters {
        return filterPreferencesManager.loadFilters()
    }

    func resetFilters() async throws {
        try await filterPreferencesManager.clearFilters()
    }

    // MARK: - SavedSearchInteractor Implementation

    func getAllSavedSearches() async throws -> [SavedSearch] {
        return try await savedSearchManager.getAllSavedSearches()
    }

    func getSavedSearch(id: UUID) async throws -> SavedSearch? {
        return try await savedSearchManager.getSavedSearch(id: id)
    }

    func saveSearch(_ search: SavedSearch) async throws {
        try await savedSearchManager.saveSearch(search)
    }

    func deleteSearch(id: UUID) async throws {
        try await savedSearchManager.deleteSearch(id: id)
    }

    func updateLastUsed(id: UUID) async throws {
        try await savedSearchManager.updateLastUsed(id: id)
    }

    func deleteSearch(_ search: SavedSearch) async throws {
        try await savedSearchManager.deleteSearch(search)
    }

    func findDuplicateSearch(
        query: String,
        latitude: Double?,
        longitude: Double?,
        filters: SearchFilters
    ) async throws -> SavedSearch? {
        return try await savedSearchManager.findDuplicateSearch(
            query: query,
            latitude: latitude,
            longitude: longitude,
            filters: filters
        )
    }

    func clearAllSavedSearches() async throws {
        try await savedSearchManager.clearAllSavedSearches()
    }

    // MARK: - Photo Loading

    /// Load photo from PhotoManager
    /// Note: This method can be called from any isolation domain because it's async
    /// and the underlying PhotoManager uses actors for thread-safe caching
    func loadPhoto(
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

    /// Load first available photo from a list of photo references
    func loadFirstPhoto(
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

    // MARK: - ReactivePipelineInteractor Implementation

    func executePipeline(
        query: String?,
        radius: Int = 1500
    ) -> AnyPublisher<[Place], Never> {
        return pipelineCoordinator.executePipeline(query: query, radius: radius)
    }

    func createDebouncedSearchPipeline(
        queryPublisher: AnyPublisher<String, Never>,
        debounceInterval: TimeInterval = 0.5
    ) -> AnyPublisher<[Place], Never> {
        return pipelineCoordinator.createDebouncedSearchPipeline(
            queryPublisher: queryPublisher,
            debounceInterval: debounceInterval
        )
    }

    func createThrottledLocationPipeline(
        throttleInterval: TimeInterval = 2.0
    ) -> AnyPublisher<CLLocationCoordinate2D, Never> {
        return pipelineCoordinator.createThrottledLocationPipeline(
            throttleInterval: throttleInterval
        )
    }

    var pipelineStatusPublisher: AnyPublisher<PipelineStatus, Never> {
        return pipelineCoordinator.$pipelineStatus.eraseToAnyPublisher()
    }

    var mergedResultsPublisher: AnyPublisher<[Place], Never> {
        return pipelineCoordinator.$mergedResults.eraseToAnyPublisher()
    }

    var pipelineErrorsPublisher: AnyPublisher<[PipelineError], Never> {
        return pipelineCoordinator.$errors.eraseToAnyPublisher()
    }

    func cancelAllPipelines() {
        pipelineCoordinator.cancelAllPipelines()
    }
}

