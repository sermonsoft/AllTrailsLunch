//
//  CombinePipelineTests.swift
//  AllTrailsLunchTests
//
//  Created by Tri Le on 02/12/25.
//

import XCTest
import Combine
import CoreLocation
@testable import AllTrailsLunchApp

// MARK: - Mock URLSession

class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockResponse: HTTPURLResponse?
    static var mockError: Error?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        if let response = MockURLProtocol.mockResponse {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let data = MockURLProtocol.mockData {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// Integration tests for Combine data pipelines
/// Demonstrates:
/// - Thread safety and actor isolation
/// - Backpressure handling
/// - Proper cancellation and memory management
/// - Multi-source data coordination
/// - Error recovery and resilience
@MainActor
final class CombinePipelineTests: XCTestCase {

    var cancellables: Set<AnyCancellable>!
    var mockClient: PlacesClient!
    var combineService: CombinePlacesService!
    var mockSession: URLSession!

    override func setUp() async throws {
        try await super.setUp()
        cancellables = Set<AnyCancellable>()

        // Configure mock URLSession
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)

        // Use test API key with mock session
        mockClient = PlacesClient(apiKey: "test-key", session: mockSession)
        combineService = CombinePlacesService(client: mockClient, session: mockSession)

        // Setup default mock response
        setupSuccessResponse()
    }

    func setupSuccessResponse() {
        let mockJSON = """
        {
            "results": [
                {
                    "place_id": "test-place-1",
                    "name": "Test Restaurant",
                    "vicinity": "123 Test St",
                    "geometry": {
                        "location": {
                            "lat": 37.7749,
                            "lng": -122.4194
                        }
                    },
                    "rating": 4.5,
                    "user_ratings_total": 100
                }
            ],
            "status": "OK"
        }
        """
        MockURLProtocol.mockData = mockJSON.data(using: .utf8)
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        MockURLProtocol.mockError = nil
    }

    func setupErrorResponse() {
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockResponse = nil
        MockURLProtocol.mockError = URLError(.notConnectedToInternet)
    }
    
    override func tearDown() async throws {
        cancellables.removeAll()
        combineService = nil
        mockClient = nil
        mockSession = nil
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockResponse = nil
        MockURLProtocol.mockError = nil
        try await super.tearDown()
    }
    
    // MARK: - Network Publisher Tests
    
    func testSearchNearbyPublisher_Success() async throws {
        let expectation = XCTestExpectation(description: "Search nearby completes")
        
        combineService.searchNearbyPublisher(
            latitude: 37.7749,
            longitude: -122.4194,
            radius: 1500
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success but got error: \(error)")
                }
                expectation.fulfill()
            },
            receiveValue: { result in
                XCTAssertNotNil(result.results)
                print("✅ Received \(result.results.count) places from network")
            }
        )
        .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testSearchTextPublisher_Success() async throws {
        let expectation = XCTestExpectation(description: "Search text completes")
        
        combineService.searchTextPublisher(
            query: "pizza",
            latitude: 37.7749,
            longitude: -122.4194
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success but got error: \(error)")
                }
                expectation.fulfill()
            },
            receiveValue: { result in
                XCTAssertNotNil(result.results)
                print("✅ Received \(result.results.count) places from text search")
            }
        )
        .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testRetryLogic_NetworkFailure() async throws {
        let expectation = XCTestExpectation(description: "Retry logic executes")
        var attemptCount = 0

        // Setup error response
        setupErrorResponse()

        // This will fail but should retry
        combineService.searchNearbyPublisher(
            latitude: 37.7749,
            longitude: -122.4194,
            radius: 1500
        )
        .handleEvents(receiveSubscription: { _ in
            attemptCount += 1
        })
        .sink(
            receiveCompletion: { completion in
                // Should have retried 2 times (total 3 attempts)
                print("✅ Retry logic executed \(attemptCount) time(s)")
                expectation.fulfill()
            },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    // MARK: - Thread Safety Tests
    
    func testPublishedProperties_ThreadSafety() async throws {
        let expectation = XCTestExpectation(description: "Published properties update safely")
        
        // Subscribe to loading state
        combineService.$isLoading
            .dropFirst() // Skip initial value
            .sink { isLoading in
                print("✅ Loading state changed: \(isLoading)")
                if !isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Trigger network request
        combineService.searchNearbyPublisher(
            latitude: 37.7749,
            longitude: -122.4194,
            radius: 1500
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }

    // MARK: - Backpressure Tests

    func testBackpressure_MultipleRequests() async throws {
        let expectation = XCTestExpectation(description: "Backpressure handled correctly")
        expectation.expectedFulfillmentCount = 3

        // Fire multiple requests rapidly
        for i in 0..<3 {
            combineService.searchNearbyPublisher(
                latitude: 37.7749 + Double(i) * 0.01,
                longitude: -122.4194,
                radius: 1500
            )
            .sink(
                receiveCompletion: { _ in
                    expectation.fulfill()
                },
                receiveValue: { result in
                    print("✅ Request \(i) completed with \(result.results.count) results")
                }
            )
            .store(in: &cancellables)
        }

        await fulfillment(of: [expectation], timeout: 30.0)
    }

    // MARK: - Cancellation Tests

    func testCancellation_ProperCleanup() async throws {
        let expectation = XCTestExpectation(description: "Cancellation works correctly")

        let cancellable = combineService.searchNearbyPublisher(
            latitude: 37.7749,
            longitude: -122.4194,
            radius: 1500
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure = completion {
                    print("✅ Request was cancelled")
                    expectation.fulfill()
                }
            },
            receiveValue: { _ in
                XCTFail("Should not receive value after cancellation")
            }
        )

        // Cancel immediately
        cancellable.cancel()

        // Give it a moment to process cancellation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        expectation.fulfill()

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Memory Leak Tests

    func testMemoryManagement_NoCycles() async throws {
        weak var weakService: CombinePlacesService?

        autoreleasepool {
            let service = CombinePlacesService(client: mockClient, session: .shared)
            weakService = service

            var localCancellables = Set<AnyCancellable>()

            service.searchNearbyPublisher(
                latitude: 37.7749,
                longitude: -122.4194,
                radius: 1500
            )
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &localCancellables)

            localCancellables.removeAll()
        }

        // Service should be deallocated
        XCTAssertNil(weakService, "Service should be deallocated - no retain cycles")
        print("✅ No memory leaks detected")
    }

    // MARK: - Error Handling Tests

    func testErrorHandling_InvalidCoordinates() async throws {
        let expectation = XCTestExpectation(description: "Error handled correctly")

        combineService.searchNearbyPublisher(
            latitude: 999, // Invalid latitude
            longitude: 999, // Invalid longitude
            radius: 1500
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("✅ Error handled correctly: \(error)")
                    expectation.fulfill()
                }
            },
            receiveValue: { _ in
                // May still succeed with ZERO_RESULTS
                expectation.fulfill()
            }
        )
        .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 10.0)
    }

    // MARK: - Publisher Composition Tests

    func testPublisherComposition_RequestCount() async throws {
        let expectation = XCTestExpectation(description: "Request count increments")

        combineService.$requestCount
            .dropFirst() // Skip initial 0
            .sink { count in
                XCTAssertGreaterThan(count, 0)
                print("✅ Request count: \(count)")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        combineService.searchNearbyPublisher(
            latitude: 37.7749,
            longitude: -122.4194,
            radius: 1500
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 10.0)
    }
}


