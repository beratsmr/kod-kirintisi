import Foundation
import Testing
@testable import KodKirintisiCore

@Suite("Puzzle bank resource")
struct PuzzleBankResourceTests {
    @Test("The bank is bundled with the package")
    func bankIsBundled() throws {
        _ = try #require(PuzzleBankResource.url)
    }

    @Test("The bundled bank is readable and non-empty")
    func bankIsReadable() throws {
        let data = try PuzzleBankResource.data()
        #expect(!data.isEmpty)
    }

    @Test("The bundled bank is valid JSON with a version and puzzles")
    func bankIsWellFormed() throws {
        let data = try PuzzleBankResource.data()
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let root = try #require(object)
        #expect(root["version"] is Int)
        let puzzles = try #require(root["puzzles"] as? [Any])
        #expect(!puzzles.isEmpty)
    }
}
