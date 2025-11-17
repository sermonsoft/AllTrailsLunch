//
//  DetailInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation

/// Protocol for Detail feature business logic
@MainActor
protocol DetailInteractor {
    // MARK: - Place Details
    
    /// Get detailed information about a place
    /// - Parameter placeId: The place ID to get details for
    /// - Returns: Detailed place information
    /// - Throws: PlacesError if request fails
    func getPlaceDetails(placeId: String) async throws -> PlaceDetail
    
    // MARK: - Favorites

    /// Check if a place is favorited
    /// - Parameter placeId: The place ID to check
    /// - Returns: True if favorited, false otherwise
    func isFavorite(_ placeId: String) -> Bool

    /// Toggle favorite status for a place (ID only)
    /// - Parameter placeId: The place ID to toggle
    /// - Throws: Error if toggle fails
    func toggleFavorite(_ placeId: String) async throws

    /// Toggle favorite status for a place (with full place data)
    /// - Parameter place: The place to toggle
    /// - Returns: New favorite status (true if now favorited, false if unfavorited)
    /// - Throws: Error if toggle fails
    func toggleFavorite(_ place: Place) async throws -> Bool

    /// Add a place to favorites (ID only)
    /// - Parameter placeId: The place ID to add
    /// - Throws: Error if add fails
    func addFavorite(_ placeId: String) async throws

    /// Add a place to favorites (with full place data)
    /// - Parameter place: The place to add
    /// - Throws: Error if add fails
    func addFavorite(_ place: Place) async throws

    /// Remove a place from favorites
    /// - Parameter placeId: The place ID to remove
    /// - Throws: Error if remove fails
    func removeFavorite(_ placeId: String) async throws
}

