//
//  ShimmerView.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 05/11/25.
//

import SwiftUI

// MARK: - Shimmer View

struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.1),
                            Color.gray.opacity(0.3)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .mask(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: phase - 0.3),
                                    .init(color: .white, location: phase),
                                    .init(color: .clear, location: phase + 0.3)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1.3
                    }
                }
        }
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        if isLoading {
            content
                .overlay(ShimmerView())
        } else {
            content
        }
    }
}

extension View {
    func shimmer(isLoading: Bool) -> some View {
        modifier(ShimmerModifier(isLoading: isLoading))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 200, height: 100)
            .cornerRadius(8)
            .shimmer(isLoading: true)
        
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 150, height: 150)
            .clipShape(Circle())
            .shimmer(isLoading: true)
    }
    .padding()
}

