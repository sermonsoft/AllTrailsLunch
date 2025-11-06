//
//  TestFixtures.swift
//  AllTrailsLunchAppTests
//
//  Created by Tri Le on 04/11/25.
//

import Foundation
import CoreLocation
@testable import AllTrailsLunchApp

// MARK: - Place Fixtures

enum PlaceFixtures {
    static let sanFranciscoLocation = CLLocationCoordinate2D(
        latitude: 37.7749,
        longitude: -122.4194
    )
    
    static let newYorkLocation = CLLocationCoordinate2D(
        latitude: 40.7128,
        longitude: -74.0060
    )
    
    static func createPlace(
        id: String = "test-place-1",
        name: String = "Test Restaurant",
        rating: Double = 4.5,
        userRatingsTotal: Int = 100,
        priceLevel: Int = 2,
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        address: String? = "123 Test St, San Francisco, CA",
        photoReferences: [String] = ["photo1", "photo2"],
        isFavorite: Bool = false
    ) -> Place {
        Place(
            id: id,
            name: name,
            rating: rating,
            userRatingsTotal: userRatingsTotal,
            priceLevel: priceLevel,
            latitude: latitude,
            longitude: longitude,
            address: address,
            photoReferences: photoReferences,
            isFavorite: isFavorite
        )
    }
    
    static let sampleRestaurant = createPlace(
        id: "place-1",
        name: "The Golden Gate Grill",
        rating: 4.7,
        userRatingsTotal: 250,
        priceLevel: 3
    )
    
    static let samplePizzaPlace = createPlace(
        id: "place-2",
        name: "Tony's Pizza",
        rating: 4.3,
        userRatingsTotal: 180,
        priceLevel: 2
    )
    
    static let sampleSushiPlace = createPlace(
        id: "place-3",
        name: "Sakura Sushi",
        rating: 4.8,
        userRatingsTotal: 320,
        priceLevel: 3
    )
    
    static let sampleBurgerPlace = createPlace(
        id: "place-4",
        name: "Burger Haven",
        rating: 4.2,
        userRatingsTotal: 150,
        priceLevel: 1
    )
    
    static let sampleCafePlace = createPlace(
        id: "place-5",
        name: "Cozy Cafe",
        rating: 4.6,
        userRatingsTotal: 200,
        priceLevel: 2
    )
    
    static var samplePlaces: [Place] {
        [
            sampleRestaurant,
            samplePizzaPlace,
            sampleSushiPlace,
            sampleBurgerPlace,
            sampleCafePlace
        ]
    }
    
    static var highRatedPlaces: [Place] {
        samplePlaces.filter { ($0.rating ?? 0) >= 4.5 }
    }

    static var lowPricePlaces: [Place] {
        samplePlaces.filter { ($0.priceLevel ?? 0) <= 2 }
    }
}

// MARK: - PlaceDTO Fixtures

enum PlaceDTOFixtures {
    static func createPlaceDTO(
        id: String = "test-place-1",
        name: String = "Test Restaurant",
        rating: Double = 4.5,
        userRatingsTotal: Int = 100,
        priceLevel: Int = 2,
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        formattedAddress: String = "123 Test St",
        photos: [PhotoDTO]? = nil,
        types: [String] = ["restaurant"]
    ) -> PlaceDTO {
        PlaceDTO(
            id: id,
            name: name,
            rating: rating,
            userRatingsTotal: userRatingsTotal,
            priceLevel: priceLevel,
            geometry: GeometryDTO(
                location: LocationDTO(lat: latitude, lng: longitude)
            ),
            formattedAddress: formattedAddress,
            photos: photos,
            types: types
        )
    }
    
    static let samplePlaceDTO = createPlaceDTO(
        id: "dto-1",
        name: "Sample Restaurant DTO"
    )
    
    static var samplePlaceDTOs: [PlaceDTO] {
        [
            createPlaceDTO(id: "dto-1", name: "Restaurant 1"),
            createPlaceDTO(id: "dto-2", name: "Restaurant 2"),
            createPlaceDTO(id: "dto-3", name: "Restaurant 3")
        ]
    }
}

// MARK: - PlaceDetailsDTO Fixtures

enum PlaceDetailsDTOFixtures {
    static func createPlaceDetailsDTO(
        name: String = "Test Restaurant",
        rating: Double = 4.5,
        formattedPhoneNumber: String? = "(555) 123-4567",
        openingHours: OpeningHoursDTO? = nil,
        website: String? = "https://example.com",
        reviews: [ReviewDTO]? = nil,
        formattedAddress: String = "123 Test St"
    ) -> PlaceDetailsDTO {
        PlaceDetailsDTO(
            name: name,
            rating: rating,
            formattedPhoneNumber: formattedPhoneNumber,
            openingHours: openingHours,
            website: website,
            reviews: reviews,
            formattedAddress: formattedAddress
        )
    }
    
    static let sampleDetails = createPlaceDetailsDTO(
        name: "Sample Restaurant",
        openingHours: OpeningHoursDTO(
            openNow: true,
            weekdayText: [
                "Monday: 11:00 AM – 10:00 PM",
                "Tuesday: 11:00 AM – 10:00 PM",
                "Wednesday: 11:00 AM – 10:00 PM",
                "Thursday: 11:00 AM – 10:00 PM",
                "Friday: 11:00 AM – 11:00 PM",
                "Saturday: 10:00 AM – 11:00 PM",
                "Sunday: 10:00 AM – 9:00 PM"
            ]
        )
    )
}

// MARK: - SearchFilters Fixtures

enum SearchFiltersFixtures {
    static let defaultFilters = SearchFilters.default

    static let highRatingFilter = SearchFilters(
        minRating: 4.5,
        maxPriceLevel: nil,
        openNow: false
    )

    static let lowPriceFilter = SearchFilters(
        minRating: nil,
        maxPriceLevel: 2,
        openNow: false
    )

    static let openNowFilter = SearchFilters(
        minRating: nil,
        maxPriceLevel: nil,
        openNow: true
    )

    static let combinedFilter = SearchFilters(
        minRating: 4.0,
        maxPriceLevel: 2,
        openNow: true
    )
}

// MARK: - SavedSearch Fixtures

enum SavedSearchFixtures {
    static func createSavedSearch(
        name: String = "Test Search",
        query: String = "pizza",
        location: (latitude: Double, longitude: Double)? = (37.7749, -122.4194),
        filters: SearchFilters = .default
    ) -> SavedSearch {
        SavedSearch(
            name: name,
            query: query,
            location: location,
            filters: filters
        )
    }
    
    static let pizzaSearch = createSavedSearch(
        name: "Pizza Places",
        query: "pizza"
    )
    
    static let sushiSearch = createSavedSearch(
        name: "Sushi Restaurants",
        query: "sushi",
        filters: SearchFiltersFixtures.highRatingFilter
    )
    
    static let nearbySearch = createSavedSearch(
        name: "Nearby Restaurants",
        query: "",
        filters: SearchFiltersFixtures.openNowFilter
    )
}

// MARK: - Error Fixtures

enum ErrorFixtures {
    static let networkError = PlacesError.networkUnavailable

    static let invalidResponse = PlacesError.invalidResponse("Invalid JSON")

    static let locationPermissionDenied = PlacesError.locationPermissionDenied

    static let requestFailed = PlacesError.requestFailed(
        statusCode: 500,
        message: "Internal Server Error"
    )

    static let unknownError = PlacesError.unknown("Unknown error occurred")
}

