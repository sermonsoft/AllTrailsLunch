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
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $viewModel.searchText) { query in
                    viewModel.performSearch(query)
                }
                .padding()
                
                // View Mode Toggle
                Picker("View Mode", selection: $viewModel.viewMode) {
                    Text("List").tag(ViewMode.list)
                    Text("Map").tag(ViewMode.map)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Content
                if viewModel.isLoading && viewModel.results.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .navigationTitle("Find Lunch")
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let onSearch: (String) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search restaurants...", text: $text)
                .onChange(of: text) { _, newValue in
                    onSearch(newValue)
                }
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Restaurants Found")
                .font(.headline)
            
            Text("Try searching for a different restaurant or location")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: PlacesError
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.headline)
            
            Text(error.errorDescription ?? "An unknown error occurred")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
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

