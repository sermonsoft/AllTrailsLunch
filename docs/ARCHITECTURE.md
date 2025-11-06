# Architecture Guide

> **Overview**: This document explains the architectural decisions and design patterns used in the AllTrails Lunch app.

---

## 📐 Architecture Overview

### 5-Layer Clean Architecture (VIPER-Inspired)

```
┌─────────────────────────────────────────────────────────────┐
│                    VIEW LAYER (SwiftUI)                     │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────┐ │
│  │ DiscoveryView   │  │ DetailView       │  │ MapView    │ │
│  │ - UI Components │  │ - Restaurant     │  │ - Map      │ │
│  │ - User Input    │  │   Details        │  │   Display  │ │
│  └─────────────────┘  └──────────────────┘  └────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│              VIEWMODEL LAYER (@Observable)                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ DiscoveryViewModel                                  │   │
│  │ - @Published state properties                       │   │
│  │ - User action handlers                              │   │
│  │ - UI state transformations                          │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│               INTERACTOR LAYER (Business Logic)             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ CoreInteractor (Protocol)                           │   │
│  │ - Coordinates between managers                      │   │
│  │ - Implements business rules                         │   │
│  │ - Handles complex workflows                         │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│            MANAGER LAYER (Data Coordination)                │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │ Restaurant   │  │ Favorites    │  │ Photo           │  │
│  │ Manager      │  │ Manager      │  │ Manager         │  │
│  │ - Search     │  │ - Add/Remove │  │ - Load/Cache    │  │
│  │ - Details    │  │ - Persist    │  │ - Memory Mgmt   │  │
│  └──────────────┘  └──────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│              SERVICE LAYER (External APIs)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │ Places       │  │ SwiftData    │  │ Location        │  │
│  │ Service      │  │ Service      │  │ Service         │  │
│  │ - API calls  │  │ - Persistence│  │ - GPS           │  │
│  └──────────────┘  └──────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Design Principles

### 1. Separation of Concerns

Each layer has a single, well-defined responsibility:

- **View**: Displays UI, captures user input
- **ViewModel**: Manages UI state, transforms data for display
- **Interactor**: Implements business logic, coordinates managers
- **Manager**: Coordinates data operations, maintains state
- **Service**: Handles external APIs, persistence, system services

### 2. Dependency Inversion

All dependencies point inward (toward business logic):

```swift
// ✅ Good: ViewModel depends on protocol
class DiscoveryViewModel {
    private let interactor: CoreInteracting  // Protocol
    
    init(interactor: CoreInteracting) {
        self.interactor = interactor
    }
}

// ❌ Bad: ViewModel depends on concrete implementation
class DiscoveryViewModel {
    private let interactor = CoreInteractor()  // Concrete class
}
```

### 3. Protocol-Oriented Design

All services are defined as protocols for testability:

```swift
// Service protocol
protocol PlacesService {
    func searchNearby(location: CLLocationCoordinate2D) async throws -> [Place]
}

// Production implementation
class GooglePlacesService: PlacesService { ... }

// Test implementation
class MockPlacesService: PlacesService { ... }
```

### 4. Observable State Management

Uses modern `@Observable` macro for reactive UI:

```swift
@Observable
class FavoritesManager {
    var favoriteIds: Set<String> = []  // Auto-publishes changes
    
    func toggle(_ placeId: String) {
        if favoriteIds.contains(placeId) {
            favoriteIds.remove(placeId)
        } else {
            favoriteIds.insert(placeId)
        }
        // UI automatically updates
    }
}
```

---

## 📦 Layer Details

### View Layer

**Responsibility**: Display UI and capture user input

**Key Files**:
- `Features/Discovery/DiscoveryView.swift`
- `Features/RestaurantDetail/RestaurantDetailView.swift`
- `Features/Favorites/FavoritesView.swift`

**Characteristics**:
- Pure SwiftUI views
- No business logic
- Observes ViewModel state
- Calls ViewModel methods for actions

**Example**:
```swift
struct DiscoveryView: View {
    @State private var viewModel: DiscoveryViewModel
    
    var body: some View {
        List(viewModel.results) { place in
            RestaurantRow(place: place)
                .onTapGesture {
                    viewModel.selectPlace(place)
                }
        }
        .searchable(text: $viewModel.searchQuery)
        .task {
            await viewModel.initialize()
        }
    }
}
```

### ViewModel Layer

**Responsibility**: Manage UI state and handle user actions

**Key Files**:
- `Features/Discovery/DiscoveryViewModel.swift`

**Characteristics**:
- `@Observable` for reactive updates
- `@MainActor` for main thread execution
- Transforms domain models to UI models
- Handles debouncing, loading states

**Example**:
```swift
@Observable
@MainActor
class DiscoveryViewModel {
    var results: [Place] = []
    var isLoading = false
    var errorMessage: String?
    
    private let interactor: CoreInteracting
    
