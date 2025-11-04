# VIPER Implementation Guide for AllTrails Lunch

## 🚀 Step-by-Step Migration from MVVM to VIPER-like Architecture

This guide shows how to apply VIPER patterns from lesson_151_starter_project to your AllTrails Lunch app.

---

## Phase 1: Manager Layer (Week 1)

### Step 1.1: Create Service Protocols

**File**: `AllTrailsLunch/Sources/Core/Services/PlacesService.swift`

```swift
import Foundation
import CoreLocation

// MARK: - Service Protocols

protocol RemotePlacesService {
    func searchNearby(
        latitude: Double,
        longitude: Double,
        radius: Int
    ) async throws -> [PlaceDTO]
    
    func searchText(
        query: String,
        latitude: Double?,
        longitude: Double?
    ) async throws -> [PlaceDTO]
    
    func getPlaceDetails(placeId: String) async throws -> PlaceDetailDTO
}

protocol LocalPlacesCache {
    func getCachedPlaces(location: CLLocationCoordinate2D, radius: Int) throws -> [Place]?
    func cachePlaces(_ places: [Place], location: CLLocationCoordinate2D, radius: Int) throws
    func clearCache()
}

protocol FavoritesService {
    func getFavoriteIds() -> Set<String>
    func saveFavoriteIds(_ ids: Set<String>) throws
    func isFavorite(_ placeId: String) -> Bool
    func addFavorite(_ placeId: String) throws
    func removeFavorite(_ placeId: String) throws
}
```

### Step 1.2: Implement Services

**File**: `AllTrailsLunch/Sources/Core/Services/GooglePlacesService.swift`

```swift
import Foundation

class GooglePlacesService: RemotePlacesService {
    private let client: PlacesClient
    
    init(client: PlacesClient) {
        self.client = client
    }
    
    func searchNearby(
        latitude: Double,
        longitude: Double,
        radius: Int
    ) async throws -> [PlaceDTO] {
        let url = try client.buildNearbySearchURL(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            pageToken: nil
        )
        
        let request = try PlacesRequestBuilder()
            .setURL(url)
            .setMethod(.get)
            .build()
        
        let response: NearbySearchResponse = try await client.execute(request)
        return response.results
    }
    
    func searchText(
        query: String,
        latitude: Double?,
        longitude: Double?
    ) async throws -> [PlaceDTO] {
        let url = try client.buildTextSearchURL(
            query: query,
            latitude: latitude,
            longitude: longitude,
            pageToken: nil
        )
        
        let request = try PlacesRequestBuilder()
            .setURL(url)
            .setMethod(.get)
            .build()
        
        let response: TextSearchResponse = try await client.execute(request)
        return response.results
    }
    
    func getPlaceDetails(placeId: String) async throws -> PlaceDetailDTO {
        let url = try client.buildPlaceDetailsURL(placeId: placeId)
        let request = try PlacesRequestBuilder()
            .setURL(url)
            .setMethod(.get)
            .build()
        
        let response: PlaceDetailsResponse = try await client.execute(request)
        return response.result
    }
}
```

**File**: `AllTrailsLunch/Sources/Core/Services/UserDefaultsFavoritesService.swift`

```swift
import Foundation

class UserDefaultsFavoritesService: FavoritesService {
    private let userDefaults: UserDefaults
    private let favoritesKey = "com.alltrailslunch.favorites"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func getFavoriteIds() -> Set<String> {
        guard let data = userDefaults.data(forKey: favoritesKey),
              let ids = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return []
        }
        return ids
    }
    
    func saveFavoriteIds(_ ids: Set<String>) throws {
        let data = try JSONEncoder().encode(ids)
        userDefaults.set(data, forKey: favoritesKey)
    }
    
    func isFavorite(_ placeId: String) -> Bool {
        getFavoriteIds().contains(placeId)
    }
    
    func addFavorite(_ placeId: String) throws {
        var ids = getFavoriteIds()
        ids.insert(placeId)
        try saveFavoriteIds(ids)
    }
    
    func removeFavorite(_ placeId: String) throws {
        var ids = getFavoriteIds()
        ids.remove(placeId)
        try saveFavoriteIds(ids)
    }
}
```

### Step 1.3: Create Managers

**File**: `AllTrailsLunch/Sources/Core/Managers/RestaurantManager.swift`

