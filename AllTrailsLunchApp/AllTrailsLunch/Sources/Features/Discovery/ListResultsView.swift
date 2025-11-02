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
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            // Restaurant Image (left side)
            Image("placeholder-image")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(DesignSystem.CornerRadius.sm)

            // Content (middle)
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // Restaurant name
                Text(place.name)
                    .font(DesignSystem.Typography.h3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)

                // Rating and reviews
                HStack(spacing: DesignSystem.Spacing.xs) {
                    if let rating = place.rating {
                        HStack(spacing: 2) {
                            Image("star")
                                .resizable()
                                .renderingMode(.template)
                                .frame(width: 12, height: 12)
                                .foregroundColor(DesignSystem.Colors.star)
                            Text(String(format: "%.1f", rating))
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }

                    if let rating = place.rating, let count = place.userRatingsTotal {
                        Text("•")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }

                    if let count = place.userRatingsTotal {
                        Text("(\(count))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }

                // Supporting text (address or price)
                if let address = place.address {
                    Text(address)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                } else if !place.priceDisplay.isEmpty {
                    Text(place.priceDisplay)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer(minLength: DesignSystem.Spacing.sm)

            // Bookmark button (right side)
            Button(action: onToggleFavorite) {
                Image(place.isFavorite ? "bookmark-saved" : "bookmark-resting")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: DesignSystem.IconSize.md, height: DesignSystem.IconSize.md)
                    .foregroundColor(place.isFavorite ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.Spacing.md)
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

