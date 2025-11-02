import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

    /// The "AllTrails-White" asset catalog color resource.
    static let allTrailsWhite = DeveloperToolsSupport.ColorResource(name: "AllTrails-White", bundle: resourceBundle)

    /// The "Deep Fir" asset catalog color resource.
    static let deepFir = DeveloperToolsSupport.ColorResource(name: "Deep Fir", bundle: resourceBundle)

    /// The "Pastel-Green" asset catalog color resource.
    static let pastelGreen = DeveloperToolsSupport.ColorResource(name: "Pastel-Green", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "AllTrails_0" asset catalog image resource.
    static let allTrails0 = DeveloperToolsSupport.ImageResource(name: "AllTrails_0", bundle: resourceBundle)

    /// The "AllTrails_1" asset catalog image resource.
    static let allTrails1 = DeveloperToolsSupport.ImageResource(name: "AllTrails_1", bundle: resourceBundle)

    /// The "AllTrails_10" asset catalog image resource.
    static let allTrails10 = DeveloperToolsSupport.ImageResource(name: "AllTrails_10", bundle: resourceBundle)

    /// The "AllTrails_11" asset catalog image resource.
    static let allTrails11 = DeveloperToolsSupport.ImageResource(name: "AllTrails_11", bundle: resourceBundle)

    /// The "AllTrails_12" asset catalog image resource.
    static let allTrails12 = DeveloperToolsSupport.ImageResource(name: "AllTrails_12", bundle: resourceBundle)

    /// The "AllTrails_13" asset catalog image resource.
    static let allTrails13 = DeveloperToolsSupport.ImageResource(name: "AllTrails_13", bundle: resourceBundle)

    /// The "AllTrails_2" asset catalog image resource.
    static let allTrails2 = DeveloperToolsSupport.ImageResource(name: "AllTrails_2", bundle: resourceBundle)

    /// The "AllTrails_4" asset catalog image resource.
    static let allTrails4 = DeveloperToolsSupport.ImageResource(name: "AllTrails_4", bundle: resourceBundle)

    /// The "AllTrails_5" asset catalog image resource.
    static let allTrails5 = DeveloperToolsSupport.ImageResource(name: "AllTrails_5", bundle: resourceBundle)

    /// The "AllTrails_6" asset catalog image resource.
    static let allTrails6 = DeveloperToolsSupport.ImageResource(name: "AllTrails_6", bundle: resourceBundle)

    /// The "AllTrails_7" asset catalog image resource.
    static let allTrails7 = DeveloperToolsSupport.ImageResource(name: "AllTrails_7", bundle: resourceBundle)

    /// The "AllTrails_8" asset catalog image resource.
    static let allTrails8 = DeveloperToolsSupport.ImageResource(name: "AllTrails_8", bundle: resourceBundle)

    /// The "AllTrails_9" asset catalog image resource.
    static let allTrails9 = DeveloperToolsSupport.ImageResource(name: "AllTrails_9", bundle: resourceBundle)

    /// The "bookmark-resting" asset catalog image resource.
    static let bookmarkResting = DeveloperToolsSupport.ImageResource(name: "bookmark-resting", bundle: resourceBundle)

    /// The "bookmark-saved" asset catalog image resource.
    static let bookmarkSaved = DeveloperToolsSupport.ImageResource(name: "bookmark-saved", bundle: resourceBundle)

    /// The "list" asset catalog image resource.
    static let list = DeveloperToolsSupport.ImageResource(name: "list", bundle: resourceBundle)

    /// The "logo-lockup" asset catalog image resource.
    static let logoLockup = DeveloperToolsSupport.ImageResource(name: "logo-lockup", bundle: resourceBundle)

    /// The "map" asset catalog image resource.
    static let map = DeveloperToolsSupport.ImageResource(name: "map", bundle: resourceBundle)

    /// The "pin-resting" asset catalog image resource.
    static let pinResting = DeveloperToolsSupport.ImageResource(name: "pin-resting", bundle: resourceBundle)

    /// The "pin-selected" asset catalog image resource.
    static let pinSelected = DeveloperToolsSupport.ImageResource(name: "pin-selected", bundle: resourceBundle)

    /// The "placeholder-image" asset catalog image resource.
    static let placeholder = DeveloperToolsSupport.ImageResource(name: "placeholder-image", bundle: resourceBundle)

    /// The "search" asset catalog image resource.
    static let search = DeveloperToolsSupport.ImageResource(name: "search", bundle: resourceBundle)

    /// The "star" asset catalog image resource.
    static let star = DeveloperToolsSupport.ImageResource(name: "star", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "AllTrails-White" asset catalog color.
    static var allTrailsWhite: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .allTrailsWhite)
#else
        .init()
#endif
    }

    /// The "Deep Fir" asset catalog color.
    static var deepFir: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .deepFir)
