///
/// `RestaurantDetailView.swift`
/// AllTrailsLunch
///
/// Detail view for a restaurant.
///

import SwiftUI

struct RestaurantDetailView: View {
    let place: Place
    @EnvironmentObject var favoritesStore: FavoritesStore
    @State private var isFavorite: Bool = false
    @State private var isBookmarkAnimating = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Photo Gallery
                if !place.photoReferences.isEmpty {
                    photoGallery
                }

                // Header Card
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(place.name)
                                .font(DesignSystem.Typography.h2)
                                .foregroundColor(DesignSystem.Colors.textPrimary)

                            if let address = place.address {
                                Text(address)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }

                        Spacer()

                        Button(action: { handleBookmarkTap() }) {
                            Image(isFavorite ? "bookmark-saved" : "bookmark-resting", bundle: nil)
                                .resizable()
                                .renderingMode(.template)
                                .frame(width: DesignSystem.IconSize.lg, height: DesignSystem.IconSize.lg)
                                .foregroundColor(isFavorite ? DesignSystem.Colors.favorite : DesignSystem.Colors.textTertiary)
                                .scaleEffect(isBookmarkAnimating ? 1.3 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isBookmarkAnimating)
                        }
                    }

                    // Rating and Price
                    HStack(spacing: DesignSystem.Spacing.md) {
                        if let rating = place.rating {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(.star)
                                    .resizable()
                                    .renderingMode(.template)
                                    .frame(width: DesignSystem.IconSize.md, height: DesignSystem.IconSize.md)
                                    .foregroundColor(DesignSystem.Colors.star)
                                Text(String(format: "%.1f", rating))
                                    .font(DesignSystem.Typography.bodyBold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                        }

                        if !place.priceDisplay.isEmpty {
                            Text(place.priceDisplay)
                                .font(DesignSystem.Typography.body)
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
                
                // Contact Information Card
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Contact")
                        .font(DesignSystem.Typography.h3)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Button(action: {}) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: DesignSystem.IconSize.md))
                                .foregroundColor(DesignSystem.Colors.primary)
                            Text("Call Restaurant")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: DesignSystem.IconSize.sm))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.searchBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }

                    Button(action: {}) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "globe")
                                .font(.system(size: DesignSystem.IconSize.md))
                                .foregroundColor(DesignSystem.Colors.primary)
                            Text("Visit Website")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: DesignSystem.IconSize.sm))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.searchBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                }
                .padding(DesignSystem.Spacing.lg)
                .cardStyle()

                // Hours Card
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Hours")
                        .font(DesignSystem.Typography.h3)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: DesignSystem.IconSize.md))
                            .foregroundColor(DesignSystem.Colors.success)
                        Text("Open now")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.success)
                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.searchBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                .padding(DesignSystem.Spacing.lg)
                .cardStyle()

                Spacer()
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isFavorite = favoritesStore.isFavorite(place.id)
        }
    }
    
    // MARK: - Actions

    private func handleBookmarkTap() {
        isBookmarkAnimating = true
        toggleFavorite()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isBookmarkAnimating = false
        }
    }

    private func toggleFavorite() {
        isFavorite.toggle()
        favoritesStore.toggleFavorite(place.id)
    }

    // MARK: - Photo Gallery

    private var photoGallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ForEach(Array(place.photoReferences.prefix(5).enumerated()), id: \.offset) { index, photoRef in
                    photoGalleryItem(photoRef: photoRef, index: index)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }

    private func photoGalleryItem(photoRef: String, index: Int) -> some View {
        CachedPhotoView(
            photoReferences: [photoRef],
            maxWidth: 300,
            maxHeight: 200,
            contentMode: .fill
        )
        .frame(width: 300, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: place.id)
    }
}

#Preview {
    NavigationStack {
        RestaurantDetailView(place: Place(
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
        ))
        .environmentObject(FavoritesStore())
    }
}

