///
/// `LocationManager.swift`
/// AllTrailsLunch
///
/// Wrapper around CLLocationManager with async/await support.
///

import Foundation
import CoreLocation

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: Error?
    
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        authorizationStatus = manager.authorizationStatus
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
    
    nonisolated func locationManager(
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
    
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            self.error = error
            self.locationContinuation?.resume(throwing: PlacesError.unknown(error.localizedDescription))
            self.locationContinuation = nil
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }
}

