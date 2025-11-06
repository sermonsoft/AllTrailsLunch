//
//  UserDefaultsFavoritesService.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 01/11/25.
//

import Foundation

/// UserDefaults-based implementation of FavoritesService.
/// This is the production implementation for favorites persistence.
class UserDefaultsFavoritesService: FavoritesService {
    private let userDefaults: UserDefaults
    private let favoritesKey = "com.alltrailslunch.favorites"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - FavoritesService
    
    func getFavoriteIds() -> Set<String> {
        guard let data = userDefaults.data(forKey: favoritesKey),
              let ids = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return []
        }
        return ids
    }
    
    func saveFavoriteIds(_ ids: Set<String>) throws {
        let data = try JSONEncoder().encode(ids)
        userDefaults.set(data, forKey: favoritesKey)
    }
    
    func isFavorite(_ placeId: String) -> Bool {
        getFavoriteIds().contains(placeId)
    }
    
    func addFavorite(_ placeId: String) throws {
        var ids = getFavoriteIds()
        ids.insert(placeId)
        try saveFavoriteIds(ids)
    }
    
    func removeFavorite(_ placeId: String) throws {
        var ids = getFavoriteIds()
        ids.remove(placeId)
        try saveFavoriteIds(ids)
    }
    
    func clearAllFavorites() throws {
        try saveFavoriteIds([])
    }
}

