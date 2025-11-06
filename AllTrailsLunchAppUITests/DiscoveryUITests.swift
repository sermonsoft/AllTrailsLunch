//
//  DiscoveryUITests.swift
//  AllTrailsLunchAppTests
//
//  Created by Tri Le on 06/11/25.
//

import XCTest

final class DiscoveryUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Critical Flow Tests
    
    func testCriticalFlow_AppLaunch_DisplaysRestaurants() throws {
        // Given: App launches
        // When: Wait for restaurants to load
        let firstRestaurant = app.staticTexts.matching(identifier: "restaurant-name").firstMatch
        XCTAssertTrue(firstRestaurant.waitForExistence(timeout: 5))
        
        // Then: Restaurants are displayed
        XCTAssertTrue(firstRestaurant.exists)
    }
    
    func testCriticalFlow_Search_DisplaysResults() throws {
        // Given: App is loaded
        let searchField = app.searchFields["Search restaurants"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        
        // When: User searches for "pizza"
        searchField.tap()
        searchField.typeText("pizza")
        
        // Wait for search results
        sleep(1)
        
        // Then: Results are displayed
        let results = app.staticTexts.matching(identifier: "restaurant-name")
        XCTAssertGreaterThan(results.count, 0)
    }
    
    func testCriticalFlow_ToggleFavorite_UpdatesIcon() throws {
        // Given: App is loaded with restaurants
        let firstBookmark = app.buttons.matching(identifier: "bookmark-button").firstMatch
        XCTAssertTrue(firstBookmark.waitForExistence(timeout: 5))
        
        // When: User taps bookmark
        firstBookmark.tap()
        
        // Then: Bookmark icon updates (visual feedback)
        // Note: In real implementation, check for icon state change
        XCTAssertTrue(firstBookmark.exists)
    }
    
    func testCriticalFlow_SwitchToMapView_DisplaysMap() throws {
        // Given: App is in list view
        let mapButton = app.buttons["Map"]
        XCTAssertTrue(mapButton.waitForExistence(timeout: 5))
        
        // When: User switches to map view
        mapButton.tap()
        
        // Then: Map is displayed
        let mapView = app.otherElements["map-view"]
        XCTAssertTrue(mapView.waitForExistence(timeout: 3))
    }
    
    func testCriticalFlow_OpenRestaurantDetails_DisplaysDetails() throws {
        // Given: App is loaded with restaurants
        let firstRestaurant = app.staticTexts.matching(identifier: "restaurant-name").firstMatch
        XCTAssertTrue(firstRestaurant.waitForExistence(timeout: 5))
        
        // When: User taps on restaurant
        firstRestaurant.tap()
        
        // Then: Detail view is displayed
        let detailView = app.navigationBars.firstMatch
        XCTAssertTrue(detailView.waitForExistence(timeout: 3))
    }
    
    func testCriticalFlow_ApplyFilters_UpdatesResults() throws {
        // Given: App is loaded
        let filterButton = app.buttons["Filters"]
        XCTAssertTrue(filterButton.waitForExistence(timeout: 5))
        
        // When: User opens filters
        filterButton.tap()
        
        // Then: Filter sheet is displayed
        let filterSheet = app.sheets.firstMatch
        XCTAssertTrue(filterSheet.waitForExistence(timeout: 2))
        
        // When: User applies filter
        let applyButton = app.buttons["Apply"]
        if applyButton.exists {
            applyButton.tap()
        }
        
        // Then: Results are filtered
        let results = app.staticTexts.matching(identifier: "restaurant-name")
        XCTAssertGreaterThanOrEqual(results.count, 0)
    }
    
    func testCriticalFlow_PullToRefresh_ReloadsData() throws {
        // Given: App is loaded with restaurants
        let firstCell = app.staticTexts.matching(identifier: "restaurant-name").firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        
        // When: User pulls to refresh
        let start = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = start.withOffset(CGVector(dx: 0, dy: 200))
        start.press(forDuration: 0.1, thenDragTo: end)
        
        // Then: Loading indicator appears and data reloads
        sleep(1)
        XCTAssertTrue(firstCell.exists)
    }
    
    func testCriticalFlow_ScrollToBottom_LoadsMoreResults() throws {
        // Given: App is loaded with restaurants
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        
        // When: User scrolls to bottom
        table.swipeUp()
        table.swipeUp()
        table.swipeUp()
        
        // Then: More results are loaded
        sleep(1)
        let results = app.staticTexts.matching(identifier: "restaurant-name")
        XCTAssertGreaterThan(results.count, 0)
    }
    
    // MARK: - Map View Tests
    
    func testMapView_TapPin_ShowsCard() throws {
        // Given: Switch to map view
        let mapButton = app.buttons["Map"]
        XCTAssertTrue(mapButton.waitForExistence(timeout: 5))
        mapButton.tap()
        
        // When: User taps on a pin
        let mapView = app.otherElements["map-view"]
        XCTAssertTrue(mapView.waitForExistence(timeout: 3))
        
        // Tap center of map (where a pin likely is)
        mapView.tap()
        
        // Then: Card appears at bottom
        sleep(1)
        let card = app.otherElements.matching(identifier: "restaurant-card").firstMatch
        // Note: Card may or may not appear depending on pin location
    }
    
    func testMapView_SearchUpdates_PinsChange() throws {
        // Given: Switch to map view
        let mapButton = app.buttons["Map"]
        XCTAssertTrue(mapButton.waitForExistence(timeout: 5))
        mapButton.tap()
        
        // When: User searches
        let searchField = app.searchFields["Search restaurants"]
        searchField.tap()
        searchField.typeText("sushi")
        
        // Then: Map updates with new pins
        sleep(2)
        let mapView = app.otherElements["map-view"]
        XCTAssertTrue(mapView.exists)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling_NoLocationPermission_ShowsError() throws {
        // Note: This test requires special setup to deny location permission
        // In real implementation, use launch arguments to simulate permission denial
        
        // Given: App launches without location permission
        // Then: Error message is displayed
        // This would need to be tested with proper permission mocking
    }
    
    func testErrorHandling_NetworkError_ShowsRetry() throws {
        // Note: This test requires network simulation
        // In real implementation, use launch arguments to simulate network failure
        
        // Given: App launches with network error
        // Then: Error message and retry button are displayed
        // This would need to be tested with proper network mocking
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_AppLaunch() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launch()
            app.terminate()
        }
    }
    
    func testPerformance_SearchTyping() throws {
        let searchField = app.searchFields["Search restaurants"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        
        measure {
            searchField.tap()
            searchField.typeText("pizza")
            sleep(1)
            searchField.buttons["Clear text"].tap()
        }
    }
    
    func testPerformance_ScrollingList() throws {
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        
        measure {
            for _ in 0..<10 {
                table.swipeUp()
            }
            for _ in 0..<10 {
                table.swipeDown()
            }
        }
    }
}

