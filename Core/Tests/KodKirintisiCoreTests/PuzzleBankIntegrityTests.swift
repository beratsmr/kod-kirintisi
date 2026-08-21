import Foundation
import Testing
@testable import KodKirintisiCore

/// Guards the real bundled content.
///
/// Every rule here runs against `puzzles.json` itself, so malformed content
/// fails the build instead of reaching the App Store.
@Suite("Bundled bank integrity")
struct PuzzleBankIntegrityTests {
    @Test("The bundled bank loads and validates")
    func bundledBankIsValid() throws {
        let bank = try PuzzleBank.bundled()

        #expect(bank.version >= 1)
        #expect(!bank.puzzles.isEmpty)
    }

    @Test("The shared bank is the bundled bank")
    func sharedBankMatchesBundled() throws {
        let shared = try PuzzleBank.shared()
        let bundled = try PuzzleBank.bundled()

        #expect(shared == bundled)
    }

    @Test("Identifiers are unique")
    func identifiersAreUnique() throws {
        let bank = try PuzzleBank.bundled()
        let identifiers = Set(bank.puzzles.map(\.id))

        #expect(identifiers.count == bank.puzzles.count)
    }

    @Test("Identifiers follow the slug format")
    func identifiersAreSlugs() throws {
        let bank = try PuzzleBank.bundled()

        for puzzle in bank.puzzles {
            let matches = puzzle.id.wholeMatch(of: /[a-z0-9]+(-[a-z0-9]+)*-[0-9]{3}/) != nil
            #expect(matches, "id is not a valid slug: \(puzzle.id)")
        }
    }

    @Test("Explanations are substantial enough to be worth reading")
    func explanationsAreSubstantial() throws {
        let bank = try PuzzleBank.bundled()

        for puzzle in bank.puzzles {
            #expect(puzzle.explanation.count >= 20, "explanation too short: \(puzzle.id)")
            #expect(puzzle.explanation.count <= 600, "explanation too long: \(puzzle.id)")
        }
    }

    @Test("Every wrong choice carries a note, and the correct one does not")
    func wrongChoiceNotesArePresent() throws {
        let bank = try PuzzleBank.bundled()

        for puzzle in bank.puzzles {
            for index in puzzle.choices.indices where index != puzzle.correctIndex {
                #expect(
                    !puzzle.whyOthersWrong[index].isEmpty,
                    "missing note for choice \(index) of \(puzzle.id)"
                )
            }
            #expect(puzzle.whyOthersWrong[puzzle.correctIndex].isEmpty)
        }
    }

    @Test("Every puzzle carries at least one tag")
    func tagsArePresent() throws {
        let bank = try PuzzleBank.bundled()

        for puzzle in bank.puzzles {
            #expect(!puzzle.tags.isEmpty, "no tags: \(puzzle.id)")
            #expect(puzzle.tags.count <= 5, "too many tags: \(puzzle.id)")
        }
    }

    @Test("Reference links are https URLs")
    func referencesAreSecureURLs() throws {
        let bank = try PuzzleBank.bundled()

        for puzzle in bank.puzzles {
            guard let reference = puzzle.reference else { continue }
            #expect(!reference.title.isEmpty, "empty reference title: \(puzzle.id)")
            #expect(reference.url.hasPrefix("https://"), "insecure reference: \(puzzle.id)")
        }
    }

    @Test("A puzzle with no snippet declares language none")
    func conceptualPuzzlesDeclareNoLanguage() throws {
        let bank = try PuzzleBank.bundled()

        for puzzle in bank.puzzles where puzzle.codeSnippet == nil {
            #expect(puzzle.language == CodeLanguage.none, "snippet-less puzzle claims a language: \(puzzle.id)")
        }
    }
}
