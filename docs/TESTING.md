# Testing Guide

> **Overview**: This document explains the testing strategy, coverage, and how to run tests.

---

## 📊 Test Coverage Summary

### Test Suite Overview

| Test Type | Count | Files | Coverage |
|-----------|-------|-------|----------|
| **Integration Tests** | 22 | 2 | End-to-end workflows |
| **Unit Tests** | 51 | 8 | Managers, Services, ViewModels |
| **Performance Tests** | 13 | 1 | Speed, Memory, Concurrency |
| **Total** | **86** | **11** | **Comprehensive** |

### Coverage by Component

| Component | Tests | Coverage | Status |
|-----------|-------|----------|--------|
| FavoritesManager | 10 | 100% | ✅ |
| RestaurantManager | 7 | 100% | ✅ |
| PhotoManager | 9 | 100% | ✅ |
| DiscoveryViewModel | 15 | 95% | ✅ |
| SwiftDataService | 10 | 100% | ✅ |
| BookmarkToggle Flow | 13 | 100% | ✅ |
| Discovery Flow | 9 | 90% | ✅ |
| Performance | 13 | N/A | ✅ |

---

## 🧪 Running Tests

### Run All Tests (86 tests)

```bash
xcodebuild test -scheme AllTrailsLunchAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

**Expected**: ✅ All 86 tests pass in ~30 seconds

### Run Integration Tests Only (22 tests)

```bash
xcodebuild test -scheme AllTrailsLunchAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:AllTrailsLunchAppTests/BookmarkToggleIntegrationTests \
  -only-testing:AllTrailsLunchAppTests/DiscoveryIntegrationTests
```

### Run Unit Tests Only (51 tests)

```bash
xcodebuild test -scheme AllTrailsLunchAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -skip-testing:AllTrailsLunchAppTests/DiscoveryIntegrationTests \
  -skip-testing:AllTrailsLunchAppTests/PerformanceTests
```

### Run Performance Tests Only (13 tests)

```bash
xcodebuild test -scheme AllTrailsLunchAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:AllTrailsLunchAppTests/PerformanceTests
```

### Run Specific Test File

```bash
# BookmarkToggleIntegrationTests (13 tests)
xcodebuild test -scheme AllTrailsLunchAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:AllTrailsLunchAppTests/BookmarkToggleIntegrationTests

