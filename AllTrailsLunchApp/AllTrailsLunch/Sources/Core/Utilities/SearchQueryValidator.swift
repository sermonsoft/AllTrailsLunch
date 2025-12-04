//
//  SearchQueryValidator.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 02/12/25.
//

import Foundation

/// Validates search queries to ensure they are food and restaurant-related.
///
/// This validator uses keyword matching to determine if a search query is appropriate
/// for a restaurant discovery app. It blocks searches for non-food categories like
/// cars, schools, hotels, etc., and only allows food and restaurant-related searches.
@MainActor
final class SearchQueryValidator {
    
    // MARK: - Allowed Keywords
    
    /// Food and restaurant-related keywords that are allowed
    private static let allowedKeywords: Set<String> = [
        // Food types
        "food", "restaurant", "cafe", "coffee", "bar", "pub", "bistro", "diner",
        "eatery", "grill", "kitchen", "bakery", "pizzeria", "steakhouse", "buffet",
        "cafeteria", "canteen", "deli", "delicatessen", "fast food", "takeout",
        "takeaway", "drive-through", "food truck", "street food",
        
        // Cuisine types
        "italian", "chinese", "japanese", "mexican", "thai", "indian", "french",
        "greek", "spanish", "korean", "vietnamese", "american", "mediterranean",
        "middle eastern", "asian", "european", "latin", "caribbean", "african",
        "fusion", "sushi", "ramen", "pho", "taco", "burrito", "pizza", "pasta",
        "burger", "sandwich", "salad", "soup", "noodle", "curry", "bbq", "barbecue",
        "seafood", "steak", "chicken", "vegan", "vegetarian", "halal", "kosher",
        
        // Meal types
        "breakfast", "brunch", "lunch", "dinner", "dessert", "snack", "appetizer",
        
        // Beverage
        "tea", "juice", "smoothie", "wine", "beer", "cocktail", "drink", "beverage",
        
        // Food-related terms
        "cuisine", "dining", "meal", "dish", "menu", "chef", "cook", "culinary",
        "gastro", "taste", "flavor", "organic", "farm-to-table", "local food"
    ]
    
    // MARK: - Blocked Keywords
    
    /// Non-food categories that should be blocked
    private static let blockedKeywords: Set<String> = [
        // Transportation
        "car", "auto", "vehicle", "dealership", "garage", "mechanic", "repair shop",
        "gas station", "petrol", "parking", "taxi", "uber", "lyft", "bus", "train",
        "airport", "rental car",
        
        // Education
        "school", "university", "college", "academy", "education", "library",
        "kindergarten", "preschool", "daycare", "tutor", "learning center",
        
        // Accommodation
        "hotel", "motel", "inn", "lodge", "hostel", "resort", "accommodation",
        "bed and breakfast", "airbnb", "vacation rental",
        
        // Retail (non-food)
        "clothing", "fashion", "apparel", "shoes", "electronics", "furniture",
        "hardware", "tools", "appliances", "jewelry", "cosmetics", "beauty salon",
        "hair salon", "barber", "spa", "nail salon", "boutique",
        
        // Services
        "bank", "atm", "insurance", "lawyer", "attorney", "dentist", "doctor",
        "hospital", "clinic", "pharmacy", "gym", "fitness", "yoga", "massage",
        "real estate", "office", "coworking",
        
        // Entertainment (non-food)
        "movie", "cinema", "theater", "museum", "gallery", "park", "playground",
        "zoo", "aquarium", "casino", "nightclub", "concert", "stadium",
        
        // Other
        "church", "temple", "mosque", "synagogue", "religious", "government",
        "post office", "police", "fire station", "laundromat", "dry cleaning"
    ]
    
    // MARK: - Validation
    
    /// Validates if a search query is food/restaurant-related.
    ///
    /// - Parameter query: The search query to validate
    /// - Returns: A validation result indicating if the query is valid and a message if invalid
    static func validate(_ query: String) -> ValidationResult {
        // Empty queries are allowed (will trigger nearby search)
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .valid
        }
        
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if query contains any blocked keywords
        for blockedKeyword in blockedKeywords {
            if normalizedQuery.contains(blockedKeyword) {
                return .invalid(reason: "This app is for discovering restaurants and food. Please search for food-related items only.")
            }
        }
        
        // If query contains allowed keywords, it's valid
        for allowedKeyword in allowedKeywords {
            if normalizedQuery.contains(allowedKeyword) {
                return .valid
            }
        }
        
        // If query doesn't contain blocked keywords but also doesn't contain allowed keywords,
        // we'll be permissive and allow it (could be a restaurant name or specific dish)
        // This prevents false positives while still blocking obvious non-food searches
        return .valid
    }
    
    // MARK: - Validation Result
    
    enum ValidationResult {
        case valid
        case invalid(reason: String)
        
        var isValid: Bool {
            if case .valid = self {
                return true
            }
            return false
        }
        
        var errorMessage: String? {
            if case .invalid(let reason) = self {
                return reason
            }
            return nil
        }
    }
}
