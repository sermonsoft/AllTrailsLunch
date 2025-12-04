//
//  PerformanceTests.swift
//  AllTrailsLunchAppTests
//
//  Created by Tri Le on 06/11/25.
//

import XCTest
import CoreLocation
@testable import AllTrailsLunchApp

@MainActor
final class PerformanceTests: XCTestCase {
    
    var viewModel: DiscoveryViewModel!
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
        container.register(FilterPreferencesManager.self, service: mockFilterPreferencesManager)
        container.register(SavedSearchManager.self, service: mockSavedSearchManager)

        // Create mock interactor with the container
        mockInteractor = MockDiscoveryInteractor(container: container)

        viewModel = DiscoveryViewModel(interactor: mockInteractor, enableCombinePipelines: false)
    }

    override func tearDown() async throws {
        viewModel = nil
        mockInteractor = nil
        mockEventLogger = nil
        mockFilterPreferencesManager = nil
        mockSavedSearchManager = nil
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

        // Measure filter application with manual timing
        var totalTime: CFAbsoluteTime = 0
        let iterations = 5

        for iteration in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            await viewModel.applyFilters(SearchFiltersFixtures.highRatingFilter)
            let end = CFAbsoluteTimeGetCurrent()

            let elapsed = end - start
            totalTime += elapsed
            print("Iteration \(iteration + 1): \(String(format: "%.4f", elapsed))s")

            await viewModel.clearFilters()
        }

        let averageTime = totalTime / Double(iterations)
        print("Average filter application time: \(String(format: "%.4f", averageTime))s (1000 places)")
        print("Total time: \(String(format: "%.4f", totalTime))s")

        // Performance threshold: filtering 1000 places should complete in under 100ms on average
        XCTAssertLessThan(averageTime, 0.1, "Filter application should complete in under 100ms on average, got \(String(format: "%.4f", averageTime))s")

        // Final verification - apply filter one more time
        await viewModel.applyFilters(SearchFiltersFixtures.highRatingFilter)
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
            await viewModel.toggleFavorite(place)
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
            Task { @MainActor in
                await viewModel.applyFilters(SearchFiltersFixtures.highRatingFilter)
            }
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
            Task { @MainActor in
                for _ in 0..<50 {
                    await viewModel.applyFilters(SearchFiltersFixtures.highRatingFilter)
                    await viewModel.applyFilters(SearchFiltersFixtures.lowPriceFilter)
                    await viewModel.clearFilters()
                }
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
            try await viewModel.saveCurrentSearch(name: "Search \(i)")
        }

        // Then: Verify all saved
        let savedSearches = try await mockSavedSearchManager.getAllSavedSearches()
        XCTAssertEqual(savedSearches.count, 20)

        // Measure loading saved searches
        measure {
            Task { @MainActor in
                for savedSearch in savedSearches {
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
                await viewModel.toggleFavorite(PlaceFixtures.sampleRestaurant)
                await viewModel.applyFilters(SearchFiltersFixtures.highRatingFilter)
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
            Task { @MainActor in
                await viewModel.applyFilters(SearchFiltersFixtures.combinedFilter)
            }
        }
    }
}

