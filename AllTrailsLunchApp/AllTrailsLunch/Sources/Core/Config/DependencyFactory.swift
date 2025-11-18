//
//  DependencyFactory.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 18/11/25.
//

import Foundation

/// Responsible for creating all app dependencies (services, managers, interactors, viewmodels).
/// Single Responsibility: Dependency creation and wiring.
@MainActor
final class DependencyFactory {
    
    // MARK: - Properties
    
    private let config: EnvironmentConfiguration
    
    // MARK: - Singleton Managers
    // These are created once and reused to ensure shared state across the app
    
    private var _favoritesManager: FavoritesManager?
    private let favoritesManagerLock = NSLock()
    
    private var _coreInteractor: CoreInteractor?
    private let coreInteractorLock = NSLock()
    
    // MARK: - Initialization
    
    init(config: EnvironmentConfiguration = .shared) {
        self.config = config
    }
    
    // MARK: - Low-Level Services
    
    func createPlacesClient() -> PlacesClient {
        PlacesClient(apiKey: config.googlePlacesAPIKey)
    }
    
    func createRemotePlacesService() -> RemotePlacesService {
        GooglePlacesService(client: createPlacesClient())
    }
    
    func createFavoritesService() -> FavoritesService {
        // Use SwiftData for better persistence and querying
        let modelContext = SwiftDataStorageManager.shared.mainContext
        return SwiftDataFavoritesService(modelContext: modelContext)
    }
    
    func createEventLogger() -> EventLogger {
        // Use ConsoleEventLogger for development, FirebaseEventLogger for production
        switch config.environment {
        case .mock, .development:
            return ConsoleEventLogger(isEnabled: true)
        case .staging:
            return ConsoleEventLogger(isEnabled: true) // Or FirebaseEventLogger for staging
        case .production, .store:
            return FirebaseEventLogger(isEnabled: true)
        }
    }
    
    func createPhotoLoaderService() -> PhotoLoaderService {
        GooglePlacesPhotoLoader(apiKey: config.googlePlacesAPIKey)
    }
    
    func createPhotoCacheService() -> PhotoCacheService {
        NSCachePhotoCache()
    }
    
    func createPlacesCacheService() -> LocalPlacesCache {
        FileBasedPlacesCache()
    }
    
    // MARK: - Managers
    
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
    
    func createLocationManager() -> LocationManager {
        LocationManager()
    }
    
    func createPhotoManager() -> PhotoManager {
        PhotoManager(
            loader: createPhotoLoaderService(),
            cache: createPhotoCacheService()
        )
    }
    
    func createNetworkMonitor() -> NetworkMonitor {
        NetworkMonitor()
    }
    
    func createFilterPreferencesManager() -> FilterPreferencesManager {
        let service = FilterPreferencesService()
        return FilterPreferencesManager(service: service)
    }
    
    func createSavedSearchManager() -> SavedSearchManager {
        let modelContext = SwiftDataStorageManager.shared.mainContext
        let service = SavedSearchService(modelContext: modelContext)
        return SavedSearchManager(service: service)
    }
    
    // MARK: - Interactors
    
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
    
    func createDiscoveryInteractor() -> DiscoveryInteractor {
        createCoreInteractor()  // Returns singleton instance
    }
    
    func createDetailInteractor() -> DetailInteractor {
        createCoreInteractor()  // Returns singleton instance
    }

    // MARK: - Legacy Support

    func createFavoritesStore() -> FavoritesStore {
        FavoritesStore()
    }

    // MARK: - ViewModels

    func createDiscoveryViewModel() -> DiscoveryViewModel {
        // ViewModel gets EventLogger from interactor (no need to pass it separately)
        DiscoveryViewModel(interactor: createDiscoveryInteractor())
    }

    // MARK: - Dependency Container

    /// Creates a fully configured dependency container with all app dependencies.
    /// All managers are registered as singletons to ensure shared state across the app.
    func createDependencyContainer() -> DependencyContainer {
        let container = DependencyContainer()

        // Register shared managers (singletons)
        // Order matters: FavoritesManager must be registered before RestaurantManager
        let favoritesManager = createFavoritesManager()
        container.register(FavoritesManager.self, service: favoritesManager)
        container.register(PhotoManager.self, service: createPhotoManager())
        container.register(NetworkMonitor.self, service: createNetworkMonitor())
        container.register(EventLogger.self, service: createEventLogger())
        container.register(LocationManager.self, service: createLocationManager())
        container.register(FilterPreferencesManager.self, service: createFilterPreferencesManager())
        container.register(SavedSearchManager.self, service: createSavedSearchManager())

        // RestaurantManager depends on FavoritesManager, so pass it directly
        container.register(RestaurantManager.self, service: RestaurantManager(
            remote: createRemotePlacesService(),
            cache: createPlacesCacheService(),
            favorites: favoritesManager  // ✅ Use the same instance
        ))

        return container
    }
}

