//
//  SavedSearchManager.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 02/11/25.
//

import Foundation

/// Manager for saved searches business logic.
/// Returns data via async/await - does NOT use @Observable.
/// ViewModels are responsible for managing observable state.
@MainActor
class SavedSearchManager {
    private let service: SavedSearchService

    init(service: SavedSearchService) {
        self.service = service
    }

    // MARK: - Public Methods

    /// Get all saved searches sorted by last used
    func getAllSavedSearches() async throws -> [SavedSearch] {
        return try service.getAllSavedSearches()
    }

    /// Get saved search by ID
    func getSavedSearch(id: UUID) async throws -> SavedSearch? {
        let searches = try service.getAllSavedSearches()
        return searches.first { $0.id == id }
    }

    /// Save a new search
    func saveSearch(_ search: SavedSearch) async throws {
        try service.saveSearch(search)
    }

    /// Update an existing search
    func updateSearch(_ search: SavedSearch) async throws {
        try service.updateSearch(search)
    }

    /// Delete a saved search
    func deleteSearch(_ search: SavedSearch) async throws {
        try service.deleteSearch(search)
    }

    /// Delete saved search by ID
    func deleteSearch(id: UUID) async throws {
        try service.deleteSearch(id: id)
    }

    /// Clear all saved searches
    func clearAllSavedSearches() async throws {
        try service.clearAllSavedSearches()
    }

    /// Get recently used searches (last 5)
    func getRecentSearches(limit: Int = 5) async throws -> [SavedSearch] {
        let searches = try service.getAllSavedSearches()
        return Array(searches.prefix(limit))
    }

    /// Search saved searches by name or query
    func searchSavedSearches(query: String) async throws -> [SavedSearch] {
        let searches = try service.getAllSavedSearches()
        let lowercaseQuery = query.lowercased()
        return searches.filter { search in
            search.name.lowercased().contains(lowercaseQuery) ||
            search.query.lowercased().contains(lowercaseQuery)
        }
    }

    /// Check if a search with the same parameters already exists
    func findDuplicateSearch(
        query: String,
        latitude: Double?,
        longitude: Double?,
        filters: SearchFilters
    ) async throws -> SavedSearch? {
        let searches = try service.getAllSavedSearches()
        return searches.first { search in
            search.query == query &&
            search.latitude == latitude &&
            search.longitude == longitude &&
            search.minRating == filters.minRating &&
            search.maxPriceLevel == filters.maxPriceLevel &&
            search.openNow == filters.openNow &&
            search.maxDistance == filters.maxDistance
        }
    }

    /// Update last used timestamp for a saved search
    func updateLastUsed(id: UUID) async throws {
        guard let search = try await getSavedSearch(id: id) else {
            return
        }
        search.lastUsedAt = Date()
        try await updateSearch(search)
    }
}

