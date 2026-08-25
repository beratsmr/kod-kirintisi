import Foundation
import KodKirintisiCore

extension Difficulty {
    /// Human-readable label for the Archive's filter and any other UI that
    /// needs to name a difficulty rather than just sort by it.
    var displayName: LocalizedStringResource {
        switch self {
        case .basic: "Basic"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        }
    }
}
