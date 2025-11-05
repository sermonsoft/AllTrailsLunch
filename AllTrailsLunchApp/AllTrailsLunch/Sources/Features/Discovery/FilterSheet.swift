///
/// `FilterSheet.swift`
/// AllTrailsLunch
///
/// Filter sheet for restaurant search.
///

import SwiftUI

struct FilterSheet: View {
    @Binding var filters: SearchFilters
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempFilters: SearchFilters
    
    init(filters: Binding<SearchFilters>) {
        self._filters = filters
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Rating Filter
                Section {
                    Toggle("Minimum Rating", isOn: Binding(
                        get: { tempFilters.minRating != nil },
                        set: { enabled in
                            tempFilters.minRating = enabled ? 4.0 : nil
                        }
                    ))
                    
                    if tempFilters.minRating != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Rating:")
                                Spacer()
                                Text(String(format: "%.1f+", tempFilters.minRating ?? 0))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { tempFilters.minRating ?? 3.0 },
                                    set: { tempFilters.minRating = $0 }
                                ),
                                in: 3.0...5.0,
                                step: 0.5
                            )
                        }
                    }
                } header: {
                    Text("Rating")
                } footer: {
                    if tempFilters.minRating != nil {
                        Text("Show restaurants with \(String(format: "%.1f", tempFilters.minRating ?? 0)) stars or higher")
                    }
                }
                
                // Price Level Filter
                Section {
                    Toggle("Maximum Price", isOn: Binding(
                        get: { tempFilters.maxPriceLevel != nil },
                        set: { enabled in
                            tempFilters.maxPriceLevel = enabled ? 2 : nil
                        }
                    ))
                    
                    if tempFilters.maxPriceLevel != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Price:")
                                Spacer()
                                Text(priceDisplay(tempFilters.maxPriceLevel ?? 1))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Picker("Price Level", selection: Binding(
                                get: { tempFilters.maxPriceLevel ?? 2 },
                                set: { tempFilters.maxPriceLevel = $0 }
                            )) {
                                Text("$").tag(1)
                                Text("$$").tag(2)
                                Text("$$$").tag(3)
                                Text("$$$$").tag(4)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                } header: {
                    Text("Price")
                } footer: {
                    if tempFilters.maxPriceLevel != nil {
                        Text("Show restaurants up to \(priceDisplay(tempFilters.maxPriceLevel ?? 1))")
                    }
                }
                
                // Open Now Filter
                Section {
                    Toggle("Open Now", isOn: $tempFilters.openNow)
                } footer: {
                    Text("Show only restaurants that are currently open")
                }
                
                // Distance Filter
                Section {
                    Toggle("Maximum Distance", isOn: Binding(
                        get: { tempFilters.maxDistance != nil },
                        set: { enabled in
                            tempFilters.maxDistance = enabled ? 1000 : nil
                        }
                    ))
                    
                    if tempFilters.maxDistance != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Distance:")
                                Spacer()
                                Text(distanceDisplay(tempFilters.maxDistance ?? 1000))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { Double(tempFilters.maxDistance ?? 1000) },
                                    set: { tempFilters.maxDistance = Int($0) }
                                ),
                                in: 500...5000,
                                step: 500
                            )
                        }
                    }
                } header: {
                    Text("Distance")
                } footer: {
                    if tempFilters.maxDistance != nil {
                        Text("Show restaurants within \(distanceDisplay(tempFilters.maxDistance ?? 1000))")
                    }
                }
                
                // Presets
                Section {
                    Button {
                        tempFilters = .highlyRated
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Highly Rated (4+ stars)")
                            Spacer()
                        }
                    }
                    
                    Button {
                        tempFilters = .budgetFriendly
                    } label: {
                        HStack {
                            Image(systemName: "dollarsign.circle")
                            Text("Budget Friendly ($ - $$)")
                            Spacer()
                        }
                    }
                    
                    Button {
                        tempFilters = .nearby
                    } label: {
                        HStack {
                            Image(systemName: "location.circle")
                            Text("Nearby (within 1km)")
                            Spacer()
                        }
                    }
                    
                    Button {
                        tempFilters = .premium
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("Premium (4+ stars, $$$+)")
                            Spacer()
                        }
                    }
                } header: {
                    Text("Quick Filters")
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Apply") {
                        filters = tempFilters
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button("Clear All") {
                        tempFilters.clear()
                    }
                    .disabled(!tempFilters.hasActiveFilters)
                }
            }
        }
    }
    
    private func priceDisplay(_ level: Int) -> String {
        String(repeating: "$", count: level)
    }
    
    private func distanceDisplay(_ meters: Int) -> String {
        if meters < 1000 {
            return "\(meters)m"
        } else {
            let km = Double(meters) / 1000.0
            return String(format: "%.1fkm", km)
        }
    }
}

#Preview {
    FilterSheet(filters: .constant(.default))
}

