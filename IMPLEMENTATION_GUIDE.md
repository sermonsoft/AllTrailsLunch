# Architecture Improvements - Implementation Guide

## 🚀 Step-by-Step Implementation

This guide provides concrete steps to implement the architecture improvements for AllTrails Lunch.

---

## Phase 1: Protocol-Oriented Architecture

### Step 1.1: Create Protocol Definitions

**File**: `AllTrailsLunch/Sources/Core/Protocols/RepositoryProtocols.swift`

```swift
import Foundation
import CoreLocation

// MARK: - Repository Protocols

protocol RestaurantRepositoryProtocol {
    func searchNearby(
        latitude: Double,
        longitude: Double,
        radius: Int,
        pageToken: String?
    ) async throws -> (places: [Place], nextPageToken: String?)
    
    func searchText(
        query: String,
        latitude: Double?,
        longitude: Double?,
        pageToken: String?
    ) async throws -> (places: [Place], nextPageToken: String?)
    
    func getPlaceDetails(placeId: String) async throws -> PlaceDetail
}

protocol LocationManagerProtocol {
    var userLocation: CLLocationCoordinate2D? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    
    func requestLocationPermission() async throws -> CLLocationCoordinate2D
}

protocol FavoritesStoreProtocol: AnyObject {
    var favoriteIds: Set<String> { get }
    
    func isFavorite(_ placeId: String) -> Bool
    func toggleFavorite(_ placeId: String)
    func addFavorite(_ placeId: String)
    func removeFavorite(_ placeId: String)
    func clearAllFavorites()
}
```

### Step 1.2: Update Existing Classes to Conform

**File**: `AllTrailsLunch/Sources/Core/Models/RestaurantRepository.swift`

```swift
// Add protocol conformance
extension RestaurantRepository: RestaurantRepositoryProtocol {
    // Existing implementation already matches protocol
}
```

**File**: `AllTrailsLunch/Sources/Core/Location/LocationManager.swift`

```swift
// Add protocol conformance
extension LocationManager: LocationManagerProtocol {
    // Existing implementation already matches protocol
}
```

**File**: `AllTrailsLunch/Sources/Core/Favorites/FavoritesStore.swift`

```swift
// Add protocol conformance
extension FavoritesStore: FavoritesStoreProtocol {
    // Existing implementation already matches protocol
}
```

### Step 1.3: Update ViewModel to Use Protocols

**File**: `AllTrailsLunch/Sources/Features/Discovery/DiscoveryViewModel.swift`

```swift
@MainActor
class DiscoveryViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var results: [Place] = []
    @Published var viewMode: ViewMode = .list
    @Published var isLoading: Bool = false
    @Published var error: PlacesError?
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var nextPageToken: String?
    
    // Use protocols instead of concrete types
    private let repository: RestaurantRepositoryProtocol
    private let locationManager: LocationManagerProtocol
    private let favoritesStore: FavoritesStoreProtocol
    
    private var searchTask: Task<Void, Never>?
    private var debounceTimer: Timer?
    
    init(
        repository: RestaurantRepositoryProtocol,
        locationManager: LocationManagerProtocol,
        favoritesStore: FavoritesStoreProtocol
    ) {
        self.repository = repository
        self.locationManager = locationManager
        self.favoritesStore = favoritesStore
    }
    
    // Rest of implementation stays the same
}
```

---

## Phase 2: Use Case Layer

### Step 2.1: Create Use Case Protocols

**File**: `AllTrailsLunch/Sources/Core/UseCases/UseCaseProtocols.swift`

```swift
import Foundation
import CoreLocation

// MARK: - Use Case Protocols

protocol SearchNearbyRestaurantsUseCase {
    func execute(
        latitude: Double,
        longitude: Double,
        radius: Int
    ) async throws -> [Place]
}

protocol SearchRestaurantsByTextUseCase {
    func execute(
        query: String,
        location: CLLocationCoordinate2D?
    ) async throws -> [Place]
}

protocol LoadMoreRestaurantsUseCase {
    func execute(
        query: String,
        location: CLLocationCoordinate2D?,
        pageToken: String
    ) async throws -> (places: [Place], nextPageToken: String?)
}

protocol ToggleFavoriteUseCase {
    func execute(placeId: String) async
}

protocol GetPlaceDetailsUseCase {
    func execute(placeId: String) async throws -> PlaceDetail
}
```

### Step 2.2: Implement Use Cases

**File**: `AllTrailsLunch/Sources/Core/UseCases/SearchNearbyRestaurantsUseCaseImpl.swift`

