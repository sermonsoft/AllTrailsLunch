# Code Examples

> **Overview**: Key implementation examples demonstrating best practices and design patterns.

---

## 📋 Table of Contents

1. [Type-Safe Analytics](#type-safe-analytics)
2. [Protocol-Based Dependency Injection](#protocol-based-dependency-injection)
3. [Observable State Management](#observable-state-management)
4. [Error Handling](#error-handling)
5. [Async/Await Networking](#asyncawait-networking)
6. [Debounced Search](#debounced-search)
7. [Pagination](#pagination)
8. [Photo Caching](#photo-caching)

---

## 1. Type-Safe Analytics

### Problem
String-based analytics are error-prone and hard to refactor.

### Solution
Use protocol-based events with compile-time checking.

### Implementation

```swift
// Core/Analytics/LoggableEvent.swift

protocol LoggableEvent {
    var name: String { get }
    var parameters: [String: Any] { get }
}

enum AnalyticsEvent: LoggableEvent {
    case searchPerformed(query: String, resultCount: Int)
    case placeSelected(placeId: String, placeName: String)
    case favoriteToggled(placeId: String, isFavorite: Bool)
    case filterApplied(filterType: String, value: String)
    case viewModeChanged(mode: String)
    
    var name: String {
        switch self {
        case .searchPerformed: return "search_performed"
        case .placeSelected: return "place_selected"
        case .favoriteToggled: return "favorite_toggled"
        case .filterApplied: return "filter_applied"
        case .viewModeChanged: return "view_mode_changed"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .searchPerformed(let query, let count):
            return ["query": query, "result_count": count]
        case .placeSelected(let id, let name):
            return ["place_id": id, "place_name": name]
        case .favoriteToggled(let id, let isFavorite):
            return ["place_id": id, "is_favorite": isFavorite]
        case .filterApplied(let type, let value):
            return ["filter_type": type, "value": value]
        case .viewModeChanged(let mode):
            return ["mode": mode]
        }
    }
}

// Usage
eventLogger.log(.searchPerformed(query: "pizza", resultCount: 42))
eventLogger.log(.favoriteToggled(placeId: "123", isFavorite: true))
```

### Benefits
- ✅ Compile-time type checking
- ✅ Autocomplete for event names
- ✅ Easy to refactor
- ✅ Self-documenting

---

## 2. Protocol-Based Dependency Injection

### Problem
Hard-coded dependencies make testing difficult.

### Solution
Use protocols and constructor injection.

### Implementation

```swift
// Core/Services/PlacesService.swift

protocol PlacesService {
    func searchNearby(
        location: CLLocationCoordinate2D,
        radius: Int,
        pageToken: String?
    ) async throws -> PlacesResponse
    
    func searchText(
        query: String,
        location: CLLocationCoordinate2D?,
        pageToken: String?
    ) async throws -> PlacesResponse
}

// Production implementation
class GooglePlacesService: PlacesService {
    private let apiKey: String
    private let session: URLSession
    
    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    func searchNearby(...) async throws -> PlacesResponse {
        // Real API call
    }
}

// Test implementation
class MockPlacesService: PlacesService {
    var searchNearbyResult: Result<PlacesResponse, Error> = .success(.empty)
    
    func searchNearby(...) async throws -> PlacesResponse {
        try searchNearbyResult.get()
    }
}

// Usage in ViewModel
class DiscoveryViewModel {
    private let interactor: CoreInteracting
    
    init(interactor: CoreInteracting) {
        self.interactor = interactor
    }
}

// Production
let viewModel = DiscoveryViewModel(
    interactor: CoreInteractor(
        restaurantManager: RestaurantManager(
            placesService: GooglePlacesService(apiKey: "...")
        )
    )
)

// Testing
let viewModel = DiscoveryViewModel(
    interactor: MockInteractor()
)
```

### Benefits
- ✅ Easy to test with mocks
- ✅ Flexible (swap implementations)
- ✅ Explicit dependencies
- ✅ No hidden dependencies

---

## 3. Observable State Management

### Problem
`@Published` has performance overhead and requires `ObservableObject`.

### Solution
Use modern `@Observable` macro.

### Implementation

```swift
// Core/Managers/FavoritesManager.swift

import Observation

@Observable
class FavoritesManager {
    // Automatically publishes changes
    var favoriteIds: Set<String> = []
    
    private let service: FavoritesService
    
    init(service: FavoritesService) {
        self.service = service
        Task {
            await loadFavorites()
        }
    }
    
    func toggle(_ placeId: String) {
        if favoriteIds.contains(placeId) {
            favoriteIds.remove(placeId)
            Task { try? await service.remove(placeId) }
        } else {
            favoriteIds.insert(placeId)
            Task { try? await service.add(placeId) }
        }
        // UI automatically updates
    }
    
    func isFavorite(_ placeId: String) -> Bool {
        favoriteIds.contains(placeId)
    }
    
    private func loadFavorites() async {
        do {
            let favorites = try await service.getAll()
            favoriteIds = Set(favorites.map(\.id))
        } catch {
            print("Failed to load favorites: \(error)")
        }
    }
}

// Usage in View
struct RestaurantRow: View {
    let place: Place
    @State private var favoritesManager: FavoritesManager
    
    var body: some View {
        HStack {
            Text(place.name)
            Spacer()
            Button {
                favoritesManager.toggle(place.id)
            } label: {
                Image(systemName: favoritesManager.isFavorite(place.id) 
                    ? "heart.fill" 
                    : "heart")
            }
        }
        // Automatically re-renders when favoriteIds changes
    }
}
```

### Benefits
- ✅ Better performance than `@Published`
- ✅ Cleaner syntax (no `ObservableObject`)
- ✅ Automatic UI updates
- ✅ Type-safe

---

## 4. Error Handling

### Problem
Generic errors don't help users recover.

### Solution
Use custom error types with user-friendly messages.

### Implementation

```swift
// Core/Networking/PlacesError.swift

enum PlacesError: LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case rateLimitExceeded
    case locationPermissionDenied
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingError:
            return "Failed to parse server response."
        case .rateLimitExceeded:
            return "Too many requests. Please try again later."
        case .locationPermissionDenied:
            return "Location permission denied. Enable in Settings."
        case .noResults:
            return "No restaurants found nearby."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidAPIKey:
            return "Contact support for a valid API key."
        case .networkError:
            return "Check your internet connection and try again."
        case .invalidResponse, .decodingError:
            return "Try again or contact support if the problem persists."
        case .rateLimitExceeded:
            return "Wait a few minutes before searching again."
        case .locationPermissionDenied:
            return "Go to Settings → Privacy → Location Services."
        case .noResults:
            return "Try a different search query or location."
        }
    }
}

// Usage in ViewModel
@MainActor
class DiscoveryViewModel {
    var errorMessage: String?
    var recoverySuggestion: String?
    
    func performSearch() async {
        do {
            results = try await interactor.searchRestaurants(query: searchQuery)
            errorMessage = nil
        } catch let error as PlacesError {
            errorMessage = error.errorDescription
            recoverySuggestion = error.recoverySuggestion
        } catch {
            errorMessage = "An unexpected error occurred."
            recoverySuggestion = "Please try again."
        }
    }
}

// Usage in View
if let errorMessage = viewModel.errorMessage {
    VStack {
        Text(errorMessage)
            .foregroundColor(.red)
        if let suggestion = viewModel.recoverySuggestion {
            Text(suggestion)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        Button("Retry") {
            Task { await viewModel.performSearch() }
        }
    }
}
```

### Benefits
- ✅ User-friendly error messages
- ✅ Recovery suggestions
- ✅ Type-safe error handling
- ✅ Easy to test

---

## 5. Async/Await Networking

### Problem
Completion handlers lead to callback hell.

### Solution
Use modern async/await.

### Implementation

```swift
// Core/Services/GooglePlacesService.swift

class GooglePlacesService: PlacesService {
    private let apiKey: String
    private let session: URLSession
    
    func searchNearby(
        location: CLLocationCoordinate2D,
        radius: Int = 5000,
        pageToken: String? = nil
    ) async throws -> PlacesResponse {
        // Build request
        let request = try buildNearbyRequest(
            location: location,
            radius: radius,
            pageToken: pageToken
        )
        
        // Perform request with retry
        let (data, response) = try await performWithRetry(request)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlacesError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PlacesError.networkError(
                NSError(domain: "HTTP", code: httpResponse.statusCode)
            )
        }
        
        // Decode response
        do {
            return try JSONDecoder().decode(PlacesResponse.self, from: data)
        } catch {
            throw PlacesError.decodingError(error)
        }
    }
    
    private func performWithRetry(
        _ request: URLRequest,
        maxRetries: Int = 3
    ) async throws -> (Data, URLResponse) {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await session.data(for: request)
            } catch {
                lastError = error
                if attempt < maxRetries - 1 {
                    // Exponential backoff
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? PlacesError.networkError(
            NSError(domain: "Unknown", code: -1)
        )
    }
}
```

### Benefits
- ✅ Clean, linear code flow
- ✅ Easy error handling
- ✅ Automatic retry with exponential backoff
- ✅ No callback hell

---

## 6. Debounced Search

### Problem
Searching on every keystroke wastes API calls.

### Solution
Debounce search with 500ms delay.

### Implementation

```swift
// Features/Discovery/DiscoveryViewModel.swift

@Observable
@MainActor
class DiscoveryViewModel {
    var searchQuery: String = "" {
        didSet {
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
                guard !Task.isCancelled else { return }
                await performSearch()
            }
        }
    }
    
    private var searchTask: Task<Void, Never>?
    
    func performSearch() async {
        guard !searchQuery.isEmpty else {
            await searchNearby()
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            results = try await interactor.searchRestaurants(query: searchQuery)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### Benefits
- ✅ Reduces API calls
- ✅ Better user experience
- ✅ Cancels previous searches
- ✅ Simple implementation

---

## 7. Pagination

### Problem
Loading all results at once is slow.

### Solution
Load results in pages with next_page_token.

### Implementation

```swift
// Features/Discovery/DiscoveryViewModel.swift

@Observable
@MainActor
class DiscoveryViewModel {
    var results: [Place] = []
    var nextPageToken: String?
    var isLoadingMore = false
    
    func loadNextPage() async {
        guard let token = nextPageToken, !isLoadingMore else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let response = try await interactor.loadNextPage(token: token)
            results.append(contentsOf: response.places)
            nextPageToken = response.nextPageToken
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func shouldLoadMore(for place: Place) -> Bool {
        guard let lastPlace = results.last else { return false }
        return place.id == lastPlace.id && nextPageToken != nil
    }
}

// Usage in View
List(viewModel.results) { place in
    RestaurantRow(place: place)
        .task {
            if viewModel.shouldLoadMore(for: place) {
                await viewModel.loadNextPage()
            }
        }
}
```

### Benefits
- ✅ Fast initial load
- ✅ Smooth scrolling
- ✅ Automatic loading
- ✅ Efficient memory usage

---

## 8. Photo Caching

### Problem
Re-downloading photos wastes bandwidth and is slow.

### Solution
In-memory cache with NSCache.

### Implementation

```swift
// Core/Managers/PhotoManager.swift

@Observable
class PhotoManager {
    private let cache = NSCache<NSString, UIImage>()
    private let placesService: PlacesService
    private var loadingTasks: [String: Task<UIImage?, Never>] = [:]
    
    func loadPhoto(
        reference: String,
        maxWidth: Int = 400,
        maxHeight: Int = 400
    ) async -> UIImage? {
        // Check cache first
        if let cached = cache.object(forKey: reference as NSString) {
            return cached
        }
        
        // Check if already loading
        if let existingTask = loadingTasks[reference] {
            return await existingTask.value
        }
        
        // Create new loading task
        let task = Task {
            await loadPhotoFromNetwork(
                reference: reference,
                maxWidth: maxWidth,
                maxHeight: maxHeight
            )
        }
        loadingTasks[reference] = task
        
        let image = await task.value
        loadingTasks.removeValue(forKey: reference)
        
        // Cache result
        if let image = image {
            cache.setObject(image, forKey: reference as NSString)
        }
        
        return image
    }
    
    private func loadPhotoFromNetwork(
        reference: String,
        maxWidth: Int,
        maxHeight: Int
    ) async -> UIImage? {
        do {
            let data = try await placesService.getPhoto(
                reference: reference,
                maxWidth: maxWidth,
                maxHeight: maxHeight
            )
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
```

### Benefits
- ✅ Fast photo loading
- ✅ Automatic memory management
- ✅ Prevents duplicate requests
- ✅ Easy to clear cache

---

## 📚 Summary

These examples demonstrate:

1. **Type Safety**: Compile-time checks prevent runtime errors
2. **Modern Swift**: @Observable, async/await, protocols
3. **Error Handling**: User-friendly messages with recovery
4. **Performance**: Debouncing, caching, pagination
5. **Testability**: Protocol-based design, dependency injection
6. **Clean Code**: Clear, maintainable, well-documented

**See the actual implementation in the codebase for complete details.**

