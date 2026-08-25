import Charts
import KodKirintisiCore
import SwiftUI

/// A horizontal bar per category, showing that category's accuracy so far.
///
/// Categories the user hasn't answered anything in are simply absent from
/// ``StatsSnapshot/byCategory`` — see ``StatsCalculator/byCategory(records:puzzles:)``
/// — so there is nothing here to distinguish "0% accuracy" from "not started".
struct CategoryAccuracyChart: View {
    private struct Row: Identifiable {
        let category: PuzzleCategory
        let summary: StatsCalculator.Summary
        var id: PuzzleCategory {
            category
        }
    }

    let byCategory: [PuzzleCategory: StatsCalculator.Summary]

    /// Spelled out as a stored value rather than `.percent` at each call
    /// site: the bare form is ambiguous between `Double`, `Float`, and
    /// `Decimal` percent styles and needs this exact type to resolve.
    private let percentFormat = FloatingPointFormatStyle<Double>.Percent().precision(.fractionLength(0))

    var body: some View {
        if rows.isEmpty {
            ContentUnavailableView(
                "No Answers Yet",
                systemImage: "chart.bar",
                description: Text("Answer a few puzzles to see your accuracy by category.")
            )
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Accuracy by Category")
                    .font(.headline)
                Chart(rows) { row in
                    BarMark(
                        x: .value("Accuracy", row.summary.accuracy),
                        y: .value("Category", String(localized: row.category.badgeName))
                    )
                    .foregroundStyle(.tint)
                    // A 100% bar ends exactly at the domain maximum, so its
                    // trailing label would sit outside the plot area and be
                    // clipped to "10". Letting it move back inside keeps the
                    // best scores — the ones worth showing off — readable.
                    .annotation(
                        position: .trailing,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        Text(row.summary.accuracy, format: percentFormat)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXScale(domain: 0 ... 1)
                .chartXAxis {
                    AxisMarks(format: percentFormat)
                }
                .frame(height: CGFloat(rows.count) * 36 + 20)
            }
        }
    }

    /// Most-practiced category first; ties broken by raw value so the order
    /// is stable rather than depending on dictionary iteration.
    private var rows: [Row] {
        byCategory
            .map { Row(category: $0.key, summary: $0.value) }
            .sorted {
                $0.summary.answered != $1.summary.answered
                    ? $0.summary.answered > $1.summary.answered
                    : $0.category.rawValue < $1.category.rawValue
            }
    }
}
