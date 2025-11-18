//
//  PhotoLoadingInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation

/// Protocol for photo loading business logic
/// Follows Interface Segregation Principle - focused on photo loading only
///
/// Note: This protocol is NOT @MainActor isolated because photo loading is an async
/// operation that can be called from any isolation domain. The underlying PhotoManager
/// is @MainActor but uses actors for caching, making it safe to call from anywhere.
protocol PhotoLoadingInteractor {
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

