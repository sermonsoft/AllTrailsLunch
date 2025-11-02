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
        ZStack(alignment: .top) {
            mapView

            if let selectedPlace = selectedPlace {
                VStack {
                    Spacer()
                        .frame(height: 200) // Position card in upper portion of map
                    selectedPlaceCallout(selectedPlace)
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

    private func selectedPlaceCallout(_ place: Place) -> some View {
        NavigationLink(destination: RestaurantDetailView(place: place)) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                // Placeholder for image
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.searchBackground)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    )

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(place.name)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)

                    if let rating = place.rating {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(.star)
                                .resizable()
                                .renderingMode(.template)
                                .frame(width: DesignSystem.IconSize.xs, height: DesignSystem.IconSize.xs)
                                .foregroundColor(DesignSystem.Colors.star)
                            Text(String(format: "%.1f", rating))
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            if let count = place.userRatingsTotal {
                                Text("(\(count))")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }

                    if let address = place.address {
                        Text(address)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button(action: {}) {
                    Image(place.isFavorite ? "bookmark-saved" : "bookmark-resting", bundle: nil)
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: DesignSystem.IconSize.md, height: DesignSystem.IconSize.md)
                        .foregroundColor(place.isFavorite ? DesignSystem.Colors.favorite : DesignSystem.Colors.textSecondary)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(Color.white)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .shadow(color: DesignSystem.Shadows.card.color, radius: DesignSystem.Shadows.card.radius, x: DesignSystem.Shadows.card.x, y: DesignSystem.Shadows.card.y)
            .frame(width: 320)
        }
        .buttonStyle(.plain)
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
