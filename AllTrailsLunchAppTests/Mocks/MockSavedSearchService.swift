//
//  MockSavedSearchService.swift
//  AllTrailsLunchAppTests
//
//  Created by Tri Le on 04/11/25.
//

import Foundation
import SwiftData
@testable import AllTrailsLunchApp

@MainActor
final class MockSavedSearchService: SavedSearchService {

    // MARK: - Mock State

    var savedSearches: [SavedSearch] = []
    var shouldThrowError = false

    // MARK: - Call Tracking

    var getAllSearchesCallCount = 0
    var saveSearchCallCount = 0
    var deleteSearchCallCount = 0
    var lastSavedSearch: SavedSearch?
    var lastDeletedSearchId: UUID?

    // MARK: - Initializer

    init() {
        // Create an in-memory model container for testing
        let schema = Schema([SavedSearch.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        super.init(modelContext: container.mainContext)
    }

    // MARK: - SavedSearchService Overrides

    override func getAllSavedSearches() throws -> [SavedSearch] {
        getAllSearchesCallCount += 1
        return savedSearches
    }

    override func saveSearch(_ search: SavedSearch) throws {
        saveSearchCallCount += 1
        lastSavedSearch = search

        if shouldThrowError {
            throw NSError(domain: "TestError", code: -1, userInfo: nil)
        }

        savedSearches.append(search)
    }

    override func deleteSearch(id: UUID) throws {
        deleteSearchCallCount += 1
        lastDeletedSearchId = id

        if shouldThrowError {
            throw NSError(domain: "TestError", code: -1, userInfo: nil)
        }

        savedSearches.removeAll { $0.id == id }
    }

    // MARK: - Test Helpers

    func reset() {
        savedSearches.removeAll()
        shouldThrowError = false
        getAllSearchesCallCount = 0
        saveSearchCallCount = 0
        deleteSearchCallCount = 0
        lastSavedSearch = nil
        lastDeletedSearchId = nil
    }
}

