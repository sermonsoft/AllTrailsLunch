//
//  PlacesClient.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 01/11/25.
//

import Foundation

class PlacesClient {
    private let session: URLSession
    private let apiKey: String
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 1.0
    
    private static let baseURL = "https://maps.googleapis.com/maps/api/place"
    
    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    func execute<T: Decodable>(_ request: PlacesRequest) async throws -> T {
        let urlRequest = request.toURLRequest()
        let context = NetworkLogger.shared.logRequest(urlRequest)

        for attempt in 0..<maxRetries {
            do {
                // Use simulated network in development builds
                #if DEV
                let (data, response) = try await session.simulatedData(for: urlRequest)
                #else
                let (data, response) = try await session.data(for: urlRequest)
                #endif

                guard let httpResponse = response as? HTTPURLResponse else {
                    let error = PlacesError.invalidResponse("Invalid response type")
                    NetworkLogger.shared.logError(context, error: error)
                    throw error
                }

                switch httpResponse.statusCode {
                case 200...299:
                    NetworkLogger.shared.logResponse(context, response: httpResponse, data: data)

                    do {
                        let decoder = JSONDecoder()
                        return try decoder.decode(T.self, from: data)
                    } catch {
                        let decodingError = PlacesError.decodingError(error.localizedDescription)
                        NetworkLogger.shared.logError(context, error: decodingError, response: httpResponse, data: data)
                        throw decodingError
                    }

                case 400...499:
                    let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                    let error = PlacesError.requestFailed(statusCode: httpResponse.statusCode, message: message)
                    NetworkLogger.shared.logError(context, error: error, response: httpResponse, data: data)
                    throw error

                case 500...599:
                    if attempt < maxRetries - 1 {
                        let delay = retryDelay * pow(2.0, Double(attempt))
                        NetworkLogger.shared.logRetry(context, attempt: attempt + 1, delay: delay)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    let error = PlacesError.requestFailed(statusCode: httpResponse.statusCode, message: "Server error")
                    NetworkLogger.shared.logError(context, error: error, response: httpResponse, data: data)
                    throw error

                default:
                    let error = PlacesError.requestFailed(statusCode: httpResponse.statusCode, message: "Unknown status code")
                    NetworkLogger.shared.logError(context, error: error, response: httpResponse, data: data)
                    throw error
                }
            } catch let error as PlacesError {
                throw error
            } catch {
                if attempt < maxRetries - 1 {
                    let delay = retryDelay * pow(2.0, Double(attempt))
                    NetworkLogger.shared.logRetry(context, attempt: attempt + 1, delay: delay)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                let unknownError = PlacesError.unknown(error.localizedDescription)
                NetworkLogger.shared.logError(context, error: unknownError)
                throw unknownError
            }
        }

        let maxRetriesError = PlacesError.unknown("Max retries exceeded")
        NetworkLogger.shared.logError(context, error: maxRetriesError)
        throw maxRetriesError
    }
    
    // MARK: - Endpoint Builders
    
    func buildNearbySearchURL(
        latitude: Double,
        longitude: Double,
        radius: Int = 1500,
        type: String = "restaurant",
        pageToken: String? = nil
    ) throws -> URL {
        var components = URLComponents(string: "\(Self.baseURL)/nearbysearch/json")
        components?.queryItems = [
            URLQueryItem(name: "location", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        if let pageToken = pageToken {
            components?.queryItems?.append(URLQueryItem(name: "pagetoken", value: pageToken))
        }
        
        guard let url = components?.url else {
            throw PlacesError.invalidURL("Failed to build nearby search URL")
        }
        
        return url
    }
    
    func buildTextSearchURL(
        query: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        pageToken: String? = nil
    ) throws -> URL {
        var components = URLComponents(string: "\(Self.baseURL)/textsearch/json")
        var queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        if let latitude = latitude, let longitude = longitude {
            queryItems.append(URLQueryItem(name: "location", value: "\(latitude),\(longitude)"))
        }
        
        if let pageToken = pageToken {
            queryItems.append(URLQueryItem(name: "pagetoken", value: pageToken))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw PlacesError.invalidURL("Failed to build text search URL")
        }
        
        return url
    }
    
    func buildDetailsURL(placeId: String) throws -> URL {
        var components = URLComponents(string: "\(Self.baseURL)/details/json")
        components?.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "fields", value: "name,rating,formatted_phone_number,opening_hours,website,reviews,formatted_address"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else {
            throw PlacesError.invalidURL("Failed to build details URL")
        }
        
        return url
    }
}

