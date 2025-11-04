# Architecture Improvements for AllTrails Lunch

## 📊 Current Architecture Analysis

### ✅ What's Already Good

Your current architecture follows solid patterns:

1. **MVVM Pattern** - DiscoveryViewModel manages state
2. **Repository Pattern** - RestaurantRepository abstracts data access
3. **Dependency Injection** - AppConfiguration factory pattern
4. **Async/Await** - Modern Swift concurrency
5. **Clean Separation** - Core, Features, App structure
6. **Network Logging** - Comprehensive debugging system
7. **Multi-Environment** - Build configurations (Mock, Dev, Staging, Prod, Store)

### 🎯 Comparison with AIChatCourse Architecture

**AIChatCourse** (UIKit + MVVM + CoreData):
- ✅ MVVM with clear separation
- ✅ CoreData for persistence
- ✅ Coordinator pattern for navigation
- ✅ Service layer abstraction
- ✅ Protocol-oriented design
- ✅ Comprehensive error handling

**AllTrails Lunch** (SwiftUI + MVVM):
- ✅ MVVM with @Published properties
- ⚠️ UserDefaults for persistence (limited)
- ⚠️ NavigationStack (basic navigation)
- ✅ Repository pattern
- ⚠️ Some protocol usage, could be expanded
- ✅ Good error handling

---

## 🚀 Recommended Improvements

### 1. **Protocol-Oriented Architecture** ⭐⭐⭐

**Problem**: Direct dependencies on concrete types make testing difficult and reduce flexibility.

**Current**:
```swift
class DiscoveryViewModel: ObservableObject {
    private let repository: RestaurantRepository
    private let locationManager: LocationManager
    private let favoritesStore: FavoritesStore
}
```

**Improved**:
```swift
// Define protocols
protocol RestaurantRepositoryProtocol {
    func searchNearby(latitude: Double, longitude: Double, radius: Int, pageToken: String?) async throws -> (places: [Place], nextPageToken: String?)
    func searchText(query: String, latitude: Double?, longitude: Double?, pageToken: String?) async throws -> (places: [Place], nextPageToken: String?)
    func getPlaceDetails(placeId: String) async throws -> PlaceDetail
}

protocol LocationManagerProtocol {
    func requestLocationPermission() async throws -> CLLocationCoordinate2D
}

protocol FavoritesStoreProtocol: ObservableObject {
    var favoriteIds: Set<String> { get }
    func isFavorite(_ placeId: String) -> Bool
    func toggleFavorite(_ placeId: String)
}

// Use protocols in ViewModel
class DiscoveryViewModel: ObservableObject {
    private let repository: RestaurantRepositoryProtocol
    private let locationManager: LocationManagerProtocol
    private let favoritesStore: any FavoritesStoreProtocol
}
```

**Benefits**:
- ✅ Easy to create mock implementations for testing
- ✅ Swap implementations without changing ViewModel
- ✅ Better separation of concerns
- ✅ Follows SOLID principles

---

### 2. **Use Case / Interactor Layer** ⭐⭐⭐

**Problem**: ViewModels contain too much business logic, making them hard to test and reuse.

**Current**: ViewModel handles search logic directly

**Improved**: Extract use cases

```swift
// MARK: - Use Cases

protocol SearchNearbyRestaurantsUseCase {
    func execute(latitude: Double, longitude: Double, radius: Int) async throws -> [Place]
}

class SearchNearbyRestaurantsUseCaseImpl: SearchNearbyRestaurantsUseCase {
    private let repository: RestaurantRepositoryProtocol
    
    init(repository: RestaurantRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(latitude: Double, longitude: Double, radius: Int = 1500) async throws -> [Place] {
        let (places, _) = try await repository.searchNearby(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            pageToken: nil
        )
        return places
    }
}

protocol SearchRestaurantsByTextUseCase {
    func execute(query: String, location: CLLocationCoordinate2D?) async throws -> [Place]
}

protocol ToggleFavoriteUseCase {
    func execute(placeId: String) async
}

// ViewModel becomes simpler
class DiscoveryViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var results: [Place] = []
    @Published var isLoading: Bool = false
    @Published var error: PlacesError?
    
    private let searchNearbyUseCase: SearchNearbyRestaurantsUseCase
    private let searchTextUseCase: SearchRestaurantsByTextUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    
    func searchNearby() async {
        isLoading = true
        error = nil
        
        do {
            results = try await searchNearbyUseCase.execute(
                latitude: userLocation.latitude,
                longitude: userLocation.longitude,
                radius: 1500
            )
        } catch let error as PlacesError {
            self.error = error
        }
        
        isLoading = false
    }
}
```

