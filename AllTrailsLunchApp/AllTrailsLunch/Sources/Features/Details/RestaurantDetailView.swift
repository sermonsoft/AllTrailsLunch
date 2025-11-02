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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(place.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let address = place.address {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { toggleFavorite() }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(isFavorite ? .red : .gray)
                        }
                    }
                    
                    // Rating and Price
                    HStack(spacing: 16) {
                        if let rating = place.rating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        if !place.priceDisplay.isEmpty {
                            Text(place.priceDisplay)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Contact Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.blue)
                        Text("Call")
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        Text("Website")
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // Hours
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hours")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open now")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Restaurant Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isFavorite = favoritesStore.isFavorite(place.id)
        }
    }
    
    private func toggleFavorite() {
        isFavorite.toggle()
        favoritesStore.toggleFavorite(place.id)
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

