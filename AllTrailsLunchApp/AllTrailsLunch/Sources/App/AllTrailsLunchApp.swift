//
//  AllTrailsLunchApp.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 06/11/25.
//

import SwiftUI

/// Main app entry point for AllTrails Lunch.
///
/// Configures the app with:
/// - Dependency injection for core services
/// - Shared FavoritesManager instance across components
/// - Environment objects for SwiftUI views
/// - Network monitoring and photo management
@main
struct AllTrailsLunchApp: App {
    @State private var viewModel: DiscoveryViewModel
    @State private var favoritesManager: FavoritesManager
    @State private var photoManager: PhotoManager
    @State private var networkMonitor: NetworkMonitor

    init() {
        let config = AppConfiguration.shared

        // CRITICAL: Create interactor FIRST, then pass it to viewModel
        // This ensures they share the same FavoritesManager instance
        // The singleton pattern in AppConfiguration guarantees this
        let interactor = config.createDiscoveryInteractor()
        let viewModel = DiscoveryViewModel(
            interactor: interactor,
            eventLogger: config.createEventLogger()
        )
        let photoManager = config.createPhotoManager()
        let networkMonitor = config.createNetworkMonitor()

        // Access FavoritesManager from the interactor protocol
        let favoritesManager = interactor.favoritesManager

        _viewModel = State(wrappedValue: viewModel)
        _favoritesManager = State(wrappedValue: favoritesManager)
        _photoManager = State(wrappedValue: photoManager)
        _networkMonitor = State(wrappedValue: networkMonitor)
    }

    var body: some Scene {
        WindowGroup {
            DiscoveryView(
                viewModel: viewModel,
                photoManager: photoManager,
                networkMonitor: networkMonitor
            )
            .environment(favoritesManager)
            .task {
                await viewModel.initialize()
            }
        }
    }
}