```swift
import Foundation
import CoreLocation

@MainActor
@Observable
class RestaurantManager {
    private let remote: RemotePlacesService
    private let cache: LocalPlacesCache?
    private let favorites: FavoritesManager
    
    init(
        remote: RemotePlacesService,
        cache: LocalPlacesCache? = nil,
        favorites: FavoritesManager
    ) {
        self.remote = remote
        self.cache = cache
        self.favorites = favorites
    }
    
    func searchNearby(
        location: CLLocationCoordinate2D,
        radius: Int = 1500
    ) async throws -> [Place] {
        // Check cache first
        if let cached = try? cache?.getCachedPlaces(location: location, radius: radius) {
            return cached
        }
        
        // Fetch from remote
        let dtos = try await remote.searchNearby(
            latitude: location.latitude,
            longitude: location.longitude,
            radius: radius
        )
        
        // Convert to domain models
        let places = dtos.map { Place(from: $0) }
        
        // Apply favorite status
        let placesWithFavorites = await favorites.applyFavoriteStatus(to: places)
        
        // Cache results
        try? cache?.cachePlaces(placesWithFavorites, location: location, radius: radius)
        
        return placesWithFavorites
    }
    
    func searchText(
        query: String,
        location: CLLocationCoordinate2D?
    ) async throws -> [Place] {
        let dtos = try await remote.searchText(
            query: query,
            latitude: location?.latitude,
            longitude: location?.longitude
        )
        
        let places = dtos.map { Place(from: $0) }
        return await favorites.applyFavoriteStatus(to: places)
    }
    
    func getPlaceDetails(placeId: String) async throws -> PlaceDetail {
        let dto = try await remote.getPlaceDetails(placeId: placeId)
        var detail = PlaceDetail(from: dto)
        detail.isFavorite = favorites.isFavorite(placeId)
        return detail
    }
}
```

**File**: `AllTrailsLunch/Sources/Core/Managers/FavoritesManager.swift`

```swift
import Foundation

@MainActor
@Observable
class FavoritesManager {
    private let service: FavoritesService
    
    private(set) var favoriteIds: Set<String> = []
    
    init(service: FavoritesService) {
        self.service = service
        self.favoriteIds = service.getFavoriteIds()
    }
    
    func isFavorite(_ placeId: String) -> Bool {
        favoriteIds.contains(placeId)
    }
    
    func toggleFavorite(_ placeId: String) {
        if favoriteIds.contains(placeId) {
            favoriteIds.remove(placeId)
            try? service.removeFavorite(placeId)
        } else {
            favoriteIds.insert(placeId)
            try? service.addFavorite(placeId)
        }
    }
    
    func applyFavoriteStatus(to places: [Place]) async -> [Place] {
        places.map { place in
            var updatedPlace = place
            updatedPlace.isFavorite = isFavorite(place.id)
            return updatedPlace
        }
    }
}
```

---

## Phase 2: Interactor Layer (Week 2)

### Step 2.1: Create Global Interactor

**File**: `AllTrailsLunch/Sources/Core/Interactor/GlobalInteractor.swift`

```swift
import Foundation

@MainActor
protocol GlobalInteractor {
    func trackEvent(event: LoggableEvent)
}

protocol LoggableEvent {
    var eventName: String { get }
    var parameters: [String: Any]? { get }
    var type: LogType { get }
}

enum LogType {
    case analytic
    case warning
    case severe
}
```

### Step 2.2: Create Screen-Specific Interactors

**File**: `AllTrailsLunch/Sources/Features/Discovery/DiscoveryInteractor.swift`

```swift
import Foundation
import CoreLocation

@MainActor
protocol DiscoveryInteractor: GlobalInteractor {
    var userLocation: CLLocationCoordinate2D? { get }
    var favoriteIds: Set<String> { get }
    
    func requestLocationPermission() async throws -> CLLocationCoordinate2D
    func searchNearby(location: CLLocationCoordinate2D, radius: Int) async throws -> [Place]
    func searchText(query: String, location: CLLocationCoordinate2D?) async throws -> [Place]
    func toggleFavorite(placeId: String)
}
```

### Step 2.3: Create Core Interactor

**File**: `AllTrailsLunch/Sources/Core/Interactor/CoreInteractor.swift`

