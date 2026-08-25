import Foundation
import KodKirintisiCore

extension PuzzleCategory {
    /// Short label for the widget's category badge.
    ///
    /// Kept deliberately terse — the small widget gives the badge about eight
    /// characters before it starts truncating, so these are abbreviations
    /// rather than the full category names used in the app's filters.
    var badgeName: LocalizedStringResource {
        switch self {
        case .swiftLanguage: "Swift"
        case .concurrency: "Async"
        case .memoryARC: "ARC"
        case .swiftUI: "SwiftUI"
        case .foundation: "Foundation"
        case .algorithms: "Algo"
        case .iOSPlatform: "iOS"
        }
    }

    /// SF Symbol shown next to the badge.
    var symbolName: String {
        switch self {
        case .swiftLanguage: "swift"
        case .concurrency: "arrow.triangle.branch"
        case .memoryARC: "memorychip"
        case .swiftUI: "rectangle.3.group"
        case .foundation: "shippingbox"
        case .algorithms: "function"
        case .iOSPlatform: "iphone"
        }
    }
}
