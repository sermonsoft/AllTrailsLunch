//
//  DiscoveryViewModel.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 04/11/25.
//

import Foundation
import CoreLocation
import Observation

/// View mode for displaying restaurant results
enum ViewMode {
    case list
    case map
}

// MARK: - Discovery Events

extension DiscoveryViewModel {
    enum Event: LoggableEvent {
        case screenViewed
        case searchPerformed(query: String, resultCount: Int)
        case nearbySearchPerformed(resultCount: Int)
        case viewModeChanged(mode: ViewMode)
        case favoriteToggled(placeId: String, isFavorite: Bool)
        case placeSelected(placeId: String, placeName: String)
        case loadMoreResults(pageNumber: Int)
        case locationPermissionRequested
        case locationPermissionGranted
        case locationPermissionDenied
        case searchError(error: String)
        case filtersApplied(filterCount: Int)
        case filtersCleared
        case searchSaved(name: String)
        case savedSearchLoaded(name: String)

        var eventName: String {
            switch self {
            case .screenViewed:
                return "discovery_screen_viewed"
            case .searchPerformed:
                return "search_performed"
            case .nearbySearchPerformed:
                return "nearby_search_performed"
            case .viewModeChanged:
                return "view_mode_changed"
            case .favoriteToggled:
                return "favorite_toggled"
            case .placeSelected:
                return "place_selected"
            case .loadMoreResults:
                return "load_more_results"
            case .locationPermissionRequested:
                return "location_permission_requested"
            case .locationPermissionGranted:
                return "location_permission_granted"
            case .locationPermissionDenied:
                return "location_permission_denied"
            case .searchError:
                return "search_error"
            case .filtersApplied:
                return "filters_applied"
            case .filtersCleared:
                return "filters_cleared"
            case .searchSaved:
                return "search_saved"
            case .savedSearchLoaded:
                return "saved_search_loaded"
            }
        }

        var category: String {
            switch self {
            case .screenViewed:
                return EventCategory.navigation
            case .searchPerformed, .nearbySearchPerformed, .searchError:
                return EventCategory.search
            case .viewModeChanged:
                return EventCategory.discovery
            case .favoriteToggled:
                return EventCategory.favorites
            case .placeSelected:
                return EventCategory.discovery
            case .loadMoreResults:
                return EventCategory.search
            case .locationPermissionRequested, .locationPermissionGranted, .locationPermissionDenied:
                return EventCategory.location
            case .filtersApplied, .filtersCleared:
                return EventCategory.search
            case .searchSaved, .savedSearchLoaded:
                return EventCategory.search
            }
        }

        var parameters: [String: Any] {
            switch self {
            case .screenViewed:
                return [:]
            case .searchPerformed(let query, let resultCount):
                return ["query": query, "result_count": resultCount]
            case .nearbySearchPerformed(let resultCount):
                return ["result_count": resultCount]
            case .viewModeChanged(let mode):
                return ["mode": mode == .list ? "list" : "map"]
            case .favoriteToggled(let placeId, let isFavorite):
                return ["place_id": placeId, "is_favorite": isFavorite]
            case .placeSelected(let placeId, let placeName):
                return ["place_id": placeId, "place_name": placeName]
            case .loadMoreResults(let pageNumber):
                return ["page_number": pageNumber]
            case .locationPermissionRequested, .locationPermissionGranted, .locationPermissionDenied:
                return [:]
            case .searchError(let error):
                return ["error": error]
            case .filtersApplied(let filterCount):
                return ["filter_count": filterCount]
            case .filtersCleared:
                return [:]
            case .searchSaved(let name):
                return ["search_name": name]
            case .savedSearchLoaded(let name):
                return ["search_name": name]
            }
        }
    }
}

