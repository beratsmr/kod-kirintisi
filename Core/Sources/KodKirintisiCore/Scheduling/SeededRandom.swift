import Foundation

/// A deterministic pseudo-random generator (SplitMix64).
///
/// The daily puzzle must be identical in the app and in the widget, which are
/// separate processes that never talk to each other. They agree by computing
/// the same pure function from the same seed, so the generator has to be
/// reproducible on every platform and across releases — that rules out the
/// system generator.
///
/// SplitMix64 is used because it is a handful of arithmetic operations with no
/// lookup tables, and its output is fully specified by the constants below.
public struct SeededRandom: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }

    /// A value in `0 ..< upperBound`, with the modulo bias removed.
    ///
    /// Values that fall in the short, incomplete final block of the 64-bit
    /// range are rejected and redrawn, so every outcome is equally likely.
    /// - Parameter upperBound: Must be greater than zero.
    public mutating func next(upperBound: UInt64) -> UInt64 {
        guard upperBound > 1 else { return 0 }
        // 2^64 mod upperBound, computed in unsigned wrap-around arithmetic.
        let threshold = (0 &- upperBound) % upperBound
        var value = next()
        while value < threshold {
            value = next()
        }
        return value % upperBound
    }
}
