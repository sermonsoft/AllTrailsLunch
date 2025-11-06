//
//  MockFilterPreferencesService.swift
//  AllTrailsLunchAppTests
//
//  Created by Tri Le on 04/11/25.
//

import Foundation
@testable import AllTrailsLunchApp

final class MockFilterPreferencesService: FilterPreferencesService {

    // MARK: - Mock State

    var savedFilters: SearchFilters = .default

    // MARK: - Call Tracking

    var loadFiltersCallCount = 0
    var saveFiltersCallCount = 0

    // MARK: - FilterPreferencesService Methods

    override func loadFilters() -> SearchFilters {
        loadFiltersCallCount += 1
        return savedFilters
    }

    override func saveFilters(_ filters: SearchFilters) {
        saveFiltersCallCount += 1
        savedFilters = filters
    }

    override func clearFilters() {
        savedFilters = .default
    }

    // MARK: - Test Helpers

    func reset() {
        savedFilters = .default
        loadFiltersCallCount = 0
        saveFiltersCallCount = 0
    }
}

