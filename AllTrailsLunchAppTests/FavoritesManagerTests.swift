//
//  FavoritesManagerTests.swift
//  AllTrailsLunchAppTests
//
//  Created by Tri Le on 02/11/25.
//

import XCTest
@testable import AllTrailsLunchApp

@MainActor
final class FavoritesManagerTests: XCTestCase {
    var sut: FavoritesManager!
    var mockService: MockFavoritesService!
    
    override func setUp() {
        super.setUp()
        mockService = MockFavoritesService()
        sut = FavoritesManager(service: mockService)
    }
    
    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testInitialization_LoadsFavoritesFromService() {
        // Given
        mockService.favoriteIds = ["place1", "place2"]

        // When
        sut = FavoritesManager(service: mockService)

        // Then
        XCTAssertEqual(sut.getFavoriteIds(), ["place1", "place2"])
    }
    
    func testIsFavorite_ReturnsTrueForFavoritedPlace() {
        // Given
        mockService.favoriteIds = ["place1"]
        sut = FavoritesManager(service: mockService)
        
        // When
        let result = sut.isFavorite("place1")
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testIsFavorite_ReturnsFalseForNonFavoritedPlace() {
        // Given
        mockService.favoriteIds = ["place1"]
        sut = FavoritesManager(service: mockService)
        
        // When
        let result = sut.isFavorite("place2")
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testToggleFavorite_AddsFavoriteWhenNotPresent() async throws {
        // Given
        mockService.favoriteIds = []
        sut = FavoritesManager(service: mockService)

        // When
        try await sut.toggleFavorite("place1")

        // Then
        XCTAssertTrue(sut.getFavoriteIds().contains("place1"))
        XCTAssertEqual(mockService.addFavoriteCallCount, 1)
        XCTAssertEqual(mockService.lastAddedPlaceId, "place1")
    }

    func testToggleFavorite_RemovesFavoriteWhenPresent() async throws {
        // Given
        mockService.favoriteIds = ["place1"]
        sut = FavoritesManager(service: mockService)

        // When
        try await sut.toggleFavorite("place1")

        // Then
        XCTAssertFalse(sut.getFavoriteIds().contains("place1"))
        XCTAssertEqual(mockService.removeFavoriteCallCount, 1)
        XCTAssertEqual(mockService.lastRemovedPlaceId, "place1")
    }

    func testAddFavorite_AddsPlaceToFavorites() async throws {
        // Given
        mockService.favoriteIds = []
        sut = FavoritesManager(service: mockService)

        // When
        try await sut.addFavorite("place1")

        // Then
        XCTAssertTrue(sut.getFavoriteIds().contains("place1"))
        XCTAssertEqual(mockService.addFavoriteCallCount, 1)
    }

    func testAddFavorite_DoesNotAddDuplicate() async throws {
        // Given
        mockService.favoriteIds = ["place1"]
        sut = FavoritesManager(service: mockService)

        // When
        try await sut.addFavorite("place1")

        // Then
        XCTAssertEqual(sut.getFavoriteIds().count, 1)
        XCTAssertEqual(mockService.addFavoriteCallCount, 0)
    }

    func testRemoveFavorite_RemovesPlaceFromFavorites() async throws {
        // Given
        mockService.favoriteIds = ["place1"]
        sut = FavoritesManager(service: mockService)

        // When
        try await sut.removeFavorite("place1")

        // Then
        XCTAssertFalse(sut.getFavoriteIds().contains("place1"))
        XCTAssertEqual(mockService.removeFavoriteCallCount, 1)
    }

    func testClearAllFavorites_RemovesAllFavorites() async throws {
        // Given
        mockService.favoriteIds = ["place1", "place2", "place3"]
        sut = FavoritesManager(service: mockService)

        // When
        try await sut.clearAllFavorites()

        // Then
        XCTAssertTrue(sut.getFavoriteIds().isEmpty)
        XCTAssertEqual(mockService.clearAllFavoritesCallCount, 1)
    }
    
    func testApplyFavoriteStatus_UpdatesPlacesWithFavoriteStatus() {
        // Given
        mockService.favoriteIds = ["place1", "place3"]
        sut = FavoritesManager(service: mockService)
        
        let places = [
            Place(id: "place1", name: "Place 1", rating: 4.5, userRatingsTotal: 100, priceLevel: 2, latitude: 0, longitude: 0, address: nil, photoReferences: [], isFavorite: false),
            Place(id: "place2", name: "Place 2", rating: 4.0, userRatingsTotal: 50, priceLevel: 1, latitude: 0, longitude: 0, address: nil, photoReferences: [], isFavorite: false),
            Place(id: "place3", name: "Place 3", rating: 4.8, userRatingsTotal: 200, priceLevel: 3, latitude: 0, longitude: 0, address: nil, photoReferences: [], isFavorite: false)
        ]
        
        // When
        let result = sut.applyFavoriteStatus(to: places)
        
        // Then
        XCTAssertTrue(result[0].isFavorite)
        XCTAssertFalse(result[1].isFavorite)
        XCTAssertTrue(result[2].isFavorite)
    }
}

// MARK: - Mock Favorites Service

class MockFavoritesService: FavoritesService {
    var favoriteIds: Set<String> = []

    var addFavoriteCallCount = 0
    var removeFavoriteCallCount = 0
    var clearAllFavoritesCallCount = 0

    var lastAddedPlaceId: String?
    var lastRemovedPlaceId: String?

    var shouldThrowError = false

    func getFavoriteIds() -> Set<String> {
        return favoriteIds
    }

    func saveFavoriteIds(_ ids: Set<String>) throws {
        if shouldThrowError {
            throw NSError(domain: "MockFavoritesService", code: 1, userInfo: nil)
        }
        favoriteIds = ids
    }

    func isFavorite(_ placeId: String) -> Bool {
        favoriteIds.contains(placeId)
    }

    func addFavorite(_ placeId: String) throws {
        addFavoriteCallCount += 1
        lastAddedPlaceId = placeId
        if shouldThrowError {
            throw NSError(domain: "MockFavoritesService", code: 1, userInfo: nil)
        }
        favoriteIds.insert(placeId)
    }

    func removeFavorite(_ placeId: String) throws {
        removeFavoriteCallCount += 1
        lastRemovedPlaceId = placeId
        if shouldThrowError {
            throw NSError(domain: "MockFavoritesService", code: 1, userInfo: nil)
        }
        favoriteIds.remove(placeId)
    }

    func clearAllFavorites() throws {
        clearAllFavoritesCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "MockFavoritesService", code: 1, userInfo: nil)
        }
        favoriteIds.removeAll()
    }
}

