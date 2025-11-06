//
//  RestaurantManagerTests.swift
//  AllTrailsLunchAppTests
//
//  Created by Tri Le on 02/11/25.
//

import XCTest
import CoreLocation
@testable import AllTrailsLunchApp

@MainActor
final class RestaurantManagerTests: XCTestCase {
    var sut: RestaurantManager!
    var mockRemoteService: MockRemotePlacesService!
    var mockFavoritesManager: FavoritesManager!
    var mockFavoritesService: MockFavoritesService!
    
    override func setUp() {
        super.setUp()
        mockRemoteService = MockRemotePlacesService()
        mockFavoritesService = MockFavoritesService()
        mockFavoritesManager = FavoritesManager(service: mockFavoritesService)
        sut = RestaurantManager(
            remote: mockRemoteService,
            cache: nil,
            favorites: mockFavoritesManager
        )
    }
    
    override func tearDown() {
        sut = nil
        mockRemoteService = nil
        mockFavoritesManager = nil
        mockFavoritesService = nil
        super.tearDown()
    }
    
    // MARK: - Search Nearby Tests
    
    func testSearchNearby_ReturnsPlacesWithFavoriteStatus() async throws {
        // Given
        let location = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let dto1 = createPlaceDTO(id: "place1", name: "Restaurant 1")
        let dto2 = createPlaceDTO(id: "place2", name: "Restaurant 2")
        
        mockRemoteService.nearbySearchResult = ([dto1, dto2], nil)
        mockFavoritesService.favoriteIds = ["place1"]
        mockFavoritesManager = FavoritesManager(service: mockFavoritesService)
        sut = RestaurantManager(remote: mockRemoteService, cache: nil, favorites: mockFavoritesManager)
        
        // When
        let (places, nextToken) = try await sut.searchNearby(location: location, radius: 1500)
        
        // Then
        XCTAssertEqual(places.count, 2)
        XCTAssertTrue(places[0].isFavorite)
        XCTAssertFalse(places[1].isFavorite)
        XCTAssertNil(nextToken)
        XCTAssertEqual(mockRemoteService.searchNearbyCallCount, 1)
    }
    
    func testSearchNearby_PassesCorrectParameters() async throws {
        // Given
        let location = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        mockRemoteService.nearbySearchResult = ([], nil)
        
        // When
        _ = try await sut.searchNearby(location: location, radius: 2000, pageToken: "token123")
        
        // Then
        XCTAssertEqual(mockRemoteService.lastLatitude, 37.7749)
        XCTAssertEqual(mockRemoteService.lastLongitude, -122.4194)
        XCTAssertEqual(mockRemoteService.lastRadius, 2000)
        XCTAssertEqual(mockRemoteService.lastPageToken, "token123")
    }
    
    func testSearchNearby_ReturnsNextPageToken() async throws {
        // Given
        let location = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let dto = createPlaceDTO(id: "place1", name: "Restaurant 1")
        mockRemoteService.nearbySearchResult = ([dto], "next_token_123")
        
        // When
        let (_, nextToken) = try await sut.searchNearby(location: location)
        
        // Then
        XCTAssertEqual(nextToken, "next_token_123")
    }
    
    // MARK: - Search Text Tests
    
    func testSearchText_ReturnsPlacesWithFavoriteStatus() async throws {
        // Given
        let dto1 = createPlaceDTO(id: "place1", name: "Pizza Place")
        let dto2 = createPlaceDTO(id: "place2", name: "Burger Joint")
        
        mockRemoteService.textSearchResult = ([dto1, dto2], nil)
        mockFavoritesService.favoriteIds = ["place2"]
        mockFavoritesManager = FavoritesManager(service: mockFavoritesService)
        sut = RestaurantManager(remote: mockRemoteService, cache: nil, favorites: mockFavoritesManager)
        
        // When
        let (places, _) = try await sut.searchText(query: "pizza")
        
        // Then
        XCTAssertEqual(places.count, 2)
        XCTAssertFalse(places[0].isFavorite)
        XCTAssertTrue(places[1].isFavorite)
    }
    
    func testSearchText_PassesCorrectParameters() async throws {
        // Given
        let location = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        mockRemoteService.textSearchResult = ([], nil)
        
        // When
        _ = try await sut.searchText(query: "sushi", location: location, pageToken: "token456")
        
        // Then
        XCTAssertEqual(mockRemoteService.lastQuery, "sushi")
        XCTAssertEqual(mockRemoteService.lastTextSearchLatitude, 37.7749)
        XCTAssertEqual(mockRemoteService.lastTextSearchLongitude, -122.4194)
        XCTAssertEqual(mockRemoteService.lastTextSearchPageToken, "token456")
    }
    
