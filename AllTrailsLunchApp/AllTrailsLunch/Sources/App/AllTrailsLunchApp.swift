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
/// - CoreInteractor initialized once as singleton with all managers
/// - DependencyContainer created inside CoreInteractor with shared manager instances
/// - All managers and services are singletons, ensuring shared state across the app
/// - Clean architecture: ViewModel → Interactor → Manager → Service
@main
struct AllTrailsLunchApp: App {
    @State private var viewModel: DiscoveryViewModel

    init() {
        let config = AppConfiguration.shared

        // Create CoreInteractor singleton (which creates and holds the DependencyContainer)
        // The singleton pattern ensures all ViewModels share the same interactor and managers
        let coreInteractor = config.createCoreInteractor()

        // Use EventLogger from the container to avoid creating duplicate instances
        let eventLogger = coreInteractor.container.eventLogger

        let viewModel = DiscoveryViewModel(
            interactor: coreInteractor,
            eventLogger: eventLogger
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

