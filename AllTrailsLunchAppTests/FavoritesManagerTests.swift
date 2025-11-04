///
/// `FavoritesManagerTests.swift`
/// AllTrailsLunchTests
///
/// Unit tests for FavoritesManager with mock service.
///

import XCTest
@testable import AllTrailsLunch

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
        XCTAssertEqual(sut.favoriteIds, ["place1", "place2"])
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
    
    func testToggleFavorite_AddsFavoriteWhenNotPresent() {
        // Given
        mockService.favoriteIds = []
        sut = FavoritesManager(service: mockService)
        
        // When
        sut.toggleFavorite("place1")
        
        // Then
        XCTAssertTrue(sut.favoriteIds.contains("place1"))
        XCTAssertEqual(mockService.addFavoriteCallCount, 1)
        XCTAssertEqual(mockService.lastAddedPlaceId, "place1")
    }
    
    func testToggleFavorite_RemovesFavoriteWhenPresent() {
        // Given
        mockService.favoriteIds = ["place1"]
        sut = FavoritesManager(service: mockService)
        
        // When
        sut.toggleFavorite("place1")
        
        // Then
        XCTAssertFalse(sut.favoriteIds.contains("place1"))
        XCTAssertEqual(mockService.removeFavoriteCallCount, 1)
        XCTAssertEqual(mockService.lastRemovedPlaceId, "place1")
    }
    
    func testAddFavorite_AddsPlaceToFavorites() {
        // Given
        mockService.favoriteIds = []
        sut = FavoritesManager(service: mockService)
        
        // When
        sut.addFavorite("place1")
        
        // Then
        XCTAssertTrue(sut.favoriteIds.contains("place1"))
        XCTAssertEqual(mockService.addFavoriteCallCount, 1)
    }
    
    func testAddFavorite_DoesNotAddDuplicate() {
        // Given
        mockService.favoriteIds = ["place1"]
        sut = FavoritesManager(service: mockService)
        
        // When
        sut.addFavorite("place1")
        
        // Then
        XCTAssertEqual(sut.favoriteIds.count, 1)
        XCTAssertEqual(mockService.addFavoriteCallCount, 0)
    }
    
    func testRemoveFavorite_RemovesPlaceFromFavorites() {
        // Given
        mockService.favoriteIds = ["place1"]
        sut = FavoritesManager(service: mockService)
        
        // When
        sut.removeFavorite("place1")
        
        // Then
        XCTAssertFalse(sut.favoriteIds.contains("place1"))
        XCTAssertEqual(mockService.removeFavoriteCallCount, 1)
    }
    
    func testClearAllFavorites_RemovesAllFavorites() {
        // Given
        mockService.favoriteIds = ["place1", "place2", "place3"]
        sut = FavoritesManager(service: mockService)
        
        // When
        sut.clearAllFavorites()
        
        // Then
        XCTAssertTrue(sut.favoriteIds.isEmpty)
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
    
    func getFavoriteIds() -> Set<String> {
        return favoriteIds
    }
    
    func saveFavoriteIds(_ ids: Set<String>) throws {
        favoriteIds = ids
    }
    
    func isFavorite(_ placeId: String) -> Bool {
        favoriteIds.contains(placeId)
    }
    
    func addFavorite(_ placeId: String) throws {
        addFavoriteCallCount += 1
        lastAddedPlaceId = placeId
        favoriteIds.insert(placeId)
    }
    
    func removeFavorite(_ placeId: String) throws {
        removeFavoriteCallCount += 1
        lastRemovedPlaceId = placeId
        favoriteIds.remove(placeId)
    }
    
    func clearAllFavorites() throws {
        clearAllFavoritesCallCount += 1
        favoriteIds.removeAll()
    }
}

