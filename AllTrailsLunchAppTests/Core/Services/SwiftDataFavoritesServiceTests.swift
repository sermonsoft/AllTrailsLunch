//
//  SwiftDataFavoritesServiceTests.swift
//  AllTrailsLunchAppTests
//
//  Created by AllTrails on 2025-11-04.
//

import XCTest
import SwiftData
@testable import AllTrailsLunchApp

@MainActor
final class SwiftDataFavoritesServiceTests: XCTestCase {
    var service: SwiftDataFavoritesService!
    var modelContext: ModelContext!
    var container: ModelContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory container for testing
        let schema = Schema([FavoritePlace.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        container = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = container.mainContext
        service = SwiftDataFavoritesService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        container = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Operations Tests
    
    func testAddFavorite_WithPlaceId_AddsToFavorites() throws {
        // Given
        let placeId = "test_place_1"
        
        // When
        try service.addFavorite(placeId)
        
        // Then
        XCTAssertTrue(service.isFavorite(placeId))
        let favoriteIds = service.getFavoriteIds()
        XCTAssertEqual(favoriteIds.count, 1)
        XCTAssertTrue(favoriteIds.contains(placeId))
    }
    
    func testAddFavorite_WithFullPlace_StoresAllData() throws {
        // Given
        let place = Place(
            id: "test_place_1",
            name: "Test Restaurant",
            rating: 4.5,
            userRatingsTotal: 100,
            priceLevel: 2,
            latitude: 37.7749,
            longitude: -122.4194,
            address: "123 Test St",
            photoReferences: ["photo1", "photo2"],
            isFavorite: false
        )
        
        // When
        try service.addFavorite(place)
        
        // Then
        XCTAssertTrue(service.isFavorite(place.id))
        
        let favorites = try service.getAllFavorites()
        XCTAssertEqual(favorites.count, 1)
        
        let favorite = favorites.first!
        XCTAssertEqual(favorite.placeId, place.id)
        XCTAssertEqual(favorite.name, place.name)
        XCTAssertEqual(favorite.address, place.address)
        XCTAssertEqual(favorite.latitude, place.latitude)
        XCTAssertEqual(favorite.longitude, place.longitude)
        XCTAssertEqual(favorite.rating, place.rating)
        XCTAssertEqual(favorite.priceLevel, place.priceLevel)
        XCTAssertEqual(favorite.photoReferences, place.photoReferences)
    }
    
    func testRemoveFavorite_RemovesFromFavorites() throws {
        // Given
        let placeId = "test_place_1"
        try service.addFavorite(placeId)
        XCTAssertTrue(service.isFavorite(placeId))
        
        // When
        try service.removeFavorite(placeId)
        
        // Then
        XCTAssertFalse(service.isFavorite(placeId))
        let favoriteIds = service.getFavoriteIds()
        XCTAssertEqual(favoriteIds.count, 0)
    }
    
    func testIsFavorite_ReturnsTrueForFavorite() throws {
        // Given
        let placeId = "test_place_1"
        try service.addFavorite(placeId)
        
        // When
        let isFavorite = service.isFavorite(placeId)
        
        // Then
        XCTAssertTrue(isFavorite)
    }
    
    func testIsFavorite_ReturnsFalseForNonFavorite() {
        // Given
        let placeId = "test_place_1"
        
        // When
        let isFavorite = service.isFavorite(placeId)
        
        // Then
        XCTAssertFalse(isFavorite)
    }
    
    func testClearAllFavorites_RemovesAllFavorites() throws {
        // Given
        try service.addFavorite("place1")
        try service.addFavorite("place2")
        try service.addFavorite("place3")
        XCTAssertEqual(service.getFavoriteIds().count, 3)
        
        // When
        try service.clearAllFavorites()
        
        // Then
        XCTAssertEqual(service.getFavoriteIds().count, 0)
        let favorites = try service.getAllFavorites()
        XCTAssertEqual(favorites.count, 0)
    }
    
    // MARK: - Update Tests
    
    func testUpdateFavorite_UpdatesExistingData() throws {
        // Given
        let originalPlace = Place(
            id: "test_place_1",
            name: "Original Name",
            rating: 4.0,
            userRatingsTotal: 50,
            priceLevel: 1,
            latitude: 37.7749,
            longitude: -122.4194,
            address: "123 Old St",
            photoReferences: ["photo1"],
            isFavorite: false
        )
        try service.addFavorite(originalPlace)

        // When
        let updatedPlace = Place(
            id: "test_place_1",
            name: "Updated Name",
            rating: 4.8,
            userRatingsTotal: 200,
            priceLevel: 3,
            latitude: 37.7749,
            longitude: -122.4194,
            address: "456 New St",
            photoReferences: ["photo1", "photo2", "photo3"],
            isFavorite: false
        )
        try service.updateFavorite(updatedPlace)
        
        // Then
        let favorites = try service.getAllFavorites()
        XCTAssertEqual(favorites.count, 1)
        
        let favorite = favorites.first!
        XCTAssertEqual(favorite.name, "Updated Name")
        XCTAssertEqual(favorite.address, "456 New St")
        XCTAssertEqual(favorite.rating, 4.8)
        XCTAssertEqual(favorite.priceLevel, 3)
        XCTAssertEqual(favorite.photoReferences.count, 3)
    }
    
    func testAddFavorite_WithExistingPlace_UpdatesData() throws {
        // Given
        let originalPlace = Place(
            id: "test_place_1",
            name: "Original Name",
            rating: 4.0,
            userRatingsTotal: 50,
            priceLevel: 1,
            latitude: 37.7749,
            longitude: -122.4194,
            address: "123 Old St",
            photoReferences: ["photo1"],
            isFavorite: false
        )
        try service.addFavorite(originalPlace)

        // When - Add same place with updated data
        let updatedPlace = Place(
            id: "test_place_1",
            name: "Updated Name",
            rating: 4.8,
            userRatingsTotal: 200,
            priceLevel: 3,
            latitude: 37.7749,
            longitude: -122.4194,
            address: "456 New St",
            photoReferences: ["photo1", "photo2"],
            isFavorite: false
        )
        try service.addFavorite(updatedPlace)
        
        // Then - Should update, not duplicate
        let favorites = try service.getAllFavorites()
        XCTAssertEqual(favorites.count, 1)
        
        let favorite = favorites.first!
        XCTAssertEqual(favorite.name, "Updated Name")
        XCTAssertEqual(favorite.rating, 4.8)
    }
    
    // MARK: - Query Tests

    func testGetAllFavorites_ReturnsSortedByDateAdded() async throws {
        // Given
        let place1 = createTestPlace(id: "1", name: "First")
        let place2 = createTestPlace(id: "2", name: "Second")
        let place3 = createTestPlace(id: "3", name: "Third")

        try service.addFavorite(place1)
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
        try service.addFavorite(place2)
        try await Task.sleep(nanoseconds: 10_000_000)
        try service.addFavorite(place3)

        // When
        let favorites = try service.getAllFavorites()

        // Then
        XCTAssertEqual(favorites.count, 3)
        // Should be sorted by date added (newest first)
        XCTAssertEqual(favorites[0].name, "Third")
        XCTAssertEqual(favorites[1].name, "Second")
        XCTAssertEqual(favorites[2].name, "First")
    }
    
    func testGetFavoritesSortedByRating_ReturnsSortedByRating() throws {
        // Given
        let place1 = createTestPlace(id: "1", name: "Low Rating", rating: 3.5)
        let place2 = createTestPlace(id: "2", name: "High Rating", rating: 4.8)
        let place3 = createTestPlace(id: "3", name: "Medium Rating", rating: 4.2)
        
        try service.addFavorite(place1)
        try service.addFavorite(place2)
        try service.addFavorite(place3)
        
        // When
        let favorites = try service.getFavoritesSortedByRating()
        
        // Then
        XCTAssertEqual(favorites.count, 3)
        XCTAssertEqual(favorites[0].rating, 4.8)
        XCTAssertEqual(favorites[1].rating, 4.2)
        XCTAssertEqual(favorites[2].rating, 3.5)
    }
    
    // MARK: - Helper Methods

    private func createTestPlace(
        id: String,
        name: String,
        rating: Double = 4.5,
        latitude: Double = 37.7749,
        longitude: Double = -122.4194
    ) -> Place {
        Place(
            id: id,
            name: name,
            rating: rating,
            userRatingsTotal: 100,
            priceLevel: 2,
            latitude: latitude,
            longitude: longitude,
            address: "123 Test St",
            photoReferences: ["photo1"],
            isFavorite: false
        )
    }
}

