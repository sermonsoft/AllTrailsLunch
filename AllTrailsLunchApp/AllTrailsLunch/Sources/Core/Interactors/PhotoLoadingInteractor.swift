//
//  PhotoLoadingInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation

/// Protocol for photo loading business logic
/// Follows Interface Segregation Principle - focused on photo loading only
@MainActor
protocol PhotoLoadingInteractor {
    // MARK: - Photo Loading
    
    /// Load a photo from a photo reference
    /// - Parameters:
    ///   - photoReference: Google Places photo reference
    ///   - maxWidth: Maximum width for the photo
    ///   - maxHeight: Maximum height for the photo
    /// - Returns: Image data if successful, nil otherwise
    nonisolated func loadPhoto(
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
    nonisolated func loadFirstPhoto(
        from photoReferences: [String],
        maxWidth: Int,
        maxHeight: Int
    ) async -> Data?
}

