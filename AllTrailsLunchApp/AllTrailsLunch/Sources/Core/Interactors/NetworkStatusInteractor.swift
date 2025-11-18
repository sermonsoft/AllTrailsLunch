//
//  NetworkStatusInteractor.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 03/11/25.
//

import Foundation

/// Protocol for network status business logic
/// Follows Interface Segregation Principle - focused on network status only
@MainActor
protocol NetworkStatusInteractor {
    // MARK: - Network Status
    
    /// Check if device is connected to network
    /// - Returns: True if connected, false otherwise
    func isNetworkConnected() -> Bool
    
    /// Get the current connection type
    /// - Returns: Connection type (wifi, cellular, ethernet, unknown)
    func getConnectionType() -> NetworkMonitor.ConnectionType
}

