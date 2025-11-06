//
//  SavedSearchService.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 04/11/25.
//

import Foundation
import SwiftData

/// Service for saved search operations
@MainActor
class SavedSearchService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD Operations
    
    /// Get all saved searches sorted by last used
    func getAllSavedSearches() throws -> [SavedSearch] {
        let descriptor = FetchDescriptor<SavedSearch>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Get saved search by ID
    func getSavedSearch(id: UUID) throws -> SavedSearch? {
        let predicate = #Predicate<SavedSearch> { search in
            search.id == id
        }
        let descriptor = FetchDescriptor<SavedSearch>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }
    
    /// Save a new search
    func saveSearch(_ search: SavedSearch) throws {
        modelContext.insert(search)
        try modelContext.save()
    }
    
    /// Update an existing search
    func updateSearch(_ search: SavedSearch) throws {
        search.lastUsedAt = Date()
        try modelContext.save()
    }
    
    /// Delete a saved search
    func deleteSearch(_ search: SavedSearch) throws {
        modelContext.delete(search)
        try modelContext.save()
    }
    
    /// Delete saved search by ID
    func deleteSearch(id: UUID) throws {
        guard let search = try getSavedSearch(id: id) else {
            return
        }
        try deleteSearch(search)
    }
    
    /// Clear all saved searches
    func clearAllSavedSearches() throws {
        let searches = try getAllSavedSearches()
        for search in searches {
            modelContext.delete(search)
        }
        try modelContext.save()
    }
    
    // MARK: - Query Operations
    
    /// Get recently used searches (last 5)
    func getRecentSearches(limit: Int = 5) throws -> [SavedSearch] {
        let descriptor = FetchDescriptor<SavedSearch>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        let allSearches = try modelContext.fetch(descriptor)
        return Array(allSearches.prefix(limit))
    }
    
    /// Search saved searches by name or query
    func searchSavedSearches(query: String) throws -> [SavedSearch] {
        let lowercaseQuery = query.lowercased()
        let allSearches = try getAllSavedSearches()
        
        return allSearches.filter { search in
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
    ) throws -> SavedSearch? {
        let allSearches = try getAllSavedSearches()
        
        return allSearches.first { search in
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

