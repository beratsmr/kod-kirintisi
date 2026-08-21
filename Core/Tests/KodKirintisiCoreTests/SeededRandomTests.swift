import Foundation
import Testing
@testable import KodKirintisiCore

@Suite("Seeded random")
struct SeededRandomTests {
    @Test("The same seed produces the same sequence")
    func isDeterministic() {
        var first = SeededRandom(seed: 2026)
        var second = SeededRandom(seed: 2026)

        for _ in 0 ..< 100 {
            #expect(first.next() == second.next())
        }
    }

    @Test("Different seeds produce different sequences")
    func differsBySeed() {
        var first = SeededRandom(seed: 1)
        var second = SeededRandom(seed: 2)

        let left = (0 ..< 20).map { _ in first.next() }
        let right = (0 ..< 20).map { _ in second.next() }

        #expect(left != right)
    }

    @Test("A zero seed still produces varied output")
    func handlesZeroSeed() {
        var generator = SeededRandom(seed: 0)
        let values = (0 ..< 20).map { _ in generator.next() }

        #expect(Set(values).count == values.count)
        #expect(!values.contains(0))
    }

    @Test("SplitMix64 matches its published output for seed zero")
    func matchesReferenceVector() {
        // Reference values for SplitMix64 seeded with 0, which pins the
        // algorithm: if these change, every user's schedule would change too.
        var generator = SeededRandom(seed: 0)

        #expect(generator.next() == 0xE220_A839_7B1D_CDAF)
        #expect(generator.next() == 0x6E78_9E6A_A1B9_65F4)
        #expect(generator.next() == 0x06C4_5D18_8009_454F)
    }

    @Test("Bounded values stay inside the bound")
    func staysInBounds() {
        var generator = SeededRandom(seed: 7)

        for _ in 0 ..< 500 {
            #expect(generator.next(upperBound: 10) < 10)
        }
    }

    @Test("A bound of one is always zero")
    func handlesBoundOfOne() {
        var generator = SeededRandom(seed: 7)

        for _ in 0 ..< 10 {
            #expect(generator.next(upperBound: 1) == 0)
        }
    }

    @Test("Bounded values cover the whole range")
    func coversTheRange() {
        var generator = SeededRandom(seed: 11)
        var seen = Set<UInt64>()

        for _ in 0 ..< 1000 {
            seen.insert(generator.next(upperBound: 6))
        }

        #expect(seen == Set(0 ..< 6))
    }

    @Test("Bounded values are not obviously biased")
    func isReasonablyUniform() {
        var generator = SeededRandom(seed: 3)
        var counts = [Int](repeating: 0, count: 4)

        let draws = 40000
        for _ in 0 ..< draws {
            counts[Int(generator.next(upperBound: 4))] += 1
        }

        // Each bucket should hold about a quarter; allow a wide margin so the
        // test checks for real bias rather than for one particular sequence.
        for count in counts {
            #expect(abs(count - draws / 4) < draws / 20, "bucket skew: \(counts)")
        }
    }
}