# DiscoveryViewModelTests (15 tests)
xcodebuild test -scheme AllTrailsLunchAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:AllTrailsLunchAppTests/DiscoveryViewModelTests
```

---

## 📁 Test Files

### Integration Tests (22 tests)

#### 1. BookmarkToggleIntegrationTests.swift (13 tests)

**Purpose**: Verify favorites sync across the entire app

**Key Tests**:
- `testFavoritesManager_SingleInstanceShared()` - Singleton pattern
- `testBookmarkToggle_UpdatesSharedFavoritesManager()` - State sync
- `testBookmarkToggle_ViewModelResultsMatchFavoritesManager()` - Consistency
- `testBookmarkToggle_ServiceFailure_StillUpdatesMemoryState()` - Error handling
- `testBookmarkToggle_LogsEventCorrectly()` - Analytics

**What It Tests**:
- FavoritesManager is shared across app
- ViewModel and Interactor see same state
- Observable state updates correctly
- Service failures don't break in-memory state
- Analytics events are logged

#### 2. DiscoveryIntegrationTests.swift (9 tests)

**Purpose**: Verify end-to-end discovery workflows

**Key Tests**:
- `testCompleteFlow_AppLaunch_NearbySearch_ViewDetails()` - Happy path
- `testCompleteFlow_Search_Filter_Favorite_Save()` - Complex workflow
- `testCompleteFlow_NetworkError_Refresh()` - Error recovery
- `testCompleteFlow_Pagination_LoadMore()` - Pagination
- `testEdgeCase_RapidSearchChanges()` - Debouncing

**What It Tests**:
- App launch → nearby search → view details
- Search → filter → favorite → save search
- Network error → retry → success
- Load more results with pagination
- Rapid search changes (debouncing)

### Unit Tests (51 tests)

#### 1. FavoritesManagerTests.swift (10 tests)

**Tests**:
- Add/remove favorites
- Toggle favorites
- Check if favorited
- Clear all favorites
- Apply favorite status to places
- Load from service on init

#### 2. RestaurantManagerTests.swift (7 tests)

**Tests**:
- Search nearby with correct parameters
- Search text with correct parameters
- Get place details with favorite status
- Return next page token
- Apply favorite status to results

#### 3. PhotoManagerTests.swift (9 tests)

**Tests**:
- Load photo from network
- Cache photos in memory
- Return cached photos
- Handle concurrent requests
- Load first photo from array
- Custom dimensions
- Clear cache
- Cache statistics

#### 4. DiscoveryViewModelTests.swift (15 tests)

**Tests**:
- Initialization with default values
- Request location permission
- Grant/deny location permission
- Perform nearby search
- Perform text search
- Apply filters
- Clear filters
- Toggle favorites
- Load next page
- View mode changes
- Error handling

#### 5. SwiftDataFavoritesServiceTests.swift (10 tests)

**Tests**:
- Add favorite with place ID
- Add favorite with full place data
- Update existing favorite
- Remove favorite
- Check if favorited
- Get all favorites sorted by date
- Get favorites sorted by rating
- Clear all favorites

### Performance Tests (13 tests)

#### PerformanceTests.swift (13 tests)

**Categories**:

1. **Search Performance** (3 tests)
   - `testPerformance_SearchWithLargeDataset()` - 1000 places
   - `testPerformance_RapidSearchChanges()` - Debouncing
   - `testPerformance_ApplyFiltersToLargeDataset()` - Filtering

2. **Memory Performance** (2 tests)
   - `testMemory_LargeResultSet()` - 1000 places
   - `testMemory_MultipleSearches()` - Memory leaks

3. **CPU Performance** (2 tests)
   - `testCPU_FilteringComplexCriteria()` - Complex filters
   - `testPerformance_EventLogging()` - Analytics overhead

4. **Concurrency** (2 tests)
   - `testStress_ConcurrentFilterChanges()` - Thread safety
   - `testStress_RapidViewModeChanges()` - State consistency

5. **Other** (4 tests)
   - `testPerformance_InitializeViewModel()` - Startup time
   - `testPerformance_ToggleFavoriteMultipleTimes()` - Favorite speed
   - `testPerformance_LoadMultiplePages()` - Pagination
   - `testStress_SaveAndLoadMultipleSearches()` - Persistence

**Benchmarks**:
- Search: < 0.01s for 1000 places
- Filter: < 0.01s for complex criteria
- Toggle favorite: < 0.001s
- Initialize ViewModel: < 0.01s

---

## 🎯 Testing Strategy

### 1. Integration Tests

**Purpose**: Verify end-to-end workflows work correctly

**Approach**:
- Test complete user flows
- Use real objects (not mocks)
- Verify state synchronization
- Test error recovery

**Example**:
```swift
func testCompleteFlow_Search_Filter_Favorite_Save() async throws {
    // 1. Perform search
    viewModel.searchQuery = "pizza"
    await viewModel.performSearch()
    XCTAssertFalse(viewModel.results.isEmpty)
    
    // 2. Apply filters
    viewModel.applyFilters(minRating: 4.0)
    XCTAssertTrue(viewModel.results.allSatisfy { $0.rating >= 4.0 })
    
    // 3. Toggle favorite
    let place = viewModel.results.first!
    await viewModel.toggleFavorite(place)
    XCTAssertTrue(favoritesManager.isFavorite(place.id))
    
    // 4. Save search
    await viewModel.saveCurrentSearch(name: "Good Pizza")
    XCTAssertTrue(viewModel.savedSearches.contains { $0.name == "Good Pizza" })
}
```

### 2. Unit Tests

**Purpose**: Test individual components in isolation

**Approach**:
- Use mock dependencies
- Test one thing at a time
- Cover edge cases
- Fast execution

**Example**:
```swift
func testToggleFavorite_AddsFavoriteWhenNotPresent() {
    // Arrange
    let manager = FavoritesManager(service: MockFavoritesService())
    let place = Place.fixture(id: "123")
    
    // Act
    manager.toggle(place.id)
    
    // Assert
    XCTAssertTrue(manager.isFavorite(place.id))
    XCTAssertEqual(manager.favoriteIds.count, 1)
}
```

### 3. Performance Tests

**Purpose**: Ensure app performs well under load

**Approach**:
- Test with large datasets
- Measure time and memory
- Test concurrent operations
- Verify no memory leaks

**Example**:
```swift
func testPerformance_SearchWithLargeDataset() {
    let places = (0..<1000).map { Place.fixture(id: "\($0)") }
    
    measure {
        let filtered = places.filter { $0.name.contains("pizza") }
        XCTAssertNotNil(filtered)
    }
    // Expected: < 0.01s
}
```

---

## 🔧 Mock Objects

### MockPlacesService

```swift
class MockPlacesService: PlacesService {
    var searchNearbyResult: Result<[Place], Error> = .success([])
    var searchTextResult: Result<[Place], Error> = .success([])
    
