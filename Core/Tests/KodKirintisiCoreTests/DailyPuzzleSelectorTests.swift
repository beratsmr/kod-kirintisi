import Foundation
import Testing
@testable import KodKirintisiCore

@Suite("Daily puzzle selection")
struct DailyPuzzleSelectorTests {
    /// Day zero for the fixture installation: 2026-01-01T00:00:00Z.
    ///
    /// The schedule counts from the install rather than from a date fixed in
    /// the source, so every test has to say when its installation began. The
    /// tests below measure days as offsets from here, which is why most of
    /// them start counting at 2026-01-01.
    private let epoch = Date(timeIntervalSince1970: 1_767_225_600)

    /// A fixed calendar so a test never depends on where it runs.
    private func calendar(timeZone identifier: String = "UTC") throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: identifier))
        return calendar
    }

    private func date(
        _ year: Int, _ month: Int, _ day: Int,
        hour: Int = 12, minute: Int = 0,
        in calendar: Calendar
    ) throws -> Date {
        let components = DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute
        )
        return try #require(calendar.date(from: components))
    }

    @Test("An empty bank has no selector")
    func rejectsEmptyBank() {
        #expect(DailyPuzzleSelector(seed: 1, puzzleCount: 0, epoch: epoch) == nil)
    }

    @Test("A single-puzzle bank always returns that puzzle")
    func handlesSinglePuzzleBank() throws {
        let calendar = try calendar()
        let selector = try #require(DailyPuzzleSelector(seed: 99, puzzleCount: 1, epoch: epoch))

        for offset in 0 ..< 5 {
            let day = try date(2026, 1, 1 + offset, in: calendar)
            #expect(selector.index(for: day, calendar: calendar) == 0)
        }
    }

    @Test("The same day always yields the same puzzle")
    func isDeterministicWithinADay() throws {
        let calendar = try calendar()
        let selector = try #require(DailyPuzzleSelector(seed: 12345, puzzleCount: 120, epoch: epoch))

        let morning = try date(2026, 3, 14, hour: 0, minute: 1, in: calendar)
        let evening = try date(2026, 3, 14, hour: 23, minute: 59, in: calendar)

        #expect(selector.index(for: morning, calendar: calendar)
            == selector.index(for: evening, calendar: calendar))
    }

    @Test("Two selectors with the same seed agree, which is how app and widget match")
    func isReproducibleAcrossInstances() throws {
        let calendar = try calendar()
        let first = try #require(DailyPuzzleSelector(seed: 777, puzzleCount: 120, epoch: epoch))
        let second = try #require(DailyPuzzleSelector(seed: 777, puzzleCount: 120, epoch: epoch))

        for offset in 0 ..< 40 {
            let day = try date(2026, 1, 1 + offset, in: calendar)
            #expect(first.index(for: day, calendar: calendar)
                == second.index(for: day, calendar: calendar))
        }
    }

    @Test("Different seeds order the bank differently")
    func differentSeedsDiffer() throws {
        let calendar = try calendar()
        let first = try #require(DailyPuzzleSelector(seed: 1, puzzleCount: 120, epoch: epoch))
        let second = try #require(DailyPuzzleSelector(seed: 2, puzzleCount: 120, epoch: epoch))

        var differences = 0
        for offset in 0 ..< 60 {
            let day = try date(2026, 1, 1 + offset, in: calendar)
            let left = first.index(for: day, calendar: calendar)
            let right = second.index(for: day, calendar: calendar)
            if left != right {
                differences += 1
            }
        }
        #expect(differences > 40, "seeds produced near-identical schedules")
    }

    @Test("No puzzle repeats until the bank is exhausted")
    func doesNotRepeatWithinACycle() throws {
        let calendar = try calendar()
        let count = 120
        let selector = try #require(DailyPuzzleSelector(seed: 2024, puzzleCount: count, epoch: epoch))

        var seen: [Int] = []
        for offset in 0 ..< count {
            let day = try date(2026, 1, 1 + offset, in: calendar)
            seen.append(selector.index(for: day, calendar: calendar))
        }

        #expect(Set(seen).count == count, "a puzzle repeated inside one cycle")
        #expect(Set(seen) == Set(0 ..< count), "the cycle did not cover the whole bank")
    }

    @Test("The schedule wraps once the bank is exhausted")
    func wrapsAfterExhaustion() throws {
        let calendar = try calendar()
        let count = 30
        let selector = try #require(DailyPuzzleSelector(seed: 5, puzzleCount: count, epoch: epoch))

        let first = try date(2026, 1, 1, in: calendar)
        let afterCycle = try #require(
            calendar.date(byAdding: .day, value: count, to: first)
        )

        #expect(selector.index(for: first, calendar: calendar)
            == selector.index(for: afterCycle, calendar: calendar))
    }

    @Test("Day zero is the day of the install")
    func epochIsDayZero() throws {
        let calendar = try calendar()
        let selector = try #require(DailyPuzzleSelector(seed: 1, puzzleCount: 120, epoch: epoch))

        #expect(selector.dayIndex(for: epoch, calendar: calendar) == 0)
    }

    /// An installation started later is on its own day one, not dropped into
    /// the middle of a schedule that has been running without it. This is the
    /// whole point of anchoring the epoch to the install.
    @Test("A later install still starts at day zero")
    func laterInstallStartsAtDayZero() throws {
        let calendar = try calendar()
        let installDay = try date(2027, 6, 15, in: calendar)
        let selector = try #require(
            DailyPuzzleSelector(seed: 1, puzzleCount: 120, epoch: installDay)
        )

        #expect(selector.dayIndex(for: installDay, calendar: calendar) == 0)
        #expect(selector.revealedIndices(throughDayIndex: 0).count == 1)

        let nextDay = try date(2027, 6, 16, in: calendar)
        #expect(selector.dayIndex(for: nextDay, calendar: calendar) == 1)
    }

    @Test("Dates before the epoch clamp to day zero")
    func clampsBeforeEpoch() throws {
        let calendar = try calendar()
        let selector = try #require(DailyPuzzleSelector(seed: 1, puzzleCount: 120, epoch: epoch))

        let longBefore = try date(2020, 6, 15, in: calendar)
        let dayBefore = try date(2025, 12, 31, in: calendar)

        #expect(selector.dayIndex(for: longBefore, calendar: calendar) == 0)
        #expect(selector.dayIndex(for: dayBefore, calendar: calendar) == 0)
        #expect(selector.index(for: dayBefore, calendar: calendar)
            == selector.index(for: epoch, calendar: calendar))
    }

    @Test("The puzzle changes at local midnight, not at UTC midnight")
    func rollsOverAtLocalMidnight() throws {
        // Istanbul is UTC+3, so 22:00 UTC is already the next local day.
        let istanbul = try calendar(timeZone: "Europe/Istanbul")
        let selector = try #require(DailyPuzzleSelector(seed: 42, puzzleCount: 120, epoch: epoch))

        let lateEvening = try date(2026, 5, 10, hour: 23, minute: 30, in: istanbul)
        let justAfterMidnight = try date(2026, 5, 11, hour: 0, minute: 30, in: istanbul)

        #expect(selector.index(for: lateEvening, calendar: istanbul)
            != selector.index(for: justAfterMidnight, calendar: istanbul))
        #expect(selector.dayIndex(for: justAfterMidnight, calendar: istanbul)
            == selector.dayIndex(for: lateEvening, calendar: istanbul) + 1)
    }

    @Test("A spring-forward day still advances by exactly one")
    func handlesDaylightSavingSpringForward() throws {
        // New York loses an hour at 02:00 on 2026-03-08.
        let newYork = try calendar(timeZone: "America/New_York")
        let selector = try #require(DailyPuzzleSelector(seed: 8, puzzleCount: 120, epoch: epoch))

        let before = try date(2026, 3, 7, in: newYork)
        let during = try date(2026, 3, 8, in: newYork)
        let after = try date(2026, 3, 9, in: newYork)

        #expect(selector.dayIndex(for: during, calendar: newYork)
            == selector.dayIndex(for: before, calendar: newYork) + 1)
        #expect(selector.dayIndex(for: after, calendar: newYork)
            == selector.dayIndex(for: during, calendar: newYork) + 1)
    }

    @Test("A fall-back day still advances by exactly one")
    func handlesDaylightSavingFallBack() throws {
        // New York gains an hour at 02:00 on 2026-11-01.
        let newYork = try calendar(timeZone: "America/New_York")
        let selector = try #require(DailyPuzzleSelector(seed: 8, puzzleCount: 120, epoch: epoch))

        let before = try date(2026, 10, 31, in: newYork)
        let during = try date(2026, 11, 1, in: newYork)
        let after = try date(2026, 11, 2, in: newYork)

        #expect(selector.dayIndex(for: during, calendar: newYork)
            == selector.dayIndex(for: before, calendar: newYork) + 1)
        #expect(selector.dayIndex(for: after, calendar: newYork)
            == selector.dayIndex(for: during, calendar: newYork) + 1)
    }

    @Test("New year's eve rolls over into a single new day")
    func handlesYearBoundary() throws {
        let calendar = try calendar()
        let selector = try #require(DailyPuzzleSelector(seed: 3, puzzleCount: 120, epoch: epoch))

        let lastDay = try date(2026, 12, 31, hour: 23, minute: 59, in: calendar)
        let newYear = try date(2027, 1, 1, hour: 0, minute: 1, in: calendar)

        #expect(selector.dayIndex(for: newYear, calendar: calendar)
            == selector.dayIndex(for: lastDay, calendar: calendar) + 1)
    }

    @Test("A leap day counts as one ordinary day")
    func handlesLeapDay() throws {
        let calendar = try calendar()
        let selector = try #require(DailyPuzzleSelector(seed: 3, puzzleCount: 120, epoch: epoch))

        let before = try date(2028, 2, 28, in: calendar)
        let leapDay = try date(2028, 2, 29, in: calendar)
        let after = try date(2028, 3, 1, in: calendar)

        #expect(selector.dayIndex(for: leapDay, calendar: calendar)
            == selector.dayIndex(for: before, calendar: calendar) + 1)
        #expect(selector.dayIndex(for: after, calendar: calendar)
            == selector.dayIndex(for: leapDay, calendar: calendar) + 1)
    }

    @Test("Day zero reveals exactly one puzzle")
    func revealedIndicesStartsWithOne() throws {
        let selector = try #require(DailyPuzzleSelector(seed: 9, puzzleCount: 30, epoch: epoch))

        let revealed = selector.revealedIndices(throughDayIndex: 0)

        #expect(revealed.count == 1)
        #expect(try (0 ..< 30).contains(#require(revealed.first)))
    }

    @Test("A negative day index reveals nothing")
    func revealedIndicesRejectsNegativeDays() throws {
        let selector = try #require(DailyPuzzleSelector(seed: 9, puzzleCount: 30, epoch: epoch))

        #expect(selector.revealedIndices(throughDayIndex: -1).isEmpty)
    }

    @Test("Revealed indices grow by exactly one puzzle a day, without repeats")
    func revealedIndicesAccumulateWithoutRepeats() throws {
        let count = 30
        let selector = try #require(DailyPuzzleSelector(seed: 9, puzzleCount: count, epoch: epoch))

        for dayIndex in 0 ..< count {
            let revealed = selector.revealedIndices(throughDayIndex: dayIndex)
            #expect(revealed.count == dayIndex + 1)
            #expect(Set(revealed).count == revealed.count, "a puzzle repeated before the cycle ended")
        }
    }

    @Test("Revealed indices stop growing once the bank is exhausted")
    func revealedIndicesCapAtTheBankSize() throws {
        let count = 12
        let selector = try #require(DailyPuzzleSelector(seed: 9, puzzleCount: count, epoch: epoch))

        let atExhaustion = selector.revealedIndices(throughDayIndex: count - 1)
        let wellPastExhaustion = selector.revealedIndices(throughDayIndex: count * 5)

        #expect(atExhaustion.count == count)
        #expect(wellPastExhaustion == atExhaustion, "a second cycle must not add or reorder entries")
    }

    @Test("Every index stays inside the bank")
    func staysInBounds() throws {
        let calendar = try calendar()
        let count = 17
        let selector = try #require(DailyPuzzleSelector(seed: 6, puzzleCount: count, epoch: epoch))

        for offset in 0 ..< 100 {
            let day = try date(2026, 1, 1 + offset, in: calendar)
            let index = selector.index(for: day, calendar: calendar)
            #expect((0 ..< count).contains(index))
        }
    }
}
