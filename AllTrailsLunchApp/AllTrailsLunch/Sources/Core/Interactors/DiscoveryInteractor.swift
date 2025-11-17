//
//  DiscoveryInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation
import CoreLocation

/// Protocol for Discovery feature business logic
/// ViewModels should ONLY call methods on this protocol, never access managers directly
@MainActor
protocol DiscoveryInteractor {
    // MARK: - Location

    /// Request location permission and get user's current location
    /// - Returns: User's current location coordinates
    /// - Throws: PlacesError if permission denied or location unavailable
    func requestLocationPermission() async throws -> CLLocationCoordinate2D
    
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
    
    /// Get all favorite place IDs
    /// - Returns: Set of favorite place IDs
    func getFavoriteIds() -> Set<String>

    // MARK: - Network Monitoring

    /// Get the network monitor for observing connectivity status
    /// - Returns: NetworkMonitor instance
    func getNetworkMonitor() -> NetworkMonitor

    // MARK: - Event Logging

    /// Get the event logger for logging analytics events
    /// - Returns: EventLogger instance
    func getEventLogger() -> EventLogger

    // MARK: - Photo Loading

    /// Load a photo from a photo reference
    /// - Parameters:
    ///   - photoReference: Google Places photo reference
    ///   - maxWidth: Maximum width for the photo
    ///   - maxHeight: Maximum height for the photo
    /// - Returns: Image data if successful, nil otherwise
    func loadPhoto(
        photoReference: String,
        maxWidth: Int,
        maxHeight: Int
    ) async -> Data?

    /// Load the first available photo from a list of photo references
    /// - Parameters:
    ///   - photoReferences: Array of Google Places photo references
    ///   - maxWidth: Maximum width for the photo
    ///   - maxHeight: Maximum height for the photo
    /// - Returns: Image data if successful, nil otherwise
    func loadFirstPhoto(
        from photoReferences: [String],
        maxWidth: Int,
        maxHeight: Int
    ) async -> Data?
}

