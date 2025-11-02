# AllTrails Lunch - File Structure

## Complete Project Layout

```
AllTrailsLunch/
│
├── Sources/
│   │
│   ├── App/
│   │   └── AllTrailsLunchApp.swift
│   │       └── Main app entry point with dependency injection
│   │
│   ├── Core/
│   │   │
│   │   ├── Networking/
│   │   │   ├── PlacesClient.swift
│   │   │   │   └── HTTP client with retry logic and error handling
│   │   │   ├── PlacesRequest.swift
│   │   │   │   └── Request builder with fluent API pattern
│   │   │   ├── PlacesError.swift
│   │   │   │   └── Comprehensive error types with recovery suggestions
│   │   │   └── HTTPMethod.swift
│   │   │       └── HTTP methods enum (GET, POST, etc.)
│   │   │
│   │   ├── Models/
│   │   │   ├── PlaceDTO.swift
│   │   │   │   └── Data Transfer Objects for API responses
│   │   │   │       ├── NearbySearchResponse
│   │   │   │       ├── TextSearchResponse
│   │   │   │       ├── PlaceDTO
│   │   │   │       ├── PlaceDetailsResponse
│   │   │   │       └── Supporting DTOs
│   │   │   ├── Place.swift
│   │   │   │   └── Domain models
│   │   │   │       ├── Place
│   │   │   │       ├── PlaceDetail
│   │   │   │       ├── OpeningHours
│   │   │   │       └── Review
│   │   │   └── RestaurantRepository.swift
│   │   │       └── Data access layer
│   │   │           ├── searchNearby()
│   │   │           ├── searchText()
│   │   │           └── getPlaceDetails()
│   │   │
│   │   ├── Location/
│   │   │   └── LocationManager.swift
│   │   │       └── CLLocationManager wrapper with async/await
│   │   │           ├── requestLocationPermission()
│   │   │           └── Location tracking
│   │   │
│   │   ├── Favorites/
│   │   │   └── FavoritesStore.swift
│   │   │       └── UserDefaults-based persistence
│   │   │           ├── isFavorite()
│   │   │           ├── toggleFavorite()
│   │   │           └── clearAllFavorites()
│   │   │
│   │   └── Config/
│   │       └── AppConfiguration.swift
│   │           └── Dependency injection and setup
│   │               ├── createPlacesClient()
│   │               ├── createLocationManager()
│   │               ├── createFavoritesStore()
│   │               ├── createRepository()
│   │               └── createDiscoveryViewModel()
│   │
│   └── Features/
│       │
│       ├── Discovery/
│       │   ├── DiscoveryView.swift
│       │   │   └── Main discovery screen
│       │   │       ├── SearchBar
│       │   │       ├── View mode toggle (List/Map)
│       │   │       ├── EmptyStateView
│       │   │       └── ErrorView
│       │   ├── DiscoveryViewModel.swift
│       │   │   └── State management for discovery
│       │   │       ├── @Published var searchText
│       │   │       ├── @Published var results
│       │   │       ├── @Published var viewMode
│       │   │       ├── performSearch()
│       │   │       ├── searchNearby()
│       │   │       ├── searchText()
│       │   │       ├── loadNextPage()
│       │   │       └── toggleFavorite()
│       │   ├── ListResultsView.swift
│       │   │   └── List view for results
│       │   │       ├── RestaurantRow
│       │   │       └── Pagination support
│       │   └── MapResultsView.swift
│       │       └── Map view for results
│       │           ├── MapKit integration
│       │           ├── Annotations
│       │           └── Pin selection
│       │
│       └── Details/
│           └── RestaurantDetailView.swift
│               └── Restaurant detail screen
│                   ├── Name, rating, price
│                   ├── Address and phone
│                   ├── Opening hours
│                   ├── Website link
│                   ├── Reviews
│                   └── Favorite button
│
├── Tests/
│   ├── NetworkingTests/
│   │   └── (Ready for implementation)
│   │       ├── PlacesClientTests
│   │       ├── URLBuildingTests
│   │       └── ErrorHandlingTests
│   │
│   └── ViewModelTests/
│       └── (Ready for implementation)
│           ├── DiscoveryViewModelTests
│           ├── FavoritesStoreTests
│           └── RepositoryTests
│
├── Documentation/
│   ├── SETUP_GUIDE.md
│   │   └── Complete setup instructions
│   ├── PROJECT_SUMMARY.md
│   │   └── Comprehensive project overview
│   ├── QUICK_START.md
│   │   └── Quick reference guide
│   ├── IMPLEMENTATION_COMPLETE.md
│   │   └── Implementation status and highlights
│   └── FILE_STRUCTURE.md
│       └── This file
│
└── Configuration/
    └── (To be created)
        ├── Secrets.xcconfig
        │   └── API key configuration
        └── Info.plist
            └── Location permissions
```

