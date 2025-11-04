///
/// `DetailInteractor.swift`
/// AllTrailsLunch
///
/// Protocol defining business logic for the Detail feature.
/// This allows ViewModels to depend on abstractions instead of concrete types.
///

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
    
    /// Toggle favorite status for a place
    /// - Parameter placeId: The place ID to toggle
    func toggleFavorite(_ placeId: String)
    
    /// Add a place to favorites
    /// - Parameter placeId: The place ID to add
    func addFavorite(_ placeId: String)
    
    /// Remove a place from favorites
    /// - Parameter placeId: The place ID to remove
    func removeFavorite(_ placeId: String)
}

