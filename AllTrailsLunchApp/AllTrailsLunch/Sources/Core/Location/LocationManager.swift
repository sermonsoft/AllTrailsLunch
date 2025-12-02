//
//  LocationManager.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 02/11/25.
//

import Foundation
import CoreLocation
import Combine

/// Manager for location services.
/// Returns data via async/await - does NOT use @Observable or ObservableObject.
/// ViewModels are responsible for managing observable state.
///
/// Combine Integration:
/// - Publishes location updates for reactive pipelines
/// - Thread-safe updates on MainActor
/// - Supports both async/await and Combine patterns
@MainActor
class LocationManager: NSObject, CLLocationManagerDelegate {

    // MARK: - Combine Publishers

    /// Published user location for Combine pipelines
    @Published private(set) var userLocation: CLLocationCoordinate2D?

    /// Published authorization status
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public API

    /// Get current location (cached if available)
    func getUserLocation() -> CLLocationCoordinate2D? {
        return userLocation
    }

    /// Get current authorization status
    func getAuthorizationStatus() -> CLAuthorizationStatus {
        return authorizationStatus
    }

    // MARK: - Authorization

    func requestLocationPermission() async throws -> CLLocationCoordinate2D {
        let status = manager.authorizationStatus

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if let location = userLocation {
                return location
            }
            return try await requestLocation()

        case .denied, .restricted:
            throw PlacesError.locationPermissionDenied

        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            return try await requestLocation()

        @unknown default:
            throw PlacesError.unknown("Unknown authorization status")
        }
    }

    // MARK: - Location Requests

    private func requestLocation() async throws -> CLLocationCoordinate2D {
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.manager.requestLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate

    /// CLLocationManagerDelegate methods are called on an arbitrary thread by CoreLocation.
    /// Since CLLocationManagerDelegate is a pre-concurrency Objective-C protocol, these methods
    /// are implicitly nonisolated. We use Task { @MainActor } to safely hop to the main actor
    /// to update our @MainActor-isolated properties.
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.userLocation = location.coordinate
            self.locationContinuation?.resume(returning: location.coordinate)
            self.locationContinuation = nil
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            self.locationContinuation?.resume(throwing: PlacesError.unknown(error.localizedDescription))
            self.locationContinuation = nil
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }
}

