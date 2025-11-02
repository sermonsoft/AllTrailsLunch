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
    
    private let repository: RestaurantRepository
    private let locationManager: LocationManager
    private let favoritesStore: FavoritesStore
    private var searchTask: Task<Void, Never>?
    private var debounceTimer: Timer?
    
    init(
        repository: RestaurantRepository,
        locationManager: LocationManager,
        favoritesStore: FavoritesStore
    ) {
        self.repository = repository
        self.locationManager = locationManager
        self.favoritesStore = favoritesStore
    }
    
    // MARK: - Initialization
    
    func initialize() async {
        do {
            let location = try await locationManager.requestLocationPermission()
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
            let (places, nextToken) = try await repository.searchNearby(
                latitude: location.latitude,
                longitude: location.longitude
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
            let (places, nextToken) = try await repository.searchText(
                query: query,
                latitude: userLocation?.latitude,
                longitude: userLocation?.longitude
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
            let (places, nextToken) = try await repository.searchText(
                query: searchText,
                latitude: userLocation?.latitude,
                longitude: userLocation?.longitude,
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
        favoritesStore.toggleFavorite(place.id)
        
        if let index = results.firstIndex(where: { $0.id == place.id }) {
            results[index].isFavorite = favoritesStore.isFavorite(place.id)
        }
    }
}

