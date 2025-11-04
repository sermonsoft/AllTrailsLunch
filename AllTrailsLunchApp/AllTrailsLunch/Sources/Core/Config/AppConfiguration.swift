///
/// `AppConfiguration.swift`
/// AllTrailsLunch
///
/// Application configuration and dependency injection.
/// Supports multiple build environments: MOCK, DEV, STAGING, PRD, STORE
///

import Foundation

// MARK: - Build Environment

enum BuildEnvironment {
    case mock
    case development
    case staging
    case production
    case store

    /// Google Places API base URL
    var placesBaseURL: String {
        switch self {
        case .mock:
            return "https://mock.places.api.com" // Not used - mock uses local JSON
        case .development:
            return "https://maps.googleapis.com/maps/api/place"
        case .staging:
            return "https://maps.googleapis.com/maps/api/place"
        case .production, .store:
            return "https://maps.googleapis.com/maps/api/place"
        }
    }

    /// API timeout interval
    var timeout: TimeInterval {
        switch self {
        case .mock:
            return 5.0 // Short timeout for mock
        case .development:
            return 30.0
        case .staging:
            return 30.0
        case .production, .store:
            return 30.0
        }
    }

    /// Whether to use mock data
    var useMockData: Bool {
        return self == .mock
    }

    /// Environment display name for debugging
    var displayName: String {
        switch self {
        case .mock:
            return "Mock (Local JSON)"
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        case .store:
            return "Store (Production)"
        }
    }
}

// MARK: - App Configuration

struct AppConfiguration {
    static let shared = AppConfiguration()

    // MARK: - Properties

    let environment: BuildEnvironment
    let googlePlacesAPIKey: String
    let timeout: TimeInterval

    // MARK: - Initialization

    init() {
        self.environment = Self.detectEnvironment()
        self.googlePlacesAPIKey = Self.loadAPIKey()
        self.timeout = environment.timeout

        // Log active configuration
        Self.logConfiguration(environment: environment)
    }

    // MARK: - Environment Detection

    private static func detectEnvironment() -> BuildEnvironment {
        // 1) Allow runtime override via environment variables (for UI tests)
        let env = ProcessInfo.processInfo.environment
        if let override = (env["ENV"] ?? env["CONFIG"])?.uppercased() {
            switch override {
            case "MOCK":
                return .mock
            case "DEV", "DEVELOPMENT":
                return .development
            case "STAGING":
                return .staging
            case "PROD", "PRODUCTION":
                return .production
            case "STORE":
                return .store
            default:
                break
            }
        }

        // 2) Allow override via launch arguments
        let args = ProcessInfo.processInfo.arguments.map { $0.uppercased() }
        if args.contains("MOCK") {
            return .mock
        }
        if args.contains("DEV") || args.contains("DEVELOPMENT") {
            return .development
        }
        if args.contains("STAGING") {
            return .staging
        }
        if args.contains("PROD") || args.contains("PRODUCTION") {
            return .production
        }
        if args.contains("STORE") {
            return .store
        }

        // 3) Use compilation flags
        #if MOCK
        return .mock
        #elseif DEV
        return .development
        #elseif STAGING
        return .staging
        #elseif STORE
        return .store
        #elseif PRD
        return .production
        #else
        // Default to development if no flag is set
        return .development
        #endif
    }

    // MARK: - API Key Loading

    private static func loadAPIKey() -> String {
        // Try to load from environment variable first
        if let key = ProcessInfo.processInfo.environment["GOOGLE_PLACES_API_KEY"] {
            return key
        }

        // Fallback to embedded key - in production, this should be loaded from xcconfig
        return "AIzaSyAvAaPcSL1SNPUguENa_p2P-SuRaxGUduw"
    }

    // MARK: - Logging

    private static func logConfiguration(environment: BuildEnvironment) {
        print("🔧 AppConfiguration: Environment = \(environment.displayName)")
        print("🔧 AppConfiguration: Use Mock Data = \(environment.useMockData)")
        print("🔧 AppConfiguration: Timeout = \(environment.timeout)s")
        if !environment.useMockData {
            print("🔧 AppConfiguration: Places API Base URL = \(environment.placesBaseURL)")
        }
    }


    // MARK: - Dependency Injection

    // MARK: - Low-Level Services

    func createPlacesClient() -> PlacesClient {
        PlacesClient(apiKey: googlePlacesAPIKey)
    }

    func createRemotePlacesService() -> RemotePlacesService {
        GooglePlacesService(client: createPlacesClient())
    }

    func createFavoritesService() -> FavoritesService {
        UserDefaultsFavoritesService()
    }

    func createEventLogger() -> EventLogger {
        // Use ConsoleEventLogger for development, FirebaseEventLogger for production
        switch environment {
        case .mock, .development:
            return ConsoleEventLogger(isEnabled: true)
        case .staging:
            return ConsoleEventLogger(isEnabled: true) // Or FirebaseEventLogger for staging
        case .production, .store:
            return FirebaseEventLogger(isEnabled: true)
        }
    }

    func createPhotoLoaderService() -> PhotoLoaderService {
        GooglePlacesPhotoLoader(apiKey: googlePlacesAPIKey)
    }

    func createPhotoCacheService() -> PhotoCacheService {
        NSCachePhotoCache()
    }

    func createPlacesCacheService() -> LocalPlacesCache {
        FileBasedPlacesCache()
    }

    // MARK: - Managers

    @MainActor
    func createFavoritesManager() -> FavoritesManager {
        FavoritesManager(service: createFavoritesService())
    }

    @MainActor
    func createRestaurantManager() -> RestaurantManager {
        RestaurantManager(
            remote: createRemotePlacesService(),
            cache: createPlacesCacheService(),
            favorites: createFavoritesManager()
        )
    }

    @MainActor
    func createLocationManager() -> LocationManager {
        LocationManager()
    }

    @MainActor
    func createPhotoManager() -> PhotoManager {
        PhotoManager(
            loader: createPhotoLoaderService(),
            cache: createPhotoCacheService()
        )
    }

    @MainActor
    func createNetworkMonitor() -> NetworkMonitor {
        NetworkMonitor()
    }

    // MARK: - Interactors (Protocol-Based Services)

    @MainActor
    func createCoreInteractor() -> CoreInteractor {
        CoreInteractor(
            restaurantManager: createRestaurantManager(),
            favoritesManager: createFavoritesManager(),
            locationManager: createLocationManager()
        )
    }

    @MainActor
    func createDiscoveryInteractor() -> DiscoveryInteractor {
        createCoreInteractor()
    }

    @MainActor
    func createDetailInteractor() -> DetailInteractor {
        createCoreInteractor()
    }

    // MARK: - Legacy Support (for backward compatibility with views)

    @MainActor
    func createFavoritesStore() -> FavoritesStore {
        FavoritesStore()
    }

    // MARK: - ViewModels

    @MainActor
    func createDiscoveryViewModel() -> DiscoveryViewModel {
        DiscoveryViewModel(
            interactor: createDiscoveryInteractor(),
            eventLogger: createEventLogger()
        )
    }
}