```swift
import Foundation
import CoreLocation

@MainActor
struct CoreInteractor {
    private let restaurantManager: RestaurantManager
    private let locationManager: LocationManager
    private let favoritesManager: FavoritesManager
    private let logManager: LogManager?
    
    init(container: DependencyContainer) {
        self.restaurantManager = container.resolve(RestaurantManager.self)!
        self.locationManager = container.resolve(LocationManager.self)!
        self.favoritesManager = container.resolve(FavoritesManager.self)!
        self.logManager = container.resolve(LogManager.self)
    }
}

// MARK: - GlobalInteractor

extension CoreInteractor: GlobalInteractor {
    func trackEvent(event: LoggableEvent) {
        logManager?.trackEvent(event: event)
    }
}

// MARK: - DiscoveryInteractor

extension CoreInteractor: DiscoveryInteractor {
    var userLocation: CLLocationCoordinate2D? {
        locationManager.userLocation
    }
    
    var favoriteIds: Set<String> {
        favoritesManager.favoriteIds
    }
    
    func requestLocationPermission() async throws -> CLLocationCoordinate2D {
        try await locationManager.requestLocationPermission()
    }
    
    func searchNearby(location: CLLocationCoordinate2D, radius: Int) async throws -> [Place] {
        try await restaurantManager.searchNearby(location: location, radius: radius)
    }
    
    func searchText(query: String, location: CLLocationCoordinate2D?) async throws -> [Place] {
        try await restaurantManager.searchText(query: query, location: location)
    }
    
    func toggleFavorite(placeId: String) {
        favoritesManager.toggleFavorite(placeId)
    }
}
```

---

## Phase 3: Router Layer (Week 3)

### Step 3.1: Create Global Router

**File**: `AllTrailsLunch/Sources/Core/Router/GlobalRouter.swift`

```swift
import SwiftUI

@MainActor
protocol GlobalRouter {
    func showAlert(error: Error)
    func showAlert(
        _ style: AlertStyle,
        title: String,
        subtitle: String?,
        buttons: (() -> AnyView)?
    )
    func dismissScreen()
    func dismissModal()
}

enum AlertStyle {
    case alert
    case confirmationDialog
}
```

### Step 3.2: Create Screen-Specific Routers

**File**: `AllTrailsLunch/Sources/Features/Discovery/DiscoveryRouter.swift`

```swift
import SwiftUI

@MainActor
protocol DiscoveryRouter: GlobalRouter {
    func showRestaurantDetail(place: Place)
    func showMapView()
    func showListView()
}
```

### Step 3.3: Create Core Router

**File**: `AllTrailsLunch/Sources/Core/Router/CoreRouter.swift`

```swift
import SwiftUI

@MainActor
struct CoreRouter: DiscoveryRouter {
    let router: AnyRouter
    let builder: CoreBuilder
    
    // MARK: - GlobalRouter
    
    func showAlert(error: Error) {
        router.showAlert(error: error)
    }
    
    func showAlert(
        _ style: AlertStyle,
        title: String,
        subtitle: String?,
        buttons: (() -> AnyView)?
    ) {
        // Implementation
    }
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    func dismissModal() {
        router.dismissModal()
    }
    
    // MARK: - DiscoveryRouter
    
    func showRestaurantDetail(place: Place) {
        router.showScreen(.push) { router in
            builder.restaurantDetailView(router: router, place: place)
        }
    }
    
    func showMapView() {
        // Implementation
    }
    
    func showListView() {
        // Implementation
    }
}
```

---

## Phase 4: Presenter Layer (Week 4)

### Step 4.1: Convert ViewModel to Presenter

**File**: `AllTrailsLunch/Sources/Features/Discovery/DiscoveryPresenter.swift`