    func performSearch() async {
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

### Interactor Layer

**Responsibility**: Implement business logic and coordinate managers

**Key Files**:
- `Core/Interactors/CoreInteractor.swift`
- `Core/Interactors/CoreInteracting.swift` (protocol)

**Characteristics**:
- Protocol-based for testability
- Coordinates multiple managers
- Implements complex workflows
- No UI dependencies

**Example**:
```swift
protocol CoreInteracting {
    func searchRestaurants(query: String) async throws -> [Place]
    func toggleFavorite(_ place: Place) async throws
}

class CoreInteractor: CoreInteracting {
    private let restaurantManager: RestaurantManager
    private let favoritesManager: FavoritesManager
    
    func toggleFavorite(_ place: Place) async throws {
        favoritesManager.toggle(place.id)
        try await favoritesManager.save()
        // Business logic: log analytics, update UI, etc.
    }
}
```

### Manager Layer

**Responsibility**: Coordinate data operations and maintain state

**Key Files**:
- `Core/Managers/RestaurantManager.swift`
- `Core/Managers/FavoritesManager.swift`
- `Core/Managers/PhotoManager.swift`

**Characteristics**:
- `@Observable` for shared state
- Coordinates service calls
- Applies business rules
- Caches data

**Example**:
```swift
@Observable
class RestaurantManager {
    private let placesService: PlacesService
    private let favoritesManager: FavoritesManager
    
    func searchNearby(location: CLLocationCoordinate2D) async throws -> [Place] {
        var places = try await placesService.searchNearby(location: location)
        
        // Apply favorite status
        places = favoritesManager.applyFavoriteStatus(to: places)
        
        return places
    }
}
```

### Service Layer

**Responsibility**: Handle external APIs and system services

**Key Files**:
- `Core/Services/GooglePlacesService.swift`
- `Core/Services/SwiftDataFavoritesService.swift`
- `Core/Services/LocationService.swift`

**Characteristics**:
- Protocol-based
- No business logic
- Pure data operations
- Error handling

**Example**:
```swift
protocol PlacesService {
    func searchNearby(location: CLLocationCoordinate2D) async throws -> [Place]
}

class GooglePlacesService: PlacesService {
    func searchNearby(location: CLLocationCoordinate2D) async throws -> [Place] {
        let request = buildRequest(location: location)
        let response = try await URLSession.shared.data(for: request)
        return try decode(response)
    }
}
```

---

## 🔧 Design Patterns

### 1. Dependency Injection

**Pattern**: Constructor injection for all dependencies

**Benefits**:
- Testability (easy to inject mocks)
- Flexibility (swap implementations)
- Explicit dependencies

**Example**:
```swift
class DiscoveryViewModel {
    private let interactor: CoreInteracting
    
    init(interactor: CoreInteracting) {
        self.interactor = interactor
    }
}

// Production
let viewModel = DiscoveryViewModel(interactor: CoreInteractor())

// Testing
let viewModel = DiscoveryViewModel(interactor: MockInteractor())
```

### 2. Repository Pattern

**Pattern**: Managers abstract data access

**Benefits**:
- Centralized data logic
- Easy to switch data sources
- Caching layer

**Example**:
```swift
class FavoritesManager {
    private let service: FavoritesService
    private var cache: Set<String> = []
    
    func isFavorite(_ placeId: String) -> Bool {
        cache.contains(placeId)  // Fast in-memory check
    }
    
    func save() async throws {
        try await service.save(favoriteIds: Array(cache))  // Persist
    }
}
```

### 3. Observer Pattern

**Pattern**: `@Observable` for reactive state

**Benefits**:
- Automatic UI updates
- Better performance than `@Published`
- Type-safe

**Example**:
```swift
@Observable
class FavoritesManager {
    var favoriteIds: Set<String> = []  // Changes auto-publish
}

// In View
struct FavoritesView: View {
    @State private var manager: FavoritesManager
    
    var body: some View {
        Text("Favorites: \(manager.favoriteIds.count)")
        // Auto-updates when favoriteIds changes
    }
}
```

---

## 📊 Data Flow

### Search Flow

```
User types "pizza"
    ↓
DiscoveryView updates searchQuery
    ↓
DiscoveryViewModel.performSearch() called (debounced 500ms)
    ↓
CoreInteractor.searchRestaurants(query: "pizza")
    ↓
RestaurantManager.searchText(query: "pizza")
    ↓
GooglePlacesService.searchText(query: "pizza")
    ↓
API Response → [Place]
    ↓
RestaurantManager applies favorite status
    ↓
CoreInteractor returns [Place]
    ↓
DiscoveryViewModel updates results
    ↓
DiscoveryView re-renders with new results
```

### Favorite Toggle Flow

```
User taps heart icon
    ↓
DiscoveryView calls viewModel.toggleFavorite(place)
    ↓
DiscoveryViewModel calls interactor.toggleFavorite(place)
    ↓
CoreInteractor calls favoritesManager.toggle(place.id)
    ↓
FavoritesManager updates favoriteIds Set
    ↓
@Observable publishes change
    ↓
All views observing FavoritesManager update
    ↓
CoreInteractor logs analytics event
    ↓
FavoritesManager persists to SwiftData
```

---

## 🎨 Why This Architecture?

### Benefits

1. **Testability**: Protocol-based design makes testing easy
2. **Maintainability**: Clear boundaries make changes isolated
3. **Scalability**: Add features without touching existing code
4. **Type Safety**: Compile-time checks prevent runtime errors
5. **Performance**: @Observable is more efficient than @Published

### Trade-offs

1. **More Files**: 5 layers means more files to navigate
2. **Boilerplate**: Protocols require interface + implementation
3. **Learning Curve**: Developers need to understand architecture

### When to Use

✅ **Good for**:
- Medium to large apps
- Team projects
- Long-term maintenance
- Complex business logic

❌ **Overkill for**:
- Simple CRUD apps
- Prototypes
- Single-developer projects
- Short-lived apps

---

## 📚 Further Reading

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [VIPER Architecture](https://www.objc.io/issues/13-architecture/viper/)
- [Protocol-Oriented Programming in Swift](https://developer.apple.com/videos/play/wwdc2015/408/)
- [Observable Macro Documentation](https://developer.apple.com/documentation/observation)

