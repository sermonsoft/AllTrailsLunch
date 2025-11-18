//
//  SavedSearchInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation

/// Protocol for saved search business logic
/// Follows Interface Segregation Principle - focused on saved searches only
@MainActor
protocol SavedSearchInteractor {
    // MARK: - Saved Searches
    
    /// Get all saved searches sorted by last used
    /// - Returns: Array of saved searches
    /// - Throws: Error if retrieval fails
    func getAllSavedSearches() async throws -> [SavedSearch]
    
    /// Get saved search by ID
    /// - Parameter id: The saved search ID
    /// - Returns: Saved search if found, nil otherwise
    /// - Throws: Error if retrieval fails
    func getSavedSearch(id: UUID) async throws -> SavedSearch?
    
    /// Save a search
    /// - Parameter search: The search to save
    /// - Throws: Error if save fails
    func saveSearch(_ search: SavedSearch) async throws
    
    /// Delete a saved search
    /// - Parameter id: The saved search ID to delete
    /// - Throws: Error if delete fails
    func deleteSearch(id: UUID) async throws
    
    /// Update last used timestamp for a saved search
    /// - Parameter id: The saved search ID
    /// - Throws: Error if update fails
    func updateLastUsed(id: UUID) async throws

    /// Delete a saved search by object
    /// - Parameter search: The saved search to delete
    /// - Throws: Error if delete fails
    func deleteSearch(_ search: SavedSearch) async throws

    /// Find duplicate search with same parameters
    /// - Parameters:
    ///   - query: Search query text
    ///   - latitude: Optional latitude
    ///   - longitude: Optional longitude
    ///   - filters: Search filters
    /// - Returns: Duplicate search if found, nil otherwise
    /// - Throws: Error if search fails
    func findDuplicateSearch(
        query: String,
        latitude: Double?,
        longitude: Double?,
        filters: SearchFilters
    ) async throws -> SavedSearch?

    /// Clear all saved searches
    /// - Throws: Error if clear fails
    func clearAllSavedSearches() async throws
}

