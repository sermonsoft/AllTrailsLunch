//
//  FilterPreferencesManager.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 02/11/25.
//

import Foundation
import Observation

/// Manager for filter preferences with observable state.
/// Wraps FilterPreferencesService to provide business logic and state management.
@MainActor
@Observable
class FilterPreferencesManager {
    private let service: FilterPreferencesService
    
    // Observable state - automatically triggers UI updates
    private(set) var currentFilters: SearchFilters
    
    init(service: FilterPreferencesService) {
        self.service = service
        self.currentFilters = service.loadFilters()
    }
    
    // MARK: - Public Methods
    
    /// Get current filters
    func getFilters() -> SearchFilters {
        return currentFilters
    }
    
    /// Save filters and update observable state
    func saveFilters(_ filters: SearchFilters) {
        currentFilters = filters
        service.saveFilters(filters)
    }
    
    /// Load filters from persistence
    func loadFilters() -> SearchFilters {
        let filters = service.loadFilters()
        currentFilters = filters
        return filters
    }
    
    /// Clear filters and reset to default
    func clearFilters() {
        currentFilters = .default
        service.clearFilters()
    }
    
    /// Check if filters are currently applied (not default)
    func hasActiveFilters() -> Bool {
        return currentFilters != .default
    }
}

