//
//  AppConfiguration.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 31/10/25.
//

import Foundation

// MARK: - App Configuration

/// Simplified facade for app configuration and dependency creation.
/// Single Responsibility: Provide a simple API for accessing configuration and dependencies.
///
/// This class delegates to:
/// - `EnvironmentConfiguration` for environment detection and config values
/// - `DependencyFactory` for creating all dependencies
@MainActor
final class AppConfiguration {
    static let shared = AppConfiguration()

    // MARK: - Properties

    private let environmentConfig: EnvironmentConfiguration
    private let factory: DependencyFactory

    // MARK: - Initialization

    private init() {
        self.environmentConfig = .shared
        self.factory = DependencyFactory(config: environmentConfig)
    }

    // MARK: - Environment Access

    var environment: BuildEnvironment {
        environmentConfig.environment
    }

    var googlePlacesAPIKey: String {
        environmentConfig.googlePlacesAPIKey
    }

    var timeout: TimeInterval {
        environmentConfig.timeout
    }

    // MARK: - Dependency Creation (Delegates to Factory)

    // MARK: - Low-Level Services

    func createPlacesClient() -> PlacesClient {
        factory.createPlacesClient()
    }

    func createRemotePlacesService() -> RemotePlacesService {
        factory.createRemotePlacesService()
    }

    func createFavoritesService() -> FavoritesService {
        factory.createFavoritesService()
    }

    func createEventLogger() -> EventLogger {
        factory.createEventLogger()
    }

    func createPhotoLoaderService() -> PhotoLoaderService {
        factory.createPhotoLoaderService()
    }

    func createPhotoCacheService() -> PhotoCacheService {
        factory.createPhotoCacheService()
    }

    func createPlacesCacheService() -> LocalPlacesCache {
        factory.createPlacesCacheService()
    }

    // MARK: - Managers

    func createFavoritesManager() -> FavoritesManager {
        factory.createFavoritesManager()
    }

    func createLocationManager() -> LocationManager {
        factory.createLocationManager()
    }

    func createPhotoManager() -> PhotoManager {
        factory.createPhotoManager()
    }

    func createNetworkMonitor() -> NetworkMonitor {
        factory.createNetworkMonitor()
    }

    func createFilterPreferencesManager() -> FilterPreferencesManager {
        factory.createFilterPreferencesManager()
    }

    func createSavedSearchManager() -> SavedSearchManager {
        factory.createSavedSearchManager()
    }

    // MARK: - Interactors

    func createCoreInteractor() -> CoreInteractor {
        factory.createCoreInteractor()
    }

    func createDiscoveryInteractor() -> DiscoveryInteractor {
        factory.createDiscoveryInteractor()
    }

    func createDetailInteractor() -> DetailInteractor {
        factory.createDetailInteractor()
    }

    // MARK: - ViewModels

    func createDiscoveryViewModel() -> DiscoveryViewModel {
        factory.createDiscoveryViewModel()
    }

    // MARK: - Dependency Container

    func createDependencyContainer() -> DependencyContainer {
        factory.createDependencyContainer()
    }
}

