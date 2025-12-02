//
//  DataPipelineCoordinator.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 02/12/25.
//

import Foundation
import Combine
import CoreLocation

/// Multi-source data pipeline coordinator demonstrating advanced Combine patterns.
///
/// This coordinator showcases enterprise-grade reactive programming:
/// - Merging multiple asynchronous data sources (network, cache, location, favorites)
/// - Thread-safe coordination across different isolation domains
/// - Backpressure handling and cancellation
/// - Deterministic data flow with proper error boundaries
/// - Memory leak prevention with weak references
///
/// Real-world applications:
/// - CAD event stream coordination (similar to AllTrails dispatch systems)
/// - AVL position updates merged with GIS layers
/// - Real-time situational awareness with multiple data feeds
/// - Synchronized state management across distributed sources
@MainActor
class DataPipelineCoordinator {
    
    // MARK: - Dependencies
    
    private let combineService: CombinePlacesService
    private let cache: LocalPlacesCache?
    private let favoritesManager: FavoritesManager
    private let locationManager: LocationManager
    
    // MARK: - Cancellables
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published State
    
    /// Merged results from all sources
    @Published private(set) var mergedResults: [Place] = []
    
    /// Pipeline status
    @Published private(set) var pipelineStatus: PipelineStatus = .idle
    
    /// Aggregated errors from all sources
    @Published private(set) var errors: [PipelineError] = []
    
    // MARK: - Initialization
    
    init(
        combineService: CombinePlacesService,
        cache: LocalPlacesCache?,
        favoritesManager: FavoritesManager,
        locationManager: LocationManager
    ) {
        self.combineService = combineService
        self.cache = cache
        self.favoritesManager = favoritesManager
        self.locationManager = locationManager
    }
    
    // MARK: - Pipeline Orchestration
    
