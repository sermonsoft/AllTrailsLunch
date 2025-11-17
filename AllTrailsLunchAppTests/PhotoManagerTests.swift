//
//  PhotoManagerTests.swift
//  AllTrailsLunchAppTests
//
//  Created by Tri Le on 02/11/25.
//

import XCTest
@testable import AllTrailsLunchApp

@MainActor
final class PhotoManagerTests: XCTestCase {
    
    var photoManager: PhotoManager!
    var mockLoader: MockPhotoLoader!
    var mockCache: MockPhotoCache!
    
    override func setUp() async throws {
        mockLoader = MockPhotoLoader()
        mockCache = MockPhotoCache()
        photoManager = PhotoManager(loader: mockLoader, cache: mockCache)
    }
    
    override func tearDown() async throws {
        photoManager = nil
        mockLoader = nil
        mockCache = nil
    }
    
    // MARK: - Photo Loading Tests
    
    func testLoadPhoto_WhenCached_ReturnsCachedImage() async {
        // Given
        let photoReference = "test-photo-ref"
        let cachedData = createTestImageData()
        await mockCache.setCachedData(cachedData, for: "test-photo-ref_400x400")

        // When
        let result = await photoManager.loadPhoto(photoReference: photoReference)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(mockLoader.loadCallCount, 0, "Should not load from network when cached")
    }

    func testLoadPhoto_WhenNotCached_LoadsFromNetwork() async {
        // Given
        let photoReference = "test-photo-ref"
        let networkData = createTestImageData()
        mockLoader.dataToReturn = networkData

        // When
        let result = await photoManager.loadPhoto(photoReference: photoReference)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(mockLoader.loadCallCount, 1, "Should load from network when not cached")
        let cacheCount = await mockCache.getCachedDataCount()
        XCTAssertEqual(cacheCount, 1, "Should cache the loaded data")
    }
    
    func testLoadPhoto_WhenNetworkFails_ReturnsNil() async {
        // Given
        let photoReference = "test-photo-ref"
        mockLoader.shouldFail = true
        
        // When
        let result = await photoManager.loadPhoto(photoReference: photoReference)
        
        // Then
        XCTAssertNil(result, "Should return nil when network fails")
    }
    
    func testLoadPhoto_WithCustomDimensions_UsesDimensions() async {
        // Given
        let photoReference = "test-photo-ref"
        let maxWidth = 800
        let maxHeight = 600
        mockLoader.dataToReturn = createTestImageData()

        // When
        _ = await photoManager.loadPhoto(
            photoReference: photoReference,
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )

        // Then
        XCTAssertEqual(mockLoader.lastMaxWidth, maxWidth)
        XCTAssertEqual(mockLoader.lastMaxHeight, maxHeight)
    }
    
    // MARK: - First Photo Loading Tests
    
    func testLoadFirstPhoto_WithEmptyArray_ReturnsNil() async {
        // Given
        let photoReferences: [String] = []
        
        // When
        let result = await photoManager.loadFirstPhoto(from: photoReferences)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testLoadFirstPhoto_WithMultipleReferences_LoadsFirst() async {
        // Given
        let photoReferences = ["first", "second", "third"]
        mockLoader.dataToReturn = createTestImageData()

        // When
        let result = await photoManager.loadFirstPhoto(from: photoReferences)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(mockLoader.lastPhotoReference, "first")
    }

    // MARK: - Cache Management Tests

    func testClearCache_ClearsAllCachedPhotos() async {
        // Given
        await mockCache.setCachedData(createTestImageData(), for: "photo1")
        await mockCache.setCachedData(createTestImageData(), for: "photo2")

        // When
        await photoManager.clearCache()

        // Then
        let isEmpty = await mockCache.isEmpty()
        XCTAssertTrue(isEmpty, "Cache should be cleared")
    }
    
    func testGetCacheStats_ReturnsCorrectStats() async {
        // Given
        await mockCache.setStats(PhotoCacheStats(
            memoryCount: 10,
            diskCount: 50,
            totalMemorySize: 1024 * 1024, // 1 MB
            totalDiskSize: 10 * 1024 * 1024 // 10 MB
        ))

        // When
        let stats = await photoManager.getCacheStats()

        // Then
        XCTAssertEqual(stats.memoryCount, 10)
        XCTAssertEqual(stats.diskCount, 50)
        XCTAssertEqual(stats.memorySizeMB, 1.0, accuracy: 0.01)
        XCTAssertEqual(stats.diskSizeMB, 10.0, accuracy: 0.01)
    }
    
    // MARK: - Concurrent Loading Tests

    func testLoadPhoto_ConcurrentRequests_LoadsOnce() async {
        // Given
        let photoReference = "test-photo-ref"
        mockLoader.dataToReturn = createTestImageData()
        mockLoader.loadDelay = 0.1 // Simulate network delay

        // When - Load same photo concurrently
        async let result1 = photoManager.loadPhoto(photoReference: photoReference)
        async let result2 = photoManager.loadPhoto(photoReference: photoReference)
        async let result3 = photoManager.loadPhoto(photoReference: photoReference)

        let results = await [result1, result2, result3]

        // Then
        XCTAssertEqual(results.compactMap { $0 }.count, 3, "All requests should succeed")
        XCTAssertEqual(mockLoader.loadCallCount, 1, "Should only load once for concurrent requests")
    }

    // MARK: - Helper Methods

    private func createTestImageData() -> Data {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }

        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))

        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }
}

// MARK: - Mock Photo Loader

class MockPhotoLoader: PhotoLoaderService {
    var dataToReturn: Data?
    var shouldFail = false
    var loadCallCount = 0
    var lastPhotoReference: String?
    var lastMaxWidth: Int?
    var lastMaxHeight: Int?
    var loadDelay: TimeInterval = 0

    func buildPhotoURL(photoReference: String, maxWidth: Int, maxHeight: Int) -> URL? {
        lastPhotoReference = photoReference
        lastMaxWidth = maxWidth
        lastMaxHeight = maxHeight
        return URL(string: "https://example.com/photo/\(photoReference)?w=\(maxWidth)&h=\(maxHeight)")
    }

    func loadPhoto(from url: URL) async throws -> Data {
        loadCallCount += 1

        if loadDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(loadDelay * 1_000_000_000))
        }

        if shouldFail {
            throw PhotoError.invalidResponse
        }

        guard let data = dataToReturn else {
            throw PhotoError.invalidImageData
        }

        return data
    }
}

// MARK: - Mock Photo Cache

actor MockPhotoCache: PhotoCacheService {
    private var cachedData: [String: Data] = [:]
    private var stats = PhotoCacheStats(memoryCount: 0, diskCount: 0, totalMemorySize: 0, totalDiskSize: 0)

    func getCachedPhoto(for key: String) async -> Data? {
        cachedData[key]
    }

    func cachePhoto(_ data: Data, for key: String) async {
        cachedData[key] = data
    }

    func removePhoto(for key: String) async {
        cachedData.removeValue(forKey: key)
    }

    func clearCache() async {
        cachedData.removeAll()
    }

    func getCacheStats() async -> PhotoCacheStats {
        stats
    }

    // Test helper methods
    func setCachedData(_ data: Data, for key: String) {
        cachedData[key] = data
    }

    func getCachedDataCount() -> Int {
        cachedData.count
    }

    func isEmpty() -> Bool {
        cachedData.isEmpty
    }

    func setStats(_ newStats: PhotoCacheStats) {
        stats = newStats
    }
}

