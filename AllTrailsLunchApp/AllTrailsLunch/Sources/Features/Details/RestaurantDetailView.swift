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
    @State private var placeDetail: PlaceDetail?
    @State private var isLoadingDetails = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Photo
                if !place.photoReferences.isEmpty {
                    heroPhoto
                }

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
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

                    if let phoneNumber = placeDetail?.phoneNumber {
                        Button(action: { callRestaurant(phoneNumber: phoneNumber) }) {
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
                    } else if isLoadingDetails {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: DesignSystem.IconSize.md))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                            Text("Loading...")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                            Spacer()
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.searchBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }

                    if let website = placeDetail?.website {
                        Button(action: { openWebsite(url: website) }) {
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
                    } else if isLoadingDetails {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "globe")
                                .font(.system(size: DesignSystem.IconSize.md))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                            Text("Loading...")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                            Spacer()
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
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isFavorite = favoritesStore.isFavorite(place.id)
            await loadPlaceDetails()
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

    private func loadPlaceDetails() async {
        isLoadingDetails = true
        defer { isLoadingDetails = false }

        do {
            let manager = AppConfiguration.shared.createRestaurantManager()
            placeDetail = try await manager.getPlaceDetails(placeId: place.id)
        } catch {
            print("❌ Failed to load place details: \(error.localizedDescription)")
        }
    }

    private func callRestaurant(phoneNumber: String) {
        // Remove all non-numeric characters from phone number
        let cleanedNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        if let url = URL(string: "tel://\(cleanedNumber)") {
            openURL(url)
        }
    }

    private func openWebsite(url: URL) {
        openURL(url)
    }

    // MARK: - Hero Photo

    private var heroPhoto: some View {
        CachedPhotoView(
            photoReferences: place.photoReferences,
            maxWidth: 800,
            maxHeight: 400,
            contentMode: .fill
        )
        .frame(height: 250)
        .clipped()
        .transition(.opacity)
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

