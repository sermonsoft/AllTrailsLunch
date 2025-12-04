//
//  DiscoveryViewModelTests.swift
//  AllTrailsLunchAppTests
//
//  Created by Tri Le on 04/11/25.
//

import XCTest
import CoreLocation
@testable import AllTrailsLunchApp

@MainActor
final class DiscoveryViewModelTests: XCTestCase {
    
    var sut: DiscoveryViewModel!
    var mockInteractor: MockDiscoveryInteractor!
    var mockEventLogger: MockEventLogger!
    var mockFilterPreferencesManager: FilterPreferencesManager!
    var mockSavedSearchManager: SavedSearchManager!

    override func setUp() async throws {
        try await super.setUp()

        // Create mock event logger first
        mockEventLogger = MockEventLogger()

        // Create mock managers
        mockFilterPreferencesManager = FilterPreferencesManager(service: MockFilterPreferencesService())
        mockSavedSearchManager = SavedSearchManager(service: MockSavedSearchService())

        // Create container with mock event logger
        let container = DependencyContainer()
        container.register(EventLogger.self, service: mockEventLogger)
        container.register(FavoritesManager.self, service: AppConfiguration.shared.createFavoritesManager())
        container.register(PhotoManager.self, service: AppConfiguration.shared.createPhotoManager())
        container.register(NetworkMonitor.self, service: AppConfiguration.shared.createNetworkMonitor())
        container.register(LocationManager.self, service: AppConfiguration.shared.createLocationManager())
        container.register(RestaurantManager.self, service: RestaurantManager(
            remote: AppConfiguration.shared.createRemotePlacesService(),
            cache: AppConfiguration.shared.createPlacesCacheService(),
            container: container
        ))
        container.register(FilterPreferencesManager.self, service: mockFilterPreferencesManager)
        container.register(SavedSearchManager.self, service: mockSavedSearchManager)

        // Create mock interactor with the container
        mockInteractor = MockDiscoveryInteractor(container: container)

        // Disable Combine pipelines in tests to avoid interference
        sut = DiscoveryViewModel(interactor: mockInteractor, enableCombinePipelines: false)
    }

