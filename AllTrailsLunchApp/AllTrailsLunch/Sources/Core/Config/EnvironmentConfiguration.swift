//
//  EnvironmentConfiguration.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 18/11/25.
//

import Foundation

// MARK: - Build Environment

enum BuildEnvironment {
    case mock
    case development
    case staging
    case production
    case store

    /// Google Places API base URL
    var placesBaseURL: String {
        switch self {
        case .mock:
            return "https://mock.places.api.com" // Not used - mock uses local JSON
        case .development:
            return "https://maps.googleapis.com/maps/api/place"
        case .staging:
            return "https://maps.googleapis.com/maps/api/place"
        case .production, .store:
            return "https://maps.googleapis.com/maps/api/place"
        }
    }

    /// API timeout interval
    var timeout: TimeInterval {
        switch self {
        case .mock:
            return 5.0 // Short timeout for mock
        case .development:
            return 30.0
        case .staging:
            return 30.0
        case .production, .store:
            return 30.0
        }
    }

    /// Whether to use mock data
    var useMockData: Bool {
        return self == .mock
    }

    /// Environment display name for debugging
    var displayName: String {
        switch self {
        case .mock:
            return "Mock (Local JSON)"
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        case .store:
            return "Store (Production)"
        }
    }
}

// MARK: - Environment Configuration

/// Responsible for detecting build environment and loading configuration values.
/// Single Responsibility: Environment detection and configuration loading.
final class EnvironmentConfiguration {
    static let shared = EnvironmentConfiguration()

    // MARK: - Properties

    let environment: BuildEnvironment
    let googlePlacesAPIKey: String
    let timeout: TimeInterval

    // MARK: - Initialization

    private init() {
        self.environment = Self.detectEnvironment()
        self.googlePlacesAPIKey = Self.loadAPIKey()
        self.timeout = environment.timeout

        // Log active configuration
        Self.logConfiguration(environment: environment)
    }

    // MARK: - Environment Detection

    private static func detectEnvironment() -> BuildEnvironment {
        // 1) Allow runtime override via environment variables (for UI tests)
        let env = ProcessInfo.processInfo.environment
        if let override = (env["ENV"] ?? env["CONFIG"])?.uppercased() {
            switch override {
            case "MOCK":
                return .mock
            case "DEV", "DEVELOPMENT":
                return .development
            case "STAGING":
                return .staging
            case "PROD", "PRODUCTION":
                return .production
            case "STORE":
                return .store
            default:
                break
            }
        }

        // 2) Allow override via launch arguments
        let args = ProcessInfo.processInfo.arguments.map { $0.uppercased() }
        if args.contains("MOCK") {
            return .mock
        }
        if args.contains("DEV") || args.contains("DEVELOPMENT") {
            return .development
        }
        if args.contains("STAGING") {
            return .staging
        }
        if args.contains("PROD") || args.contains("PRODUCTION") {
            return .production
        }
        if args.contains("STORE") {
            return .store
        }

        // 3) Use compilation flags
        #if MOCK
        return .mock
        #elseif DEV
        return .development
        #elseif STAGING
        return .staging
        #elseif STORE
        return .store
        #elseif PRD
        return .production
        #else
        // Default to development if no flag is set
        return .development
        #endif
    }

    // MARK: - API Key Loading

    private static func loadAPIKey() -> String {
        // 1. Try environment variable first (for CI/CD and testing)
        if let key = ProcessInfo.processInfo.environment["GOOGLE_PLACES_API_KEY"] {
            return key
        }

        // 2. Try Info.plist (loaded from xcconfig at build time)
        if let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY") as? String,
           !key.isEmpty,
           key != "$(GOOGLE_PLACES_API_KEY)" { // Ensure it's not the placeholder
            return key
        }

        // 3. Fail fast in production - don't use hardcoded keys
        #if DEBUG
        // Only allow fallback in debug builds for development convenience
        print("⚠️ WARNING: Using hardcoded API key. Configure Secrets.xcconfig for production.")
        return "AIzaSyAvAaPcSL1SNPUguENa_p2P-SuRaxGUduw"
        #else
        fatalError("❌ GOOGLE_PLACES_API_KEY not configured. Please set up Config/Secrets.xcconfig")
        #endif
    }

    // MARK: - Logging

    private static func logConfiguration(environment: BuildEnvironment) {
        print("🔧 EnvironmentConfiguration: Environment = \(environment.displayName)")
        print("🔧 EnvironmentConfiguration: Use Mock Data = \(environment.useMockData)")
        print("🔧 EnvironmentConfiguration: Timeout = \(environment.timeout)s")
        if !environment.useMockData {
            print("🔧 EnvironmentConfiguration: Places API Base URL = \(environment.placesBaseURL)")
        }
    }
}