#else
        .init()
#endif
    }

    /// The "Pastel-Green" asset catalog color.
    static var pastelGreen: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pastelGreen)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "AllTrails-White" asset catalog color.
    static var allTrailsWhite: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .allTrailsWhite)
#else
        .init()
#endif
    }

    /// The "Deep Fir" asset catalog color.
    static var deepFir: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .deepFir)
#else
        .init()
#endif
    }

    /// The "Pastel-Green" asset catalog color.
    static var pastelGreen: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .pastelGreen)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "AllTrails-White" asset catalog color.
    static var allTrailsWhite: SwiftUI.Color { .init(.allTrailsWhite) }

    /// The "Deep Fir" asset catalog color.
    static var deepFir: SwiftUI.Color { .init(.deepFir) }

    /// The "Pastel-Green" asset catalog color.
    static var pastelGreen: SwiftUI.Color { .init(.pastelGreen) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "AllTrails-White" asset catalog color.
    static var allTrailsWhite: SwiftUI.Color { .init(.allTrailsWhite) }

    /// The "Deep Fir" asset catalog color.
    static var deepFir: SwiftUI.Color { .init(.deepFir) }

    /// The "Pastel-Green" asset catalog color.
    static var pastelGreen: SwiftUI.Color { .init(.pastelGreen) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "AllTrails_0" asset catalog image.
    static var allTrails0: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .allTrails0)
#else
        .init()
#endif
    }

    /// The "AllTrails_1" asset catalog image.
    static var allTrails1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .allTrails1)
#else
        .init()
#endif
    }

    /// The "AllTrails_10" asset catalog image.
    static var allTrails10: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .allTrails10)
#else
        .init()
#endif
    }

    /// The "AllTrails_11" asset catalog image.
    static var allTrails11: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .allTrails11)
#else
        .init()
#endif
    }

    /// The "AllTrails_12" asset catalog image.
    static var allTrails12: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .allTrails12)
#else
        .init()
#endif
    }

    /// The "AllTrails_13" asset catalog image.
    static var allTrails13: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .allTrails13)
#else
        .init()
#endif
    }

    /// The "AllTrails_2" asset catalog image.
    static var allTrails2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .allTrails2)
#else
        .init()
#endif
    }

    /// The "AllTrails_4" asset catalog image.
    static var allTrails4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .allTrails4)
#else
        .init()
#endif
    }

    /// The "AllTrails_5" asset catalog image.
    static var allTrails5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .allTrails5)
#else
        .init()
#endif
    }

    /// The "AllTrails_6" asset catalog image.
    static var allTrails6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .allTrails6)
#else
        .init()
#endif
    }

    /// The "AllTrails_7" asset catalog image.
    static var allTrails7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .allTrails7)
#else
        .init()
#endif
    }

    /// The "AllTrails_8" asset catalog image.
    static var allTrails8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .allTrails8)
#else
        .init()
#endif
    }

    /// The "AllTrails_9" asset catalog image.
    static var allTrails9: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .allTrails9)
#else
        .init()
#endif
    }

    /// The "bookmark-resting" asset catalog image.
    static var bookmarkResting: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bookmarkResting)