## File Descriptions

### Networking Layer

#### PlacesClient.swift
- **Purpose**: Core HTTP client for Google Places API
- **Key Methods**:
  - `execute<T>()`: Generic request execution with retry logic
  - `buildNearbySearchURL()`: Build nearby search endpoint
  - `buildTextSearchURL()`: Build text search endpoint
  - `buildDetailsURL()`: Build place details endpoint
- **Features**: Retry logic, error handling, timeout management

#### PlacesRequest.swift
- **Purpose**: Request builder with fluent API
- **Key Classes**:
  - `PlacesRequest`: Immutable request object
  - `PlacesRequestBuilder`: Builder for constructing requests
- **Features**: Fluent API, method chaining, validation

#### PlacesError.swift
- **Purpose**: Comprehensive error types
- **Error Types**: 10 different error cases
- **Features**: User-friendly descriptions, recovery suggestions

#### HTTPMethod.swift
- **Purpose**: HTTP methods enum
- **Methods**: GET, POST, PUT, PATCH, DELETE

### Data Models

#### PlaceDTO.swift
- **Purpose**: Data Transfer Objects for API responses
- **DTOs**:
  - `NearbySearchResponse`
  - `TextSearchResponse`
  - `PlaceDTO`
  - `PlaceDetailsResponse`
  - `PlaceDetailsDTO`
  - `OpeningHoursDTO`
  - `ReviewDTO`
- **Features**: Codable, JSON mapping, nested structures

#### Place.swift
- **Purpose**: Domain models
- **Models**:
  - `Place`: Main restaurant model
  - `PlaceDetail`: Detailed restaurant information
  - `OpeningHours`: Hours of operation
  - `Review`: Customer review
- **Features**: Computed properties, coordinate conversion, formatting

#### RestaurantRepository.swift
- **Purpose**: Data access layer
- **Methods**:
  - `searchNearby()`: Search nearby restaurants
  - `searchText()`: Search by text query
  - `getPlaceDetails()`: Get detailed information
- **Features**: DTO to domain model mapping, favorite status integration

### Services

#### LocationManager.swift
- **Purpose**: Location services wrapper
- **Key Methods**:
  - `requestLocationPermission()`: Request and get location
  - `requestLocation()`: Get current location
- **Features**: @MainActor, async/await, CLLocationManagerDelegate

#### FavoritesStore.swift
- **Purpose**: Favorites persistence
- **Key Methods**:
  - `isFavorite()`: Check if place is favorite
  - `toggleFavorite()`: Add/remove favorite
  - `addFavorite()`: Add to favorites
  - `removeFavorite()`: Remove from favorites
  - `clearAllFavorites()`: Clear all favorites
- **Features**: UserDefaults persistence, @Published, thread-safe

### View Models

#### DiscoveryViewModel.swift
- **Purpose**: State management for discovery screen
- **Published Properties**:
  - `searchText`: Current search query
  - `results`: Search results
  - `viewMode`: List or map view
  - `isLoading`: Loading state
  - `error`: Error state
  - `userLocation`: User's location
  - `nextPageToken`: Pagination token
