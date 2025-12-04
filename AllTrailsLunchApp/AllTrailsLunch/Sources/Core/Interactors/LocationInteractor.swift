//
//  LocationInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation
import CoreLocation

/// Protocol for location services business logic
/// Follows Interface Segregation Principle - focused on location only
@MainActor
protocol LocationInteractor {
    // MARK: - Location
    
    /// Request location permission and get user's current location
    /// - Returns: User's current location coordinates
    /// - Throws: PlacesError if permission denied or location unavailable
    func requestLocationPermission() async throws -> CLLocationCoordinate2D
}

