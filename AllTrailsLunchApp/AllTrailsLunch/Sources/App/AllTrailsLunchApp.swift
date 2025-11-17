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
/// - DependencyContainer created inside CoreInteractor with shared manager instances
/// - Clean architecture: ViewModel → Interactor → Manager → Service
@main
struct AllTrailsLunchApp: App {
    @State private var viewModel: DiscoveryViewModel

    init() {
        let config = AppConfiguration.shared

        // Create interactor (which creates and holds the DependencyContainer with all managers)
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

