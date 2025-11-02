///
/// `AllTrailsLunchApp.swift`
/// AllTrailsLunch
///
/// Main application entry point.
///

import SwiftUI

@main
struct AllTrailsLunchApp: App {
    @StateObject private var viewModel: DiscoveryViewModel
    @StateObject private var favoritesStore: FavoritesStore
    
    init() {
        let config = AppConfiguration.shared
        let favoritesStore = config.createFavoritesStore()
        let viewModel = config.createDiscoveryViewModel()
        
        _viewModel = StateObject(wrappedValue: viewModel)
        _favoritesStore = StateObject(wrappedValue: favoritesStore)
    }
    
    var body: some Scene {
        WindowGroup {
            DiscoveryView(viewModel: viewModel)
                .environmentObject(favoritesStore)
                .task {
                    await viewModel.initialize()
                }
        }
    }
}

