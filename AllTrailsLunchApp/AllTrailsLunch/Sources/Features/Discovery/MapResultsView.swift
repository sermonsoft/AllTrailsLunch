///
/// `MapResultsView.swift`
/// AllTrailsLunch
///
/// Map view for displaying restaurant locations.
///

import SwiftUI
import MapKit

struct MapResultsView: View {
    // MARK: - Properties

    let places: [Place]
    let onToggleFavorite: (Place) -> Void

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedPlace: Place?

    // MARK: - Constants

    private let cardTopOffset: CGFloat = 200
    private let mapSpan: Double = 0.05

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            mapView
            selectedPlaceCallout
        }
        .onAppear(perform: updateMapRegion)
        .onChange(of: places) { _, _ in updateMapRegion() }
    }

    // MARK: - Map View

    private var mapView: some View {
        Map(position: $position, selection: $selectedPlace) {
            ForEach(places) { place in
                Annotation("", coordinate: place.coordinate) {
                    MapPinView(
                        place: place,
                        isSelected: selectedPlace?.id == place.id
                    )
                }
                .tag(place)
            }
        }
        .mapStyle(.standard)
    }

    // MARK: - Selected Place Callout

    @ViewBuilder
    private var selectedPlaceCallout: some View {
        if let selectedPlace = selectedPlace {
            VStack {
                Spacer()
                    .frame(height: cardTopOffset)
                selectedPlaceCard(selectedPlace)
                    .transition(.scale.combined(with: .opacity))
                Spacer()
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedPlace.id)
        }
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

    // MARK: - Map Region Update

    private func updateMapRegion() {
        guard !places.isEmpty else { return }

        let coordinates = places.map { $0.coordinate }
        let center = calculateCenter(from: coordinates)
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: mapSpan, longitudeDelta: mapSpan)
        )

        position = .region(region)
    }

    private func calculateCenter(from coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        let avgLat = coordinates.map { $0.latitude }.reduce(0, +) / Double(coordinates.count)
        let avgLon = coordinates.map { $0.longitude }.reduce(0, +) / Double(coordinates.count)
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }
}

// MARK: - Map Pin View Component

struct MapPinView: View {
    // MARK: - Properties

    let place: Place
    let isSelected: Bool

    @EnvironmentObject var favoritesStore: FavoritesStore

    // MARK: - Constants

    private let selectedPinSize: CGFloat = 40
    private let defaultPinSize: CGFloat = 32

    // MARK: - Body

    var body: some View {
        Image(pinImageName, bundle: nil)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: pinSize, height: pinSize)
            .foregroundColor(pinColor)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }

    // MARK: - Computed Properties

    private var pinImageName: String {
        isSelected ? "pin-selected" : "pin-resting"
    }

    private var pinSize: CGFloat {
        isSelected ? selectedPinSize : defaultPinSize
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
