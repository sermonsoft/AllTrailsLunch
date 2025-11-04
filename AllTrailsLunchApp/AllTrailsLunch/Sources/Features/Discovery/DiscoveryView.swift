///
/// `DiscoveryView.swift`
/// AllTrailsLunch
///
/// Main discovery screen with search and list/map toggle.
///

import SwiftUI

struct DiscoveryView: View {
    @Bindable var viewModel: DiscoveryViewModel
    @EnvironmentObject var favoritesStore: FavoritesStore
    @State private var photoManager: PhotoManager
    @State private var networkMonitor: NetworkMonitor

    init(
        viewModel: DiscoveryViewModel,
        photoManager: PhotoManager? = nil,
        networkMonitor: NetworkMonitor? = nil
    ) {
        self.viewModel = viewModel
        self._photoManager = State(initialValue: photoManager ?? AppConfiguration.shared.createPhotoManager())
        self._networkMonitor = State(initialValue: networkMonitor ?? AppConfiguration.shared.createNetworkMonitor())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    OfflineIndicatorView(isOffline: !networkMonitor.isConnected)
                        .animation(.easeInOut, value: networkMonitor.isConnected)

                    ZStack {
                        contentView
                        floatingToggleButton
                    }
                }
                .toolbar { logoToolbarItem }
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.white, for: .navigationBar)
                .background(DesignSystem.Colors.background)
                .photoManager(photoManager)

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
        SearchBar(text: $viewModel.searchText) { query in
            viewModel.performSearch(query)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, DesignSystem.Spacing.md)
        .padding(.bottom, DesignSystem.Spacing.sm)
        .background(Color.white)
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
                onToggleFavorite: viewModel.toggleFavorite,
                onLoadMore: { await viewModel.loadNextPage() },
                onRefresh: { await viewModel.refresh() }
            )
        case .map:
            MapResultsView(
                places: viewModel.results,
                onToggleFavorite: viewModel.toggleFavorite
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
    return DiscoveryView(
        viewModel: config.createDiscoveryViewModel(),
        photoManager: config.createPhotoManager()
    )
    .environmentObject(config.createFavoritesStore())
}

