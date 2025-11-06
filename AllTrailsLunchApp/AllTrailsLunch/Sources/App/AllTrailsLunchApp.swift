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
    @State private var interactor: CoreInteractor
    @State private var photoManager: PhotoManager
    @State private var networkMonitor: NetworkMonitor

    init() {
        let config = AppConfiguration.shared
        let interactor = config.createDiscoveryInteractor() as! CoreInteractor
        let viewModel = config.createDiscoveryViewModel()
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

