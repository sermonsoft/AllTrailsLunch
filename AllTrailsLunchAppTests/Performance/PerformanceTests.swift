///
/// `PerformanceTests.swift`
/// AllTrailsLunchAppTests
///
/// Performance and stress tests for the AllTrailsLunch app.
///

import XCTest
import CoreLocation
@testable import AllTrailsLunchApp

@MainActor
final class PerformanceTests: XCTestCase {
    
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
    
    // MARK: - Load Performance Tests
    
    func testPerformance_InitializeViewModel() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces

        // Measure - run multiple iterations manually
        for _ in 0..<5 {
            await viewModel.initialize()
            mockInteractor.reset()
            mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
            mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        }

        // Final verification
        XCTAssertEqual(viewModel.results.count, 5)
    }
    
    func testPerformance_SearchWithLargeDataset() async {
        // Given: Large dataset
        let largePlaceList = (0..<100).map { index in
            PlaceFixtures.createPlace(
                id: "place-\(index)",
                name: "Restaurant \(index)",
                rating: Double.random(in: 3.0...5.0),
                userRatingsTotal: Int.random(in: 10...500),
                priceLevel: Int.random(in: 1...4)
            )
        }

        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = largePlaceList

        // Measure - run multiple iterations manually
        for _ in 0..<5 {
            await viewModel.initialize()
            mockInteractor.reset()
            mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
            mockInteractor.placesToReturn = largePlaceList
        }

        // Verify results loaded
        XCTAssertEqual(viewModel.results.count, 100)
    }
    
    func testPerformance_ApplyFiltersToLargeDataset() async {
        // Given: Large dataset
        let largePlaceList = (0..<1000).map { index in
            PlaceFixtures.createPlace(
                id: "place-\(index)",
                name: "Restaurant \(index)",
                rating: Double.random(in: 3.0...5.0),
                userRatingsTotal: Int.random(in: 10...500),
                priceLevel: Int.random(in: 1...4)
            )
        }
        
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = largePlaceList
        await viewModel.initialize()
        
        // Measure filter application
        measure {
            viewModel.applyFilters(SearchFiltersFixtures.highRatingFilter)
        }

        // Verify filtering worked
        XCTAssertTrue(viewModel.results.allSatisfy { ($0.rating ?? 0) >= 4.5 })
    }
    
    func testPerformance_RapidSearchChanges() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        await viewModel.initialize()
        
        // Measure rapid search changes
        measure {
            for query in ["pizza", "sushi", "burger", "cafe", "bar"] {
                viewModel.performSearch(query)
            }
        }
    }
    
    func testPerformance_ToggleFavoriteMultipleTimes() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = [PlaceFixtures.sampleRestaurant]
        await viewModel.initialize()

        let place = PlaceFixtures.sampleRestaurant

        // Measure - run directly without measure block
        for _ in 0..<100 {
            viewModel.toggleFavorite(place)
        }

        // Verify call count
        XCTAssertEqual(mockInteractor.toggleFavoriteCallCount, 100)
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemory_LargeResultSet() async {
        // Given: Very large dataset
        let veryLargePlaceList = (0..<5000).map { index in
            PlaceFixtures.createPlace(
                id: "place-\(index)",
                name: "Restaurant \(index)",
                rating: Double.random(in: 3.0...5.0),
                userRatingsTotal: Int.random(in: 10...500),
                priceLevel: Int.random(in: 1...4),
                photoReferences: (0..<5).map { "photo-\(index)-\($0)" }
            )
        }
        
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = veryLargePlaceList
        
        // When
        await viewModel.initialize()
        
        // Then: Verify all loaded
        XCTAssertEqual(viewModel.results.count, 5000)
        
        // Measure memory usage during filtering
        measure(metrics: [XCTMemoryMetric()]) {
            viewModel.applyFilters(SearchFiltersFixtures.highRatingFilter)
        }
    }
    
    func testMemory_MultipleSearches() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        
        // Measure memory during multiple searches
        measure(metrics: [XCTMemoryMetric()]) {
            Task { @MainActor in
                for i in 0..<50 {
                    mockInteractor.placesToReturn = (0..<20).map { index in
                        PlaceFixtures.createPlace(
                            id: "place-\(i)-\(index)",
                            name: "Restaurant \(i)-\(index)"
                        )
                    }
                    await viewModel.refresh()
                }
            }
        }
    }
    
    // MARK: - Stress Tests
    
    func testStress_RapidViewModeChanges() {
        // Measure
        measure {
            for _ in 0..<100 {
                viewModel.viewMode = .map
                viewModel.viewMode = .list
            }
        }
        
        // Verify final state
        XCTAssertEqual(viewModel.viewMode, .list)
    }
    
    func testStress_ConcurrentFilterChanges() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        await viewModel.initialize()
        
        // Measure concurrent filter changes
        measure {
            for _ in 0..<50 {
                viewModel.applyFilters(SearchFiltersFixtures.highRatingFilter)
                viewModel.applyFilters(SearchFiltersFixtures.lowPriceFilter)
                viewModel.clearFilters()
            }
        }
    }
    
    func testStress_SaveAndLoadMultipleSearches() async throws {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        await viewModel.initialize()
        
        // When: Save multiple searches
        for i in 0..<20 {
            try viewModel.saveCurrentSearch(name: "Search \(i)")
        }
        
        // Then: Verify all saved
        XCTAssertEqual(mockSavedSearchService.savedSearches.count, 20)
        
        // Measure loading saved searches
        measure {
            Task { @MainActor in
                for savedSearch in mockSavedSearchService.savedSearches {
                    await viewModel.loadSavedSearch(savedSearch)
                }
            }
        }
    }
    
    // MARK: - Pagination Performance
    
    func testPerformance_LoadMultiplePages() async {
        // Given: Initial page
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = Array(PlaceFixtures.samplePlaces.prefix(2))
        mockInteractor.nextPageTokenToReturn = "page-2"
        await viewModel.initialize()

        // Measure loading 10 pages - run directly without measure block
        for page in 2...10 {
            mockInteractor.placesToReturn = (0..<2).map { index in
                PlaceFixtures.createPlace(
                    id: "place-page\(page)-\(index)",
                    name: "Restaurant Page \(page)-\(index)"
                )
            }
            mockInteractor.nextPageTokenToReturn = page < 10 ? "page-\(page + 1)" : nil
            await viewModel.loadNextPage()
        }

        // Verify all pages loaded
        XCTAssertEqual(viewModel.results.count, 20) // 2 per page × 10 pages
    }
    
    // MARK: - Event Logging Performance
    
    func testPerformance_EventLogging() async {
        // Given
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = PlaceFixtures.samplePlaces
        
        // Measure event logging overhead
        measure {
            Task { @MainActor in
                await viewModel.initialize()
                viewModel.viewMode = .map
                viewModel.viewMode = .list
                viewModel.toggleFavorite(PlaceFixtures.sampleRestaurant)
                viewModel.applyFilters(SearchFiltersFixtures.highRatingFilter)
            }
        }
        
        // Verify events logged
        XCTAssertGreaterThan(mockEventLogger.logCallCount, 0)
    }
    
    // MARK: - CPU Performance
    
    func testCPU_FilteringComplexCriteria() async {
        // Given: Large dataset
        let largePlaceList = (0..<1000).map { index in
            PlaceFixtures.createPlace(
                id: "place-\(index)",
                name: "Restaurant \(index)",
                rating: Double.random(in: 3.0...5.0),
                userRatingsTotal: Int.random(in: 10...500),
                priceLevel: Int.random(in: 1...4)
            )
        }
        
        mockInteractor.locationToReturn = PlaceFixtures.sanFranciscoLocation
        mockInteractor.placesToReturn = largePlaceList
        await viewModel.initialize()
        
        // Measure CPU usage during complex filtering
        measure(metrics: [XCTCPUMetric()]) {
            viewModel.applyFilters(SearchFiltersFixtures.combinedFilter)
        }
    }
}

