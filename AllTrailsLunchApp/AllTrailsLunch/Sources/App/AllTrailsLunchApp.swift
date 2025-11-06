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
    @State private var interactor: CoreInteractor
    @State private var photoManager: PhotoManager
    @State private var networkMonitor: NetworkMonitor

    init() {
        let config = AppConfiguration.shared

        // CRITICAL: Create interactor FIRST, then pass it to viewModel
        // This ensures they share the same FavoritesManager instance
        let interactor = config.createDiscoveryInteractor() as! CoreInteractor
        let viewModel = DiscoveryViewModel(
            interactor: interactor,
            eventLogger: config.createEventLogger()
        )
        let photoManager = config.createPhotoManager()
        let networkMonitor = config.createNetworkMonitor()

        _viewModel = State(wrappedValue: viewModel)
        _interactor = State(wrappedValue: interactor)
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
            .environment(interactor.favoritesManager)
            .task {
                await viewModel.initialize()
            }
        }
    }
}