```swift
import Foundation

class SearchNearbyRestaurantsUseCaseImpl: SearchNearbyRestaurantsUseCase {
    private let repository: RestaurantRepositoryProtocol
    
    init(repository: RestaurantRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(
        latitude: Double,
        longitude: Double,
        radius: Int = 1500
    ) async throws -> [Place] {
        let (places, _) = try await repository.searchNearby(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            pageToken: nil
        )
        return places
    }
}
```

**File**: `AllTrailsLunch/Sources/Core/UseCases/SearchRestaurantsByTextUseCaseImpl.swift`

```swift
import Foundation
import CoreLocation

class SearchRestaurantsByTextUseCaseImpl: SearchRestaurantsByTextUseCase {
    private let repository: RestaurantRepositoryProtocol
    
    init(repository: RestaurantRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(
        query: String,
        location: CLLocationCoordinate2D?
    ) async throws -> [Place] {
        let (places, _) = try await repository.searchText(
            query: query,
            latitude: location?.latitude,
            longitude: location?.longitude,
            pageToken: nil
        )
        return places
    }
}
```

**File**: `AllTrailsLunch/Sources/Core/UseCases/ToggleFavoriteUseCaseImpl.swift`

```swift
import Foundation

@MainActor
class ToggleFavoriteUseCaseImpl: ToggleFavoriteUseCase {
    private let favoritesStore: FavoritesStoreProtocol
    
    init(favoritesStore: FavoritesStoreProtocol) {
        self.favoritesStore = favoritesStore
    }
    
    func execute(placeId: String) async {
        favoritesStore.toggleFavorite(placeId)
    }
}
```

### Step 2.3: Update AppConfiguration

**File**: `AllTrailsLunch/Sources/Core/Config/AppConfiguration.swift`

```swift
extension AppConfiguration {
    // MARK: - Use Case Factory Methods
    
    func createSearchNearbyUseCase() -> SearchNearbyRestaurantsUseCase {
        SearchNearbyRestaurantsUseCaseImpl(repository: createRepository())
    }
    
    func createSearchTextUseCase() -> SearchRestaurantsByTextUseCase {
        SearchRestaurantsByTextUseCaseImpl(repository: createRepository())
    }
    
    func createToggleFavoriteUseCase() -> ToggleFavoriteUseCase {
        ToggleFavoriteUseCaseImpl(favoritesStore: createFavoritesStore())
    }
    
    func createGetPlaceDetailsUseCase() -> GetPlaceDetailsUseCase {
        GetPlaceDetailsUseCaseImpl(repository: createRepository())
    }
    
    // Update ViewModel creation
    @MainActor
    func createDiscoveryViewModel() -> DiscoveryViewModel {
        DiscoveryViewModel(
            searchNearbyUseCase: createSearchNearbyUseCase(),
            searchTextUseCase: createSearchTextUseCase(),
            toggleFavoriteUseCase: createToggleFavoriteUseCase(),
            locationManager: createLocationManager(),
            favoritesStore: createFavoritesStore()
        )
    }
}
```

### Step 2.4: Refactor ViewModel to Use Use Cases

**File**: `AllTrailsLunch/Sources/Features/Discovery/DiscoveryViewModel.swift`

```swift
@MainActor
class DiscoveryViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var results: [Place] = []
    @Published var viewMode: ViewMode = .list
    @Published var isLoading: Bool = false
    @Published var error: PlacesError?
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var nextPageToken: String?
    
    // Use cases instead of repository
    private let searchNearbyUseCase: SearchNearbyRestaurantsUseCase
    private let searchTextUseCase: SearchRestaurantsByTextUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let locationManager: LocationManagerProtocol
    private let favoritesStore: FavoritesStoreProtocol
    
    private var searchTask: Task<Void, Never>?
    private var debounceTimer: Timer?
    
    init(
        searchNearbyUseCase: SearchNearbyRestaurantsUseCase,
        searchTextUseCase: SearchRestaurantsByTextUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        locationManager: LocationManagerProtocol,
        favoritesStore: FavoritesStoreProtocol
    ) {
        self.searchNearbyUseCase = searchNearbyUseCase
        self.searchTextUseCase = searchTextUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.locationManager = locationManager
        self.favoritesStore = favoritesStore
    }
    
    // MARK: - Search Operations
    
    private func searchNearby() async {
        guard let location = userLocation else {
            error = .locationPermissionDenied
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let places = try await searchNearbyUseCase.execute(
                latitude: location.latitude,
                longitude: location.longitude,
                radius: 1500
            )
            self.results = places
            self.nextPageToken = nil
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
            let places = try await searchTextUseCase.execute(
                query: query,
                location: userLocation
            )
            self.results = places
            self.nextPageToken = nil
        } catch let error as PlacesError {
            self.error = error
        } catch {
            self.error = .unknown(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    // MARK: - Favorites
    
    func toggleFavorite(_ place: Place) {
        Task {
            await toggleFavoriteUseCase.execute(placeId: place.id)
            
            // Update local state
            if let index = results.firstIndex(where: { $0.id == place.id }) {
                results[index].isFavorite = favoritesStore.isFavorite(place.id)
            }
        }
    }
}
```

