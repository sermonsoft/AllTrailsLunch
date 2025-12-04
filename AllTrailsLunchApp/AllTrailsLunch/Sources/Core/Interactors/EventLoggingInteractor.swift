//
//  EventLoggingInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation

/// Protocol for event logging business logic
/// Follows Interface Segregation Principle - focused on event logging only
@MainActor
protocol EventLoggingInteractor {
    // MARK: - Event Logging
    
    /// Log an analytics event
    /// - Parameter event: The event to log
    func logEvent(_ event: LoggableEvent)
    
    /// Log a screen view event
    /// - Parameters:
    ///   - screenName: Name of the screen
    ///   - screenClass: Class name of the screen (optional)
    func logScreenView(screenName: String, screenClass: String?)
    
    /// Log a custom event with name and parameters
    /// - Parameters:
    ///   - eventName: Name of the event
    ///   - parameters: Event parameters
    func logCustomEvent(name: String, parameters: [String: Any]?)
}

