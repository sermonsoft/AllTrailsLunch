//
//  SaveSearchSheet.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 06/11/25.
//

import SwiftUI

struct SaveSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchName: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    let query: String
    let location: (latitude: Double, longitude: Double)?
    let filters: SearchFilters
    @Bindable var savedSearchManager: SavedSearchManager
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Search Name", text: $searchName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Name")
                } footer: {
                    Text("Give this search a memorable name")
                }
                
                Section {
                    if !query.isEmpty {
                        LabeledContent("Query", value: query)
                    } else {
                        LabeledContent("Query", value: "Nearby Restaurants")
                    }
                    
                    if let location = location {
                        LabeledContent("Location") {
                            Text(String(format: "%.4f, %.4f", location.latitude, location.longitude))
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Search Details")
                }
                
                if filters.hasActiveFilters {
                    Section {
                        if let minRating = filters.minRating {
                            LabeledContent("Minimum Rating") {
                                Text(String(format: "%.1f+ stars", minRating))
                            }
                        }
                        
                        if let maxPriceLevel = filters.maxPriceLevel {
                            LabeledContent("Maximum Price") {
                                Text(String(repeating: "$", count: maxPriceLevel))
                            }
                        }
                        
                        if filters.openNow {
                            LabeledContent("Open Now") {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        
                        if let maxDistance = filters.maxDistance {
                            LabeledContent("Maximum Distance") {
                                if maxDistance < 1000 {
                                    Text("\(maxDistance)m")
                                } else {
                                    let km = Double(maxDistance) / 1000.0
                                    Text(String(format: "%.1fkm", km))
                                }
                            }
                        }
                    } header: {
                        Text("Active Filters")
                    }
                }
            }
            .navigationTitle("Save Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveSearch()
                    }
                    .fontWeight(.semibold)
                    .disabled(searchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    @MainActor
    private func saveSearch() {
        let trimmedName = searchName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a name for this search"
            showError = true
            return
        }
        
        // Check for duplicate
        if let duplicate = savedSearchManager.findDuplicateSearch(
            query: query,
            latitude: location?.latitude,
            longitude: location?.longitude,
            filters: filters
        ) {
            errorMessage = "A search with these parameters already exists: \"\(duplicate.displayName)\""
            showError = true
            return
        }

        // Create and save the search
        let savedSearch = SavedSearch(
            name: trimmedName,
            query: query,
            location: location,
            filters: filters
        )

        do {
            try savedSearchManager.saveSearch(savedSearch)
            onSave()
            dismiss()
        } catch {
            errorMessage = "Failed to save search: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    let service = SavedSearchService(modelContext: SwiftDataStorageManager.shared.mainContext)
    let manager = SavedSearchManager(service: service)
    return SaveSearchSheet(
        query: "Pizza",
        location: (latitude: 37.7749, longitude: -122.4194),
        filters: .highlyRated,
        savedSearchManager: manager,
        onSave: {}
    )
}

