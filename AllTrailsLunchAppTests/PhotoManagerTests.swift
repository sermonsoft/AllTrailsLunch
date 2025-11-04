///
/// `PhotoManagerTests.swift`
/// AllTrailsLunchAppTests
///
/// Unit tests for PhotoManager and photo caching services.
///

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
        let cachedImage = createTestImage()
        await mockCache.setCachedImage(cachedImage, for: "test-photo-ref_400x400")

        // When
        let result = await photoManager.loadPhoto(photoReference: photoReference)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(mockLoader.loadCallCount, 0, "Should not load from network when cached")
    }
    
    func testLoadPhoto_WhenNotCached_LoadsFromNetwork() async {
        // Given
        let photoReference = "test-photo-ref"
        let networkImage = createTestImage()
        mockLoader.imageToReturn = networkImage

        // When
        let result = await photoManager.loadPhoto(photoReference: photoReference)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(mockLoader.loadCallCount, 1, "Should load from network when not cached")
        let cacheCount = await mockCache.getCachedImageCount()
        XCTAssertEqual(cacheCount, 1, "Should cache the loaded image")
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
        mockLoader.imageToReturn = createTestImage()
        
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
        mockLoader.imageToReturn = createTestImage()
        
        // When
        let result = await photoManager.loadFirstPhoto(from: photoReferences)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(mockLoader.lastPhotoReference, "first")
    }
    
    // MARK: - Cache Management Tests
    
    func testClearCache_ClearsAllCachedPhotos() async {
        // Given
        await mockCache.setCachedImage(createTestImage(), for: "photo1")
        await mockCache.setCachedImage(createTestImage(), for: "photo2")

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
        mockLoader.imageToReturn = createTestImage()
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
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}

// MARK: - Mock Photo Loader

class MockPhotoLoader: PhotoLoaderService {
    var imageToReturn: UIImage?
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
    
    func loadPhoto(from url: URL) async throws -> UIImage {
        loadCallCount += 1
        
        if loadDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(loadDelay * 1_000_000_000))
        }
        
        if shouldFail {
            throw PhotoError.invalidResponse
        }
        
        guard let image = imageToReturn else {
            throw PhotoError.invalidImageData
        }
        
        return image
    }
}

// MARK: - Mock Photo Cache

actor MockPhotoCache: PhotoCacheService {
    private var cachedImages: [String: UIImage] = [:]
    private var stats = PhotoCacheStats(memoryCount: 0, diskCount: 0, totalMemorySize: 0, totalDiskSize: 0)

    func getCachedPhoto(for key: String) async -> UIImage? {
        cachedImages[key]
    }

    func cachePhoto(_ image: UIImage, for key: String) async {
        cachedImages[key] = image
    }

    func removePhoto(for key: String) async {
        cachedImages.removeValue(forKey: key)
    }

    func clearCache() async {
        cachedImages.removeAll()
    }

    func getCacheStats() async -> PhotoCacheStats {
        stats
    }

    // Test helper methods
    func setCachedImage(_ image: UIImage, for key: String) {
        cachedImages[key] = image
    }

    func getCachedImageCount() -> Int {
        cachedImages.count
    }

    func isEmpty() -> Bool {
        cachedImages.isEmpty
    }

    func setStats(_ newStats: PhotoCacheStats) {
        stats = newStats
    }
}

