//
//  GooglePlacesService.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 01/11/25.
//

import Foundation

/// Google Places API implementation of RemotePlacesService.
/// This is the production implementation that talks to the real API.
class GooglePlacesService: RemotePlacesService {
    private let client: PlacesClient
    
    init(client: PlacesClient) {
        self.client = client
    }
    
    // MARK: - RemotePlacesService
    
    func searchNearby(
        latitude: Double,
        longitude: Double,
        radius: Int,
        pageToken: String?
    ) async throws -> (results: [PlaceDTO], nextPageToken: String?) {
        let url = try client.buildNearbySearchURL(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            pageToken: pageToken
        )
        
        let request = try PlacesRequestBuilder()
            .setURL(url)
            .setMethod(.get)
            .build()
        
        let response: NearbySearchResponse = try await client.execute(request)
        
        guard response.status == "OK" || response.status == "ZERO_RESULTS" else {
            throw PlacesError.invalidResponse("API returned status: \(response.status)")
        }
        
        return (response.results, response.nextPageToken)
    }
    
    func searchText(
        query: String,
        latitude: Double?,
        longitude: Double?,
        pageToken: String?
    ) async throws -> (results: [PlaceDTO], nextPageToken: String?) {
        let url = try client.buildTextSearchURL(
            query: query,
            latitude: latitude,
            longitude: longitude,
            pageToken: pageToken
        )
        
        let request = try PlacesRequestBuilder()
            .setURL(url)
            .setMethod(.get)
            .build()
        
        let response: TextSearchResponse = try await client.execute(request)
        
        guard response.status == "OK" || response.status == "ZERO_RESULTS" else {
            throw PlacesError.invalidResponse("API returned status: \(response.status)")
        }
        
        return (response.results, response.nextPageToken)
    }
    
    func getPlaceDetails(placeId: String) async throws -> PlaceDetailsDTO {
        let url = try client.buildDetailsURL(placeId: placeId)
        
        let request = try PlacesRequestBuilder()
            .setURL(url)
            .setMethod(.get)
            .build()
        
        let response: PlaceDetailsResponse = try await client.execute(request)
        
        guard response.status == "OK" else {
            throw PlacesError.invalidResponse("API returned status: \(response.status)")
        }
        
        return response.result
    }
}

