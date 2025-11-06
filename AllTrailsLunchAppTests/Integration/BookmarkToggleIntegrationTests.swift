//
//  BookmarkToggleIntegrationTests.swift
//  AllTrailsLunchAppTests
//
//  Created by Tri Le on 06/11/25.
//

import XCTest
import SwiftUI
import CoreLocation
@testable import AllTrailsLunchApp

/// Integration tests for bookmark toggle functionality.
///
/// These tests verify that:
/// - FavoritesManager is properly shared as a single instance
/// - Bookmark state remains synchronized across all components
/// - ViewModel updates propagate correctly to the underlying data layer
/// - Observable state updates trigger UI refreshes
@MainActor
final class BookmarkToggleIntegrationTests: XCTestCase {

    // MARK: - Properties

    var coreInteractor: CoreInteractor!
    var viewModel: DiscoveryViewModel!
    var favoritesManager: FavoritesManager!
    var mockFavoritesService: MockFavoritesService!
    var mockEventLogger: MockEventLogger!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Create mock services
        mockFavoritesService = MockFavoritesService()
        mockEventLogger = MockEventLogger()
        
        // Create FavoritesManager with mock service
        favoritesManager = FavoritesManager(service: mockFavoritesService)
        
        // Create CoreInteractor with the FavoritesManager
        let config = AppConfiguration.shared
        let mockRemoteService = MockRemotePlacesService()
        mockRemoteService.nearbySearchResult = (results: [], nextPageToken: nil)

        coreInteractor = CoreInteractor(
            restaurantManager: RestaurantManager(
                remote: mockRemoteService,
                cache: nil,
                favorites: favoritesManager
            ),
            favoritesManager: favoritesManager,
            locationManager: config.createLocationManager()
        )
        
