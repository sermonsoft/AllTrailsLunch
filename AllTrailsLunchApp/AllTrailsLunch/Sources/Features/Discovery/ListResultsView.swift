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
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.md) {
                ForEach(places) { place in
                    NavigationLink(destination: RestaurantDetailView(place: place)) {
                        RestaurantRow(
                            place: place,
                            onToggleFavorite: { onToggleFavorite(place) }
                        )
                    }
                    .buttonStyle(.plain)
                }

                if isLoading {
                    ProgressView()
                        .padding(DesignSystem.Spacing.lg)
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - Restaurant Row

struct RestaurantRow: View {
    let place: Place
    let onToggleFavorite: () -> Void
    @EnvironmentObject var favoritesStore: FavoritesStore

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header with name and favorite button
            HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(place.name)
                        .font(DesignSystem.Typography.h3)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let address = place.address {
                        Text(address)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: DesignSystem.Spacing.sm)

                Button(action: onToggleFavorite) {
                    Image(systemName: place.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: DesignSystem.IconSize.md))
                        .foregroundColor(place.isFavorite ? DesignSystem.Colors.favorite : DesignSystem.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }

            // Rating, price, and review count
            HStack(spacing: DesignSystem.Spacing.md) {
                if let rating = place.rating {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "star.fill")
                            .font(.system(size: DesignSystem.IconSize.sm))
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

                if let count = place.userRatingsTotal {
                    Text("(\(count) reviews)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }

                Spacer()
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .cardStyle()
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

