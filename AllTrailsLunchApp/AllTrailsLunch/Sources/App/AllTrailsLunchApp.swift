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
/// - CoreInteractor initialized once at app level with all managers
/// - PhotoManager injected via environment from the container
/// - Clean architecture: ViewModel → Interactor → Manager → Service
@main
struct AllTrailsLunchApp: App {
    @State private var viewModel: DiscoveryViewModel
    private let container: DependencyContainer

    init() {
        let config = AppConfiguration.shared

        // Create container with all managers initialized once
        container = config.createDependencyContainer()

        // Create interactor (which holds references to managers)
        // The singleton pattern in AppConfiguration ensures shared instances
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

