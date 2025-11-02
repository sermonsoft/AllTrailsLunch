///
/// `AppConfiguration.swift`
/// AllTrailsLunch
///
/// Application configuration and dependency injection.
///

import Foundation

struct AppConfiguration {
    static let shared = AppConfiguration()
    
    // API Configuration
    let googlePlacesAPIKey: String
    
    init() {
        // Load API key from environment or configuration
        // In production, this should be loaded from a secure configuration file
        self.googlePlacesAPIKey = Self.loadAPIKey()
    }
    
    private static func loadAPIKey() -> String {
        // Try to load from environment variable first
        if let key = ProcessInfo.processInfo.environment["GOOGLE_PLACES_API_KEY"] {
            return key
        }
        
        // Fallback to a placeholder - in production, this should be loaded from xcconfig
        return "YOUR_API_KEY_HERE"
    }
    
    // MARK: - Dependency Injection
    
    func createPlacesClient() -> PlacesClient {
        PlacesClient(apiKey: googlePlacesAPIKey)
    }
    
    @MainActor
    func createLocationManager() -> LocationManager {
        LocationManager()
    }
    
    @MainActor
    func createFavoritesStore() -> FavoritesStore {
        FavoritesStore()
    }
    
    @MainActor
    func createRepository() -> RestaurantRepository {
        RestaurantRepository(
            placesClient: createPlacesClient(),
            favoritesStore: createFavoritesStore()
        )
    }
    
    @MainActor
    func createDiscoveryViewModel() -> DiscoveryViewModel {
        DiscoveryViewModel(
            repository: createRepository(),
            locationManager: createLocationManager(),
            favoritesStore: createFavoritesStore()
        )
    }
}
