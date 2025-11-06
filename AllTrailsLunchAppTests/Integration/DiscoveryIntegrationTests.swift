///
/// `DiscoveryIntegrationTests.swift`
/// AllTrailsLunchAppTests
///
/// Integration tests for the complete discovery flow.
///

import XCTest
import CoreLocation
@testable import AllTrailsLunchApp

@MainActor
final class DiscoveryIntegrationTests: XCTestCase {
    
    var viewModel: DiscoveryViewModel!
    var mockInteractor: MockDiscoveryInteractor!
    var mockEventLogger: MockEventLogger!
    var mockFilterPreferences: MockFilterPreferencesService!
    var mockSavedSearchService: MockSavedSearchService!
    
    override func setUp() async throws {
        try await super.setUp()
        mockInteractor = MockDiscoveryInteractor()
        mockEventLogger = MockEventLogger()
        mockFilterPreferences = MockFilterPreferencesService()
        mockSavedSearchService = MockSavedSearchService()
        
        viewModel = DiscoveryViewModel(
            interactor: mockInteractor,
            eventLogger: mockEventLogger,
            filterPreferences: mockFilterPreferences,
            savedSearchService: mockSavedSearchService
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockInteractor = nil
        mockEventLogger = nil
        mockFilterPreferences = nil
        mockSavedSearchService = nil
        try await super.tearDown()
    }
    
    // MARK: - Complete User Flows
    
    func testCompleteFlow_AppLaunch_NearbySearch_ViewDetails() async {
        // Given: App launches
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        
        // When: Initialize
        await viewModel.initialize()
        
        // Then: Location permission requested
        XCTAssertEqual(mockInteractor.requestLocationPermissionCallCount, 1)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "location_permission_requested"))
        
