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
    let onToggleFavorite: (Place) -> Void
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedPlace: Place?

    var body: some View {
        ZStack(alignment: .top) {
            mapView

            if let selectedPlace = selectedPlace {
                VStack {
                    Spacer()
                        .frame(height: 200) // Position card in upper portion of map
                    selectedPlaceCard(selectedPlace)
                        .transition(.scale.combined(with: .opacity))
                    Spacer()
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedPlace.id)
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
            RestaurantRow(
                place: place,
                onToggleFavorite: { onToggleFavorite(place) }
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DesignSystem.Spacing.lg)
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
    @EnvironmentObject var favoritesStore: FavoritesStore

    var body: some View {
        Image(isSelected ? "pin-selected" : "pin-resting", bundle: nil)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
            .foregroundColor(pinColor)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }

    private var pinColor: Color {
        if isSelected {
            return DesignSystem.Colors.primary
        } else if place.isFavorite {
            return DesignSystem.Colors.favorite
        } else {
            return DesignSystem.Colors.accent
        }
    }
}

#Preview {
    MapResultsView(
        places: [
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
        ],
        onToggleFavorite: { _ in }
    )
    .environmentObject(FavoritesStore())
}
