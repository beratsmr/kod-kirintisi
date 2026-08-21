import Foundation
import Testing
@testable import KodKirintisiCore

@Suite("Progress store")
struct ProgressStoreTests {
    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("kodkirintisi-tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func record(_ puzzleID: String, isCorrect: Bool = true) -> AnswerRecord {
        AnswerRecord(
            puzzleID: puzzleID,
            selectedIndex: isCorrect ? 0 : 1,
            isCorrect: isCorrect,
            answeredAt: Date(timeIntervalSince1970: 1_767_225_600)
        )
    }

    @Test("A first launch creates progress with the injected seed")
    func firstLaunchUsesInjectedSeed() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = FileProgressStore(url: directory.appendingPathComponent("progress.json"))
        let store = ProgressStore(persistence: file) { 4242 }

        let progress = try await store.progress()

        #expect(progress.installSeed == 4242)
        #expect(progress.records.isEmpty)
    }

    @Test("The seed is written immediately, so the widget sees the same one")
    func firstLaunchPersistsTheSeed() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let file = FileProgressStore(url: url)
        let store = ProgressStore(persistence: file) { 4242 }

        _ = try await store.progress()

        // A second store, standing in for the widget process, must agree.
        let widgetSide = ProgressStore(persistence: FileProgressStore(url: url)) { 9999 }
        #expect(try await widgetSide.progress().installSeed == 4242)
    }

    @Test("The seed never changes once created")
    func seedIsStable() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = FileProgressStore(url: directory.appendingPathComponent("progress.json"))
        let store = ProgressStore(persistence: file) { 7 }

        let first = try await store.progress().installSeed
        try await store.recordAnswer(record("swift-a-001"))
        let afterAnswer = try await store.progress().installSeed
        let afterReload = try await store.reload().installSeed

        #expect(first == 7)
        #expect(afterAnswer == 7)
        #expect(afterReload == 7)
    }

    @Test("An answer is written through to disk")
    func answerIsPersisted() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let store = ProgressStore(persistence: FileProgressStore(url: url)) { 1 }

        let stored = try await store.recordAnswer(record("swift-a-001"))

        #expect(stored)
        let onDisk = try #require(try FileProgressStore(url: url).load())
        #expect(onDisk.records["swift-a-001"]?.isCorrect == true)
    }

    @Test("The first answer to a puzzle wins, even through the store")
    func firstAnswerWins() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let store = ProgressStore(persistence: FileProgressStore(url: url)) { 1 }

        let first = try await store.recordAnswer(record("swift-a-001", isCorrect: false))
        let second = try await store.recordAnswer(record("swift-a-001", isCorrect: true))

        #expect(first)
        #expect(!second)
        #expect(try await store.progress().records["swift-a-001"]?.isCorrect == false)
    }

    @Test("Reloading picks up an answer written by the other process")
    func reloadSeesExternalWrites() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let appSide = ProgressStore(persistence: FileProgressStore(url: url)) { 3 }

        _ = try await appSide.progress()

        // The widget answers while the app is in the background.
        let widgetSide = ProgressStore(persistence: FileProgressStore(url: url)) { 3 }
        try await widgetSide.recordAnswer(record("swift-a-001"))

        #expect(try await appSide.progress().records.isEmpty, "stale copy expected before reload")
        let reloaded = try await appSide.reload()
        #expect(reloaded.records.count == 1)
    }

    @Test("A corrupt file yields a clean start rather than a failure")
    func recoversFromCorruptFile() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        try Data("not json at all".utf8).write(to: url)
        let store = ProgressStore(persistence: FileProgressStore(url: url)) { 55 }

        let progress = try await store.progress()

        #expect(progress.installSeed == 55)
        #expect(progress.records.isEmpty)
    }

    @Test("Reloading after the file vanishes keeps the seed")
    func reloadKeepsSeedWhenFileDisappears() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let store = ProgressStore(persistence: FileProgressStore(url: url)) { 1234 }

        _ = try await store.progress()
        try FileManager.default.removeItem(at: url)

        // A new seed here would reshuffle the schedule under the user.
        #expect(try await store.reload().installSeed == 1234)
        #expect(try FileProgressStore(url: url).load()?.installSeed == 1234)
    }

    @Test("Concurrent answers are all recorded and leave a readable file")
    func concurrentWritesStayConsistent() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let store = ProgressStore(persistence: FileProgressStore(url: url)) { 2 }
        let count = 50

        try await withThrowingTaskGroup(of: Bool.self) { group in
            for index in 0 ..< count {
                group.addTask {
                    try await store.recordAnswer(record("swift-\(index)-001"))
                }
            }
            for try await stored in group {
                #expect(stored)
            }
        }

        #expect(try await store.progress().records.count == count)
        let onDisk = try #require(try FileProgressStore(url: url).load())
        #expect(onDisk.records.count == count, "the file must not be truncated or interleaved")
    }

    @Test("Concurrent answers to the same puzzle store exactly one")
    func concurrentDuplicatesStoreOnce() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let store = ProgressStore(persistence: FileProgressStore(url: url)) { 2 }

        let results = try await withThrowingTaskGroup(of: Bool.self) { group -> [Bool] in
            for _ in 0 ..< 20 {
                group.addTask {
                    try await store.recordAnswer(record("swift-a-001"))
                }
            }
            var collected: [Bool] = []
            for try await stored in group {
                collected.append(stored)
            }
            return collected
        }

        #expect(results.filter(\.self).count == 1, "only one write should have won")
        #expect(try await store.progress().records.count == 1)
    }
}
