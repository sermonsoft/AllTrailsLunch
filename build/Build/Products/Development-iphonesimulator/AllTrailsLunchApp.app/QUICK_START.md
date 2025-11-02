# AllTrails Lunch - Quick Start Guide

## 5-Minute Setup

### 1. Get API Key
```bash
# Go to Google Cloud Console
# Create project → Enable Places API → Create API key
# Copy your API key
```

### 2. Configure App
```swift
// In AppConfiguration.swift
private static func loadAPIKey() -> String {
    return "YOUR_API_KEY_HERE"  // Replace with your key
}
```

### 3. Update Info.plist
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to find nearby restaurants</string>
```

### 4. Build & Run
```bash
cd AllTrailsLunch
xcodebuild build -scheme AllTrailsLunch
```

## Project Structure

```
Sources/
├── App/                    # Entry point
├── Core/
│   ├── Networking/        # API client
│   ├── Models/            # Domain models
│   ├── Location/          # Location services
│   ├── Favorites/         # Favorites store
│   └── Config/            # Configuration
└── Features/
    ├── Discovery/         # Main screen
    └── Details/           # Detail screen
```

## Key Classes

### PlacesClient
```swift
let client = PlacesClient(apiKey: "YOUR_KEY")

// Nearby search
let url = try client.buildNearbySearchURL(
    latitude: 37.7749,
    longitude: -122.4194
)

// Text search
let url = try client.buildTextSearchURL(query: "pizza")

// Place details
let url = try client.buildDetailsURL(placeId: "ChIJ...")
```

### RestaurantRepository
```swift
let repo = RestaurantRepository(
    placesClient: client,
    favoritesStore: favoritesStore
)

// Search nearby
let (places, nextToken) = try await repo.searchNearby(
    latitude: 37.7749,
    longitude: -122.4194
)

// Search text
let (places, nextToken) = try await repo.searchText(
    query: "pizza",
    latitude: 37.7749,
    longitude: -122.4194
)

// Get details
let detail = try await repo.getPlaceDetails(placeId: "ChIJ...")
```

### LocationManager
```swift
let locationManager = LocationManager()

// Request location
let coordinate = try await locationManager.requestLocationPermission()
print("User location: \(coordinate.latitude), \(coordinate.longitude)")
```

### FavoritesStore
```swift
let favoritesStore = FavoritesStore()

// Check if favorite
let isFavorite = favoritesStore.isFavorite("ChIJ...")

// Toggle favorite
favoritesStore.toggleFavorite("ChIJ...")

// Get all favorites
let ids = favoritesStore.favoriteIds
```

### DiscoveryViewModel
```swift
@StateObject var viewModel = DiscoveryViewModel(
    repository: repo,
    locationManager: locationManager,
    favoritesStore: favoritesStore
)

// Initialize (call on app launch)
await viewModel.initialize()

// Search
viewModel.performSearch("pizza")

// Toggle favorite
viewModel.toggleFavorite(place)

// Load next page
await viewModel.loadNextPage()
```

## Common Tasks

### Add a New Search Endpoint
```swift
// 1. Add to PlacesClient
func buildNewSearchURL(...) throws -> URL {
    var components = URLComponents(string: "...")
    components?.queryItems = [...]
    return components?.url ?? throw PlacesError.invalidURL(...)
}

// 2. Add to RestaurantRepository
func searchNew(...) async throws -> (places: [Place], nextPageToken: String?) {
    let url = try placesClient.buildNewSearchURL(...)
    let request = try PlacesRequestBuilder()
        .setURL(url)
        .setMethod(.get)
        .build()
    let response: NewSearchResponse = try await placesClient.execute(request)
    return (response.results.map { Place(from: $0) }, response.nextPageToken)
}

// 3. Add to DiscoveryViewModel
func searchNew(...) async {
    let (places, nextToken) = try await repository.searchNew(...)
    self.results = places
    self.nextPageToken = nextToken
}
```

### Add a New Error Type
```swift
// In PlacesError.swift
enum PlacesError: LocalizedError {
    case newError(String)
    
