///
/// `OfflineIndicatorView.swift`
/// AllTrailsLunch
///
/// Banner that shows when the device is offline.
///

import SwiftUI

// MARK: - Offline Indicator View

struct OfflineIndicatorView: View {
    let isOffline: Bool
    
    var body: some View {
        if isOffline {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: DesignSystem.IconSize.sm))
                    .foregroundColor(.white)
                
                Text("You're offline. Showing cached results.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.white)
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(Color.orange)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        OfflineIndicatorView(isOffline: true)
        Spacer()
    }
}

