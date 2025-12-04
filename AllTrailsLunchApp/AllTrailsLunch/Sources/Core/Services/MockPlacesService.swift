//
//  MockPlacesService.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/12/25.
//

import Foundation
import CoreLocation

/// Mock implementation of RemotePlacesService for UI testing and development.
/// Loads mock data from JSON files to simulate real API responses.
final class MockPlacesService: RemotePlacesService {

    // MARK: - Properties

    private let mockNearbyResponse: NearbySearchResponse
    private let mockDetailsResponse: PlaceDetailsResponse

    // MARK: - Initialization

    init() {
        // Load mock data from JSON files
        self.mockNearbyResponse = Self.loadMockNearbyResponse()
        self.mockDetailsResponse = Self.loadMockDetailsResponse()
    }

    // MARK: - Mock Data Loading

    private static func loadMockNearbyResponse() -> NearbySearchResponse {
        // Try to load from JSON file first
        if let url = Bundle.main.url(forResource: "nearby_search", withExtension: "json", subdirectory: "MockData"),
           let data = try? Data(contentsOf: url),
           let response = try? JSONDecoder().decode(NearbySearchResponse.self, from: data) {
            print("✅ MockPlacesService: Loaded nearby_search.json from bundle")
            return response
        }

        // Fallback to embedded JSON data
        print("⚠️ MockPlacesService: Using embedded mock data (JSON file not found in bundle)")
        let jsonString = """
        {
          "results": [
            {
              "business_status": "OPERATIONAL",
              "geometry": {
                "location": {
                  "lat": 37.7736,
                  "lng": -122.421608
                }
              },
              "name": "Zuni Café",
              "opening_hours": {
                "open_now": true
              },
              "photos": [
                {
                  "height": 2592,
                  "photo_reference": "mock-photo-1",
                  "width": 4608
                }
              ],
              "place_id": "ChIJO7u9q5-AhYARiSSXyWv9eJ8",
              "price_level": 3,
              "rating": 4.4,
              "types": [
                "restaurant",
                "food",
                "point_of_interest",
                "establishment"
              ],
              "user_ratings_total": 2100,
              "vicinity": "1658 Market Street, San Francisco",
              "formatted_address": "1658 Market St, San Francisco, CA 94102"
            },
            {
              "business_status": "OPERATIONAL",
              "geometry": {
                "location": {
                  "lat": 37.7614,
                  "lng": -122.4241
                }
              },
              "name": "Tartine Bakery",
              "opening_hours": {
                "open_now": true
              },
              "photos": [
                {
                  "height": 3024,
                  "photo_reference": "mock-photo-2",
                  "width": 4032
                }
              ],
              "place_id": "ChIJmzrKr5-AhYARoJrKr5-AhYA",
              "price_level": 2,
              "rating": 4.5,
              "types": [
                "bakery",
                "cafe",
                "food",
                "point_of_interest",
                "establishment"
              ],
              "user_ratings_total": 3200,
              "vicinity": "600 Guerrero Street, San Francisco",
              "formatted_address": "600 Guerrero St, San Francisco, CA 94110"
            },
            {
              "business_status": "OPERATIONAL",
              "geometry": {
                "location": {
                  "lat": 37.7849,
                  "lng": -122.4324
                }
              },
              "name": "State Bird Provisions",
              "opening_hours": {
                "open_now": false
              },
              "photos": [
                {
                  "height": 2268,
                  "photo_reference": "mock-photo-3",
                  "width": 4032
                }
              ],
              "place_id": "ChIJxzrKr5-AhYARxJrKr5-AhYA",
              "price_level": 3,
              "rating": 4.7,
              "types": [
                "restaurant",
                "food",
                "point_of_interest",
                "establishment"
              ],
              "user_ratings_total": 1580,
              "vicinity": "1529 Fillmore Street, San Francisco",
              "formatted_address": "1529 Fillmore St, San Francisco, CA 94115"
            },
            {
              "business_status": "OPERATIONAL",
              "geometry": {
                "location": {
                  "lat": 37.8794,
                  "lng": -122.2686
                }
              },
              "name": "Chez Panisse",
              "opening_hours": {
                "open_now": true
              },
              "photos": [
                {
                  "height": 3024,
                  "photo_reference": "mock-photo-4",
                  "width": 4032
                }
              ],
              "place_id": "ChIJyzrKr5-AhYARyJrKr5-AhYA",
              "price_level": 4,
              "rating": 4.6,
              "types": [
                "restaurant",
                "food",
                "point_of_interest",
                "establishment"
              ],
              "user_ratings_total": 890,
              "vicinity": "1517 Shattuck Avenue, Berkeley",
              "formatted_address": "1517 Shattuck Ave, Berkeley, CA 94709"
            },
            {
              "business_status": "OPERATIONAL",
              "geometry": {
                "location": {
                  "lat": 38.4024,
                  "lng": -122.3625
                }
              },
              "name": "The French Laundry",
              "opening_hours": {
                "open_now": false
              },
              "photos": [
                {
                  "height": 2268,
                  "photo_reference": "mock-photo-5",
                  "width": 4032
                }
              ],
              "place_id": "ChIJzzrKr5-AhYARzJrKr5-AhYA",
              "price_level": 4,
              "rating": 4.8,
              "types": [
                "restaurant",
                "food",
                "point_of_interest",
                "establishment"
              ],
              "user_ratings_total": 1250,
              "vicinity": "6640 Washington Street, Yountville",
              "formatted_address": "6640 Washington St, Yountville, CA 94599"
            }
          ],
          "status": "OK"
        }
        """

        guard let data = jsonString.data(using: .utf8),
              let response = try? JSONDecoder().decode(NearbySearchResponse.self, from: data) else {
            fatalError("Failed to decode embedded mock data")
        }

        return response
    }

