//
//  EventLogger.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation
import os.log

// MARK: - EventLogger Protocol

/// Protocol for logging analytics events
protocol EventLogger {
    /// Log an event to analytics
    /// - Parameter event: The event to log
    func log(_ event: LoggableEvent)
    
    /// Log a screen view event
    /// - Parameters:
    ///   - screenName: Name of the screen
    ///   - screenClass: Class name of the screen (optional)
    func logScreenView(screenName: String, screenClass: String?)
    
    /// Log a custom event with name and parameters
    /// - Parameters:
    ///   - eventName: Name of the event
    ///   - parameters: Event parameters
    func logEvent(name: String, parameters: [String: Any]?)
}

// MARK: - Console Event Logger (Development)

/// Console-based event logger for development and debugging
/// Logs events to the console using OSLog
class ConsoleEventLogger: EventLogger {
    private let logger = Logger(subsystem: "com.alltrailslunch", category: "Analytics")
    private let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func log(_ event: LoggableEvent) {
        guard isEnabled else { return }
        
        let parametersString = event.parameters.isEmpty
            ? ""
            : " | Parameters: \(formatParameters(event.parameters))"
        
        logger.info("📊 [\(event.category)] \(event.eventName)\(parametersString)")
    }
    
    func logScreenView(screenName: String, screenClass: String?) {
        guard isEnabled else { return }
        
        let classInfo = screenClass.map { " (\($0))" } ?? ""
        logger.info("📱 Screen View: \(screenName)\(classInfo)")
    }
    
    func logEvent(name: String, parameters: [String: Any]?) {
        guard isEnabled else { return }
        
        let parametersString = parameters.map { formatParameters($0) } ?? "none"
        logger.info("📊 Event: \(name) | Parameters: \(parametersString)")
    }
    
    // MARK: - Helpers
    
    private func formatParameters(_ parameters: [String: Any]) -> String {
        parameters.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
    }
}

// MARK: - Firebase Event Logger (Production)

/// Firebase-based event logger for production
/// This is a placeholder - integrate with Firebase Analytics when ready
class FirebaseEventLogger: EventLogger {
    private let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func log(_ event: LoggableEvent) {
        guard isEnabled else { return }
        
        // TODO: Integrate with Firebase Analytics
        // Analytics.logEvent(event.eventName, parameters: event.parameters)
        
        // For now, fall back to console logging
        print("🔥 Firebase Event: [\(event.category)] \(event.eventName)")
    }
    
    func logScreenView(screenName: String, screenClass: String?) {
        guard isEnabled else { return }
        
        // TODO: Integrate with Firebase Analytics
        // Analytics.logEvent(AnalyticsEventScreenView, parameters: [
        //     AnalyticsParameterScreenName: screenName,
        //     AnalyticsParameterScreenClass: screenClass ?? ""
        // ])
        
        print("🔥 Firebase Screen View: \(screenName)")
    }
    
    func logEvent(name: String, parameters: [String: Any]?) {
        guard isEnabled else { return }
        
        // TODO: Integrate with Firebase Analytics
        // Analytics.logEvent(name, parameters: parameters)
        
        print("🔥 Firebase Event: \(name)")
    }
}

// MARK: - Mock Event Logger (Testing)

/// Mock event logger for unit tests
class MockEventLogger: EventLogger {
    private(set) var loggedEvents: [LoggableEvent] = []
    private(set) var screenViews: [(screenName: String, screenClass: String?)] = []
    private(set) var customEvents: [(name: String, parameters: [String: Any]?)] = []
    
    func log(_ event: LoggableEvent) {
        loggedEvents.append(event)
    }
    
    func logScreenView(screenName: String, screenClass: String?) {
        screenViews.append((screenName, screenClass))
    }
    
    func logEvent(name: String, parameters: [String: Any]?) {
        customEvents.append((name, parameters))
    }
    
    func reset() {
        loggedEvents.removeAll()
        screenViews.removeAll()
        customEvents.removeAll()
    }
}

