//
//  LoggableEvent.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation

/// Protocol for events that can be logged to analytics
protocol LoggableEvent {
    /// Event name for analytics (e.g., "screen_view", "button_tap")
    var eventName: String { get }
    
    /// Event parameters as key-value pairs
    var parameters: [String: Any] { get }
    
    /// Event category for grouping (e.g., "discovery", "favorites", "detail")
    var category: String { get }
}

// MARK: - Default Implementation

extension LoggableEvent {
    /// Default parameters - can be overridden
    var parameters: [String: Any] {
        return [:]
    }
}

// MARK: - Common Event Categories

enum EventCategory {
    static let discovery = "discovery"
    static let favorites = "favorites"
    static let detail = "detail"
    static let search = "search"
    static let location = "location"
    static let navigation = "navigation"
}