    /// Execute multi-source data pipeline
    /// Demonstrates: merge, combineLatest, flatMap, error handling, thread coordination
    func executePipeline(
        query: String?,
        radius: Int = 1500
    ) -> AnyPublisher<[Place], Never> {
        
        pipelineStatus = .loading
        errors.removeAll()
        
        // Source 1: Location stream
        let locationPublisher = createLocationPublisher()
        
        // Source 2: Network stream (depends on location)
        let networkPublisher = locationPublisher
            .flatMap { [weak self] location -> AnyPublisher<[PlaceDTO], PipelineError> in
                guard let self = self else {
                    return Fail(error: PipelineError.serviceUnavailable)
                        .eraseToAnyPublisher()
                }
                
                if let query = query {
                    return self.combineService.searchTextPublisher(
                        query: query,
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                    .map { $0.results }
                    .mapError { PipelineError.network($0) }
                    .eraseToAnyPublisher()
                } else {
                    return self.combineService.searchNearbyPublisher(
                        latitude: location.latitude,
                        longitude: location.longitude,
                        radius: radius
                    )
                    .map { $0.results }
                    .mapError { PipelineError.network($0) }
                    .eraseToAnyPublisher()
                }
            }
        
        // Source 3: Cache stream (depends on location)
        let cachePublisher = locationPublisher
            .flatMap { [weak self] location -> AnyPublisher<[Place], PipelineError> in
                guard let self = self, let cache = self.cache else {
                    return Just([])
                        .setFailureType(to: PipelineError.self)
                        .eraseToAnyPublisher()
                }
                
                do {
                    let cached = try cache.getCachedPlaces(location: location, radius: radius) ?? []
                    return Just(cached)
                        .setFailureType(to: PipelineError.self)
                        .eraseToAnyPublisher()
                } catch {
                    return Fail(error: PipelineError.cache(error))
                        .eraseToAnyPublisher()
                }
            }
        
        // Source 4: Favorites stream
        let favoritesPublisher = Just(favoritesManager.getFavoriteIds())
            .setFailureType(to: PipelineError.self)
            .eraseToAnyPublisher()
        
        // Merge network and cache results
        let mergedDataPublisher = Publishers.Merge(
            networkPublisher.map { dtos in dtos.map { Place(from: $0) } },
            cachePublisher
        )
        .collect() // Collect all emissions
        .map { arrays -> [Place] in
            // Flatten and deduplicate
            let allPlaces = arrays.flatMap { $0 }
            var seen = Set<String>()
            return allPlaces.filter { place in
                guard !seen.contains(place.id) else { return false }
                seen.insert(place.id)
                return true
            }
        }

        // Combine data with favorites to enrich results
        return Publishers.CombineLatest(mergedDataPublisher, favoritesPublisher)
            .map { [weak self] places, favoriteIds -> [Place] in
                guard let self = self else { return [] }

                // Enrich places with favorite status
                return places.map { place in
                    var enrichedPlace = place
                    enrichedPlace.isFavorite = favoriteIds.contains(place.id)
                    return enrichedPlace
                }
            }
            .handleEvents(
                receiveOutput: { [weak self] places in
                    Task { @MainActor in
                        self?.mergedResults = places
                        self?.pipelineStatus = .success(count: places.count)
                    }
                },
                receiveCompletion: { [weak self] completion in
                    Task { @MainActor in
                        if case .failure(let error) = completion {
                            self?.errors.append(error)
                            self?.pipelineStatus = .failed(error)
                        }
                    }
                }
            )
            .catch { [weak self] error -> AnyPublisher<[Place], Never> in
                // Error recovery: return cached results or empty array
                Task { @MainActor in
                    self?.errors.append(error)
                    self?.pipelineStatus = .failed(error)
                }
                return Just([])
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Helper Publishers

    /// Create location publisher with error handling
    private func createLocationPublisher() -> AnyPublisher<CLLocationCoordinate2D, PipelineError> {
        return Future<CLLocationCoordinate2D, PipelineError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.serviceUnavailable))
                return
            }

            Task {
                do {
                    let location = try await self.locationManager.requestLocationPermission()
                    promise(.success(location))
                } catch {
                    promise(.failure(.location(error)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Debounced search pipeline for text queries
    /// Demonstrates: debounce, removeDuplicates, switchToLatest
    func createDebouncedSearchPipeline(
        queryPublisher: AnyPublisher<String, Never>,
        debounceInterval: TimeInterval = 0.5
    ) -> AnyPublisher<[Place], Never> {

        return queryPublisher
            .debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .flatMap { [weak self] query -> AnyPublisher<[Place], Never> in
                guard let self = self else {
                    return Just([]).eraseToAnyPublisher()
                }
                return self.executePipeline(query: query)
            }
            .eraseToAnyPublisher()
    }

    /// Throttled location updates pipeline
    /// Demonstrates: throttle, distinctUntilChanged
    func createThrottledLocationPipeline(
        throttleInterval: TimeInterval = 2.0
    ) -> AnyPublisher<CLLocationCoordinate2D, Never> {

        return locationManager.$userLocation
            .compactMap { $0 }
            .throttle(for: .seconds(throttleInterval), scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates { lhs, rhs in
                // Consider locations within 10 meters as duplicate
                let distance = CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
                    .distance(from: CLLocation(latitude: rhs.latitude, longitude: rhs.longitude))
                return distance < 10
            }
            .eraseToAnyPublisher()
    }

    /// Cancel all active pipelines
    func cancelAllPipelines() {
        cancellables.removeAll()
        pipelineStatus = .idle
    }
}

// MARK: - Supporting Types

enum PipelineStatus: Equatable {
    case idle
    case loading
    case success(count: Int)
    case failed(PipelineError)
}

enum PipelineError: Error, Equatable {
    case network(PlacesError)
    case cache(Error)
    case location(Error)
    case serviceUnavailable

    static func == (lhs: PipelineError, rhs: PipelineError) -> Bool {
        switch (lhs, rhs) {
        case (.network(let lhsError), .network(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.cache, .cache), (.location, .location), (.serviceUnavailable, .serviceUnavailable):
            return true
        default:
            return false
        }
    }
}


