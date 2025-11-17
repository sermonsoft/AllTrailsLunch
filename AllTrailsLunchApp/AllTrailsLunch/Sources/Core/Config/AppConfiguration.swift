//
//  AppConfiguration.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 31/10/25.
//

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

final class AppConfiguration {
    static let shared = AppConfiguration()

    // MARK: - Properties

    let environment: BuildEnvironment
    let googlePlacesAPIKey: String
    let timeout: TimeInterval

    // MARK: - Singleton Managers
    // These are created once and reused to ensure shared state across the app

    private var _favoritesManager: FavoritesManager?
    private let favoritesManagerLock = NSLock()

    private var _coreInteractor: CoreInteractor?
    private let coreInteractorLock = NSLock()

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
        // 1. Try environment variable first (for CI/CD and testing)
        if let key = ProcessInfo.processInfo.environment["GOOGLE_PLACES_API_KEY"] {
            return key
        }

        // 2. Try Info.plist (loaded from xcconfig at build time)
        if let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY") as? String,
           !key.isEmpty,
           key != "$(GOOGLE_PLACES_API_KEY)" { // Ensure it's not the placeholder
            return key
        }

        // 3. Fail fast in production - don't use hardcoded keys
        #if DEBUG
        // Only allow fallback in debug builds for development convenience
        print("⚠️ WARNING: Using hardcoded API key. Configure Secrets.xcconfig for production.")
        return "AIzaSyAvAaPcSL1SNPUguENa_p2P-SuRaxGUduw"
        #else
        fatalError("❌ GOOGLE_PLACES_API_KEY not configured. Please set up Config/Secrets.xcconfig")
        #endif
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

    @MainActor
    func createFavoritesService() -> FavoritesService {
        // Use SwiftData for better persistence and querying
        let modelContext = SwiftDataStorageManager.shared.mainContext
        return SwiftDataFavoritesService(modelContext: modelContext)
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
        // Thread-safe singleton pattern
        favoritesManagerLock.lock()
        defer { favoritesManagerLock.unlock() }

        if let existing = _favoritesManager {
            return existing
        }

        let manager = FavoritesManager(service: createFavoritesService())
        _favoritesManager = manager
        return manager
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
        // Thread-safe singleton pattern - ensures single CoreInteractor instance
        coreInteractorLock.lock()
        defer { coreInteractorLock.unlock() }

        if let existing = _coreInteractor {
            return existing
        }

        // Create dependency container with all shared managers
        // The container holds ALL managers as singletons
        let container = createDependencyContainer()

        // CoreInteractor only needs the container - it resolves all managers from it
        let interactor = CoreInteractor(container: container)

        _coreInteractor = interactor
        return interactor
    }

    @MainActor
    func createDiscoveryInteractor() -> DiscoveryInteractor {
        createCoreInteractor()  // Returns singleton instance
    }

    @MainActor
    func createDetailInteractor() -> DetailInteractor {
        createCoreInteractor()  // Returns singleton instance
    }

    // MARK: - Legacy Support (for backward compatibility with views)

    @MainActor
    func createFavoritesStore() -> FavoritesStore {
        FavoritesStore()
    }

    // MARK: - ViewModels

    @MainActor
    func createDiscoveryViewModel() -> DiscoveryViewModel {
        // ViewModel gets EventLogger from interactor (no need to pass it separately)
        DiscoveryViewModel(interactor: createDiscoveryInteractor())
    }

    // MARK: - Dependency Container

    /// Creates a fully configured dependency container with all app dependencies.
    /// All managers are registered as singletons to ensure shared state across the app.
    @MainActor
    func createDependencyContainer() -> DependencyContainer {
        let container = DependencyContainer()

        // Register shared managers (singletons)
        // Order matters: FavoritesManager must be registered before RestaurantManager
        container.register(FavoritesManager.self, service: createFavoritesManager())
        container.register(PhotoManager.self, service: createPhotoManager())
        container.register(NetworkMonitor.self, service: createNetworkMonitor())
        container.register(EventLogger.self, service: createEventLogger())
        container.register(LocationManager.self, service: createLocationManager())

        // RestaurantManager depends on FavoritesManager, so register it after
        container.register(RestaurantManager.self, service: createRestaurantManager())

        return container
    }
}