---

## Phase 3: Unified State Management

### Step 3.1: Create ViewState Enum

**File**: `AllTrailsLunch/Sources/Core/State/ViewState.swift`

```swift
import Foundation

// MARK: - View State

enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case error(PlacesError)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var data: T? {
        if case .loaded(let data) = self { return data }
        return nil
    }
    
    var error: PlacesError? {
        if case .error(let error) = self { return error }
        return nil
    }
    
    var isEmpty: Bool {
        if case .loaded(let data as [Any]) = self {
            return data.isEmpty
        }
        return false
    }
}

// MARK: - Convenience Extensions

extension ViewState where T: Collection {
    var count: Int {
        data?.count ?? 0
    }
}
```

### Step 3.2: Update ViewModel

**File**: `AllTrailsLunch/Sources/Features/Discovery/DiscoveryViewModel.swift`

```swift
@MainActor
class DiscoveryViewModel: ObservableObject {
    @Published var state: ViewState<[Place]> = .idle
    @Published var searchText: String = ""
    @Published var viewMode: ViewMode = .list
    @Published var userLocation: CLLocationCoordinate2D?
    
    // Computed properties for convenience
    var results: [Place] {
        state.data ?? []
    }
    
    var isLoading: Bool {
        state.isLoading
    }
    
    var error: PlacesError? {
        state.error
    }
    
    private func searchNearby() async {
        state = .loading
        
        do {
            let places = try await searchNearbyUseCase.execute(...)
            state = .loaded(places)
        } catch let error as PlacesError {
            state = .error(error)
        }
    }
}
```

### Step 3.3: Update Views

**File**: `AllTrailsLunch/Sources/Features/Discovery/DiscoveryView.swift`

```swift
struct DiscoveryView: View {
    @ObservedObject var viewModel: DiscoveryViewModel
    
    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.state {
        case .idle:
            EmptyStateView()
        case .loading:
            loadingView
        case .loaded(let places):
            if places.isEmpty {
                EmptyStateView()
            } else {
                resultsView(places: places)
            }
        case .error(let error):
            ErrorView(error: error)
        }
    }
    
    private func resultsView(places: [Place]) -> some View {
        switch viewModel.viewMode {
        case .list:
            ListResultsView(
                places: places,
                isLoading: false,
                onToggleFavorite: viewModel.toggleFavorite,
                onLoadMore: { await viewModel.loadNextPage() }
            )
        case .map:
            MapResultsView(
                places: places,
                onToggleFavorite: viewModel.toggleFavorite
            )
        }
    }
}
```

---

## 🧪 Testing Benefits

With these changes, you can now easily create mocks:

**File**: `AllTrailsLunchTests/Mocks/MockRestaurantRepository.swift`

```swift
class MockRestaurantRepository: RestaurantRepositoryProtocol {
    var searchNearbyResult: (places: [Place], nextPageToken: String?)?
    var searchNearbyError: Error?
    
    func searchNearby(...) async throws -> (places: [Place], nextPageToken: String?) {
        if let error = searchNearbyError {
            throw error
        }
        return searchNearbyResult ?? ([], nil)
    }
}

// Test example
func testSearchNearby() async {
    let mockRepo = MockRestaurantRepository()
    mockRepo.searchNearbyResult = ([testPlace], nil)
    
    let useCase = SearchNearbyRestaurantsUseCaseImpl(repository: mockRepo)
    let viewModel = DiscoveryViewModel(
        searchNearbyUseCase: useCase,
        ...
    )
    
    await viewModel.searchNearby()
    
    XCTAssertEqual(viewModel.results.count, 1)
}
```

---

## 📊 Migration Checklist

- [ ] Create protocol definitions
- [ ] Update existing classes to conform to protocols
- [ ] Create use case protocols
- [ ] Implement use cases
- [ ] Update AppConfiguration factory methods
- [ ] Refactor ViewModel to use protocols and use cases
- [ ] Create ViewState enum
- [ ] Update ViewModel to use ViewState
- [ ] Update Views to handle ViewState
- [ ] Write unit tests for use cases
- [ ] Write unit tests for ViewModels
- [ ] Update documentation

---

## 🎯 Next Steps

After completing these phases, consider:

1. **CoreData Integration** - See ARCHITECTURE_IMPROVEMENTS.md Phase 2
2. **Caching Layer** - Implement memory + disk cache
3. **Coordinator Pattern** - Centralize navigation
4. **Analytics** - Track user behavior
5. **Performance Monitoring** - Measure improvements