**Benefits**:
- ✅ Single Responsibility Principle
- ✅ Reusable business logic
- ✅ Easier to test
- ✅ Clear separation of concerns

---

### 3. **CoreData for Persistence** ⭐⭐

**Problem**: UserDefaults is limited for complex data and doesn't support relationships.

**Current**:
```swift
class FavoritesStore: ObservableObject {
    @Published private(set) var favoriteIds: Set<String> = []
    private let userDefaults: UserDefaults
}
```

**Improved**: Use CoreData

```swift
// CoreData Entity
@objc(FavoritePlace)
public class FavoritePlace: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var rating: Double
    @NSManaged public var address: String?
    @NSManaged public var addedDate: Date
    @NSManaged public var lastViewedDate: Date?
}

// CoreData Manager
protocol CoreDataManagerProtocol {
    var viewContext: NSManagedObjectContext { get }
    func save() throws
}

class CoreDataManager: CoreDataManagerProtocol {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AllTrailsLunch")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData error: \(error)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func save() throws {
        if viewContext.hasChanges {
            try viewContext.save()
        }
    }
}

// Enhanced FavoritesStore with CoreData
@MainActor
class FavoritesStore: ObservableObject {
    @Published private(set) var favorites: [FavoritePlace] = []
    
    private let coreDataManager: CoreDataManagerProtocol
    
    init(coreDataManager: CoreDataManagerProtocol = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
        loadFavorites()
    }
    
    func loadFavorites() {
        let request: NSFetchRequest<FavoritePlace> = FavoritePlace.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "addedDate", ascending: false)]
        
        do {
            favorites = try coreDataManager.viewContext.fetch(request)
        } catch {
            print("Error loading favorites: \(error)")
        }
    }
    
    func toggleFavorite(_ place: Place) {
        if let existing = favorites.first(where: { $0.id == place.id }) {
            coreDataManager.viewContext.delete(existing)
        } else {
            let favorite = FavoritePlace(context: coreDataManager.viewContext)
            favorite.id = place.id
            favorite.name = place.name
            favorite.rating = place.rating ?? 0
            favorite.address = place.address
            favorite.addedDate = Date()
        }
        
        try? coreDataManager.save()
        loadFavorites()
    }
}
```

**Benefits**:
- ✅ Store complete Place objects, not just IDs
- ✅ Support for relationships (e.g., favorite lists, tags)
- ✅ Better performance for large datasets
- ✅ Offline-first architecture
- ✅ Search history, recent searches
- ✅ Cache API responses

---

### 4. **Coordinator Pattern for Navigation** ⭐⭐

**Problem**: Navigation logic scattered across views makes it hard to manage complex flows.

**Current**: NavigationLink in views

**Improved**: Coordinator pattern

```swift
// MARK: - Coordinator Protocol

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    func start()
}

// MARK: - App Coordinator

class AppCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let appConfiguration: AppConfiguration
    
    init(navigationController: UINavigationController, appConfiguration: AppConfiguration) {
        self.navigationController = navigationController
        self.appConfiguration = appConfiguration
    }
    
    func start() {
        showDiscovery()
    }
    
    func showDiscovery() {
        let viewModel = appConfiguration.createDiscoveryViewModel()
        viewModel.coordinator = self
        let view = DiscoveryView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        navigationController.setViewControllers([hostingController], animated: false)
    }
    
    func showRestaurantDetail(_ place: Place) {
        let view = RestaurantDetailView(place: place)
        let hostingController = UIHostingController(rootView: view)
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    func showFavorites() {
        // Navigate to favorites screen
    }
}

// ViewModel with coordinator
class DiscoveryViewModel: ObservableObject {
    weak var coordinator: AppCoordinator?
    
    func didSelectPlace(_ place: Place) {
        coordinator?.showRestaurantDetail(place)
    }
}
```

**Benefits**:
- ✅ Centralized navigation logic
- ✅ Easier to test navigation flows
- ✅ Support for deep linking
- ✅ Better control over navigation stack

---

### 5. **Caching Layer** ⭐⭐⭐

**Problem**: No caching means repeated API calls for same data.

**Improved**: Add caching layer