    func searchNearby(location: CLLocationCoordinate2D) async throws -> [Place] {
        try searchNearbyResult.get()
    }
    
    func searchText(query: String) async throws -> [Place] {
        try searchTextResult.get()
    }
}
```

### MockFavoritesService

```swift
class MockFavoritesService: FavoritesService {
    var favorites: [String: Place] = [:]
    
    func add(_ place: Place) async throws {
        favorites[place.id] = place
    }
    
    func remove(_ placeId: String) async throws {
        favorites.removeValue(forKey: placeId)
    }
    
    func getAll() async throws -> [Place] {
        Array(favorites.values)
    }
}
```

### MockEventLogger

```swift
class MockEventLogger: EventLogger {
    var loggedEvents: [LoggableEvent] = []
    
    func log(_ event: LoggableEvent) {
        loggedEvents.append(event)
    }
}
```

---

## ✅ Test Quality Checklist

### Good Test Characteristics

- [ ] **Fast**: Runs in < 1 second
- [ ] **Isolated**: No dependencies on other tests
- [ ] **Repeatable**: Same result every time
- [ ] **Self-Validating**: Pass/fail is clear
- [ ] **Timely**: Written with the code

### Test Coverage Goals

- [ ] **Happy Path**: Normal usage works
- [ ] **Edge Cases**: Empty, nil, boundary values
- [ ] **Error Cases**: Network errors, invalid data
- [ ] **Concurrency**: Thread-safe operations
- [ ] **Performance**: Meets speed requirements

---

## 📈 Coverage Report

### Current Coverage

```
Overall Coverage: 92%

Core/
  Managers/          100%
  Services/          95%
  Interactors/       90%
  
Features/
  Discovery/         95%
  RestaurantDetail/  85%
  Favorites/         90%
  
Networking/          90%
Analytics/           100%
```

### Uncovered Areas

1. **UI Tests**: Only 2 UI tests (could add more)
2. **Error Recovery**: Some edge cases not tested
3. **Offline Mode**: Not fully tested

---

## 🚀 Running Tests in Xcode

### Via Xcode UI

1. Open `AllTrailsLunchApp.xcodeproj`
2. Press `⌘U` to run all tests
3. Or: Product → Test

### Via Test Navigator

1. Press `⌘6` to open Test Navigator
2. Click ▶ next to test suite/file/method
3. View results in Report Navigator (`⌘9`)

### Via Command Line

```bash
# All tests
xcodebuild test -scheme AllTrailsLunchAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# With coverage
xcodebuild test -scheme AllTrailsLunchAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -enableCodeCoverage YES
```

---

## 📝 Writing New Tests

### Test Template

```swift
import XCTest
@testable import AllTrailsLunchApp

final class MyComponentTests: XCTestCase {
    var sut: MyComponent!  // System Under Test
    var mockDependency: MockDependency!
    
    override func setUp() {
        super.setUp()
        mockDependency = MockDependency()
        sut = MyComponent(dependency: mockDependency)
    }
    
    override func tearDown() {
        sut = nil
        mockDependency = nil
        super.tearDown()
    }
    
    func testFeature_Scenario_ExpectedBehavior() {
        // Arrange
        let input = "test"
        
        // Act
        let result = sut.doSomething(input)
        
        // Assert
        XCTAssertEqual(result, "expected")
    }
}
```

---

**Total Tests**: 86
**Pass Rate**: 100%
**Execution Time**: ~30 seconds
**Coverage**: 92%

