//
//  DependencyContainer.swift
//  AllTrailsLunch
//
//  Centralized dependency injection container for managing app-wide dependencies.
//  Inspired by modern DI patterns to avoid prop drilling through view hierarchies.
//

import SwiftUI

/// A centralized container for managing and resolving dependencies throughout the app.
/// Uses @Observable to allow SwiftUI views to react to changes in registered services.
@Observable
@MainActor
final class DependencyContainer {
    
    // MARK: - Storage
    
    private var services: [String: Any] = [:]
    
    // MARK: - Registration
    
    /// Register a service instance with the container
    /// - Parameters:
    ///   - type: The type to register (typically a protocol)
    ///   - service: The concrete instance to register
    func register<T>(_ type: T.Type, service: T) {
        let key = "\(type)"
        services[key] = service
    }
    
    /// Register a service using a factory closure
    /// - Parameters:
    ///   - type: The type to register
    ///   - factory: A closure that creates the service instance
    func register<T>(_ type: T.Type, factory: () -> T) {
        let key = "\(type)"
        services[key] = factory()
    }
    
    // MARK: - Resolution
    
    /// Resolve a service from the container
    /// - Parameter type: The type to resolve
    /// - Returns: The registered service instance, or nil if not found
    func resolve<T>(_ type: T.Type) -> T? {
        let key = "\(type)"
        return services[key] as? T
    }
    
    /// Resolve a required service from the container
    /// - Parameter type: The type to resolve
    /// - Returns: The registered service instance
    /// - Note: Crashes if the service is not registered (use for required dependencies)
    func require<T>(_ type: T.Type) -> T {
        guard let service = resolve(type) else {
            fatalError("Required dependency \(type) not registered in DependencyContainer")
        }
        return service
    }
}

// MARK: - Environment Key

private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue: DependencyContainer? = nil
}

extension EnvironmentValues {
    var dependencyContainer: DependencyContainer? {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Inject the dependency container into the environment
    func dependencyContainer(_ container: DependencyContainer) -> some View {
        environment(\.dependencyContainer, container)
    }
}

// MARK: - Manager Access Helpers

extension DependencyContainer {
    
    /// Quick access to FavoritesManager
    var favoritesManager: FavoritesManager {
        require(FavoritesManager.self)
    }
    
    /// Quick access to PhotoManager
    var photoManager: PhotoManager {
        require(PhotoManager.self)
    }
    
    /// Quick access to NetworkMonitor
    var networkMonitor: NetworkMonitor {
        require(NetworkMonitor.self)
    }
    
    /// Quick access to EventLogger
    var eventLogger: EventLogger {
        require(EventLogger.self)
    }

    /// Quick access to LocationManager
    var locationManager: LocationManager {
        require(LocationManager.self)
    }

    /// Quick access to RestaurantManager
    var restaurantManager: RestaurantManager {
        require(RestaurantManager.self)
    }

    /// Quick access to FilterPreferencesManager
    var filterPreferencesManager: FilterPreferencesManager {
        require(FilterPreferencesManager.self)
    }

    /// Quick access to SavedSearchManager
    var savedSearchManager: SavedSearchManager {
        require(SavedSearchManager.self)
    }

    // MARK: - Combine Services Access

    /// Quick access to DataPipelineCoordinator
    var dataPipelineCoordinator: DataPipelineCoordinator {
        require(DataPipelineCoordinator.self)
    }

    /// Quick access to CombinePlacesService
    var combinePlacesService: CombinePlacesService {
        require(CombinePlacesService.self)
    }

    /// Quick access to LocalPlacesCache
    var localPlacesCache: LocalPlacesCache {
        require(LocalPlacesCache.self)
    }
}

