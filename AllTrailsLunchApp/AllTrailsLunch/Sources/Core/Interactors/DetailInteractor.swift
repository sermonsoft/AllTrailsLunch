//
//  DetailInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation

/// Protocol for Detail feature business logic
/// Composes smaller, focused protocols following Interface Segregation Principle
@MainActor
protocol DetailInteractor:
    PlaceDetailsInteractor,
    FavoritesInteractor,
    PhotoLoadingInteractor {
    // This protocol composes all the smaller protocols needed for the Detail feature
    // No additional methods needed - all functionality comes from composed protocols
}