#else
        .init()
#endif
    }

    /// The "bookmark-saved" asset catalog image.
    static var bookmarkSaved: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bookmarkSaved)
#else
        .init()
#endif
    }

    /// The "list" asset catalog image.
    static var list: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .list)
#else
        .init()
#endif
    }

    /// The "logo-lockup" asset catalog image.
    static var logoLockup: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .logoLockup)
#else
        .init()
#endif
    }

    /// The "map" asset catalog image.
    static var map: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .map)
#else
        .init()
#endif
    }

    /// The "pin-resting" asset catalog image.
    static var pinResting: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pinResting)
#else
        .init()
#endif
    }

    /// The "pin-selected" asset catalog image.
    static var pinSelected: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pinSelected)
#else
        .init()
#endif
    }

    /// The "placeholder-image" asset catalog image.
    static var placeholder: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .placeholder)
#else
        .init()
#endif
    }

    /// The "search" asset catalog image.
    static var search: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .search)
#else
        .init()
#endif
    }

    /// The "star" asset catalog image.
    static var star: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .star)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "AllTrails_0" asset catalog image.
    static var allTrails0: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .allTrails0)
#else
        .init()
#endif
    }

    /// The "AllTrails_1" asset catalog image.
    static var allTrails1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .allTrails1)
#else
        .init()
#endif
    }

    /// The "AllTrails_10" asset catalog image.
    static var allTrails10: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .allTrails10)
#else
        .init()
#endif
    }

    /// The "AllTrails_11" asset catalog image.
    static var allTrails11: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .allTrails11)
#else
        .init()
#endif
    }

    /// The "AllTrails_12" asset catalog image.
    static var allTrails12: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .allTrails12)
#else
        .init()
#endif
    }

    /// The "AllTrails_13" asset catalog image.
    static var allTrails13: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .allTrails13)
#else
        .init()
#endif
    }

    /// The "AllTrails_2" asset catalog image.
    static var allTrails2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .allTrails2)
#else
        .init()
#endif
    }

    /// The "AllTrails_4" asset catalog image.
    static var allTrails4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .allTrails4)
#else
        .init()
#endif
    }

    /// The "AllTrails_5" asset catalog image.
    static var allTrails5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .allTrails5)
#else
        .init()
#endif
    }

    /// The "AllTrails_6" asset catalog image.
    static var allTrails6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .allTrails6)
#else
        .init()
#endif
    }

    /// The "AllTrails_7" asset catalog image.
    static var allTrails7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .allTrails7)
#else
        .init()
#endif
    }

    /// The "AllTrails_8" asset catalog image.
    static var allTrails8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .allTrails8)
#else
        .init()
#endif
    }

    /// The "AllTrails_9" asset catalog image.
    static var allTrails9: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .allTrails9)
#else
        .init()
#endif
    }

    /// The "bookmark-resting" asset catalog image.
    static var bookmarkResting: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bookmarkResting)
#else
        .init()
#endif
    }

    /// The "bookmark-saved" asset catalog image.
    static var bookmarkSaved: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bookmarkSaved)
#else
        .init()
#endif
    }

    /// The "list" asset catalog image.
    static var list: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .list)
#else
        .init()
#endif
    }

    /// The "logo-lockup" asset catalog image.
    static var logoLockup: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .logoLockup)
#else
        .init()
#endif
    }

    /// The "map" asset catalog image.
    static var map: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .map)
#else
        .init()
#endif
    }

    /// The "pin-resting" asset catalog image.
    static var pinResting: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pinResting)
#else
        .init()
#endif
    }

    /// The "pin-selected" asset catalog image.
    static var pinSelected: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pinSelected)
#else
        .init()
#endif
    }

    /// The "placeholder-image" asset catalog image.
    static var placeholder: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .placeholder)
#else
        .init()
#endif
    }

    /// The "search" asset catalog image.
    static var search: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .search)
#else
        .init()
#endif
    }

    /// The "star" asset catalog image.
    static var star: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .star)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

