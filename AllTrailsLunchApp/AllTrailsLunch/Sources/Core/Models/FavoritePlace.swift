///
/// `FavoritePlace.swift`
/// AllTrailsLunch
///
/// SwiftData model for persisting favorite places.
///

import Foundation
import SwiftData

// MARK: - Favorite Place Model

@Model
final class FavoritePlace {
    @Attribute(.unique) var placeId: String
    var name: String
    var address: String?
    var rating: Double?
    var priceLevel: Int?
    var latitude: Double
    var longitude: Double
    var photoReferences: [String]
    var addedAt: Date
    
    init(
        placeId: String,
        name: String,
        address: String? = nil,
        rating: Double? = nil,
        priceLevel: Int? = nil,
        latitude: Double,
        longitude: Double,
        photoReferences: [String] = [],
        addedAt: Date = Date()
    ) {
        self.placeId = placeId
        self.name = name
        self.address = address
        self.rating = rating
        self.priceLevel = priceLevel
        self.latitude = latitude
        self.longitude = longitude
        self.photoReferences = photoReferences
        self.addedAt = addedAt
    }
    
    /// Create a FavoritePlace from a Place model
    convenience init(from place: Place) {
        self.init(
            placeId: place.id,
            name: place.name,
            address: place.address,
            rating: place.rating,
            priceLevel: place.priceLevel,
            latitude: place.latitude,
            longitude: place.longitude,
            photoReferences: place.photoReferences,
            addedAt: Date()
        )
    }
}

