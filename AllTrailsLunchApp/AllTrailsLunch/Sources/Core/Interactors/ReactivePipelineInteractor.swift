//
//  ReactivePipelineInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/12/25.
//

import Foundation
import Combine
import CoreLocation

/// Protocol for reactive data pipeline operations
/// Follows Interface Segregation Principle - focused on Combine pipelines only
/// Provides access to DataPipelineCoordinator's reactive streams
@MainActor
protocol ReactivePipelineInteractor {
    // MARK: - Pipeline Execution
    
    /// Execute multi-source data pipeline
    /// Merges data from network, cache, location, and favorites
    /// - Parameters:
    ///   - query: Optional search query text
    ///   - radius: Search radius in meters (default: 1500)
    /// - Returns: Publisher that emits merged place results
    func executePipeline(
        query: String?,
        radius: Int
    ) -> AnyPublisher<[Place], Never>
    
    // MARK: - Debounced Search Pipeline
    
    /// Create debounced search pipeline
    /// Waits for user to stop typing before executing search
    /// - Parameters:
    ///   - queryPublisher: Publisher that emits search query strings
    ///   - debounceInterval: Time to wait after last input (default: 0.5s)
    /// - Returns: Publisher that emits debounced search results
    func createDebouncedSearchPipeline(
        queryPublisher: AnyPublisher<String, Never>,
        debounceInterval: TimeInterval
    ) -> AnyPublisher<[Place], Never>
    
    // MARK: - Throttled Location Pipeline
    
    /// Create throttled location updates pipeline
    /// Limits frequency of location-based searches
    /// - Parameter throttleInterval: Minimum time between location updates (default: 2.0s)
    /// - Returns: Publisher that emits throttled location coordinates
    func createThrottledLocationPipeline(
        throttleInterval: TimeInterval
    ) -> AnyPublisher<CLLocationCoordinate2D, Never>
    
    // MARK: - Pipeline State Observation
    
    /// Publisher for pipeline status changes
    /// Emits loading, success, failed, and idle states
    var pipelineStatusPublisher: AnyPublisher<PipelineStatus, Never> { get }
    
    /// Publisher for merged results from all data sources
    /// Emits deduplicated and sorted place results
    var mergedResultsPublisher: AnyPublisher<[Place], Never> { get }
    
    /// Publisher for pipeline errors
    /// Emits errors from network, cache, or location sources
    var pipelineErrorsPublisher: AnyPublisher<[PipelineError], Never> { get }
    
    // MARK: - Pipeline Control
    
    /// Cancel all active pipelines
    /// Stops all ongoing network requests and data processing
    func cancelAllPipelines()
}

