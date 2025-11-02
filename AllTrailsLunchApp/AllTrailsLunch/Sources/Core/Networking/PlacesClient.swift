///
/// `PlacesClient.swift`
/// AllTrailsLunch
///
/// Core HTTP client for Google Places API with retry logic and error handling.
///

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
        for attempt in 0..<maxRetries {
            do {
                let urlRequest = request.toURLRequest()
                let (data, response) = try await session.data(for: urlRequest)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw PlacesError.invalidResponse("Invalid response type")
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    do {
                        let decoder = JSONDecoder()
                        return try decoder.decode(T.self, from: data)
                    } catch {
                        throw PlacesError.decodingError(error.localizedDescription)
                    }
                    
                case 400...499:
                    let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw PlacesError.requestFailed(statusCode: httpResponse.statusCode, message: message)
                    
                case 500...599:
                    if attempt < maxRetries - 1 {
                        let delay = retryDelay * pow(2.0, Double(attempt))
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    throw PlacesError.requestFailed(statusCode: httpResponse.statusCode, message: "Server error")
                    
                default:
                    throw PlacesError.requestFailed(statusCode: httpResponse.statusCode, message: "Unknown status code")
                }
            } catch let error as PlacesError {
                throw error
            } catch {
                if attempt < maxRetries - 1 {
                    let delay = retryDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                throw PlacesError.unknown(error.localizedDescription)
            }
        }
        
        throw PlacesError.unknown("Max retries exceeded")
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