```swift
// MARK: - Cache Protocol

protocol CacheProtocol {
    func get<T: Codable>(forKey key: String) -> T?
    func set<T: Codable>(_ value: T, forKey key: String, expiration: TimeInterval?)
    func remove(forKey key: String)
    func clearAll()
}

// MARK: - Memory + Disk Cache

class CacheManager: CacheProtocol {
    private let memoryCache = NSCache<NSString, CacheEntry>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("PlacesCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func get<T: Codable>(forKey key: String) -> T? {
        // Check memory cache first
        if let entry = memoryCache.object(forKey: key as NSString) {
            if !entry.isExpired {
                return entry.value as? T
            }
        }
        
        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: fileURL),
              let entry = try? JSONDecoder().decode(CacheEntry.self, from: data),
              !entry.isExpired else {
            return nil
        }
        
        // Restore to memory cache
        memoryCache.setObject(entry, forKey: key as NSString)
        return entry.value as? T
    }
    
    func set<T: Codable>(_ value: T, forKey key: String, expiration: TimeInterval? = 300) {
        let entry = CacheEntry(value: value, expiration: expiration)
        
        // Save to memory
        memoryCache.setObject(entry, forKey: key as NSString)
        
        // Save to disk
        let fileURL = cacheDirectory.appendingPathComponent(key)
        if let data = try? JSONEncoder().encode(entry) {
            try? data.write(to: fileURL)
        }
    }
}

// Enhanced Repository with caching
class RestaurantRepository: RestaurantRepositoryProtocol {
    private let placesClient: PlacesClient
    private let favoritesStore: FavoritesStoreProtocol
    private let cache: CacheProtocol
    
    func searchNearby(...) async throws -> (places: [Place], nextPageToken: String?) {
        let cacheKey = "nearby_\(latitude)_\(longitude)_\(radius)"
        
        // Check cache first
        if let cached: (places: [Place], nextPageToken: String?) = cache.get(forKey: cacheKey) {
            return cached
        }
        
        // Fetch from API
        let result = try await fetchFromAPI(...)
        
        // Cache result (5 minutes)
        cache.set(result, forKey: cacheKey, expiration: 300)
        
        return result
    }
}
```

**Benefits**:
- ✅ Reduced API calls
- ✅ Faster app performance
- ✅ Offline support
- ✅ Lower data usage

---

### 6. **State Management Improvements** ⭐⭐

**Problem**: State scattered across multiple @Published properties.

**Improved**: Unified state enum

```swift
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
}

// ViewModel with unified state
class DiscoveryViewModel: ObservableObject {
    @Published var state: ViewState<[Place]> = .idle
    @Published var searchText: String = ""
    @Published var viewMode: ViewMode = .list
    
    func searchNearby() async {
        state = .loading
        
        do {
            let places = try await searchNearbyUseCase.execute(...)
            state = .loaded(places)
        } catch let error as PlacesError {
            state = .error(error)
        }
    }
}

// View with cleaner state handling
struct DiscoveryView: View {
    @ObservedObject var viewModel: DiscoveryViewModel
    
    var body: some View {
        switch viewModel.state {
        case .idle:
            EmptyStateView()
        case .loading:
            ProgressView()
        case .loaded(let places):
            ResultsView(places: places)
        case .error(let error):
            ErrorView(error: error)
        }
    }
}
```

**Benefits**:
- ✅ Clearer state transitions
- ✅ Impossible states become impossible
- ✅ Easier to reason about
- ✅ Better error handling

---

## 📋 Implementation Priority

### Phase 1: Foundation (Week 1-2) ⭐⭐⭐
1. **Protocol-Oriented Architecture** - Define protocols for all services
2. **Use Case Layer** - Extract business logic from ViewModels
3. **Unified State Management** - Implement ViewState enum

### Phase 2: Persistence (Week 3) ⭐⭐
4. **CoreData Integration** - Replace UserDefaults with CoreData
5. **Caching Layer** - Implement memory + disk cache

### Phase 3: Navigation (Week 4) ⭐
6. **Coordinator Pattern** - Centralize navigation logic

---

## 🎯 Expected Outcomes

After implementing these improvements:

✅ **Better Testability** - 80%+ code coverage possible
✅ **Improved Performance** - 50% reduction in API calls
✅ **Offline Support** - App works without internet
✅ **Cleaner Code** - 30% reduction in ViewModel complexity
✅ **Easier Maintenance** - Clear separation of concerns
✅ **Scalability** - Easy to add new features

---

## 📚 Additional Resources

- [Swift Protocol-Oriented Programming](https://developer.apple.com/videos/play/wwdc2015/408/)
- [Clean Architecture in iOS](https://clean-swift.com/)
- [CoreData Best Practices](https://developer.apple.com/documentation/coredata)
- [Coordinator Pattern](https://www.hackingwithswift.com/articles/71/how-to-use-the-coordinator-pattern-in-ios-apps)


