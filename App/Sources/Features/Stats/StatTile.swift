import SwiftUI

/// One small stat box on the Statistics screen — a number with a label and
/// an icon, like a streak count or an accuracy percentage.
struct StatTile: View {
    let title: LocalizedStringResource
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.fill.tertiary, in: .rect(cornerRadius: 10))
    }
}
