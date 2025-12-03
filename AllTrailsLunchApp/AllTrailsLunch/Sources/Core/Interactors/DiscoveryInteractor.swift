//
//  DiscoveryInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation
import CoreLocation

/// Protocol for Discovery feature business logic
/// Composes smaller, focused protocols following Interface Segregation Principle
/// ViewModels should ONLY call methods on this protocol, never access managers directly
@MainActor
protocol DiscoveryInteractor:
    LocationInteractor,
    SearchInteractor,
    FavoritesInteractor,
    PhotoLoadingInteractor,
    PlaceDetailsInteractor,
    EventLoggingInteractor,
    NetworkStatusInteractor,
    FilterManagementInteractor,
    SavedSearchInteractor,
    ReactivePipelineInteractor {
    // This protocol composes all the smaller protocols needed for the Discovery feature
    // No additional methods needed - all functionality comes from composed protocols
}

