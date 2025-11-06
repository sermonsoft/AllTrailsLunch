///
/// `FavoritesStore.swift`
/// AllTrailsLunch
///
/// Manages favorite restaurants with UserDefaults persistence.
///

import Foundation
import Observation

@MainActor
@Observable
class FavoritesStore {
    private(set) var favoriteIds: Set<String> = []

    private let userDefaults: UserDefaults
    private let favoritesKey = "com.alltrailslunch.favorites"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadFavorites()
    }
    
    // MARK: - Public Methods
    
    func isFavorite(_ placeId: String) -> Bool {
        favoriteIds.contains(placeId)
    }
    
    func toggleFavorite(_ placeId: String) {
        if favoriteIds.contains(placeId) {
            favoriteIds.remove(placeId)
        } else {
            favoriteIds.insert(placeId)
        }
        saveFavorites()
    }
    
    func addFavorite(_ placeId: String) {
        favoriteIds.insert(placeId)
        saveFavorites()
    }
    
    func removeFavorite(_ placeId: String) {
        favoriteIds.remove(placeId)
        saveFavorites()
    }
    
    func clearAllFavorites() {
        favoriteIds.removeAll()
        saveFavorites()
    }
    
    // MARK: - Private Methods
    
    private func loadFavorites() {
        if let data = userDefaults.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favoriteIds = decoded
        }
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteIds) {
            userDefaults.set(encoded, forKey: favoritesKey)
        }
    }
}