    var errorDescription: String? {
        switch self {
        case .newError(let message):
            return "New error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .newError:
            return "Try again later"
        }
    }
}
```

### Add a New UI View
```swift
// 1. Create view file
struct NewView: View {
    var body: some View {
        VStack {
            Text("New View")
        }
    }
}

// 2. Add navigation in DiscoveryView
NavigationLink(destination: NewView()) {
    Text("Go to New View")
}
```

## API Response Examples

### Nearby Search Response
```json
{
  "results": [
    {
      "place_id": "ChIJ...",
      "name": "Restaurant Name",
      "rating": 4.5,
      "user_ratings_total": 120,
      "price_level": 2,
      "geometry": {
        "location": {
          "lat": 37.7749,
          "lng": -122.4194
        }
      },
      "formatted_address": "123 Main St",
      "photos": [
        {
          "photo_reference": "Aap_uEA...",
          "height": 1080,
          "width": 1920
        }
      ]
    }
  ],
  "next_page_token": "CqQCEA...",
  "status": "OK"
}
```

### Place Details Response
```json
{
  "result": {
    "name": "Restaurant Name",
    "rating": 4.5,
    "formatted_phone_number": "+1 (555) 123-4567",
    "opening_hours": {
      "open_now": true,
      "weekday_text": [
        "Monday: 10:00 AM – 10:00 PM",
        ...
      ]
    },
    "website": "https://example.com",
    "formatted_address": "123 Main St",
    "reviews": [
      {
        "author_name": "John Doe",
        "rating": 5,
        "text": "Great food!",
        "time": 1234567890
      }
    ]
  },
  "status": "OK"
}
```

## Debugging Tips

### Enable Logging
```swift
// Add to PlacesClient
private func logRequest(_ request: URLRequest) {
    print("🔵 Request: \(request.url?.absoluteString ?? "")")
    print("🔵 Method: \(request.httpMethod ?? "")")
}

private func logResponse(_ data: Data, _ response: HTTPURLResponse) {
    print("🟢 Response: \(response.statusCode)")
    if let json = try? JSONSerialization.jsonObject(with: data) {
        print("🟢 Body: \(json)")
    }
}
```

### Test API Calls
```swift
// In Xcode console
let client = PlacesClient(apiKey: "YOUR_KEY")
let url = try client.buildNearbySearchURL(latitude: 37.7749, longitude: -122.4194)
print(url.absoluteString)
```

### Check Favorites
```swift
let store = FavoritesStore()
print("Favorites: \(store.favoriteIds)")
```

## Performance Tips

1. **Debounce Search**: Already implemented (500ms)
2. **Pagination**: Use next_page_token for large result sets
3. **Caching**: Implement NSCache for photos
4. **Lazy Loading**: Load details only when needed
5. **Batch Requests**: Combine multiple searches if possible

## Common Issues

### "Invalid API Key"
- Check API key in AppConfiguration
- Verify API key is enabled in Google Cloud Console
- Ensure bundle identifier matches restrictions

### "Location Permission Denied"
- Check Info.plist has location descriptions
- Grant permission in simulator settings

### "No Results Found"
- Verify location coordinates are correct
- Check search query is valid
- Ensure API quota not exceeded

### "Rate Limited"
- Wait 2 seconds before using next_page_token
- Implement exponential backoff (already done)
- Check API quota in Google Cloud Console

## Resources

- [Google Places API Docs](https://developers.google.com/maps/documentation/places/web-service/overview)
- [SwiftUI Docs](https://developer.apple.com/documentation/swiftui)
- [MapKit Docs](https://developer.apple.com/documentation/mapkit)
- [CoreLocation Docs](https://developer.apple.com/documentation/corelocation)

---

**Need Help?** Check PROJECT_SUMMARY.md or SETUP_GUIDE.md for more details.

