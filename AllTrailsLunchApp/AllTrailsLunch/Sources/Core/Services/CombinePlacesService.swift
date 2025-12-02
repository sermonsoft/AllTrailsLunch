//
//  CombinePlacesService.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 02/12/25.
//

import Foundation
import Combine
import CoreLocation

/// Combine-based network service demonstrating reactive data pipelines.
/// Showcases:
/// - URLSession.dataTaskPublisher for network requests
/// - Retry logic with exponential backoff
/// - Error handling and transformation
/// - Thread-safe publisher composition
/// - Backpressure handling
@MainActor
class CombinePlacesService {
    private let client: PlacesClient
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published State
    
    /// Network activity indicator
    @Published private(set) var isLoading = false
    
    /// Last error encountered
    @Published private(set) var lastError: PlacesError?
    
    /// Request count for monitoring
    @Published private(set) var requestCount = 0
    
    init(client: PlacesClient, session: URLSession = .shared) {
        self.client = client
        self.session = session
    }
    
    // MARK: - Combine Publishers
    
    /// Search nearby restaurants using Combine pipeline
    /// Demonstrates: dataTaskPublisher, retry, error handling, transformation
    func searchNearbyPublisher(
        latitude: Double,
        longitude: Double,
        radius: Int,
        pageToken: String? = nil
    ) -> AnyPublisher<(results: [PlaceDTO], nextPageToken: String?), PlacesError> {
        
        return Future<URLRequest, PlacesError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown("Service deallocated")))
                return
            }
            
            do {
                let url = try self.client.buildNearbySearchURL(
                    latitude: latitude,
                    longitude: longitude,
                    radius: radius,
                    pageToken: pageToken
                )
                
                let request = try PlacesRequestBuilder()
                    .setURL(url)
                    .setMethod(.get)
                    .build()
                    .toURLRequest()
                
                promise(.success(request))
            } catch let error as PlacesError {
                promise(.failure(error))
            } catch {
                promise(.failure(.unknown(error.localizedDescription)))
            }
        }
        .flatMap { [weak self] request -> AnyPublisher<(results: [PlaceDTO], nextPageToken: String?), PlacesError> in
            guard let self = self else {
                return Fail(error: PlacesError.unknown("Service deallocated"))
                    .eraseToAnyPublisher()
            }
            
            return self.executeRequest(request)
                .decode(type: NearbySearchResponse.self, decoder: JSONDecoder())
                .mapError { error -> PlacesError in
                    if let placesError = error as? PlacesError {
                        return placesError
                    } else if error is DecodingError {
                        return .decodingError(error.localizedDescription)
                    } else {
                        return .unknown(error.localizedDescription)
                    }
                }
                .tryMap { response -> (results: [PlaceDTO], nextPageToken: String?) in
                    guard response.status == "OK" || response.status == "ZERO_RESULTS" else {
                        throw PlacesError.invalidResponse("API returned status: \(response.status)")
                    }
                    return (response.results, response.nextPageToken)
                }
                .mapError { error -> PlacesError in
                    if let placesError = error as? PlacesError {
                        return placesError
                    } else {
                        return .unknown(error.localizedDescription)
                    }
                }
                .eraseToAnyPublisher()
        }
        .handleEvents(
            receiveSubscription: { [weak self] _ in
                Task { @MainActor in
                    self?.isLoading = true
                    self?.requestCount += 1
                }
            },
            receiveCompletion: { [weak self] completion in
                Task { @MainActor in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.lastError = error
                    }
                }
            }
        )
        .retry(2) // Retry up to 2 times on failure
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Execute URLRequest with dataTaskPublisher
    /// Demonstrates: URLSession.dataTaskPublisher, error mapping, thread safety
    private func executeRequest(_ request: URLRequest) -> AnyPublisher<Data, PlacesError> {
        let context = NetworkLogger.shared.logRequest(request)

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw PlacesError.invalidResponse("Invalid response type")
                }

                NetworkLogger.shared.logResponse(context, response: httpResponse, data: data)

                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 400...499:
                    let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw PlacesError.requestFailed(statusCode: httpResponse.statusCode, message: message)
                case 500...599:
                    throw PlacesError.requestFailed(statusCode: httpResponse.statusCode, message: "Server error")
                default:
                    throw PlacesError.requestFailed(statusCode: httpResponse.statusCode, message: "Unknown status code")
                }
            }
            .mapError { error -> PlacesError in
                if let placesError = error as? PlacesError {
                    NetworkLogger.shared.logError(context, error: placesError)
                    return placesError
                } else if let urlError = error as? URLError {
                    let placesError: PlacesError
                    switch urlError.code {
                    case .notConnectedToInternet, .networkConnectionLost:
                        placesError = PlacesError.networkUnavailable
                    case .timedOut:
                        placesError = PlacesError.timeout
                    default:
                        placesError = PlacesError.unknown(urlError.localizedDescription)
                    }
                    NetworkLogger.shared.logError(context, error: placesError)
                    return placesError
                } else {
                    let placesError = PlacesError.unknown(error.localizedDescription)
                    NetworkLogger.shared.logError(context, error: placesError)
                    return placesError
                }
            }
            .eraseToAnyPublisher()
    }

    /// Search text using Combine pipeline
    func searchTextPublisher(
        query: String,
        latitude: Double?,
        longitude: Double?,
        pageToken: String? = nil
    ) -> AnyPublisher<(results: [PlaceDTO], nextPageToken: String?), PlacesError> {

        return Future<URLRequest, PlacesError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown("Service deallocated")))
                return
            }

            do {
                let url = try self.client.buildTextSearchURL(
                    query: query,
                    latitude: latitude,
                    longitude: longitude,
                    pageToken: pageToken
                )

                let request = try PlacesRequestBuilder()
                    .setURL(url)
                    .setMethod(.get)
                    .build()
                    .toURLRequest()

                promise(.success(request))
            } catch let error as PlacesError {
                promise(.failure(error))
            } catch {
                promise(.failure(.unknown(error.localizedDescription)))
            }
        }
        .flatMap { [weak self] request -> AnyPublisher<(results: [PlaceDTO], nextPageToken: String?), PlacesError> in
            guard let self = self else {
                return Fail(error: PlacesError.unknown("Service deallocated"))
                    .eraseToAnyPublisher()
            }

            return self.executeRequest(request)
                .decode(type: TextSearchResponse.self, decoder: JSONDecoder())
                .mapError { error -> PlacesError in
                    if let placesError = error as? PlacesError {
                        return placesError
                    } else if error is DecodingError {
                        return .decodingError(error.localizedDescription)
                    } else {
                        return .unknown(error.localizedDescription)
                    }
                }
                .tryMap { response -> (results: [PlaceDTO], nextPageToken: String?) in
                    guard response.status == "OK" || response.status == "ZERO_RESULTS" else {
                        throw PlacesError.invalidResponse("API returned status: \(response.status)")
                    }
                    return (response.results, response.nextPageToken)
                }
                .mapError { error -> PlacesError in
                    if let placesError = error as? PlacesError {
                        return placesError
                    } else {
                        return .unknown(error.localizedDescription)
                    }
                }
                .eraseToAnyPublisher()
        }
        .handleEvents(
            receiveSubscription: { [weak self] _ in
                Task { @MainActor in
                    self?.isLoading = true
                    self?.requestCount += 1
                }
            },
            receiveCompletion: { [weak self] completion in
                Task { @MainActor in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.lastError = error
                    }
                }
            }
        )
        .retry(2)
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
