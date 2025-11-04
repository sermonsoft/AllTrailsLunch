///
/// `DiscoveryViewModel.swift`
/// AllTrailsLunch
///
/// ViewModel for the discovery screen with search and filtering.
///

import Foundation
import CoreLocation
import Observation

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
            }
        }
    }
}

@MainActor
@Observable
class DiscoveryViewModel {
    var searchText: String = ""
    var results: [Place] = []
    var viewMode: ViewMode = .list {
        didSet {
            if viewMode != oldValue {
                eventLogger.log(Event.viewModeChanged(mode: viewMode))
            }
        }
    }
    var isLoading: Bool = false
    var error: PlacesError?
    var userLocation: CLLocationCoordinate2D?
    var nextPageToken: String?

    private let interactor: DiscoveryInteractor
    private let eventLogger: EventLogger
    private var searchTask: Task<Void, Never>?
    private var debounceTimer: Timer?
    private var currentPage: Int = 0

    init(interactor: DiscoveryInteractor, eventLogger: EventLogger) {
        self.interactor = interactor
        self.eventLogger = eventLogger

        // Log screen view
        eventLogger.log(Event.screenViewed)
    }

    // MARK: - Legacy Initializer (for backward compatibility)

    init(
        repository: RestaurantRepository,
        locationManager: LocationManager,
        favoritesStore: FavoritesStore
    ) {
        // Create a temporary CoreInteractor for legacy support
        let config = AppConfiguration.shared
        self.interactor = config.createCoreInteractor()
        self.eventLogger = config.createEventLogger()

        // Log screen view
        eventLogger.log(Event.screenViewed)
    }
    
    // MARK: - Initialization

    func initialize() async {
        eventLogger.log(Event.locationPermissionRequested)

        do {
            let location = try await interactor.requestLocationPermission()
            self.userLocation = location
            eventLogger.log(Event.locationPermissionGranted)
            await searchNearby()
        } catch let error as PlacesError {
            self.error = error
            if error == .locationPermissionDenied {
                eventLogger.log(Event.locationPermissionDenied)
            } else {
                eventLogger.log(Event.searchError(error: error.localizedDescription))
            }
        } catch {
            self.error = .unknown(error.localizedDescription)
            eventLogger.log(Event.searchError(error: error.localizedDescription))
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
    
    private func searchNearby() async {
        guard let location = userLocation else {
            error = .locationPermissionDenied
            return
        }

        isLoading = true
        error = nil
        currentPage = 0

        do {
            let (places, nextToken) = try await interactor.searchNearby(
                location: location,
                radius: 1500,
                pageToken: nil
            )
            self.results = places
            self.nextPageToken = nextToken

            // Log successful search
            eventLogger.log(Event.nearbySearchPerformed(resultCount: places.count))
        } catch let error as PlacesError {
            self.error = error
            eventLogger.log(Event.searchError(error: error.localizedDescription))
        } catch {
            self.error = .unknown(error.localizedDescription)
            eventLogger.log(Event.searchError(error: error.localizedDescription))
        }

        isLoading = false
    }

    private func searchText(_ query: String) async {
        isLoading = true
        error = nil
        currentPage = 0

        do {
            let (places, nextToken) = try await interactor.searchText(
                query: query,
                location: userLocation,
                pageToken: nil
            )
            self.results = places
            self.nextPageToken = nextToken

            // Log successful search
            eventLogger.log(Event.searchPerformed(query: query, resultCount: places.count))
        } catch let error as PlacesError {
            self.error = error
            eventLogger.log(Event.searchError(error: error.localizedDescription))
        } catch {
            self.error = .unknown(error.localizedDescription)
            eventLogger.log(Event.searchError(error: error.localizedDescription))
        }

        isLoading = false
    }
    
    func loadNextPage() async {
        guard let nextPageToken = nextPageToken else { return }

        isLoading = true
        currentPage += 1

        do {
            let (places, nextToken) = try await interactor.searchText(
                query: searchText,
                location: userLocation,
                pageToken: nextPageToken
            )
            self.results.append(contentsOf: places)
            self.nextPageToken = nextToken

            // Log pagination
            eventLogger.log(Event.loadMoreResults(pageNumber: currentPage))
        } catch let error as PlacesError {
            self.error = error
            eventLogger.log(Event.searchError(error: error.localizedDescription))
        } catch {
            self.error = .unknown(error.localizedDescription)
            eventLogger.log(Event.searchError(error: error.localizedDescription))
        }

        isLoading = false
    }

    // MARK: - Favorites

    func toggleFavorite(_ place: Place) {
        interactor.toggleFavorite(place.id)

        if let index = results.firstIndex(where: { $0.id == place.id }) {
            let isFavorite = interactor.isFavorite(place.id)
            results[index].isFavorite = isFavorite

            // Log favorite toggle
            eventLogger.log(Event.favoriteToggled(placeId: place.id, isFavorite: isFavorite))
        }
    }

    // MARK: - Navigation

    func didSelectPlace(_ place: Place) {
        eventLogger.log(Event.placeSelected(placeId: place.id, placeName: place.name))
    }
}

