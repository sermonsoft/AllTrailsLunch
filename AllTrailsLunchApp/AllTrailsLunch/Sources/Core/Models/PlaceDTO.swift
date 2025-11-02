///
/// `PlaceDTO.swift`
/// AllTrailsLunch
///
/// Data Transfer Objects for Google Places API responses.
///

import Foundation

// MARK: - Nearby Search Response

struct NearbySearchResponse: Decodable {
    let results: [PlaceDTO]
    let nextPageToken: String?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case results
        case nextPageToken = "next_page_token"
        case status
    }
}

// MARK: - Text Search Response

struct TextSearchResponse: Decodable {
    let results: [PlaceDTO]
    let nextPageToken: String?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case results
        case nextPageToken = "next_page_token"
        case status
    }
}

// MARK: - Place DTO

struct PlaceDTO: Decodable, Identifiable {
    let id: String
    let name: String
    let rating: Double?
    let userRatingsTotal: Int?
    let priceLevel: Int?
    let geometry: GeometryDTO
    let formattedAddress: String?
    let photos: [PhotoDTO]?
    let types: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id = "place_id"
        case name
        case rating
        case userRatingsTotal = "user_ratings_total"
        case priceLevel = "price_level"
        case geometry
        case formattedAddress = "formatted_address"
        case photos
        case types
    }
}

// MARK: - Geometry DTO

struct GeometryDTO: Decodable {
    let location: LocationDTO
}

struct LocationDTO: Decodable {
    let lat: Double
    let lng: Double
}

// MARK: - Photo DTO

struct PhotoDTO: Decodable, Identifiable {
    let id: String
    let height: Int
    let width: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "photo_reference"
        case height
        case width
    }
}

// MARK: - Place Details Response

struct PlaceDetailsResponse: Decodable {
    let result: PlaceDetailsDTO
    let status: String
}

struct PlaceDetailsDTO: Decodable {
    let name: String
    let rating: Double?
    let formattedPhoneNumber: String?
    let openingHours: OpeningHoursDTO?
    let website: String?
    let reviews: [ReviewDTO]?
    let formattedAddress: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case rating
        case formattedPhoneNumber = "formatted_phone_number"
        case openingHours = "opening_hours"
        case website
        case reviews
        case formattedAddress = "formatted_address"
    }
}

struct OpeningHoursDTO: Decodable {
    let openNow: Bool?
    let weekdayText: [String]?
    
    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
        case weekdayText = "weekday_text"
    }
}

struct ReviewDTO: Decodable {
    let authorName: String
    let rating: Int
    let text: String
    let time: Int
    
    enum CodingKeys: String, CodingKey {
        case authorName = "author_name"
        case rating
        case text
        case time
    }
}
