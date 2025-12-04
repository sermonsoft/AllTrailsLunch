//
//  SearchInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation
import CoreLocation

/// Protocol for search business logic
/// Follows Interface Segregation Principle - focused on search only
@MainActor
protocol SearchInteractor {
    // MARK: - Search
    
    /// Search for nearby restaurants based on user's location
    /// - Parameters:
    ///   - location: User's current location
    ///   - radius: Search radius in meters (default: 1500)
    ///   - pageToken: Optional pagination token for next page
    /// - Returns: Tuple of places, optional next page token, and cache flag
    /// - Throws: PlacesError if search fails
    func searchNearby(
        location: CLLocationCoordinate2D,
        radius: Int,
        pageToken: String?
    ) async throws -> (places: [Place], nextPageToken: String?, isFromCache: Bool)
    
    /// Search for restaurants by text query
    /// - Parameters:
    ///   - query: Search query text
    ///   - location: Optional user location for biased results
    ///   - pageToken: Optional pagination token for next page
    /// - Returns: Tuple of places, optional next page token, and cache flag
    /// - Throws: PlacesError if search fails
    func searchText(
        query: String,
        location: CLLocationCoordinate2D?,
        pageToken: String?
    ) async throws -> (places: [Place], nextPageToken: String?, isFromCache: Bool)
}

