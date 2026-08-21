import Foundation
import Testing
@testable import KodKirintisiCore

@Suite("File progress store")
struct FileProgressStoreTests {
    /// A private directory per test, removed afterwards.
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
            selectedIndex: 0,
            isCorrect: isCorrect,
            answeredAt: Date(timeIntervalSince1970: 1_767_225_600)
        )
    }

    @Test("Nothing stored yet is not an error")
    func missingFileLoadsNil() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileProgressStore(url: directory.appendingPathComponent("progress.json"))

        #expect(try store.load() == nil)
    }

    @Test("Progress survives a write and read")
    func roundTrips() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileProgressStore(url: directory.appendingPathComponent("progress.json"))

        var progress = UserProgress(installSeed: 987_654_321)
        progress.recordAnswer(record("swift-a-001"))
        try store.save(progress)

        let loaded = try #require(try store.load())
        #expect(loaded == progress)
        #expect(loaded.installSeed == 987_654_321)
        #expect(loaded.records.count == 1)
    }

    @Test("Saving twice replaces the file rather than appending to it")
    func overwritesCleanly() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileProgressStore(url: directory.appendingPathComponent("progress.json"))

        var progress = UserProgress(installSeed: 1)
        progress.recordAnswer(record("swift-a-001"))
        try store.save(progress)

        progress.recordAnswer(record("swift-b-001"))
        try store.save(progress)

        let loaded = try #require(try store.load())
        #expect(loaded.records.count == 2)
    }

    @Test("Missing intermediate directories are created")
    func createsDirectories() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let nested = directory
            .appendingPathComponent("group")
            .appendingPathComponent("container")
            .appendingPathComponent("progress.json")
        let store = FileProgressStore(url: nested)

        try store.save(UserProgress(installSeed: 5))

        #expect(FileManager.default.fileExists(atPath: nested.path))
        #expect(try store.load()?.installSeed == 5)
    }

    @Test("An unreadable file is moved aside and reported as empty")
    func quarantinesCorruptedFile() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let store = FileProgressStore(url: url)

        try Data("this is not progress".utf8).write(to: url)

        #expect(try store.load() == nil, "corrupt data must not be returned as progress")
        #expect(
            !FileManager.default.fileExists(atPath: url.path),
            "the corrupt file should have been moved out of the way"
        )
        #expect(
            FileManager.default.fileExists(atPath: store.quarantineURL.path),
            "the corrupt file should be recoverable"
        )
    }

    @Test("The quarantined file keeps the original bytes")
    func quarantinePreservesData() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let store = FileProgressStore(url: url)
        let original = Data("{ truncated".utf8)

        try original.write(to: url)
        _ = try store.load()

        #expect(try Data(contentsOf: store.quarantineURL) == original)
    }

    @Test("The quarantine file is named next to the original")
    func quarantineIsNamedPredictably() {
        let store = FileProgressStore(url: URL(fileURLWithPath: "/tmp/box/progress.json"))

        #expect(store.quarantineURL.lastPathComponent == "progress.corrupt.json")
    }

    @Test("Writing again after a quarantine starts a clean file")
    func recoversAfterQuarantine() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let store = FileProgressStore(url: url)

        try Data("broken".utf8).write(to: url)
        _ = try store.load()
        try store.save(UserProgress(installSeed: 42))

        #expect(try store.load()?.installSeed == 42)
    }

    @Test("A second corruption replaces the earlier quarantine instead of failing")
    func quarantineIsReplaceable() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let store = FileProgressStore(url: url)

        try Data("broken once".utf8).write(to: url)
        _ = try store.load()
        try Data("broken twice".utf8).write(to: url)
        _ = try store.load()

        #expect(try Data(contentsOf: store.quarantineURL) == Data("broken twice".utf8))
    }
}
