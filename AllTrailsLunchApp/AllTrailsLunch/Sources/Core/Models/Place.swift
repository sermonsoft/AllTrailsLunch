//
//  Place.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 31/10/25.
//

import Foundation
import CoreLocation

/// Domain model representing a restaurant/place.
///
/// This is the app's internal representation of a place, converted from PlaceDTO.
/// Includes favorite status and computed properties for UI display.
struct Place: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let rating: Double?
    let userRatingsTotal: Int?
    let priceLevel: Int?
    let latitude: Double
    let longitude: Double
    let address: String?
    let photoReferences: [String]
    var isFavorite: Bool = false
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var priceDisplay: String {
        guard let priceLevel = priceLevel else { return "" }
        return String(repeating: "$", count: priceLevel)
    }
    
    var ratingDisplay: String {
        guard let rating = rating else { return "N/A" }
        return String(format: "%.1f", rating)
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance
    static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id
    }
}

struct PlaceDetail: Equatable {
    let place: Place
    let phoneNumber: String?
    let openingHours: OpeningHours?
    let website: URL?
    let reviews: [Review]?
    
    var isOpenNow: Bool? {
        openingHours?.openNow
    }
}

struct OpeningHours: Equatable {
    let openNow: Bool?
    let weekdayText: [String]?
}

struct Review: Identifiable, Equatable {
    let id: String
    let authorName: String
    let rating: Int
    let text: String
    let timestamp: Date
    
    init(authorName: String, rating: Int, text: String, time: Int) {
        self.id = UUID().uuidString
        self.authorName = authorName
        self.rating = rating
        self.text = text
        self.timestamp = Date(timeIntervalSince1970: TimeInterval(time))
    }
}

// MARK: - Mapping from DTOs

extension Place {
    init(from dto: PlaceDTO) {
        self.id = dto.id
        self.name = dto.name
        self.rating = dto.rating
        self.userRatingsTotal = dto.userRatingsTotal
        self.priceLevel = dto.priceLevel
        self.latitude = dto.geometry.location.lat
        self.longitude = dto.geometry.location.lng
        self.address = dto.formattedAddress
        self.photoReferences = dto.photos?.map { $0.id } ?? []
        self.isFavorite = false
    }
}

extension PlaceDetail {
    init(place: Place, from dto: PlaceDetailsDTO) {
        self.place = place
        self.phoneNumber = dto.formattedPhoneNumber
        self.openingHours = dto.openingHours.map { OpeningHours(openNow: $0.openNow, weekdayText: $0.weekdayText) }
        self.website = dto.website.flatMap { URL(string: $0) }
        self.reviews = dto.reviews?.map { Review(authorName: $0.authorName, rating: $0.rating, text: $0.text, time: $0.time) }
    }
}
