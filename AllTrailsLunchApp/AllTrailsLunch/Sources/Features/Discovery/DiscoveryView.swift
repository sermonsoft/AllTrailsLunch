///
/// `DiscoveryView.swift`
/// AllTrailsLunch
///
/// Main discovery screen with search and list/map toggle.
///

import SwiftUI

struct DiscoveryView: View {
    @ObservedObject var viewModel: DiscoveryViewModel
    @EnvironmentObject var favoritesStore: FavoritesStore

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(text: $viewModel.searchText) { query in
                        viewModel.performSearch(query)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.sm)

                    // Content
                    if viewModel.isLoading && viewModel.results.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(DesignSystem.Colors.background)
                    } else if let error = viewModel.error {
                        ErrorView(error: error)
                    } else if viewModel.results.isEmpty {
                        EmptyStateView()
                    } else {
                        switch viewModel.viewMode {
                        case .list:
                            ListResultsView(
                                places: viewModel.results,
                                isLoading: viewModel.isLoading,
                                onToggleFavorite: viewModel.toggleFavorite,
                                onLoadMore: { await viewModel.loadNextPage() }
                            )
                        case .map:
                            MapResultsView(places: viewModel.results)
                    }
                    }
                }

                // Floating Toggle Button
                if !viewModel.results.isEmpty {
                    VStack {
                        Spacer()
                        ViewModeToggleButton(viewMode: $viewModel.viewMode)
                            .padding(.bottom, DesignSystem.Spacing.xl)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("logo-lockup", bundle: nil)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(DesignSystem.Colors.background)
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let onSearch: (String) -> Void

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: DesignSystem.IconSize.md))
                .foregroundColor(DesignSystem.Colors.textSecondary)

            TextField("Search restaurants", text: $text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .onChange(of: text) { _, newValue in
                    onSearch(newValue)
                }

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: DesignSystem.IconSize.md))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .searchBarStyle()
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.textTertiary)

            Text("No Restaurants Found")
                .font(DesignSystem.Typography.h2)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Text("Try searching for a different restaurant or location")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: PlacesError

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.error)

            Text("Oops!")
                .font(DesignSystem.Typography.h2)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Text(error.errorDescription ?? "An unknown error occurred")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xxl)

            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xxl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - View Mode Toggle Button

struct ViewModeToggleButton: View {
    @Binding var viewMode: ViewMode

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewMode = viewMode == .list ? .map : .list
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(viewMode == .list ? "map" : "list", bundle: nil)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)

                Text(viewMode == .list ? "Map" : "List")
                    .font(DesignSystem.Typography.h3)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.primary)
            .cornerRadius(24)
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DiscoveryView(viewModel: DiscoveryViewModel(
        repository: RestaurantRepository(
            placesClient: PlacesClient(apiKey: "test"),
            favoritesStore: FavoritesStore()
        ),
        locationManager: LocationManager(),
        favoritesStore: FavoritesStore()
    ))
    .environmentObject(FavoritesStore())
}

