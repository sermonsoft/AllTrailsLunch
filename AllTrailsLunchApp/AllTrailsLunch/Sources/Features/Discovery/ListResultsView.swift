//
//  ListResultsView.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 05/11/25.
//

import SwiftUI

struct ListResultsView: View {
    let places: [Place]
    let isLoading: Bool
    let onToggleFavorite: (Place) -> Void
    let onLoadMore: () async -> Void
    let onRefresh: (() async -> Void)?

    @Environment(\.dependencyContainer) private var container
    @Environment(\.photoManager) private var photoManager

    private var favoritesManager: FavoritesManager {
        container?.favoritesManager ?? AppConfiguration.shared.createFavoritesManager()
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.md) {
                restaurantList
                loadingIndicator
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.background)
        .refreshable {
            if let onRefresh = onRefresh {
                await onRefresh()
            }
        }
    }

    // MARK: - Subviews

    private var restaurantList: some View {
        ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
            NavigationLink(destination:
                RestaurantDetailView(place: place, onToggleFavorite: onToggleFavorite)
                    .photoManager(photoManager ?? AppConfiguration.shared.createPhotoManager())
            ) {
                RestaurantRow(
                    place: place,
                    onToggleFavorite: { onToggleFavorite(place) }
                )
            }
            .buttonStyle(.plain)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)),
                removal: .opacity
            ))
            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: places.count)
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
    @Environment(\.dependencyContainer) private var container
    @State private var isBookmarkAnimating = false

    private var favoritesManager: FavoritesManager {
        container?.favoritesManager ?? AppConfiguration.shared.createFavoritesManager()
    }

    var body: some View {
        // CRITICAL: Access favoriteIds at the TOP of body to establish observation
        let favoriteIds = favoritesManager.favoriteIds
        let isFavorite = favoriteIds.contains(place.id)

        return HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            restaurantImage
            restaurantInfo
            Spacer(minLength: DesignSystem.Spacing.sm)
            bookmarkButtonView(isFavorite: isFavorite)
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

    private func bookmarkButtonView(isFavorite: Bool) -> some View {
        Button(action: handleBookmarkTap) {
            Image(isFavorite ? "bookmark-saved" : "bookmark-resting", bundle: nil)
                .resizable()
                .renderingMode(.template)
                .frame(width: DesignSystem.IconSize.md, height: DesignSystem.IconSize.md)
                .foregroundColor(isFavorite ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                .scaleEffect(isBookmarkAnimating ? 1.3 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isBookmarkAnimating)
        }
        .buttonStyle(.plain)
    }

    private func handleBookmarkTap() {
        // Trigger animation
        isBookmarkAnimating = true

        // Call the toggle action
        onToggleFavorite()

        // Reset animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isBookmarkAnimating = false
        }
    }
}

#Preview {
    let container = AppConfiguration.shared.createDependencyContainer()

    return List {
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
    .dependencyContainer(container)
}

