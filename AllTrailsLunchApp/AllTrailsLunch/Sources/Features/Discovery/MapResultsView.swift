///
/// `MapResultsView.swift`
/// AllTrailsLunch
///
/// Map view for displaying restaurant locations.
///

import SwiftUI
import MapKit

struct MapResultsView: View {
    let places: [Place]
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedPlace: Place?
    
    var body: some View {
        ZStack {
            mapView
            
            if let selectedPlace = selectedPlace {
                VStack {
                    Spacer()
                    selectedPlaceCard(selectedPlace)
                }
            }
        }
        .onAppear {
            updateMapRegion()
        }
        .onChange(of: places) { _, _ in
            updateMapRegion()
        }
    }
    
    private var mapView: some View {
        Map(position: $position, selection: $selectedPlace) {
            ForEach(places) { place in
                Annotation("", coordinate: place.coordinate) {
                    MapPinView(place: place, isSelected: selectedPlace?.id == place.id)
                }
                .tag(place)
            }
        }
        .mapStyle(.standard)
    }
    
    private func selectedPlaceCard(_ place: Place) -> some View {
        NavigationLink(destination: RestaurantDetailView(place: place)) {
            VStack(alignment: .leading, spacing: 8) {
                Text(place.name)
                    .font(.headline)
                
                if let address = place.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    if let rating = place.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                        }
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 4)
            .padding()
        }
    }
    
    private func updateMapRegion() {
        guard !places.isEmpty else { return }
        
        let coordinates = places.map { $0.coordinate }
        let avgLat = coordinates.map { $0.latitude }.reduce(0, +) / Double(coordinates.count)
        let avgLon = coordinates.map { $0.longitude }.reduce(0, +) / Double(coordinates.count)
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        position = .region(region)
    }
}

// MARK: - Map Pin View

struct MapPinView: View {
    let place: Place
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: isSelected ? 32 : 24))
                .foregroundColor(isSelected ? .red : .blue)
        }
    }
}

#Preview {
    MapResultsView(places: [
        Place(
            id: "1",
            name: "Test Restaurant",
            rating: 4.5,
            userRatingsTotal: 120,
            priceLevel: 2,
            latitude: 37.7749,
            longitude: -122.4194,
            address: "123 Main St",
            photoReferences: [],
            isFavorite: false
        )
    ])
}
