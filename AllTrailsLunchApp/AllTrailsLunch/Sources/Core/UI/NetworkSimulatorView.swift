//
//  NetworkSimulatorView.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 05/11/25.
//

import SwiftUI

// MARK: - Network Simulator View

struct NetworkSimulatorView: View {
    @State private var simulator = NetworkSimulator.shared
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Floating debug button
            if !isExpanded {
                floatingButton
            }
            
            Spacer()
            
            // Expanded debug panel
            if isExpanded {
                debugPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: isExpanded)
    }
    
    // MARK: - Floating Button
    
    private var floatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { isExpanded = true }) {
                    Image(systemName: "network")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(simulator.isSimulationEnabled && !simulator.isNetworkOnline ? Color.red : Color.blue)
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(.trailing, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.md)
            }
        }
    }
    
    // MARK: - Debug Panel
    
    private var debugPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "network")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Network Simulator")
                    .font(DesignSystem.Typography.h3)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { isExpanded = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
            .background(Color.blue)
            
            // Controls
            VStack(spacing: DesignSystem.Spacing.md) {
                // Enable/Disable Simulation
                Toggle(isOn: Binding(
                    get: { simulator.isSimulationEnabled },
                    set: { enabled in
                        if enabled {
                            simulator.enableSimulation()
                        } else {
                            simulator.disableSimulation()
                        }
                    }
                )) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                        Text("Enable Simulation")
                            .font(DesignSystem.Typography.body)
                    }
                }
                .tint(.blue)
                
                Divider()
                
                // Network On/Off Toggle
                if simulator.isSimulationEnabled {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Image(systemName: simulator.isNetworkOnline ? "wifi" : "wifi.slash")
                                .foregroundColor(simulator.isNetworkOnline ? .green : .red)
                            Text("Network Status")
                                .font(DesignSystem.Typography.body)
                        }
                        
                        Toggle(isOn: Binding(
                            get: { simulator.isNetworkOnline },
                            set: { online in
                                simulator.setNetworkOnline(online)
                            }
                        )) {
                            Text(simulator.isNetworkOnline ? "Online" : "Offline")
                                .font(DesignSystem.Typography.bodyBold)
                                .foregroundColor(simulator.isNetworkOnline ? .green : .red)
                        }
                        .tint(simulator.isNetworkOnline ? .green : .red)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    
                    // Quick Actions
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Button(action: {
                            simulator.setNetworkOnline(false)
                        }) {
                            HStack {
                                Image(systemName: "wifi.slash")
                                Text("Go Offline")
                            }
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.white)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .background(Color.red)
                            .cornerRadius(DesignSystem.CornerRadius.sm)
                        }
                        
                        Button(action: {
                            simulator.setNetworkOnline(true)
                        }) {
                            HStack {
                                Image(systemName: "wifi")
                                Text("Go Online")
                            }
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.white)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .background(Color.green)
                            .cornerRadius(DesignSystem.CornerRadius.sm)
                        }
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("How to Test Offline Mode")
                            .font(DesignSystem.Typography.captionBold)
                    }

                    Text("1. Search for restaurants while ONLINE (data gets cached)\n2. Enable simulation and go OFFLINE\n3. Pull to refresh or search again\n4. Cached data should load with orange banner\n5. Photos show placeholder if not cached")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(DesignSystem.CornerRadius.md)

                // Warning
                if simulator.isSimulationEnabled && !simulator.isNetworkOnline {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Note")
                                .font(DesignSystem.Typography.captionBold)
                        }

                        Text("Only previously loaded data and photos will be available offline. New searches require cached data from when you were online.")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
            }
            .padding()
            .background(Color.white)
        }
        .cornerRadius(DesignSystem.CornerRadius.lg, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: -4)
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        NetworkSimulatorView()
    }
}