```swift
import SwiftUI
import CoreLocation

@Observable
@MainActor
class DiscoveryPresenter {
    private let interactor: DiscoveryInteractor
    private let router: DiscoveryRouter
    
    // State
    private(set) var results: [Place] = []
    private(set) var isLoading: Bool = false
    private(set) var error: PlacesError?
    private(set) var userLocation: CLLocationCoordinate2D?
    
    // Input
    var searchText: String = ""
    var viewMode: ViewMode = .list
    
    private var searchTask: Task<Void, Never>?
    private var debounceTimer: Timer?
    
    init(interactor: DiscoveryInteractor, router: DiscoveryRouter) {
        self.interactor = interactor
        self.router = router
    }
    
    // MARK: - View Lifecycle
    
    func onViewAppear() {
        Task {
            await requestLocation()
        }
    }
    
    // MARK: - Location
    
    func requestLocation() async {
        interactor.trackEvent(event: Event.requestLocationStart)
        
        do {
            let location = try await interactor.requestLocationPermission()
            self.userLocation = location
            interactor.trackEvent(event: Event.requestLocationSuccess)
            
            await searchNearby()
        } catch {
            self.error = .locationPermissionDenied
            interactor.trackEvent(event: Event.requestLocationFail(error: error))
        }
    }
    
    // MARK: - Search
    
    func onSearchTextChanged() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.performSearch()
            }
        }
    }
    
    private func performSearch() async {
        searchTask?.cancel()
        
        guard !searchText.isEmpty else {
            await searchNearby()
            return
        }
        
        searchTask = Task {
            await searchText(searchText)
        }
    }
    
    private func searchNearby() async {
        guard let location = userLocation else { return }
        
        isLoading = true
        error = nil
        interactor.trackEvent(event: Event.searchNearbyStart)
        
        do {
            let places = try await interactor.searchNearby(location: location, radius: 1500)
            self.results = places
            interactor.trackEvent(event: Event.searchNearbySuccess(count: places.count))
        } catch let error as PlacesError {
            self.error = error
            interactor.trackEvent(event: Event.searchNearbyFail(error: error))
        }
        
        isLoading = false
    }
    
    private func searchText(_ query: String) async {
        isLoading = true
        error = nil
        interactor.trackEvent(event: Event.searchTextStart(query: query))
        
        do {
            let places = try await interactor.searchText(query: query, location: userLocation)
            self.results = places
            interactor.trackEvent(event: Event.searchTextSuccess(query: query, count: places.count))
        } catch let error as PlacesError {
            self.error = error
            interactor.trackEvent(event: Event.searchTextFail(error: error))
        }
        
        isLoading = false
    }
    
    // MARK: - Actions
    
    func toggleFavorite(_ place: Place) {
        interactor.trackEvent(event: Event.toggleFavorite(place: place))
        interactor.toggleFavorite(placeId: place.id)
        
        // Update local state
        if let index = results.firstIndex(where: { $0.id == place.id }) {
            results[index].isFavorite = interactor.favoriteIds.contains(place.id)
        }
    }
    
    func onPlaceSelected(_ place: Place) {
        interactor.trackEvent(event: Event.placeSelected(place: place))
        router.showRestaurantDetail(place: place)
    }
    
    func onViewModeChanged(_ mode: ViewMode) {
        interactor.trackEvent(event: Event.viewModeChanged(mode: mode))
        viewMode = mode
    }
    
    // MARK: - Events
    
    enum Event: LoggableEvent {
        case requestLocationStart
        case requestLocationSuccess
        case requestLocationFail(error: Error)
        case searchNearbyStart
        case searchNearbySuccess(count: Int)
        case searchNearbyFail(error: Error)
        case searchTextStart(query: String)
        case searchTextSuccess(query: String, count: Int)
        case searchTextFail(error: Error)
        case toggleFavorite(place: Place)
        case placeSelected(place: Place)
        case viewModeChanged(mode: ViewMode)
        
        var eventName: String {
            switch self {
            case .requestLocationStart: return "Discovery_RequestLocation_Start"
            case .requestLocationSuccess: return "Discovery_RequestLocation_Success"
            case .requestLocationFail: return "Discovery_RequestLocation_Fail"
            case .searchNearbyStart: return "Discovery_SearchNearby_Start"
            case .searchNearbySuccess: return "Discovery_SearchNearby_Success"
            case .searchNearbyFail: return "Discovery_SearchNearby_Fail"
            case .searchTextStart: return "Discovery_SearchText_Start"
            case .searchTextSuccess: return "Discovery_SearchText_Success"
            case .searchTextFail: return "Discovery_SearchText_Fail"
            case .toggleFavorite: return "Discovery_ToggleFavorite"
            case .placeSelected: return "Discovery_PlaceSelected"
            case .viewModeChanged: return "Discovery_ViewModeChanged"
            }
        }
        
        var parameters: [String: Any]? {
            switch self {
            case .searchNearbySuccess(let count), .searchTextSuccess(_, let count):
                return ["count": count]
            case .searchTextStart(let query), .searchTextSuccess(let query, _):
                return ["query": query]
            case .toggleFavorite(let place), .placeSelected(let place):
                return place.eventParameters
            case .viewModeChanged(let mode):
                return ["mode": mode.rawValue]
            default:
                return nil
            }
        }
        
        var type: LogType {
            switch self {
            case .requestLocationFail, .searchNearbyFail, .searchTextFail:
                return .warning
            default:
                return .analytic
            }
        }
    }
}
```

---

See [VIPER_ARCHITECTURE_ANALYSIS.md](VIPER_ARCHITECTURE_ANALYSIS.md) for detailed pattern explanations.


