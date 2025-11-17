//
//  RestaurantDetailView.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 05/11/25.
//

import SwiftUI

struct RestaurantDetailView: View {
    let place: Place
    let onToggleFavorite: ((Place) async -> Void)?
    let loadPhoto: ([String], Int, Int) async -> Data?
    @State private var isBookmarkAnimating = false
    @State private var isFavorite = false
    @State private var placeDetail: PlaceDetail?
    @State private var isLoadingDetails = false
    @State private var showHoursDetails = false
    @Environment(\.openURL) private var openURL

    init(
        place: Place,
        onToggleFavorite: ((Place) async -> Void)? = nil,
        loadPhoto: @escaping ([String], Int, Int) async -> Data?
    ) {
        self.place = place
        self.onToggleFavorite = onToggleFavorite
        self.loadPhoto = loadPhoto
        // Initialize the state with the place's favorite status
        _isFavorite = State(initialValue: place.isFavorite)
    }

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
                                .foregroundColor(isFavorite ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
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

                    // Get Directions Button (always available)
                    Button(action: { getDirections() }) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "map.fill")
                                .font(.system(size: DesignSystem.IconSize.md))
                                .foregroundColor(DesignSystem.Colors.primary)
                            Text("Get Directions")
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

                    // Show offline message if details failed to load
                    #if DEV
                    if !isLoadingDetails && placeDetail == nil && NetworkSimulator.shared.shouldBlockRequest() {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: DesignSystem.IconSize.sm))
                                .foregroundColor(.orange)
                            Text("Additional contact info unavailable offline")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .padding(.vertical, DesignSystem.Spacing.sm)
                    }
                    #endif
                }
                .padding(DesignSystem.Spacing.lg)
                .cardStyle()

                // Hours Card
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Hours")
                        .font(DesignSystem.Typography.h3)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    if let openingHours = placeDetail?.openingHours {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showHoursDetails.toggle()
                            }
                        }) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: DesignSystem.IconSize.md))
                                        .foregroundColor(openingHours.openNow == true ? DesignSystem.Colors.success : .red)
                                    Text(openingHours.openNow == true ? "Open now" : "Closed")
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(openingHours.openNow == true ? DesignSystem.Colors.success : .red)
                                    Spacer()
                                    Image(systemName: showHoursDetails ? "chevron.up" : "chevron.down")
                                        .font(.system(size: DesignSystem.IconSize.sm))
                                        .foregroundColor(DesignSystem.Colors.textTertiary)
                                }

                                if showHoursDetails, let weekdayText = openingHours.weekdayText {
                                    Divider()
                                        .padding(.vertical, DesignSystem.Spacing.xs)

                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                        ForEach(weekdayText, id: \.self) { dayHours in
                                            HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                                                Text(dayHours)
                                                    .font(DesignSystem.Typography.caption)
                                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.searchBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                        .buttonStyle(.plain)
                    } else if isLoadingDetails {
                        HStack {
                            Image(systemName: "clock.fill")
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
                    } else {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.system(size: DesignSystem.IconSize.md))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                            Text("Hours not available")
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

                    Spacer()
                }
                .padding(DesignSystem.Spacing.lg)
            }
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPlaceDetails()
        }
    }
    
    // MARK: - Actions

    private func handleBookmarkTap() {
        isBookmarkAnimating = true

        // Toggle local state immediately for instant UI feedback
        isFavorite.toggle()

        // Call the callback to update the data source
        Task {
            await onToggleFavorite?(place)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isBookmarkAnimating = false
        }
    }

    private func loadPlaceDetails() async {
        isLoadingDetails = true
        defer { isLoadingDetails = false }

        do {
            let manager = AppConfiguration.shared.createRestaurantManager()
            placeDetail = try await manager.getPlaceDetails(placeId: place.id)
        } catch {
            // Check if this is a network simulation error (offline mode)
            #if DEV
            if NetworkSimulator.shared.shouldBlockRequest() {
                print("⚠️ RestaurantDetailView: Skipping place details - network is offline")
                return
            }
            #endif

            // Only log real errors
            if !(error is CancellationError) {
                print("❌ Failed to load place details: \(error.localizedDescription)")
            }
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

    private func getDirections() {
        // Open Apple Maps with directions to the restaurant
        let coordinate = "\(place.latitude),\(place.longitude)"
        let encodedName = place.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "http://maps.apple.com/?daddr=\(coordinate)&q=\(encodedName)") {
            openURL(url)
        }
    }

    // MARK: - Hero Photo

    private var heroPhoto: some View {
        CachedPhotoView(
            photoReferences: place.photoReferences,
            maxWidth: 800,
            maxHeight: 400,
            contentMode: .fill,
            loadPhoto: loadPhoto
        )
        .frame(height: 250)
        .clipped()
        .transition(.opacity)
    }
}

#Preview {
    NavigationStack {
        RestaurantDetailView(
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
            onToggleFavorite: { _ in },
            loadPhoto: { _, _, _ in nil }
        )
    }
}