    override func tearDown() async throws {
        sut = nil
        mockInteractor = nil
        mockEventLogger = nil
        mockFilterPreferencesManager = nil
        mockSavedSearchManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_SetsDefaultValues() {
        // Then
        XCTAssertEqual(sut.searchText, "")
        XCTAssertTrue(sut.results.isEmpty)
        XCTAssertEqual(sut.viewMode, .list)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertNil(sut.userLocation)
        XCTAssertNil(sut.nextPageToken)
    }
    
    func testInitialize_RequestsLocationPermission() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        
        // When
        await sut.initialize()
        
        // Then
        XCTAssertEqual(mockInteractor.requestLocationPermissionCallCount, 1)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "location_permission_requested"))
    }
    
    func testInitialize_GrantsLocationPermission_PerformsNearbySearch() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        
        // When
        await sut.initialize()
        
        // Then
        XCTAssertNotNil(sut.userLocation)
        XCTAssertEqual(mockInteractor.searchNearbyCallCount, 1)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "location_permission_granted"))
        XCTAssertTrue(mockEventLogger.didLog(eventName: "nearby_search_performed"))
    }
    
    func testInitialize_DeniesLocationPermission_SetsError() async {
        // Given
        mockInteractor.shouldFailLocationPermission = true
        mockInteractor.errorToThrow = .locationPermissionDenied
        
        // When
        await sut.initialize()
        
        // Then
        XCTAssertNil(sut.userLocation)
        XCTAssertEqual(sut.error, .locationPermissionDenied)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "location_permission_denied"))
    }
    
    // MARK: - Search Tests
    
    func testPerformSearch_EmptyQuery_PerformsNearbySearch() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        await sut.initialize()
        mockInteractor.reset()
        mockEventLogger.reset()
        
        // When
        sut.performSearch("")
        try? await Task.sleep(nanoseconds: 400_000_000) // Wait for debounce
        
        // Then
        XCTAssertEqual(mockInteractor.searchNearbyCallCount, 1)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "nearby_search_performed"))
    }
    
    func testPerformSearch_WithQuery_PerformsTextSearch() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = [PlaceFixtures.samplePizzaPlace]
        await sut.initialize()
        mockInteractor.reset()
        mockEventLogger.reset()
        
        // When
        sut.performSearch("pizza")
        try? await Task.sleep(nanoseconds: 600_000_000) // Wait for debounce
        
        // Then
        XCTAssertEqual(mockInteractor.searchTextCallCount, 1)
        XCTAssertEqual(mockInteractor.lastSearchTextQuery, "pizza")
        XCTAssertTrue(mockEventLogger.didLog(eventName: "search_performed"))
    }
    
    func testSearchNearby_Success_UpdatesResults() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        
        // When
        await sut.initialize()
        
        // Then
        XCTAssertEqual(sut.results.count, 5)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func testSearchNearby_Failure_SetsError() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        await sut.initialize()
        
        mockInteractor.shouldFailSearch = true
        mockInteractor.errorToThrow = ErrorFixtures.networkError
        
        // When
        await sut.refresh()
        
        // Then
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "search_error"))
    }
    
    func testSearchText_Success_UpdatesResults() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = [PlaceFixtures.sampleSushiPlace]
        await sut.initialize()
        mockInteractor.reset()

        // Set up for text search
        mockInteractor.placesToReturn = [PlaceFixtures.sampleSushiPlace]

        // When
        sut.performSearch("sushi")
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Then
        XCTAssertEqual(sut.results.count, 1)
        XCTAssertEqual(sut.results.first?.name, "Sakura Sushi")
    }
    
    // MARK: - Pagination Tests
    
    func testLoadNextPage_WithToken_LoadsMoreResults() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = [PlaceFixtures.sampleRestaurant]
        mockInteractor.nextPageTokenToReturn = "next-page-token"
        await sut.initialize()
        
        mockInteractor.placesToReturn = [PlaceFixtures.samplePizzaPlace]
        mockInteractor.nextPageTokenToReturn = nil
        
        // When
        await sut.loadNextPage()
        
        // Then
        XCTAssertEqual(sut.results.count, 2)
        XCTAssertNil(sut.nextPageToken)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "load_more_results"))
    }
    
    func testLoadNextPage_WithoutToken_DoesNothing() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        mockInteractor.nextPageTokenToReturn = nil
        await sut.initialize()
        
        let initialCount = mockInteractor.searchTextCallCount
        
        // When
        await sut.loadNextPage()
        
        // Then
        XCTAssertEqual(mockInteractor.searchTextCallCount, initialCount)
    }
    
    // MARK: - Favorite Tests
    
    func testToggleFavorite_CallsInteractor() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = [PlaceFixtures.sampleRestaurant]
        await sut.initialize()

        let place = PlaceFixtures.sampleRestaurant

        // When
        await sut.toggleFavorite(place)

        // Then
        XCTAssertEqual(mockInteractor.toggleFavoriteCallCount, 1)
        XCTAssertEqual(mockInteractor.lastToggledPlaceId, place.id)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "favorite_toggled"))
    }

    // MARK: - View Mode Tests

    func testViewMode_Change_LogsEvent() {
        // When
        sut.viewMode = .map

        // Then
        XCTAssertTrue(mockEventLogger.didLog(eventName: "view_mode_changed"))
        let params = mockEventLogger.parameters(for: "view_mode_changed")
        XCTAssertEqual(params?["mode"] as? String, "map")
    }

    // MARK: - Filter Tests

    func testApplyFilters_FiltersResults() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        await sut.initialize()

        // When
        await sut.applyFilters(SearchFiltersFixtures.highRatingFilter)

        // Then
        XCTAssertTrue(sut.results.allSatisfy { ($0.rating ?? 0) >= 4.5 })
        XCTAssertTrue(mockEventLogger.didLog(eventName: "filters_applied"))
    }

    func testClearFilters_ResetsFilters() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        await sut.initialize()

        await sut.applyFilters(SearchFiltersFixtures.highRatingFilter)

        // When
        await sut.clearFilters()

        // Then
        XCTAssertEqual(sut.filters, .default)
        XCTAssertEqual(sut.results.count, PlaceFixtures.samplePlaces.count)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "filters_cleared"))
    }

    // MARK: - Search Restriction Tests

    func testSaveSearch_WithInvalidCategory_ThrowsError() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        await sut.initialize()

        sut.searchText = "car repair shop"

        // When/Then
        do {
            try await sut.saveCurrentSearch(name: "My Car Search")
            XCTFail("Should throw error for invalid search category")
        } catch let error as PlacesError {
            if case .invalidSearchCategory = error {
                // Success
            } else {
                XCTFail("Expected invalidSearchCategory error, got \(error)")
            }
        } catch {
            XCTFail("Expected PlacesError, got \(error)")
        }
    }

    func testSaveSearch_WithValidFoodQuery_Succeeds() async throws {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        await sut.initialize()

        sut.searchText = "italian restaurant"

        // When
        try await sut.saveCurrentSearch(name: "Italian Places")

        // Then - Should not throw
        XCTAssertTrue(mockEventLogger.didLog(eventName: "search_saved"))
    }
}

