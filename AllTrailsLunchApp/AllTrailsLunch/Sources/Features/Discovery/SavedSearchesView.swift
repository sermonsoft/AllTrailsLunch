//
//  SavedSearchesView.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 06/11/25.
//

import SwiftUI

struct SavedSearchesView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var savedSearchManager: SavedSearchManager
    @State private var searchQuery: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    let onSelectSearch: (SavedSearch) -> Void

    init(
        savedSearchManager: SavedSearchManager,
        onSelectSearch: @escaping (SavedSearch) -> Void
    ) {
        self.savedSearchManager = savedSearchManager
        self.onSelectSearch = onSelectSearch
    }

    // Computed property to get saved searches from manager
    private var savedSearches: [SavedSearch] {
        if searchQuery.isEmpty {
            return savedSearchManager.getAllSavedSearches()
        } else {
            return savedSearchManager.searchSavedSearches(query: searchQuery)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if savedSearches.isEmpty {
                    emptyStateView
                } else {
                    searchList
                }
            }
            .navigationTitle("Saved Searches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if !savedSearches.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button(role: .destructive) {
                            clearAllSearches()
                        } label: {
                            Text("Clear All")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .task {
                // Manager already has the searches loaded
                // No need to load them again
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 64))
                .foregroundStyle(.gray.opacity(0.5))
            
            Text("No Saved Searches")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Save your favorite searches for quick access later")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
    
    // MARK: - Search List
    
    private var searchList: some View {
        List {
            ForEach(filteredSearches) { search in
                SavedSearchRow(search: search)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectSearch(search)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteSearch(search)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchQuery, prompt: "Search saved searches")
    }
    
    private var filteredSearches: [SavedSearch] {
        if searchQuery.isEmpty {
            return savedSearches
        } else {
            return savedSearches.filter { search in
                search.name.localizedCaseInsensitiveContains(searchQuery) ||
                search.query.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }
    
    // MARK: - Actions

    private func selectSearch(_ search: SavedSearch) {
        // Update last used date
        do {
            try savedSearchManager.updateSearch(search)
        } catch {
            print("Failed to update search: \(error)")
        }

        onSelectSearch(search)
        dismiss()
    }

    private func deleteSearch(_ search: SavedSearch) {
        do {
            try savedSearchManager.deleteSearch(search)
        } catch {
            errorMessage = "Failed to delete search: \(error.localizedDescription)"
            showError = true
        }
    }

    private func clearAllSearches() {
        do {
            try savedSearchManager.clearAllSavedSearches()
        } catch {
            errorMessage = "Failed to clear searches: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Saved Search Row

struct SavedSearchRow: View {
    let search: SavedSearch
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DesignSystem.Colors.primary)
                
                Text(search.displayName)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !search.filterSummary.isEmpty && search.filterSummary != "No filters" {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(search.filterSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text("Last used: \(search.lastUsedAt, style: .relative) ago")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

#Preview {
    let service = SavedSearchService(modelContext: SwiftDataStorageManager.shared.mainContext)
    let manager = SavedSearchManager(service: service)
    return SavedSearchesView(savedSearchManager: manager) { _ in }
}

