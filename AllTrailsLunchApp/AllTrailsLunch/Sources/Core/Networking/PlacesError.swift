//
//  PlacesError.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 31/10/25.
//

import Foundation

enum PlacesError: LocalizedError, Equatable {
    /// Invalid API key
    case invalidAPIKey
    
    /// Invalid URL construction
    case invalidURL(String)
    
    /// Request failed with status code
    case requestFailed(statusCode: Int, message: String)
    
    /// Invalid response format
    case invalidResponse(String)
    
    /// Decoding error
    case decodingError(String)
    
    /// Network connectivity error
    case networkUnavailable
    
    /// Request timeout
    case timeout
    
    /// Rate limit exceeded
    case rateLimited(retryAfter: TimeInterval?)
    
    /// Zero results from API
    case noResults
    
    /// Location permission denied
    case locationPermissionDenied

    /// Invalid search category (non-food/restaurant search)
    case invalidSearchCategory(String)

    /// Unknown error
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .requestFailed(let statusCode, let message):
            return "Request failed with status \(statusCode): \(message)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkUnavailable:
            return "Network is unavailable. Please check your connection."
        case .timeout:
            return "Request timed out. Please try again."
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .noResults:
            return "No results found for your search."
        case .locationPermissionDenied:
            return "Location permission is required to search nearby restaurants."
        case .invalidSearchCategory(let message):
            return message
        case .unknown(let message):
            return "An unknown error occurred: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .timeout:
            return "The request took too long. Please try again."
        case .rateLimited(let retryAfter):
            if let retryAfter = retryAfter {
                return "Please wait \(Int(retryAfter)) seconds before trying again."
            }
            return "Please try again later."
        case .locationPermissionDenied:
            return "Please enable location permission in Settings to search nearby restaurants."
        case .invalidSearchCategory:
            return "Try searching for restaurants, cuisines, or food items instead."
        case .invalidAPIKey:
            return "Please configure your Google Places API key in the app settings."
        default:
            return nil
        }
    }
}

