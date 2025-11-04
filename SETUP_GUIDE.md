# AllTrails Lunch - Setup Guide

## Project Overview

AllTrails Lunch is a SwiftUI-based restaurant discovery app that uses the Google Places API to help users find nearby restaurants, search by query, and manage favorites.

### Architecture

The project follows a clean, layered architecture:

```
AllTrailsLunch/
├── Sources/
│   ├── App/
│   │   └── AllTrailsLunchApp.swift          # Main app entry point
│   ├── Core/
│   │   ├── Networking/                      # Google Places API client
│   │   │   ├── PlacesClient.swift
│   │   │   ├── PlacesRequest.swift
│   │   │   ├── PlacesError.swift
│   │   │   └── HTTPMethod.swift
│   │   ├── Models/                          # Domain models & DTOs
│   │   │   ├── Place.swift
│   │   │   ├── PlaceDTO.swift
│   │   │   └── RestaurantRepository.swift
│   │   ├── Location/                        # Location services
│   │   │   └── LocationManager.swift
│   │   ├── Favorites/                       # Favorites persistence
│   │   │   └── FavoritesStore.swift
│   │   └── Config/                          # Configuration
│   │       └── AppConfiguration.swift
│   └── Features/
│       ├── Discovery/                       # Main discovery screen
│       │   ├── DiscoveryView.swift
│       │   ├── DiscoveryViewModel.swift
│       │   ├── ListResultsView.swift
│       │   └── MapResultsView.swift
│       └── Details/                         # Restaurant details
│           └── RestaurantDetailView.swift
└── Tests/
    ├── NetworkingTests/
    └── ViewModelTests/
```

## Setup Instructions

### 1. Prerequisites

- Xcode 16.2 or later
- iOS 17.0 or later
- Google Places API key

### 2. Get Google Places API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Enable the Places API
4. Create an API key (iOS app)
5. Add your app's bundle identifier to the API key restrictions

### 3. Configure API Key

Create a file `Secrets.xcconfig` in the project root:

```xcconfig
// Secrets.xcconfig
GOOGLE_PLACES_API_KEY = YOUR_API_KEY_HERE
```

Then update `AppConfiguration.swift` to load from xcconfig:

```swift
private static func loadAPIKey() -> String {
    // Load from xcconfig or environment
    return Bundle.main.infoDictionary?["GOOGLE_PLACES_API_KEY"] as? String ?? "YOUR_API_KEY_HERE"
}
```

### 4. Configure Info.plist

Add the following to your app's Info.plist:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to find nearby restaurants</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to find nearby restaurants</string>
```

### 5. Build and Run

```bash
cd AllTrailsLunch
xcodebuild build -scheme AllTrailsLunch -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Key Features

### 1. Nearby Search
- Auto-searches for restaurants near user's location on app launch
- Requires location permission
- Configurable search radius (default: 1500m)

### 2. Text Search
- Search by restaurant name or cuisine
- Debounced search (500ms delay)
- Location-biased results

### 3. List & Map Views
- Toggle between list and map views
- Map shows restaurant locations with pins
- Tap to view details

### 4. Favorites
- Heart button to add/remove favorites
- Persisted in UserDefaults
- Reflected in both list and map views

### 5. Restaurant Details
- Name, rating, price level
- Address and phone number
- Opening hours
- Website link
- Customer reviews

## API Endpoints

### Nearby Search
```
GET /maps/api/place/nearbysearch/json
Parameters:
  - location: latitude,longitude
  - radius: search radius in meters
  - type: place type (restaurant)
  - key: API key
  - pagetoken: for pagination
```

### Text Search
```
GET /maps/api/place/textsearch/json
Parameters:
  - query: search query
  - location: latitude,longitude (optional)
  - key: API key
  - pagetoken: for pagination
```

### Place Details
```
GET /maps/api/place/details/json
Parameters:
  - place_id: unique place identifier
  - fields: comma-separated field names
  - key: API key
```

## Error Handling

The app handles various error scenarios:

- **Location Permission Denied**: Shows permission request
- **Network Unavailable**: Displays network error message
- **Rate Limited**: Implements exponential backoff retry
- **Invalid Response**: Shows user-friendly error message
- **Timeout**: Retries up to 3 times with backoff

## Testing

### Unit Tests

```bash
xcodebuild test -scheme AllTrailsLunch -testPlan UnitTests
```

Tests cover:
- URL building for all endpoints
- JSON decoding from sample responses
- Favorites toggle logic
- ViewModel state management

### Integration Tests

```bash
xcodebuild test -scheme AllTrailsLunch -testPlan IntegrationTests
```

Tests cover:
- Live API calls (with recorded fixtures)
- End-to-end search flow
- Favorites persistence

## Performance Considerations

### Caching
- Photos cached in memory (NSCache)
- Optional disk cache for photos
- API responses not cached (fresh data on each search)

### Pagination
- Implements Google Places pagination with next_page_token
- 2-second delay before using next page token (API requirement)
- Load more button in list view

### Debouncing
- Search debounced at 500ms
- Prevents excessive API calls
- Cancels previous search on new input

## Commit Message

```
feat: implement AllTrails Lunch restaurant discovery app

- Add PlacesClient with Google Places API integration
- Implement nearby and text search endpoints
- Create LocationManager with async/await support
- Build DiscoveryViewModel with search and filtering
- Add list and map views for results display
- Implement FavoritesStore with UserDefaults persistence
- Create RestaurantDetailView with full place information
- Add comprehensive error handling and retry logic
- Support pagination with next_page_token
- Include location permission flow
- Implement industry-standard architectural patterns
```

## Next Steps

1. **Photo Caching**: Implement NSCache-based photo caching
2. **UI Polish**: Add animations and transitions
3. **Bonus Features**: SwiftData for favorites, Figma UI spec
4. **Testing**: Add comprehensive unit and integration tests
5. **Documentation**: Add inline code documentation

## Troubleshooting

### "Invalid API Key" Error
- Verify API key in AppConfiguration
- Check API key is enabled in Google Cloud Console
- Ensure bundle identifier matches API key restrictions

### "Location Permission Denied"
- Check Info.plist has location usage descriptions
- Grant location permission in simulator settings

### "No Results Found"
- Verify location is set correctly
- Check search query is valid
- Ensure API quota not exceeded

## Resources

- [Google Places API Documentation](https://developers.google.com/maps/documentation/places/web-service/overview)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [MapKit Documentation](https://developer.apple.com/documentation/mapkit)
- [CoreLocation Documentation](https://developer.apple.com/documentation/corelocation)

