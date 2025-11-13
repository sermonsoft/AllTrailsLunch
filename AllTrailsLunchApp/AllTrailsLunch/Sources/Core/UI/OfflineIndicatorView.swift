//
//  OfflineIndicatorView.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 05/11/25.
//

import SwiftUI

// MARK: - Offline Indicator View

struct OfflineIndicatorView: View {
    let isOffline: Bool
    let isShowingCachedData: Bool

    var body: some View {
        if isOffline || isShowingCachedData {
            VStack(spacing: 0) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: isShowingCachedData ? "arrow.clockwise.circle.fill" : "wifi.slash")
                        .font(.system(size: DesignSystem.IconSize.sm))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isShowingCachedData ? "Showing cached data" : "You're offline")
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundColor(.white)

                        #if DEV
                        if NetworkSimulator.shared.isSimulationEnabled {
                            Text("Network simulation active")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.9))
                        } else if isShowingCachedData {
                            Text("Data loaded from offline cache")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.9))
                        } else {
                            Text("Showing cached results")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        #else
                        if isShowingCachedData {
                            Text("Data loaded from offline cache")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.9))
                        } else {
                            Text("Showing cached results")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        #endif
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.sm)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(Color.orange)
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Preview

#Preview("Offline") {
    VStack(spacing: 0) {
        OfflineIndicatorView(isOffline: true, isShowingCachedData: false)
        Spacer()
    }
}

#Preview("Cached Data") {
    VStack(spacing: 0) {
        OfflineIndicatorView(isOffline: false, isShowingCachedData: true)
        Spacer()
    }
}

