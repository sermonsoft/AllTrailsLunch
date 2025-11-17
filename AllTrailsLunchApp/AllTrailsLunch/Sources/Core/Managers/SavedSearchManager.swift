//
//  SavedSearchManager.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 02/11/25.
//

import Foundation
import Observation

/// Manager for saved searches with observable state.
/// Wraps SavedSearchService to provide business logic and state management.
@MainActor
@Observable
class SavedSearchManager {
    private let service: SavedSearchService
    
    // Observable state - automatically triggers UI updates
    private(set) var savedSearches: [SavedSearch] = []
    
    init(service: SavedSearchService) {
        self.service = service
        self.loadAllSearches()
    }
    
    // MARK: - Public Methods
    
    /// Get all saved searches sorted by last used
    func getAllSavedSearches() -> [SavedSearch] {
        return savedSearches
    }
    
    /// Reload all saved searches from persistence
    func loadAllSearches() {
        do {
            savedSearches = try service.getAllSavedSearches()
        } catch {
            savedSearches = []
        }
    }
    
    /// Get saved search by ID
    func getSavedSearch(id: UUID) -> SavedSearch? {
        return savedSearches.first { $0.id == id }
    }
    
    /// Save a new search
    func saveSearch(_ search: SavedSearch) throws {
        try service.saveSearch(search)
        loadAllSearches() // Reload to update observable state
    }
    
    /// Update an existing search
    func updateSearch(_ search: SavedSearch) throws {
        try service.updateSearch(search)
        loadAllSearches() // Reload to update observable state
    }
    
    /// Delete a saved search
    func deleteSearch(_ search: SavedSearch) throws {
        try service.deleteSearch(search)
        loadAllSearches() // Reload to update observable state
    }
    
    /// Delete saved search by ID
    func deleteSearch(id: UUID) throws {
        try service.deleteSearch(id: id)
        loadAllSearches() // Reload to update observable state
    }
    
    /// Clear all saved searches
    func clearAllSavedSearches() throws {
        try service.clearAllSavedSearches()
        savedSearches.removeAll()
    }
    
    /// Get recently used searches (last 5)
    func getRecentSearches(limit: Int = 5) -> [SavedSearch] {
        return Array(savedSearches.prefix(limit))
    }
    
    /// Search saved searches by name or query
    func searchSavedSearches(query: String) -> [SavedSearch] {
        let lowercaseQuery = query.lowercased()
        return savedSearches.filter { search in
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
    ) -> SavedSearch? {
        return savedSearches.first { search in
            search.query == query &&
            search.latitude == latitude &&
            search.longitude == longitude &&
            search.minRating == filters.minRating &&
            search.maxPriceLevel == filters.maxPriceLevel &&
            search.openNow == filters.openNow &&
            search.maxDistance == filters.maxDistance
        }
    }
}