/// ViewModel for the Discovery screen.
///
/// Manages the state and business logic for restaurant discovery, including:
/// - Location-based and text-based search
/// - View mode switching (list/map)
/// - Search filters and saved searches
/// - Pagination and infinite scrolling
/// - Integration with FavoritesManager for bookmark state
///
/// Uses @Observable macro for modern SwiftUI state management.
@MainActor
@Observable
class DiscoveryViewModel {
    var searchText: String = ""
    var results: [Place] = []
    var viewMode: ViewMode = .list {
        didSet {
            if viewMode != oldValue {
                interactor.logEvent(Event.viewModeChanged(mode: viewMode))
            }
        }
    }
    var isLoading: Bool = false
    var error: PlacesError?
    var userLocation: CLLocationCoordinate2D?
    var nextPageToken: String?
    var filters: SearchFilters = .default
    var showFilterSheet: Bool = false
    var showSavedSearchesSheet: Bool = false
    var showSaveSearchSheet: Bool = false
    var isShowingCachedData: Bool = false // Track if current results are from cache

    // Observable state for favorites (managed by ViewModel, not Manager)
    var favoriteIds: Set<String> = []

    // Observable state for saved searches (managed by ViewModel, not Manager)
    var savedSearches: [SavedSearch] = []

    private let interactor: DiscoveryInteractor

    // MARK: - State (Exposed for UI Observation)

    /// Check if network is connected
    /// Accessed through interactor behavior method
    var isNetworkConnected: Bool {
        interactor.isNetworkConnected()
    }

    /// Photo loading closure for views
    /// Views should use this closure instead of accessing PhotoManager directly
    var loadPhoto: ([String], Int, Int) async -> Data? {
        { [weak self] photoReferences, maxWidth, maxHeight in
            guard let self = self else { return nil }
            return await self.interactor.loadFirstPhoto(
                from: photoReferences,
                maxWidth: maxWidth,
                maxHeight: maxHeight
            )
        }
    }

    /// Place details loading closure for views
    /// Views should use this closure instead of accessing RestaurantManager directly
    var loadPlaceDetails: (String) async throws -> PlaceDetail {
        { [weak self] placeId in
            guard let self = self else {
                throw PlacesError.invalidResponse("ViewModel deallocated")
            }
            return try await self.interactor.getPlaceDetails(placeId: placeId)
        }
    }

    private var searchTask: Task<Void, Never>?
    private var debounceTimer: Timer?
    private var currentPage: Int = 0
    private var unfilteredResults: [Place] = [] // Store unfiltered results for client-side filtering

    init(interactor: DiscoveryInteractor) {
        self.interactor = interactor

        // Load saved filters from interactor
        self.filters = interactor.getFilters()

        // Load favorite IDs from interactor into ViewModel's observable state
        self.favoriteIds = interactor.getFavoriteIds()

        // Log screen view
        interactor.logEvent(Event.screenViewed)
    }

    // MARK: - Initialization

    func initialize() async {
        interactor.logEvent(Event.locationPermissionRequested)

        // Load saved searches into ViewModel's observable state
        await loadSavedSearches()

        do {
            let location = try await interactor.requestLocationPermission()
            self.userLocation = location
            interactor.logEvent(Event.locationPermissionGranted)
            await searchNearby()
        } catch let error as PlacesError {
            self.error = error
            if error == .locationPermissionDenied {
                interactor.logEvent(Event.locationPermissionDenied)
            } else {
                interactor.logEvent(Event.searchError(error: error.localizedDescription))
            }
        } catch {
            self.error = .unknown(error.localizedDescription)
            interactor.logEvent(Event.searchError(error: error.localizedDescription))
        }
    }

    // MARK: - Saved Searches Loading

    func loadSavedSearches() async {
        do {
            savedSearches = try await interactor.getAllSavedSearches()
        } catch {
            savedSearches = []
        }
    }
    
    // MARK: - Search Operations

