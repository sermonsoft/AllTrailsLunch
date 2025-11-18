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
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @Environment(\.photoManager) private var photoManager
    
    init(
        photoReferences: [String],
        maxWidth: Int = 400,
        maxHeight: Int = 400,
        contentMode: ContentMode = .fill
    ) {
        self.photoReferences = photoReferences
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
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
        .animation(.easeInOut(duration: 0.3), value: image != nil)
        .task(id: photoReferences.first) {
            await loadPhoto()
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
    
    private func loadPhoto() async {
        // Reset state when loading new photo
        image = nil
        isLoading = true

        guard let photoManager = photoManager else {
            print("⚠️ CachedPhotoView: photoManager is nil!")
            isLoading = false
            return
        }

        print("✅ CachedPhotoView: Loading photo with references: \(photoReferences)")
        let loadedImage = await photoManager.loadFirstPhoto(
            from: photoReferences,
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )

        if loadedImage != nil {
            print("✅ CachedPhotoView: Photo loaded successfully")
        } else {
            print("⚠️ CachedPhotoView: Photo loading returned nil")
        }

        image = loadedImage
        isLoading = false
    }
}

// MARK: - Photo Manager Environment Key

struct PhotoManagerKey: EnvironmentKey {
    static let defaultValue: PhotoManager? = nil
}

extension EnvironmentValues {
    var photoManager: PhotoManager? {
        get { self[PhotoManagerKey.self] }
        set { self[PhotoManagerKey.self] = newValue }
    }
}

extension View {
    func photoManager(_ manager: PhotoManager) -> some View {
        environment(\.photoManager, manager)
    }
}

// MARK: - Preview

#Preview {
    CachedPhotoView(
        photoReferences: ["test-photo-reference"],
        maxWidth: 400,
        maxHeight: 400,
        contentMode: .fill
    )
    .frame(width: 200, height: 200)
    .photoManager(AppConfiguration.shared.createPhotoManager())
}