        // Create ViewModel with the same interactor
        viewModel = DiscoveryViewModel(
            interactor: coreInteractor,
            eventLogger: mockEventLogger
        )
    }
    
    override func tearDown() {
        viewModel = nil
        coreInteractor = nil
        favoritesManager = nil
        mockFavoritesService = nil
        mockEventLogger = nil
        super.tearDown()
    }
    
    // MARK: - Single Instance Tests

    /// Verifies CoreInteractor uses the injected FavoritesManager instance.
    func testFavoritesManager_SingleInstanceShared() {
        // Given & When
        let interactorFavoritesManager = coreInteractor.favoritesManager

        // Then
        XCTAssertTrue(interactorFavoritesManager === favoritesManager,
                      "CoreInteractor should use the same FavoritesManager instance we created")
    }

    /// Verifies multiple accesses to FavoritesManager return the same instance.
    func testFavoritesManager_InstanceIdentity() {
        // Given
        let manager1 = coreInteractor.favoritesManager
        let manager2 = coreInteractor.favoritesManager

        // When
        manager1.addFavorite("test-place-1")

        // Then
        XCTAssertTrue(manager1 === manager2, "Multiple accesses should return the same instance")
        XCTAssertTrue(manager2.isFavorite("test-place-1"), "Changes should be visible through all references")
    }
    
    // MARK: - Bookmark Toggle Integration Tests

    /// Verifies toggling a bookmark updates the shared FavoritesManager instance.
    func testBookmarkToggle_UpdatesSharedFavoritesManager() {
        // Given
        let place = PlaceFixtures.sampleRestaurant
        XCTAssertFalse(favoritesManager.isFavorite(place.id), "Place should not be favorited initially")

        // When
        viewModel.toggleFavorite(place)

        // Then
        XCTAssertTrue(favoritesManager.isFavorite(place.id),
                      "FavoritesManager should be updated when ViewModel toggles favorite")
        XCTAssertTrue(coreInteractor.favoritesManager.isFavorite(place.id),
                      "CoreInteractor's FavoritesManager should reflect the change")
    }

    /// Verifies ViewModel and CoreInteractor see consistent bookmark state.
    func testBookmarkToggle_ViewModelAndInteractorSeesSameState() {
        // Given
        let place = PlaceFixtures.sampleRestaurant

        // When
        viewModel.toggleFavorite(place)

        // Then
        let interactorSees = coreInteractor.isFavorite(place.id)
        let managerSees = favoritesManager.isFavorite(place.id)

        XCTAssertTrue(interactorSees, "Interactor should see the favorite")
        XCTAssertTrue(managerSees, "Manager should see the favorite")
        XCTAssertEqual(interactorSees, managerSees, "Interactor and Manager should see the same state")
    }

    /// Verifies state remains synchronized across multiple toggle operations.
    func testBookmarkToggle_MultipleToggles_StateStaysSynced() {
        // Given
        let place = PlaceFixtures.sampleRestaurant

        // When
        viewModel.toggleFavorite(place) // Add
        viewModel.toggleFavorite(place) // Remove
        viewModel.toggleFavorite(place) // Add again

        // Then
        XCTAssertTrue(favoritesManager.isFavorite(place.id))
        XCTAssertTrue(coreInteractor.isFavorite(place.id))
    }

    /// Verifies state synchronization when toggling multiple different places.
    func testBookmarkToggle_MultiplePlaces_AllStaysSynced() {
        // Given
        let place1 = PlaceFixtures.sampleRestaurant
        let place2 = PlaceFixtures.samplePizzaPlace
        let place3 = PlaceFixtures.sampleSushiPlace

        // When
        viewModel.toggleFavorite(place1) // Add
        viewModel.toggleFavorite(place2) // Add
        viewModel.toggleFavorite(place3) // Add
        viewModel.toggleFavorite(place2) // Remove

        // Then
        XCTAssertTrue(favoritesManager.isFavorite(place1.id))
        XCTAssertFalse(favoritesManager.isFavorite(place2.id))
        XCTAssertTrue(favoritesManager.isFavorite(place3.id))

        XCTAssertTrue(coreInteractor.isFavorite(place1.id))
        XCTAssertFalse(coreInteractor.isFavorite(place2.id))
        XCTAssertTrue(coreInteractor.isFavorite(place3.id))

        XCTAssertEqual(favoritesManager.favoriteIds.count, 2)
        XCTAssertEqual(coreInteractor.getFavoriteIds().count, 2)
    }
    
    // MARK: - Observable State Tests

    /// Verifies observable favoriteIds collection updates when adding a favorite.
    func testFavoritesManager_ObservableStateUpdates() {
        // Given
        let place = PlaceFixtures.sampleRestaurant
        let initialCount = favoritesManager.favoriteIds.count

        // When
        viewModel.toggleFavorite(place)

        // Then
        XCTAssertEqual(favoritesManager.favoriteIds.count, initialCount + 1,
                      "Observable favoriteIds should be updated")
        XCTAssertTrue(favoritesManager.favoriteIds.contains(place.id),
                      "Observable favoriteIds should contain the new favorite")
    }

    /// Verifies observable favoriteIds collection updates when removing a favorite.
    func testFavoritesManager_ObservableStateRemoves() {
        // Given
        let place = PlaceFixtures.sampleRestaurant
        viewModel.toggleFavorite(place) // Add first
        let countAfterAdd = favoritesManager.favoriteIds.count

        // When
        viewModel.toggleFavorite(place) // Remove

        // Then
        XCTAssertEqual(favoritesManager.favoriteIds.count, countAfterAdd - 1,
                      "Observable favoriteIds should be updated after removal")
        XCTAssertFalse(favoritesManager.favoriteIds.contains(place.id),
                       "Observable favoriteIds should not contain the removed favorite")
    }
    
    // MARK: - Service Integration Tests

    /// Verifies FavoritesService is called with correct parameters when toggling.
    func testBookmarkToggle_CallsServiceCorrectly() {
        // Given
        let place = PlaceFixtures.sampleRestaurant

        // When
        viewModel.toggleFavorite(place)

        // Then
        XCTAssertEqual(mockFavoritesService.addFavoriteCallCount, 1,
                      "Service should be called to persist the favorite")
        XCTAssertEqual(mockFavoritesService.lastAddedPlaceId, place.id,
                      "Service should receive the correct place ID")
    }

    /// Verifies in-memory state updates even when persistence fails.
    func testBookmarkToggle_ServiceFailure_StillUpdatesMemoryState() {
        // Given
        let place = PlaceFixtures.sampleRestaurant
        mockFavoritesService.shouldThrowError = true

        // When
        viewModel.toggleFavorite(place)

        // Then
        XCTAssertTrue(favoritesManager.isFavorite(place.id),
                      "Memory state should be updated even if persistence fails")
    }
    
    // MARK: - ViewModel Results Integration Tests

    /// Verifies ViewModel results array updates with favorite status after toggle.
    func testBookmarkToggle_UpdatesViewModelResults() {
        // Given
        let place = PlaceFixtures.sampleRestaurant
        viewModel.results = [place]

        // When
        viewModel.toggleFavorite(place)

        // Then
        XCTAssertTrue(viewModel.results[0].isFavorite,
                      "ViewModel results should be updated with favorite status")
    }

    /// Verifies ViewModel results stay synchronized with FavoritesManager state.
    func testBookmarkToggle_ViewModelResultsMatchFavoritesManager() {
        // Given
        let place1 = PlaceFixtures.sampleRestaurant
        let place2 = PlaceFixtures.samplePizzaPlace
        viewModel.results = [place1, place2]

        // When
        viewModel.toggleFavorite(place1)

        // Then
        XCTAssertEqual(viewModel.results[0].isFavorite, favoritesManager.isFavorite(place1.id),
                      "ViewModel results should match FavoritesManager state")
        XCTAssertEqual(viewModel.results[1].isFavorite, favoritesManager.isFavorite(place2.id),
                      "ViewModel results should match FavoritesManager state")
    }

    // MARK: - Event Logging Tests

    /// Verifies analytics events are logged correctly when toggling favorites.
    func testBookmarkToggle_LogsEventCorrectly() {
        // Given
        let place = PlaceFixtures.sampleRestaurant
        viewModel.results = [place]

        // When
        viewModel.toggleFavorite(place)

        // Then
        XCTAssertTrue(mockEventLogger.didLog(eventName: "favorite_toggled"),
                      "Should log favorite_toggled event")
        let params = mockEventLogger.parameters(for: "favorite_toggled")
        XCTAssertEqual(params?["place_id"] as? String, place.id)
        XCTAssertEqual(params?["is_favorite"] as? Bool, true)
    }
}

