///
/// `AllTrailsLunchApp.swift`
/// AllTrailsLunch
///
/// Main application entry point.
///

import SwiftUI

@main
struct AllTrailsLunchApp: App {
    @State private var viewModel: DiscoveryViewModel
    @State private var favoritesStore: FavoritesStore
    @State private var photoManager: PhotoManager
    @State private var networkMonitor: NetworkMonitor

    init() {
        let config = AppConfiguration.shared
        let favoritesStore = config.createFavoritesStore()
        let viewModel = config.createDiscoveryViewModel()
        let photoManager = config.createPhotoManager()
        let networkMonitor = config.createNetworkMonitor()

        _viewModel = State(wrappedValue: viewModel)
        _favoritesStore = State(wrappedValue: favoritesStore)
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
            .environment(favoritesStore)
            .task {
                await viewModel.initialize()
            }
        }
    }
}

