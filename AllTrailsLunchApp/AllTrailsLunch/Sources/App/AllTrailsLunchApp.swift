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
/// - Shared FavoritesManager instance accessible via ViewModel
/// - Clean, simple view initialization
@main
struct AllTrailsLunchApp: App {
    @State private var viewModel: DiscoveryViewModel

    init() {
        let config = AppConfiguration.shared

        // Create interactor and viewModel
        // The singleton pattern in AppConfiguration ensures shared FavoritesManager
        let interactor = config.createDiscoveryInteractor()
        let viewModel = DiscoveryViewModel(
            interactor: interactor,
            eventLogger: config.createEventLogger()
        )

        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some Scene {
        WindowGroup {
            DiscoveryView(viewModel: viewModel)
                .task {
                    await viewModel.initialize()
                }
        }
    }
}