    private static func loadMockDetailsResponse() -> PlaceDetailsResponse {
        // Try to load from JSON file first
        if let url = Bundle.main.url(forResource: "place_details", withExtension: "json", subdirectory: "MockData"),
           let data = try? Data(contentsOf: url),
           let response = try? JSONDecoder().decode(PlaceDetailsResponse.self, from: data) {
            print("✅ MockPlacesService: Loaded place_details.json from bundle")
            return response
        }

        // Fallback to embedded JSON data
        print("⚠️ MockPlacesService: Using embedded place details mock data")
        let jsonString = """
        {
          "result": {
            "name": "Zuni Café",
            "formatted_address": "1658 Market St, San Francisco, CA 94102-5949, USA",
            "formatted_phone_number": "(415) 552-2522",
            "website": "http://www.zunicafe.com/",
            "rating": 4.4,
            "opening_hours": {
              "open_now": true,
              "weekday_text": [
                "Monday: Closed",
                "Tuesday: 5:00 – 9:30 PM",
                "Wednesday: 5:00 – 9:30 PM",
                "Thursday: 5:00 – 9:30 PM",
                "Friday: 11:00 AM – 3:00 PM, 5:00 – 10:00 PM",
                "Saturday: 11:00 AM – 3:00 PM, 5:00 – 10:00 PM",
                "Sunday: 11:00 AM – 3:00 PM, 5:00 – 9:30 PM"
              ]
            },
            "reviews": [
              {
                "author_name": "John Smith",
                "rating": 5,
                "text": "Amazing food and atmosphere! The roast chicken is a must-try.",
                "time": 1701388800
              },
              {
                "author_name": "Sarah Johnson",
                "rating": 4,
                "text": "Great restaurant with classic San Francisco charm.",
                "time": 1701302400
              }
            ]
          },
          "status": "OK"
        }
        """

        guard let data = jsonString.data(using: .utf8),
              let response = try? JSONDecoder().decode(PlaceDetailsResponse.self, from: data) else {
            fatalError("Failed to decode embedded place details mock data")
        }

        return response
    }

    // MARK: - RemotePlacesService Protocol

    func searchNearby(
        latitude: Double,
        longitude: Double,
        radius: Int,
        pageToken: String?
    ) async throws -> (results: [PlaceDTO], nextPageToken: String?) {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        print("🎭 MockPlacesService: searchNearby called - returning \(mockNearbyResponse.results.count) places")

        // Return mock data from JSON file
        return (mockNearbyResponse.results, mockNearbyResponse.nextPageToken)
    }

    func searchText(
        query: String,
        latitude: Double?,
        longitude: Double?,
        pageToken: String?
    ) async throws -> (results: [PlaceDTO], nextPageToken: String?) {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Filter mock places by query
        let filtered = mockNearbyResponse.results.filter { place in
            place.name.localizedCaseInsensitiveContains(query)
        }

        print("🎭 MockPlacesService: searchText called with query '\(query)' - returning \(filtered.count) places")

        // Return filtered results, or all results if no matches
        return (filtered.isEmpty ? mockNearbyResponse.results : filtered, nil)
    }

    func getPlaceDetails(placeId: String) async throws -> PlaceDetailsDTO {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        print("🎭 MockPlacesService: getPlaceDetails called for placeId '\(placeId)'")

        // Return mock details from JSON file
        return mockDetailsResponse.result
    }
}

