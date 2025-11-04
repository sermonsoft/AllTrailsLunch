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
                restaurantList
                loadingIndicator
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.background)
    }

    // MARK: - Subviews

    private var restaurantList: some View {
        ForEach(places) { place in
            NavigationLink(destination: RestaurantDetailView(place: place)) {
                RestaurantRow(
                    place: place,
                    onToggleFavorite: { onToggleFavorite(place) }
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var loadingIndicator: some View {
        if isLoading {
            ProgressView()
                .padding(DesignSystem.Spacing.lg)
        }
    }
}

// MARK: - Restaurant Row Component

struct RestaurantRow: View {
    let place: Place
    let onToggleFavorite: () -> Void
    @EnvironmentObject var favoritesStore: FavoritesStore

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            restaurantImage
            restaurantInfo
            Spacer(minLength: DesignSystem.Spacing.sm)
            bookmarkButton
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }

    // MARK: - Image

    private var restaurantImage: some View {
        CachedPhotoView(
            photoReferences: place.photoReferences,
            maxWidth: 160, // 2x for retina
            maxHeight: 160,
            contentMode: .fill
        )
        .frame(width: 80, height: 80)
        .clipped()
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }

    // MARK: - Info Section

    private var restaurantInfo: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            restaurantName
            ratingAndReviews
            supportingText
        }
    }

    private var restaurantName: some View {
        Text(place.name)
            .font(DesignSystem.Typography.h3)
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .lineLimit(1)
            .multilineTextAlignment(.leading)
    }

    private var ratingAndReviews: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ratingView
            separator
            reviewCount
        }
    }

    @ViewBuilder
    private var ratingView: some View {
        if let rating = place.rating {
            HStack(spacing: 2) {
                Image(.star)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 12, height: 12)
                    .foregroundColor(DesignSystem.Colors.star)
                Text(String(format: "%.1f", rating))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var separator: some View {
        if place.rating != nil && place.userRatingsTotal != nil {
            Text("•")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }

    @ViewBuilder
    private var reviewCount: some View {
        if let count = place.userRatingsTotal {
            Text("(\(count))")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }

    @ViewBuilder
    private var supportingText: some View {
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

    // MARK: - Bookmark Button

    private var bookmarkButton: some View {
        Button(action: onToggleFavorite) {
            Image(place.isFavorite ? "bookmark-saved" : "bookmark-resting", bundle: nil)
                .resizable()
                .renderingMode(.template)
                .frame(width: DesignSystem.IconSize.md, height: DesignSystem.IconSize.md)
                .foregroundColor(bookmarkColor)
        }
        .buttonStyle(.plain)
    }

    private var bookmarkColor: Color {
        place.isFavorite ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary
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

