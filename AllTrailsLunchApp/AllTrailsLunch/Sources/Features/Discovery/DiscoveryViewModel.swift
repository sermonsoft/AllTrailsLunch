///
/// `DiscoveryViewModel.swift`
/// AllTrailsLunch
///
/// ViewModel for the discovery screen with search and filtering.
///

import Foundation
import CoreLocation
import Combine

enum ViewMode {
    case list
    case map
}

@MainActor
class DiscoveryViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var results: [Place] = []
    @Published var viewMode: ViewMode = .list
    @Published var isLoading: Bool = false
    @Published var error: PlacesError?
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var nextPageToken: String?

    private let interactor: DiscoveryInteractor
    private var searchTask: Task<Void, Never>?
    private var debounceTimer: Timer?

    init(interactor: DiscoveryInteractor) {
        self.interactor = interactor
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
    }
    
    // MARK: - Initialization

    func initialize() async {
        do {
            let location = try await interactor.requestLocationPermission()
            self.userLocation = location
            await searchNearby()
        } catch let error as PlacesError {
            self.error = error
        } catch {
            self.error = .unknown(error.localizedDescription)
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

        do {
            let (places, nextToken) = try await interactor.searchNearby(
                location: location,
                radius: 1500,
                pageToken: nil
            )
            self.results = places
            self.nextPageToken = nextToken
        } catch let error as PlacesError {
            self.error = error
        } catch {
            self.error = .unknown(error.localizedDescription)
        }

        isLoading = false
    }

    private func searchText(_ query: String) async {
        isLoading = true
        error = nil

        do {
            let (places, nextToken) = try await interactor.searchText(
                query: query,
                location: userLocation,
                pageToken: nil
            )
            self.results = places
            self.nextPageToken = nextToken
        } catch let error as PlacesError {
            self.error = error
        } catch {
            self.error = .unknown(error.localizedDescription)
        }

        isLoading = false
    }
    
    func loadNextPage() async {
        guard let nextPageToken = nextPageToken else { return }

        isLoading = true

        do {
            let (places, nextToken) = try await interactor.searchText(
                query: searchText,
                location: userLocation,
                pageToken: nextPageToken
            )
            self.results.append(contentsOf: places)
            self.nextPageToken = nextToken
        } catch let error as PlacesError {
            self.error = error
        } catch {
            self.error = .unknown(error.localizedDescription)
        }

        isLoading = false
    }

    // MARK: - Favorites

    func toggleFavorite(_ place: Place) {
        interactor.toggleFavorite(place.id)

        if let index = results.firstIndex(where: { $0.id == place.id }) {
            results[index].isFavorite = interactor.isFavorite(place.id)
        }
    }
}