- **Key Methods**:
  - `initialize()`: Initialize on app launch
  - `performSearch()`: Perform search with debouncing
  - `searchNearby()`: Search nearby restaurants
  - `searchText()`: Search by text
  - `loadNextPage()`: Load next page of results
  - `toggleFavorite()`: Toggle favorite status

### UI Layer

#### AllTrailsLunchApp.swift
- **Purpose**: Main app entry point
- **Features**: Dependency injection, environment setup

#### DiscoveryView.swift
- **Purpose**: Main discovery screen
- **Components**:
  - `SearchBar`: Search input with clear button
  - `ViewMode Picker`: List/Map toggle
  - `ListResultsView` or `MapResultsView`: Results display
  - `EmptyStateView`: No results state
  - `ErrorView`: Error display
- **Features**: Navigation, state management, error handling

#### ListResultsView.swift
- **Purpose**: List view for results
- **Components**:
  - `RestaurantRow`: Individual restaurant row
- **Features**: Scrollable list, pagination, favorite button

#### MapResultsView.swift
- **Purpose**: Map view for results
- **Components**:
  - `MapPinView`: Map pin annotation
- **Features**: MapKit integration, pin selection, callout

#### RestaurantDetailView.swift
- **Purpose**: Restaurant detail screen
- **Sections**:
  - Header with name and favorite button
  - Rating and price information
  - Contact information
  - Hours of operation
  - Reviews
- **Features**: Navigation, favorite toggle, link buttons

### Configuration

#### AppConfiguration.swift
- **Purpose**: Dependency injection and setup
- **Factory Methods**:
  - `createPlacesClient()`
  - `createLocationManager()`
  - `createFavoritesStore()`
  - `createRepository()`
  - `createDiscoveryViewModel()`
- **Features**: Centralized configuration, easy service switching

## Navigation Flow

```
AllTrailsLunchApp
    ↓
DiscoveryView
    ├── SearchBar (input)
    ├── ViewMode Picker (List/Map toggle)
    └── Content
        ├── ListResultsView
        │   └── RestaurantRow
        │       └── NavigationLink → RestaurantDetailView
        └── MapResultsView
            └── MapPinView
                └── NavigationLink → RestaurantDetailView

RestaurantDetailView
    ├── Name, rating, price
    ├── Address, phone
    ├── Hours, website
    ├── Reviews
    └── Favorite button
```

## Data Flow

```
User Input
    ↓
DiscoveryView
    ↓
DiscoveryViewModel
    ├── performSearch()
    ├── searchNearby()
    └── searchText()
    ↓
RestaurantRepository
    ├── searchNearby()
    ├── searchText()
    └── getPlaceDetails()
    ↓
PlacesClient
    ├── buildNearbySearchURL()
    ├── buildTextSearchURL()
    └── buildDetailsURL()
    ↓
Google Places API
    ↓
Response (JSON)
    ↓
PlaceDTO (Decodable)
    ↓
Place (Domain Model)
    ↓
UI Update
```

## File Dependencies

```
AllTrailsLunchApp
    ├── DiscoveryView
    │   ├── DiscoveryViewModel
    │   │   ├── RestaurantRepository
    │   │   │   ├── PlacesClient
    │   │   │   │   ├── PlacesRequest
    │   │   │   │   ├── PlacesError
    │   │   │   │   └── HTTPMethod
    │   │   │   ├── FavoritesStore
    │   │   │   └── PlaceDTO
    │   │   ├── LocationManager
    │   │   └── FavoritesStore
    │   ├── ListResultsView
    │   │   └── RestaurantRow
    │   └── MapResultsView
    │       └── MapPinView
    └── RestaurantDetailView
        └── FavoritesStore

AppConfiguration
    ├── PlacesClient
    ├── LocationManager
    ├── FavoritesStore
    └── RestaurantRepository
```

---

**Total Files**: 16 source files + 4 documentation files = 20 files

**Total Lines of Code**: ~2,500 lines

**Ready for**: Testing, UI polish, and bonus features

