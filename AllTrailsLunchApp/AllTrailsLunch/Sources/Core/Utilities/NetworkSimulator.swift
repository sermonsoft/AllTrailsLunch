//
//  NetworkSimulator.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation
import Observation

// MARK: - Network Simulator

/// Simulates network conditions for testing purposes.
/// Allows toggling network on/off to test offline mode behavior.
@MainActor
@Observable
class NetworkSimulator {
    
    // MARK: - Properties
    
    /// Whether network simulation is enabled
    private(set) var isSimulationEnabled: Bool = false
    
    /// Whether simulated network is "online"
    private(set) var isNetworkOnline: Bool = true
    
    /// Singleton instance for global access
    static let shared = NetworkSimulator()
    
    // MARK: - Initialization
    
    private init() {
        #if DEV
        // Only enable in development builds
        print("🔧 NetworkSimulator: Available for testing")
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Enable network simulation
    func enableSimulation() {
        isSimulationEnabled = true
        print("🔧 NetworkSimulator: Simulation enabled")
    }
    
    /// Disable network simulation
    func disableSimulation() {
        isSimulationEnabled = false
        isNetworkOnline = true
        print("🔧 NetworkSimulator: Simulation disabled")
    }
    
    /// Toggle simulated network on/off
    func toggleNetwork() {
        guard isSimulationEnabled else {
            print("⚠️ NetworkSimulator: Simulation not enabled")
            return
        }
        
        isNetworkOnline.toggle()
        print("🔧 NetworkSimulator: Network \(isNetworkOnline ? "ONLINE" : "OFFLINE")")
    }
    
    /// Set simulated network state
    func setNetworkOnline(_ online: Bool) {
        guard isSimulationEnabled else { return }
        isNetworkOnline = online
        print("🔧 NetworkSimulator: Network set to \(online ? "ONLINE" : "OFFLINE")")
    }
    
    /// Check if network request should be blocked
    func shouldBlockRequest() -> Bool {
        return isSimulationEnabled && !isNetworkOnline
    }
}

// MARK: - Simulated Network Error

enum NetworkSimulationError: Error, LocalizedError {
    case simulatedOffline
    
    var errorDescription: String? {
        switch self {
        case .simulatedOffline:
            return "Network is simulated as offline for testing"
        }
    }
}

// MARK: - URLSession Extension for Simulation

extension URLSession {
    
    /// Execute a request with network simulation support
    @MainActor
    func simulatedData(for request: URLRequest) async throws -> (Data, URLResponse) {
        // Check if request should be blocked
        if NetworkSimulator.shared.shouldBlockRequest() {
            print("🚫 NetworkSimulator: Blocking request to \(request.url?.absoluteString ?? "unknown")")
            throw NetworkSimulationError.simulatedOffline
        }
        
        // Execute normally
        return try await data(for: request)
    }
    
    /// Execute a request with network simulation support (URL variant)
    @MainActor
    func simulatedData(from url: URL) async throws -> (Data, URLResponse) {
        // Check if request should be blocked
        if NetworkSimulator.shared.shouldBlockRequest() {
            print("🚫 NetworkSimulator: Blocking request to \(url.absoluteString)")
            throw NetworkSimulationError.simulatedOffline
        }
        
        // Execute normally
        return try await data(from: url)
    }
}

