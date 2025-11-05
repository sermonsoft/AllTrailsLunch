///
/// `SavedSearch.swift`
/// AllTrailsLunch
///
/// SwiftData model for saved searches.
///

import Foundation
import SwiftData

/// Saved search with query, location, and filters
@Model
final class SavedSearch {
    @Attribute(.unique) var id: UUID
    var name: String
    var query: String
    var latitude: Double?
    var longitude: Double?
    var radius: Int
    var minRating: Double?
    var maxPriceLevel: Int?
    var openNow: Bool
    var maxDistance: Int?
    var createdAt: Date
    var lastUsedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        query: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        radius: Int = 1500,
        minRating: Double? = nil,
        maxPriceLevel: Int? = nil,
        openNow: Bool = false,
        maxDistance: Int? = nil,
        createdAt: Date = Date(),
        lastUsedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.query = query
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.minRating = minRating
        self.maxPriceLevel = maxPriceLevel
        self.openNow = openNow
        self.maxDistance = maxDistance
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
    
    /// Create from current search state
    convenience init(
        name: String,
        query: String,
        location: (latitude: Double, longitude: Double)?,
        filters: SearchFilters
    ) {
        self.init(
            name: name,
            query: query,
            latitude: location?.latitude,
            longitude: location?.longitude,
            radius: 1500,
            minRating: filters.minRating,
            maxPriceLevel: filters.maxPriceLevel,
            openNow: filters.openNow,
            maxDistance: filters.maxDistance
        )
    }
    
    /// Convert to SearchFilters
    var filters: SearchFilters {
        SearchFilters(
            minRating: minRating,
            maxPriceLevel: maxPriceLevel,
            openNow: openNow,
            maxDistance: maxDistance
        )
    }
    
    /// Display name for the search
    var displayName: String {
        if !name.isEmpty {
            return name
        } else if !query.isEmpty {
            return query
        } else {
            return "Nearby Restaurants"
        }
    }
    
    /// Summary of filters
    var filterSummary: String {
        var parts: [String] = []
        
        if let minRating = minRating {
            parts.append("\(String(format: "%.1f", minRating))+ stars")
        }
        
        if let maxPriceLevel = maxPriceLevel {
            parts.append(String(repeating: "$", count: maxPriceLevel))
        }
        
        if openNow {
            parts.append("Open now")
        }
        
        if let maxDistance = maxDistance {
            if maxDistance < 1000 {
                parts.append("\(maxDistance)m")
            } else {
                let km = Double(maxDistance) / 1000.0
                parts.append(String(format: "%.1fkm", km))
            }
        }
        
        return parts.isEmpty ? "No filters" : parts.joined(separator: " • ")
    }
}

