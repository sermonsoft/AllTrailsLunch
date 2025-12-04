//
//  FilterManagementInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation

/// Protocol for filter management business logic
/// Follows Interface Segregation Principle - focused on filter management only
@MainActor
protocol FilterManagementInteractor {
    // MARK: - Filter Management
    
    /// Get current filters from persistence
    /// - Returns: Current search filters
    func getFilters() -> SearchFilters
    
    /// Save filters to persistence
    /// - Parameter filters: Filters to save
    /// - Throws: Error if save fails
    func saveFilters(_ filters: SearchFilters) async throws
    
    /// Load filters from persistence
    /// - Returns: Loaded search filters
    func loadFilters() -> SearchFilters
    
    /// Reset filters to default values
    /// - Throws: Error if reset fails
    func resetFilters() async throws
}

