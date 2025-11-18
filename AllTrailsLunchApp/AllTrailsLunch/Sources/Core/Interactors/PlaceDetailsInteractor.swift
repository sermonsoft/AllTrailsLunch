//
//  PlaceDetailsInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation

/// Protocol for place details business logic
/// Follows Interface Segregation Principle - focused on place details only
@MainActor
protocol PlaceDetailsInteractor {
    // MARK: - Place Details
    
    /// Get detailed information about a place
    /// - Parameter placeId: The place ID to get details for
    /// - Returns: Detailed place information
    /// - Throws: PlacesError if request fails
    func getPlaceDetails(placeId: String) async throws -> PlaceDetail
}

