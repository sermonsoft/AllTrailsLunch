//
//  DiscoveryView.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 06/11/25.
//

import SwiftUI

/// Main discovery screen for browsing and searching restaurants.
///
/// Features:
/// - Location-based restaurant search
/// - Text search with filters
/// - List and map view modes
/// - Bookmark/favorite functionality
/// - Saved searches
/// - Offline indicator
struct DiscoveryView: View {
    @Bindable var viewModel: DiscoveryViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    OfflineIndicatorView(
                        isOffline: !viewModel.networkMonitor.isConnected,
                        isShowingCachedData: viewModel.isShowingCachedData
                    )
                    .animation(.easeInOut, value: viewModel.networkMonitor.isConnected)
                    .animation(.easeInOut, value: viewModel.isShowingCachedData)

                    ZStack {
                        contentView
                        floatingToggleButton
                    }
                }
                .toolbar {
                    logoToolbarItem
                    savedSearchesToolbarItem
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.white, for: .navigationBar)
                .background(DesignSystem.Colors.background)
                .sheet(isPresented: $viewModel.showSavedSearchesSheet) {
                    SavedSearchesView(savedSearchService: viewModel.savedSearchService) { savedSearch in
                        Task {
                            await viewModel.loadSavedSearch(savedSearch)
                        }
                    }
                }
                .sheet(isPresented: $viewModel.showSaveSearchSheet) {
                    SaveSearchSheet(
                        query: viewModel.searchText,
                        location: viewModel.userLocation.map { (latitude: $0.latitude, longitude: $0.longitude) },
                        filters: viewModel.filters,
                        savedSearchService: viewModel.savedSearchService,
                        onSave: {}
                    )
                }

                // Network Simulator (Development only)
                #if DEV
                NetworkSimulatorView()
                #endif
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack(spacing: 0) {
            searchBar
            mainContent
        }
    }

    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            SearchBar(text: $viewModel.searchText) { query in
                viewModel.performSearch(query)
            }

            // Filter button
            Button {
                viewModel.showFilterSheet = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundStyle(viewModel.filters.hasActiveFilters ? DesignSystem.Colors.primary : .gray)

                    // Badge for active filter count
                    if viewModel.filters.hasActiveFilters {
                        Circle()
                            .fill(DesignSystem.Colors.primary)
                            .frame(width: 16, height: 16)
                            .overlay {
                                Text("\(viewModel.filters.activeFilterCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                            .offset(x: 6, y: -6)
                    }
                }
            }
            .padding(.trailing, DesignSystem.Spacing.sm)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, DesignSystem.Spacing.md)
        .padding(.bottom, DesignSystem.Spacing.sm)
        .background(Color.white)
        .sheet(isPresented: $viewModel.showFilterSheet) {
            FilterSheet(filters: Binding(
                get: { viewModel.filters },
                set: { viewModel.applyFilters($0) }
            ))
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading && viewModel.results.isEmpty {
            loadingView
        } else if let error = viewModel.error {
            ErrorView(error: error)
        } else if viewModel.results.isEmpty {
            EmptyStateView()
        } else {
            resultsView
        }
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.Colors.background)
    }

    @ViewBuilder
    private var resultsView: some View {
        switch viewModel.viewMode {
        case .list:
            ListResultsView(
                places: viewModel.results,
                isLoading: viewModel.isLoading,
                favoriteIds: viewModel.favoriteIds,
                onToggleFavorite: viewModel.toggleFavorite,
                onLoadMore: { await viewModel.loadNextPage() },
                onRefresh: { await viewModel.refresh() },
                loadPhoto: viewModel.loadPhoto
            )
        case .map:
            MapResultsView(
                places: viewModel.results,
                favoriteIds: viewModel.favoriteIds,
                onToggleFavorite: viewModel.toggleFavorite,
                isSearchActive: !viewModel.searchText.isEmpty,
                loadPhoto: viewModel.loadPhoto
            )
        }
    }

    @ViewBuilder
    private var floatingToggleButton: some View {
        if !viewModel.results.isEmpty {
            VStack {
                Spacer()
                ViewModeToggleButton(viewMode: $viewModel.viewMode)
                    .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
    }

    private var logoToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Image("logo-lockup", bundle: nil)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 24)
        }
    }

    @ToolbarContentBuilder
    private var savedSearchesToolbarItem: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            // Save current search button
            Button {
                viewModel.showSaveSearchSheet = true
            } label: {
                Image(systemName: "bookmark.circle")
                    .font(.title3)
            }

            // View saved searches button
            Button {
                viewModel.showSavedSearchesSheet = true
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3)
            }
        }
    }
}

