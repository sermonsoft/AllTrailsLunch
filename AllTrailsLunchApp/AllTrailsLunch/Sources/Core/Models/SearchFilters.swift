///
/// `SearchFilters.swift`
/// AllTrailsLunch
///
/// Model for restaurant search filters.
///

import Foundation

/// Filters for restaurant search
struct SearchFilters: Codable, Equatable {
    var minRating: Double?
    var maxPriceLevel: Int?
    var openNow: Bool
    var maxDistance: Int? // in meters
    
    init(
        minRating: Double? = nil,
        maxPriceLevel: Int? = nil,
        openNow: Bool = false,
        maxDistance: Int? = nil
    ) {
        self.minRating = minRating
        self.maxPriceLevel = maxPriceLevel
        self.openNow = openNow
        self.maxDistance = maxDistance
    }
    
    /// Default filters (no filtering)
    static let `default` = SearchFilters()
    
    /// Check if any filters are active
    var hasActiveFilters: Bool {
        minRating != nil || maxPriceLevel != nil || openNow || maxDistance != nil
    }
    
    /// Count of active filters
    var activeFilterCount: Int {
        var count = 0
        if minRating != nil { count += 1 }
        if maxPriceLevel != nil { count += 1 }
        if openNow { count += 1 }
        if maxDistance != nil { count += 1 }
        return count
    }
    
    /// Clear all filters
    mutating func clear() {
        minRating = nil
        maxPriceLevel = nil
        openNow = false
        maxDistance = nil
    }
    
    /// Apply filters to a list of places
    func apply(to places: [Place], userLocation: (latitude: Double, longitude: Double)?) -> [Place] {
        var filtered = places
        
        // Filter by rating
        if let minRating = minRating {
            filtered = filtered.filter { place in
                guard let rating = place.rating else { return false }
                return rating >= minRating
            }
        }
        
        // Filter by price level
        if let maxPriceLevel = maxPriceLevel {
            filtered = filtered.filter { place in
                guard let priceLevel = place.priceLevel else { return true } // Include places without price info
                return priceLevel <= maxPriceLevel
            }
        }
        
        // Filter by distance
        if let maxDistance = maxDistance, let userLocation = userLocation {
            filtered = filtered.filter { place in
                let distance = calculateDistance(
                    from: userLocation,
                    to: (latitude: place.latitude, longitude: place.longitude)
                )
                return distance <= Double(maxDistance)
            }
        }
        
        // Note: openNow filtering requires place details API call
        // This is handled server-side in the Google Places API
        
        return filtered
    }
    
    /// Calculate distance between two coordinates using Haversine formula
    private func calculateDistance(
        from: (latitude: Double, longitude: Double),
        to: (latitude: Double, longitude: Double)
    ) -> Double {
        let earthRadius = 6371000.0 // meters
        
        let lat1 = from.latitude * .pi / 180.0
        let lat2 = to.latitude * .pi / 180.0
        let dLat = (to.latitude - from.latitude) * .pi / 180.0
        let dLon = (to.longitude - from.longitude) * .pi / 180.0
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
}

/// Preset filter options
extension SearchFilters {
    /// Highly rated restaurants (4+ stars)
    static let highlyRated = SearchFilters(minRating: 4.0)
    
    /// Budget-friendly restaurants ($ or $$)
    static let budgetFriendly = SearchFilters(maxPriceLevel: 2)
    
    /// Open now
    static let openNow = SearchFilters(openNow: true)
    
    /// Nearby (within 1km)
    static let nearby = SearchFilters(maxDistance: 1000)
    
    /// Premium restaurants (4+ stars, $$$ or $$$$)
    static let premium = SearchFilters(minRating: 4.0, maxPriceLevel: 4)
}

/// Filter persistence service
class FilterPreferencesService {
    private let userDefaults: UserDefaults
    private let filtersKey = "com.alltrailslunch.searchFilters"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    /// Save filters
    func saveFilters(_ filters: SearchFilters) {
        if let data = try? JSONEncoder().encode(filters) {
            userDefaults.set(data, forKey: filtersKey)
        }
    }
    
    /// Load saved filters
    func loadFilters() -> SearchFilters {
        guard let data = userDefaults.data(forKey: filtersKey),
              let filters = try? JSONDecoder().decode(SearchFilters.self, from: data) else {
            return .default
        }
        return filters
    }
    
    /// Clear saved filters
    func clearFilters() {
        userDefaults.removeObject(forKey: filtersKey)
    }
}

