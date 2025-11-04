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
    @StateObject private var favoritesStore: FavoritesStore
    @State private var photoManager: PhotoManager
    @State private var networkMonitor: NetworkMonitor

    init() {
        let config = AppConfiguration.shared
        let favoritesStore = config.createFavoritesStore()
        let viewModel = config.createDiscoveryViewModel()
        let photoManager = config.createPhotoManager()
        let networkMonitor = config.createNetworkMonitor()

        _viewModel = State(wrappedValue: viewModel)
        _favoritesStore = StateObject(wrappedValue: favoritesStore)
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
            .environmentObject(favoritesStore)
            .task {
                await viewModel.initialize()
            }
        }
    }
}

