///
/// `ListResultsView.swift`
/// AllTrailsLunch
///
/// List view for displaying restaurant results.
///

import SwiftUI

struct ListResultsView: View {
    let places: [Place]
    let isLoading: Bool
    let onToggleFavorite: (Place) -> Void
    let onLoadMore: () async -> Void
    
    var body: some View {
        List {
            ForEach(places) { place in
                NavigationLink(destination: RestaurantDetailView(place: place)) {
                    RestaurantRow(
                        place: place,
                        onToggleFavorite: { onToggleFavorite(place) }
                    )
                }
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Restaurant Row

struct RestaurantRow: View {
    let place: Place
    let onToggleFavorite: () -> Void
    @EnvironmentObject var favoritesStore: FavoritesStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let address = place.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Button(action: onToggleFavorite) {
                    Image(systemName: place.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(place.isFavorite ? .red : .gray)
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 12) {
                if let rating = place.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                    }
                }
                
                if !place.priceDisplay.isEmpty {
                    Text(place.priceDisplay)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if let count = place.userRatingsTotal {
                    Text("(\(count))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        RestaurantRow(
            place: Place(
                id: "1",
                name: "Test Restaurant",
                rating: 4.5,
                userRatingsTotal: 120,
                priceLevel: 2,
                latitude: 0,
                longitude: 0,
                address: "123 Main St",
                photoReferences: [],
                isFavorite: false
            ),
            onToggleFavorite: {}
        )
    }
    .environmentObject(FavoritesStore())
}

