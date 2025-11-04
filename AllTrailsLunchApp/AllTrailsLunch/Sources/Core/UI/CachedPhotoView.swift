///
/// `CachedPhotoView.swift`
/// AllTrailsLunch
///
/// SwiftUI view for displaying photos with automatic caching.
///

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
        .task {
            await loadPhoto()
        }
    }
    
    private var placeholderImage: some View {
        Image("placeholder-image", bundle: nil)
            .resizable()
            .aspectRatio(contentMode: contentMode)
    }
    
    private func loadPhoto() async {
        guard let photoManager = photoManager else {
            isLoading = false
            return
        }
        
        let loadedImage = await photoManager.loadFirstPhoto(
            from: photoReferences,
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )
        
        image = loadedImage
        isLoading = false
    }
}

// MARK: - Photo Manager Environment Key

private struct PhotoManagerKey: EnvironmentKey {
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

