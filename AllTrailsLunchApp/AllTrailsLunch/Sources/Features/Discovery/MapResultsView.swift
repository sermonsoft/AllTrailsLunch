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
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text(place.name)
                    .font(DesignSystem.Typography.h3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)

                if let address = place.address {
                    Text(address)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: DesignSystem.Spacing.md) {
                    if let rating = place.rating {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(.star)
                                .resizable()
                                .renderingMode(.template)
                                .frame(width: DesignSystem.IconSize.sm, height: DesignSystem.IconSize.sm)
                                .foregroundColor(DesignSystem.Colors.star)
                            Text(String(format: "%.1f", rating))
                                .font(DesignSystem.Typography.captionBold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                    }

                    if !place.priceDisplay.isEmpty {
                        Text(place.priceDisplay)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: DesignSystem.IconSize.sm))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignSystem.Spacing.lg)
            .cardStyle()
            .padding(DesignSystem.Spacing.lg)
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
        ZStack {
            // Pin shadow
            Circle()
                .fill(Color.black.opacity(0.2))
                .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                .offset(y: isSelected ? 20 : 16)
                .blur(radius: 4)

            // Pin body
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(pinColor)
                        .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)

                    Circle()
                        .fill(Color.white)
                        .frame(width: isSelected ? 32 : 24, height: isSelected ? 32 : 24)

                    if place.isFavorite {
                        Image("bookmark-saved", bundle: nil)
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: isSelected ? 16 : 12, height: isSelected ? 16 : 12)
                            .foregroundColor(pinColor)
                    } else {
                        Image(systemName: "fork.knife")
                            .font(.system(size: isSelected ? 16 : 12, weight: .semibold))
                            .foregroundColor(pinColor)
                    }
                }

                // Pin pointer
                Triangle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 12 : 10, height: isSelected ? 8 : 6)
                    .offset(y: -1)
            }
        }
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

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
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
