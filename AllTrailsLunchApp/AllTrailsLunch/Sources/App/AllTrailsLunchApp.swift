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
/// - Centralized dependency container for easy access to managers
/// - Shared FavoritesManager instance accessible via container
/// - Clean, simple view initialization without prop drilling
@main
struct AllTrailsLunchApp: App {
    @State private var viewModel: DiscoveryViewModel
    @State private var container: DependencyContainer

    init() {
        let config = AppConfiguration.shared

        // Create dependency container with all shared managers
        let container = config.createDependencyContainer()

        // Create interactor and viewModel
        // The singleton pattern in AppConfiguration ensures shared FavoritesManager
        let interactor = config.createDiscoveryInteractor()
        let viewModel = DiscoveryViewModel(
            interactor: interactor,
            eventLogger: config.createEventLogger()
        )

        _container = State(wrappedValue: container)
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some Scene {
        WindowGroup {
            DiscoveryView(viewModel: viewModel)
                .dependencyContainer(container)
                .task {
                    await viewModel.initialize()
                }
        }
    }
}

