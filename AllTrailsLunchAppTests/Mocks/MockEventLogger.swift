//
//  MockEventLogger.swift
//  AllTrailsLunchAppTests
//
//  Created by Tri Le on 03/11/25.
//

import Foundation
@testable import AllTrailsLunchApp

final class MockEventLogger: EventLogger {

    // MARK: - Call Tracking

    var loggedEvents: [LoggableEvent] = []
    var logCallCount = 0
    var screenViews: [(screenName: String, screenClass: String?)] = []
    var customEvents: [(name: String, parameters: [String: Any]?)] = []

    // MARK: - EventLogger Protocol

    func log(_ event: LoggableEvent) {
        logCallCount += 1
        loggedEvents.append(event)
    }

    func logScreenView(screenName: String, screenClass: String?) {
        screenViews.append((screenName, screenClass))
    }

    func logEvent(name: String, parameters: [String: Any]?) {
        customEvents.append((name, parameters))
    }

    // MARK: - Test Helpers

    func reset() {
        loggedEvents.removeAll()
        logCallCount = 0
        screenViews.removeAll()
        customEvents.removeAll()
    }

    func didLog(eventName: String) -> Bool {
        loggedEvents.contains { $0.eventName == eventName }
    }

    func eventCount(for eventName: String) -> Int {
        loggedEvents.filter { $0.eventName == eventName }.count
    }

    func lastEvent(named eventName: String) -> LoggableEvent? {
        loggedEvents.last { $0.eventName == eventName }
    }

    func parameters(for eventName: String) -> [String: Any]? {
        lastEvent(named: eventName)?.parameters
    }
}