// MARK: - Search Bar Component

struct SearchBar: View {
    @Binding var text: String
    let onSearch: (String) -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            searchIcon
            searchTextField
            clearButton
        }
        .searchBarStyle()
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(isFocused ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    private var searchIcon: some View {
        Image(systemName: "magnifyingglass")
            .font(.system(size: DesignSystem.IconSize.md))
            .foregroundColor(isFocused ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFocused)
    }

    private var searchTextField: some View {
        TextField("Search restaurants", text: $text)
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .focused($isFocused)
            .onChange(of: text) { _, newValue in
                onSearch(newValue)
            }
    }

    @ViewBuilder
    private var clearButton: some View {
        if !text.isEmpty {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    text = ""
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: DesignSystem.IconSize.md))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Empty State Component

struct EmptyStateView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            emptyIcon
            titleText
            messageText
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
        .opacity(isAnimating ? 1.0 : 0.0)
        .offset(y: isAnimating ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }

    private var emptyIcon: some View {
        Image(systemName: "fork.knife.circle")
            .font(.system(size: 64))
            .foregroundColor(DesignSystem.Colors.textTertiary)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: isAnimating)
    }

    private var titleText: some View {
        Text("No Restaurants Found")
            .font(DesignSystem.Typography.h2)
            .foregroundColor(DesignSystem.Colors.textPrimary)
    }

    private var messageText: some View {
        Text("Try searching for a different restaurant or location")
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, DesignSystem.Spacing.xxl)
    }
}

// MARK: - Error View Component

struct ErrorView: View {
    let error: PlacesError
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            errorIcon
            titleText
            errorMessage
            recoverySuggestion
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
        .opacity(isAnimating ? 1.0 : 0.0)
        .offset(y: isAnimating ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }

    private var errorIcon: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 64))
            .foregroundColor(DesignSystem.Colors.error)
            .rotationEffect(.degrees(isAnimating ? 0 : -10))
            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: isAnimating)
    }

    private var titleText: some View {
        Text("Oops!")
            .font(DesignSystem.Typography.h2)
            .foregroundColor(DesignSystem.Colors.textPrimary)
    }

    private var errorMessage: some View {
        Text(error.errorDescription ?? "An unknown error occurred")
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, DesignSystem.Spacing.xxl)
    }

    @ViewBuilder
    private var recoverySuggestion: some View {
        if let suggestion = error.recoverySuggestion {
            Text(suggestion)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xxl)
        }
    }
}

// MARK: - View Mode Toggle Button Component

struct ViewModeToggleButton: View {
    @Binding var viewMode: ViewMode

    var body: some View {
        Button(action: toggleViewMode) {
            buttonContent
        }
        .buttonStyle(.plain)
    }

    private var buttonContent: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            toggleIcon
            toggleLabel
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.primary)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    private var toggleIcon: some View {
        Image(viewMode == .list ? "map" : "list", bundle: nil)
            .resizable()
            .renderingMode(.template)
            .frame(width: 20, height: 20)
            .foregroundColor(.white)
    }

    private var toggleLabel: some View {
        Text(viewMode == .list ? "Map" : "List")
            .font(DesignSystem.Typography.h3)
            .foregroundColor(.white)
    }

    private func toggleViewMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            viewMode = viewMode == .list ? .map : .list
        }
    }
}

#Preview {
    let config = AppConfiguration.shared
    let container = config.createDependencyContainer()

    DiscoveryView(viewModel: config.createDiscoveryViewModel())
        .dependencyContainer(container)
}

