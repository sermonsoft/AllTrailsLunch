//
//  CachedPhotoView.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 05/11/25.
//

import SwiftUI

// MARK: - Cached Photo View

struct CachedPhotoView: View {
    let photoReferences: [String]
    let maxWidth: Int
    let maxHeight: Int
    let contentMode: ContentMode
    let loadPhoto: ([String], Int, Int) async -> Data?

    @State private var imageData: Data?
    @State private var isLoading = true

    init(
        photoReferences: [String],
        maxWidth: Int = 400,
        maxHeight: Int = 400,
        contentMode: ContentMode = .fill,
        loadPhoto: @escaping ([String], Int, Int) async -> Data?
    ) {
        self.photoReferences = photoReferences
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.contentMode = contentMode
        self.loadPhoto = loadPhoto
    }
    
    var body: some View {
        Group {
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .shimmer(isLoading: true)
            } else {
                placeholderImage
            }
        }
        .animation(.easeInOut(duration: 0.3), value: imageData != nil)
        .task(id: photoReferences.first) {
            await loadPhotoAsync()
        }
    }
    
    private var placeholderImage: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.2))

            VStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.5))

                #if DEV
                if NetworkSimulator.shared.shouldBlockRequest() {
                    Text("Offline")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
                #endif
            }
        }
    }
    
    private func loadPhotoAsync() async {
        // Reset state when loading new photo
        imageData = nil
        isLoading = true

        print("✅ CachedPhotoView: Loading photo with references: \(photoReferences)")
        let loadedData = await loadPhoto(photoReferences, maxWidth, maxHeight)

        if loadedData != nil {
            print("✅ CachedPhotoView: Photo loaded successfully")
        } else {
            print("⚠️ CachedPhotoView: Photo loading returned nil")
        }

        imageData = loadedData
        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    CachedPhotoView(
        photoReferences: ["test-photo-reference"],
        maxWidth: 400,
        maxHeight: 400,
        contentMode: .fill,
        loadPhoto: { references, width, height in
            // Mock photo loader for preview
            return nil
        }
    )
    .frame(width: 200, height: 200)
}

