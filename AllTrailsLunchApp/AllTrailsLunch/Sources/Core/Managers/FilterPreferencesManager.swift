//
//  FilterPreferencesManager.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 02/11/25.
//

import Foundation

/// Manager for filter preferences business logic.
/// Returns data via async/await - does NOT use @Observable.
/// ViewModels are responsible for managing observable state.
@MainActor
class FilterPreferencesManager {
    private let service: FilterPreferencesService

    init(service: FilterPreferencesService) {
        self.service = service
    }

    // MARK: - Public Methods

    /// Get current filters from persistence
    func getFilters() -> SearchFilters {
        return service.loadFilters()
    }

    /// Save filters to persistence
    func saveFilters(_ filters: SearchFilters) async throws {
        service.saveFilters(filters)
    }

    /// Load filters from persistence
    func loadFilters() -> SearchFilters {
        return service.loadFilters()
    }

    /// Clear filters and reset to default
    func clearFilters() async throws {
        service.clearFilters()
    }

    /// Check if filters are currently applied (not default)
    func hasActiveFilters(_ filters: SearchFilters) -> Bool {
        return filters != .default
    }
}

