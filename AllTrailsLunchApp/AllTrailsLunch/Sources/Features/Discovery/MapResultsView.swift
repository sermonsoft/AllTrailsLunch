//
//  MapResultsView.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 05/11/25.
//

import SwiftUI
import MapKit

struct MapResultsView: View {
    // MARK: - Properties

    let places: [Place]
    let onToggleFavorite: (Place) -> Void
    let isSearchActive: Bool

    @Environment(FavoritesManager.self) var favoritesManager
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
            ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
                Annotation("", coordinate: place.coordinate) {
                    MapPinView(
                        place: place,
                        isSelected: selectedPlace?.id == place.id,
                        isSearchResult: isSearchActive,
                        appearanceDelay: Double(index) * 0.05 // Stagger animation
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
        if let selectedPlace = selectedPlace,
           let currentPlace = places.first(where: { $0.id == selectedPlace.id }) {
            VStack {
                Spacer()
                    .frame(height: cardTopOffset)
                selectedPlaceCard(currentPlace)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        )
                    )
                    .shadow(
                        color: Color.black.opacity(0.2),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                Spacer()
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedPlace.id)
            // Re-render when places array changes (e.g., favorite status updated)
            .animation(.easeInOut(duration: 0.2), value: places.map { $0.isFavorite })
        }
    }

    private func selectedPlaceCard(_ place: Place) -> some View {
        NavigationLink(destination: RestaurantDetailView(place: place, onToggleFavorite: onToggleFavorite)) {
            RestaurantRow(
                place: place,
                onToggleFavorite: { onToggleFavorite(place) }
            )
            // Force view refresh when place or favorite status changes
            .id("\(place.id)-\(favoritesManager.isFavorite(place.id))")
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
    let isSearchResult: Bool
    let appearanceDelay: Double

    @Environment(FavoritesManager.self) var favoritesManager
    @State private var hasAppeared = false

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
            .scaleEffect(isSelected ? 1.0 : 0.9)
            .shadow(
                color: isSelected ? Color.black.opacity(0.3) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            // Animate color changes when favorite status changes
            .animation(.easeInOut(duration: 0.2), value: favoritesManager.favoriteIds)
            // Appear/Disappear animations
            .scaleEffect(hasAppeared ? 1.0 : 0.3)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .offset(y: hasAppeared ? 0 : -20)
            .onAppear {
                withAnimation(
                    .spring(response: 0.6, dampingFraction: 0.7)
                    .delay(appearanceDelay)
                ) {
                    hasAppeared = true
                }
            }
            .transition(
                .asymmetric(
                    insertion: .scale.combined(with: .opacity).combined(with: .offset(y: -20)),
                    removal: .scale.combined(with: .opacity)
                )
            )
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
        } else if favoritesManager.isFavorite(place.id) {
            return DesignSystem.Colors.favorite
        } else if isSearchResult {
            // Search results use a distinct blue color
            return Color.blue
        } else {
            // Nearby results use the default accent color
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
        onToggleFavorite: { _ in },
        isSearchActive: false
    )
    .environment(AppConfiguration.shared.createFavoritesManager())
}