    func performSearch(_ query: String) {
        searchTask?.cancel()
        debounceTimer?.invalidate()

        if query.isEmpty {
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    await self?.searchNearby()
                }
            }
        } else {
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    await self?.searchText(query)
                }
            }
        }
    }

    func refresh() async {
        if searchText.isEmpty {
            await searchNearby()
        } else {
            await searchText(searchText)
        }
    }
    
    private func searchNearby() async {
        guard let location = userLocation else {
            error = .locationPermissionDenied
            return
        }

        isLoading = true
        error = nil
        currentPage = 0

        do {
            let (places, nextToken, isFromCache) = try await interactor.searchNearby(
                location: location,
                radius: 1500,
                pageToken: nil
            )
            storeAndFilterResults(places)
            self.nextPageToken = nextToken
            self.isShowingCachedData = isFromCache

            // Log successful search
            interactor.logEvent(Event.nearbySearchPerformed(resultCount: results.count))
        } catch let error as PlacesError {
            self.error = error
            self.isShowingCachedData = false
            interactor.logEvent(Event.searchError(error: error.localizedDescription))
        } catch {
            self.error = .unknown(error.localizedDescription)
            self.isShowingCachedData = false
            interactor.logEvent(Event.searchError(error: error.localizedDescription))
        }

        isLoading = false
    }

    private func searchText(_ query: String) async {
        // Validate search query before performing search
        let validationResult = SearchQueryValidator.validate(query)
        guard validationResult.isValid else {
            // Set error and notify user of invalid search category
            if let errorMessage = validationResult.errorMessage {
                self.error = .invalidSearchCategory(errorMessage)
                interactor.logEvent(Event.searchError(error: "Invalid search category: \(query)"))
            }
            return
        }

        isLoading = true
        error = nil
        currentPage = 0

        do {
            let (places, nextToken, isFromCache) = try await interactor.searchText(
                query: query,
                location: userLocation,
                pageToken: nil
            )
            storeAndFilterResults(places)
            self.nextPageToken = nextToken
            self.isShowingCachedData = isFromCache

            // Log successful search
            interactor.logEvent(Event.searchPerformed(query: query, resultCount: results.count))
        } catch let error as PlacesError {
            self.error = error
            self.isShowingCachedData = false
            interactor.logEvent(Event.searchError(error: error.localizedDescription))
        } catch {
            self.error = .unknown(error.localizedDescription)
            self.isShowingCachedData = false
            interactor.logEvent(Event.searchError(error: error.localizedDescription))
        }

        isLoading = false
    }
    
    func loadNextPage() async {
        guard let nextPageToken = nextPageToken else { return }

        isLoading = true
        currentPage += 1

        do {
            let (places, nextToken, _) = try await interactor.searchText(
                query: searchText,
                location: userLocation,
                pageToken: nextPageToken
            )
            self.results.append(contentsOf: places)
            self.nextPageToken = nextToken
            // Pagination always loads from network, so don't update cache flag

            // Log pagination
            interactor.logEvent(Event.loadMoreResults(pageNumber: currentPage))
        } catch let error as PlacesError {
            self.error = error
            interactor.logEvent(Event.searchError(error: error.localizedDescription))
        } catch {
            self.error = .unknown(error.localizedDescription)
            interactor.logEvent(Event.searchError(error: error.localizedDescription))
        }

        isLoading = false
    }

    // MARK: - Favorites

    func toggleFavorite(_ place: Place) async {
        do {
            // Update via interactor (FavoritesManager + SwiftData)
            let isFavorite = try await interactor.toggleFavorite(place)

            // Update ViewModel's observable state
            if isFavorite {
                favoriteIds.insert(place.id)
            } else {
                favoriteIds.remove(place.id)
            }

            // Update results array
            if let index = results.firstIndex(where: { $0.id == place.id }) {
                results[index].isFavorite = isFavorite
            }

            // Log favorite toggle
            interactor.logEvent(Event.favoriteToggled(placeId: place.id, isFavorite: isFavorite))
        } catch {
            // Handle error silently or show to user
            print("❌ Failed to toggle favorite: \(error)")
        }
    }

    // MARK: - Navigation

    func didSelectPlace(_ place: Place) {
        interactor.logEvent(Event.placeSelected(placeId: place.id, placeName: place.name))
    }

    // MARK: - Filters

    func applyFilters(_ newFilters: SearchFilters) async {
        filters = newFilters

        do {
            try await interactor.saveFilters(newFilters)
        } catch {
            print("❌ Failed to save filters: \(error)")
        }

        // Apply filters to current results
        applyFiltersToResults()

        // Log filter application
        if newFilters.hasActiveFilters {
            interactor.logEvent(Event.filtersApplied(filterCount: newFilters.activeFilterCount))
        } else {
            interactor.logEvent(Event.filtersCleared)
        }
    }

    func clearFilters() async {
        filters = .default

        do {
            try await interactor.resetFilters()
        } catch {
            print("❌ Failed to clear filters: \(error)")
        }

        applyFiltersToResults()
        interactor.logEvent(Event.filtersCleared)
    }

    private func applyFiltersToResults() {
        // If we have unfiltered results, apply filters
        if !unfilteredResults.isEmpty {
            results = filters.apply(
                to: unfilteredResults,
                userLocation: userLocation.map { (latitude: $0.latitude, longitude: $0.longitude) }
            )
        }
    }

    private func storeAndFilterResults(_ places: [Place]) {
        // Store unfiltered results
        unfilteredResults = places

        // Apply filters
        results = filters.apply(
            to: places,
            userLocation: userLocation.map { (latitude: $0.latitude, longitude: $0.longitude) }
        )
    }

    // MARK: - Saved Searches

    func loadSavedSearch(_ savedSearch: SavedSearch) async {
        // Apply filters from saved search
        filters = savedSearch.filters

        do {
            try await interactor.saveFilters(filters)
        } catch {
            print("❌ Failed to save filters: \(error)")
        }

        // Set search text
        searchText = savedSearch.query

        // Log event
        interactor.logEvent(Event.savedSearchLoaded(name: savedSearch.displayName))

        // Perform search
        if savedSearch.query.isEmpty {
            await searchNearby()
        } else {
            await searchText(savedSearch.query)
        }
    }

    func saveCurrentSearch(name: String) async throws {
        // Validate search query before saving
        let validationResult = SearchQueryValidator.validate(searchText)
        guard validationResult.isValid else {
            if let errorMessage = validationResult.errorMessage {
                throw PlacesError.invalidSearchCategory(errorMessage)
            }
            throw PlacesError.invalidSearchCategory("Cannot save non-food/restaurant searches")
        }

        let savedSearch = SavedSearch(
            name: name,
            query: searchText,
            location: userLocation.map { (latitude: $0.latitude, longitude: $0.longitude) },
            filters: filters
        )

        try await interactor.saveSearch(savedSearch)

        // Reload saved searches into ViewModel's observable state
        await loadSavedSearches()

        // Log event
        interactor.logEvent(Event.searchSaved(name: name))
    }

    func saveSearch(
        name: String,
        query: String,
        location: (latitude: Double, longitude: Double)?,
        filters: SearchFilters
    ) async throws {
        // Validate search query before saving
        let validationResult = SearchQueryValidator.validate(query)
        guard validationResult.isValid else {
            if let errorMessage = validationResult.errorMessage {
                throw PlacesError.invalidSearchCategory(errorMessage)
            }
            throw PlacesError.invalidSearchCategory("Cannot save non-food/restaurant searches")
        }

        let savedSearch = SavedSearch(
            name: name,
            query: query,
            location: location,
            filters: filters
        )

        try await interactor.saveSearch(savedSearch)

        // Reload saved searches into ViewModel's observable state
        await loadSavedSearches()

        // Log event
        interactor.logEvent(Event.searchSaved(name: name))
    }

    func deleteSavedSearch(_ search: SavedSearch) async throws {
        try await interactor.deleteSearch(search)

        // Reload saved searches into ViewModel's observable state
        await loadSavedSearches()
    }

    func findDuplicateSearch(
        query: String,
        latitude: Double?,
        longitude: Double?,
        filters: SearchFilters
    ) async throws -> SavedSearch? {
        return try await interactor.findDuplicateSearch(
            query: query,
            latitude: latitude,
            longitude: longitude,
            filters: filters
        )
    }

    func clearAllSavedSearches() async throws {
        try await interactor.clearAllSavedSearches()

        // Reload saved searches into ViewModel's observable state
        await loadSavedSearches()
    }
}