    // MARK: - Get Place Details Tests
    
    func testGetPlaceDetails_ReturnsDetailsWithFavoriteStatus() async throws {
        // Given
        let detailsDTO = createPlaceDetailsDTO(name: "Great Restaurant")
        mockRemoteService.placeDetailsResult = detailsDTO
        mockFavoritesService.favoriteIds = ["place123"]
        mockFavoritesManager = FavoritesManager(service: mockFavoritesService)
        sut = RestaurantManager(remote: mockRemoteService, cache: nil, favorites: mockFavoritesManager)
        
        // When
        let details = try await sut.getPlaceDetails(placeId: "place123")
        
        // Then
        XCTAssertEqual(details.place.name, "Great Restaurant")
        XCTAssertTrue(details.place.isFavorite)
        XCTAssertEqual(mockRemoteService.getPlaceDetailsCallCount, 1)
        XCTAssertEqual(mockRemoteService.lastPlaceId, "place123")
    }
    
    func testGetPlaceDetails_NonFavoritedPlace() async throws {
        // Given
        let detailsDTO = createPlaceDetailsDTO(name: "Another Restaurant")
        mockRemoteService.placeDetailsResult = detailsDTO
        mockFavoritesService.favoriteIds = []
        mockFavoritesManager = FavoritesManager(service: mockFavoritesService)
        sut = RestaurantManager(remote: mockRemoteService, cache: nil, favorites: mockFavoritesManager)
        
        // When
        let details = try await sut.getPlaceDetails(placeId: "place456")
        
        // Then
        XCTAssertFalse(details.place.isFavorite)
    }
    
    // MARK: - Helper Methods
    
    private func createPlaceDTO(id: String, name: String) -> PlaceDTO {
        PlaceDTO(
            id: id,
            name: name,
            rating: 4.5,
            userRatingsTotal: 100,
            priceLevel: 2,
            geometry: GeometryDTO(location: LocationDTO(lat: 37.7749, lng: -122.4194)),
            formattedAddress: "123 Main St",
            photos: nil,
            types: ["restaurant"]
        )
    }
    
    private func createPlaceDetailsDTO(name: String) -> PlaceDetailsDTO {
        PlaceDetailsDTO(
            name: name,
            rating: 4.5,
            formattedPhoneNumber: "(555) 123-4567",
            openingHours: nil,
            website: "https://example.com",
            reviews: nil,
            formattedAddress: "123 Main St"
        )
    }
}

// MARK: - Mock Remote Places Service

class MockRemotePlacesService: RemotePlacesService {
    var nearbySearchResult: (results: [PlaceDTO], nextPageToken: String?)?
    var textSearchResult: (results: [PlaceDTO], nextPageToken: String?)?
    var placeDetailsResult: PlaceDetailsDTO?
    
    var searchNearbyCallCount = 0
    var searchTextCallCount = 0
    var getPlaceDetailsCallCount = 0
    
    var lastLatitude: Double?
    var lastLongitude: Double?
    var lastRadius: Int?
    var lastPageToken: String?
    
    var lastQuery: String?
    var lastTextSearchLatitude: Double?
    var lastTextSearchLongitude: Double?
    var lastTextSearchPageToken: String?
    
    var lastPlaceId: String?
    
    func searchNearby(
        latitude: Double,
        longitude: Double,
        radius: Int,
        pageToken: String?
    ) async throws -> (results: [PlaceDTO], nextPageToken: String?) {
        searchNearbyCallCount += 1
        lastLatitude = latitude
        lastLongitude = longitude
        lastRadius = radius
        lastPageToken = pageToken
        
        guard let result = nearbySearchResult else {
            throw PlacesError.unknown("No mock result set")
        }
        return result
    }
    
    func searchText(
        query: String,
        latitude: Double?,
        longitude: Double?,
        pageToken: String?
    ) async throws -> (results: [PlaceDTO], nextPageToken: String?) {
        searchTextCallCount += 1
        lastQuery = query
        lastTextSearchLatitude = latitude
        lastTextSearchLongitude = longitude
        lastTextSearchPageToken = pageToken
        
        guard let result = textSearchResult else {
            throw PlacesError.unknown("No mock result set")
        }
        return result
    }
    
    func getPlaceDetails(placeId: String) async throws -> PlaceDetailsDTO {
        getPlaceDetailsCallCount += 1
        lastPlaceId = placeId
        
        guard let result = placeDetailsResult else {
            throw PlacesError.unknown("No mock result set")
        }
        return result
    }
}