        // Then: Location granted and nearby search performed
        XCTAssertNotNil(viewModel.userLocation)
        XCTAssertEqual(mockInteractor.searchNearbyCallCount, 1)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "location_permission_granted"))
        XCTAssertTrue(mockEventLogger.didLog(eventName: "nearby_search_performed"))
        
        // Then: Results displayed
        XCTAssertEqual(viewModel.results.count, 5)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testCompleteFlow_Search_Filter_Favorite_Save() async {
        // Step 1: Initialize with nearby search
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        await viewModel.initialize()
        
        XCTAssertEqual(viewModel.results.count, 5)
        
        // Step 2: Perform text search
        mockInteractor.placesToReturn = [PlaceFixtures.sampleSushiPlace, PlaceFixtures.sampleCafePlace]
        viewModel.performSearch("sushi")
        try? await Task.sleep(nanoseconds: 600_000_000)

        XCTAssertEqual(mockInteractor.searchTextCallCount, 1)
        XCTAssertEqual(mockInteractor.lastSearchTextQuery, "sushi")
        XCTAssertTrue(mockEventLogger.didLog(eventName: "search_performed"))

        // Step 3: Apply filters
        viewModel.applyFilters(SearchFiltersFixtures.highRatingFilter)

        XCTAssertTrue(mockEventLogger.didLog(eventName: "filters_applied"))
        XCTAssertTrue(viewModel.results.allSatisfy { ($0.rating ?? 0) >= 4.5 })
        XCTAssertTrue(viewModel.results.count > 0, "Should have at least one result after filtering")

        // Step 4: Toggle favorite
        let place = viewModel.results.first!
        viewModel.toggleFavorite(place)
        
        XCTAssertEqual(mockInteractor.toggleFavoriteCallCount, 1)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "favorite_toggled"))
        
        // Step 5: Save search
        try? viewModel.saveCurrentSearch(name: "My Pizza Search")
        
        XCTAssertEqual(mockSavedSearchService.saveSearchCallCount, 1)
        XCTAssertEqual(mockSavedSearchService.lastSavedSearch?.name, "My Pizza Search")
        XCTAssertTrue(mockEventLogger.didLog(eventName: "search_saved"))
    }
    
    func testCompleteFlow_LoadSavedSearch_ApplyFilters() async {
        // Given: Initialize
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        await viewModel.initialize()
        
        // Given: Saved search exists
        let savedSearch = SavedSearchFixtures.sushiSearch
        mockSavedSearchService.savedSearches = [savedSearch]
        
        // When: Load saved search
        mockInteractor.placesToReturn = [PlaceFixtures.sampleSushiPlace]
        await viewModel.loadSavedSearch(savedSearch)
        
        // Then: Search performed with saved query
        XCTAssertEqual(viewModel.searchText, "sushi")
        XCTAssertEqual(mockInteractor.searchTextCallCount, 1)
        XCTAssertEqual(mockInteractor.lastSearchTextQuery, "sushi")
        
        // Then: Filters applied
        XCTAssertEqual(viewModel.filters.minRating, savedSearch.filters.minRating)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "saved_search_loaded"))
    }
    
    func testCompleteFlow_Pagination_LoadMore() async {
        // Given: Initialize with results and next page token
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = [PlaceFixtures.sampleRestaurant, PlaceFixtures.samplePizzaPlace]
        mockInteractor.nextPageTokenToReturn = "page-2-token"
        await viewModel.initialize()
        
        XCTAssertEqual(viewModel.results.count, 2)
        XCTAssertEqual(viewModel.nextPageToken, "page-2-token")
        
        // When: Load next page
        mockInteractor.placesToReturn = [PlaceFixtures.sampleSushiPlace, PlaceFixtures.sampleBurgerPlace]
        mockInteractor.nextPageTokenToReturn = "page-3-token"
        await viewModel.loadNextPage()
        
        // Then: More results appended
        XCTAssertEqual(viewModel.results.count, 4)
        XCTAssertEqual(viewModel.nextPageToken, "page-3-token")
        XCTAssertTrue(mockEventLogger.didLog(eventName: "load_more_results"))
    }
    
    func testCompleteFlow_SwitchViewMode_MaintainsState() async {
        // Given: Initialize with results
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        await viewModel.initialize()
        
        let initialResults = viewModel.results
        
        // When: Switch to map view
        viewModel.viewMode = .map
        
        // Then: Results maintained
        XCTAssertEqual(viewModel.results.count, initialResults.count)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "view_mode_changed"))
        
        // When: Switch back to list view
        viewModel.viewMode = .list
        
        // Then: Results still maintained
        XCTAssertEqual(viewModel.results.count, initialResults.count)
    }
    
    func testCompleteFlow_ErrorRecovery_Retry() async {
        // Given: Initialize fails
        mockInteractor.shouldFailLocationPermission = true
        mockInteractor.errorToThrow = .locationPermissionDenied
        await viewModel.initialize()
        
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "location_permission_denied"))
        
        // When: User grants permission and retries
        mockInteractor.shouldFailLocationPermission = false
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        await viewModel.initialize()
        
        // Then: Success
        XCTAssertNil(viewModel.error)
        XCTAssertNotNil(viewModel.userLocation)
        XCTAssertEqual(viewModel.results.count, 5)
    }
    
    func testCompleteFlow_NetworkError_Refresh() async {
        // Given: Initialize succeeds
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        await viewModel.initialize()
        
        XCTAssertEqual(viewModel.results.count, 5)
        
        // When: Refresh fails with network error
        mockInteractor.shouldFailSearch = true
        mockInteractor.errorToThrow = ErrorFixtures.networkError
        await viewModel.refresh()
        
        // Then: Error set
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(mockEventLogger.didLog(eventName: "search_error"))
        
        // When: Network recovers and refresh again
        mockInteractor.shouldFailSearch = false
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        await viewModel.refresh()
        
        // Then: Success
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.results.count, 5)
    }
    
    // MARK: - Edge Cases
    
    func testEdgeCase_EmptyResults() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = []
        
        // When
        await viewModel.initialize()
        
        // Then
        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testEdgeCase_RapidSearchChanges() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        await viewModel.initialize()
        
        // When: Rapid search changes
        viewModel.performSearch("pizza")
        viewModel.performSearch("sushi")
        viewModel.performSearch("burger")
        
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        // Then: Only last search executed
        XCTAssertEqual(mockInteractor.searchTextCallCount, 1)
        XCTAssertEqual(mockInteractor.lastSearchTextQuery, "burger")
    }
}

