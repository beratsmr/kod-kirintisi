import Foundation

/// A single multiple-choice puzzle as it ships in the bundled bank.
///
/// Every puzzle must render inside a medium widget without truncation, so the
/// text fields carry hard length limits described by ``Puzzle/WidgetLimits``.
/// ``PuzzleBank`` enforces those limits at load time.
public struct Puzzle: Sendable, Codable, Equatable, Identifiable {
    /// A pointer to further reading, shown under the explanation.
    public struct Reference: Sendable, Codable, Equatable {
        public let title: String
        public let url: String

        public init(title: String, url: String) {
            self.title = title
            self.url = url
        }
    }

    /// Size limits that keep a puzzle readable on a home screen widget.
    ///
    /// These are content constraints rather than layout code: the widget has no
    /// room to scroll, so overly long text has to be rejected before it ships.
    public enum WidgetLimits {
        /// Maximum characters in ``Puzzle/title``.
        public static let titleLength = 60
        /// Maximum characters in ``Puzzle/question``.
        public static let questionLength = 120
        /// Maximum characters in a single entry of ``Puzzle/choices``.
        public static let choiceLength = 24
        /// Number of answer buttons that fit a medium widget.
        public static let choiceCount = 2 ... 4
        /// Maximum lines in ``Puzzle/codeSnippet``.
        public static let codeSnippetLines = 6
        /// Maximum characters per line of ``Puzzle/codeSnippet``.
        public static let codeSnippetLineLength = 44
    }

    /// Permanent slug. Never changed or reused, because progress is keyed by it.
    public let id: String
    public let category: PuzzleCategory
    public let difficulty: Difficulty
    /// Short headline, shown in the small widget and in Spotlight.
    public let title: String
    /// The prompt itself, shown above the answer buttons.
    public let question: String
    /// Optional code listing the question refers to.
    public let codeSnippet: String?
    /// Language of ``codeSnippet``. Defaults to ``CodeLanguage/swift`` when absent.
    public let language: CodeLanguage
    /// Two to four answers, in display order.
    public let choices: [String]
    /// Index into ``choices`` of the correct answer.
    public let correctIndex: Int
    /// Shown after answering, in the app.
    public let explanation: String
    /// Parallel to ``choices``: why each wrong answer is wrong.
    /// The entry at ``correctIndex`` is an empty string.
    public let whyOthersWrong: [String]
    public let reference: Reference?
    public let tags: [String]

    public init(
        id: String,
        category: PuzzleCategory,
        difficulty: Difficulty,
        title: String,
        question: String,
        codeSnippet: String? = nil,
        language: CodeLanguage = .swift,
        choices: [String],
        correctIndex: Int,
        explanation: String,
        whyOthersWrong: [String],
        reference: Reference? = nil,
        tags: [String]
    ) {
        self.id = id
        self.category = category
        self.difficulty = difficulty
        self.title = title
        self.question = question
        self.codeSnippet = codeSnippet
        self.language = language
        self.choices = choices
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.whyOthersWrong = whyOthersWrong
        self.reference = reference
        self.tags = tags
    }

    /// Decodes a puzzle, defaulting ``language`` to ``CodeLanguage/swift`` when
    /// the key is absent, as the bank schema specifies.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        category = try container.decode(PuzzleCategory.self, forKey: .category)
        difficulty = try container.decode(Difficulty.self, forKey: .difficulty)
        title = try container.decode(String.self, forKey: .title)
        question = try container.decode(String.self, forKey: .question)
        codeSnippet = try container.decodeIfPresent(String.self, forKey: .codeSnippet)
        language = try container.decodeIfPresent(CodeLanguage.self, forKey: .language) ?? .swift
        choices = try container.decode([String].self, forKey: .choices)
        correctIndex = try container.decode(Int.self, forKey: .correctIndex)
        explanation = try container.decode(String.self, forKey: .explanation)
        whyOthersWrong = try container.decode([String].self, forKey: .whyOthersWrong)
        reference = try container.decodeIfPresent(Reference.self, forKey: .reference)
        tags = try container.decode([String].self, forKey: .tags)
    }
}
