import SwiftUI

struct HealthTimelineView: View {
    var entries: [TimelineEntry] = TimelineEntry.samples

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(entries) { e in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(e.title).font(.caption.weight(.semibold))
                        Text(e.subtitle).font(.caption2).opacity(0.9)
                    }
                    .padding(10)
                    .frame(width: 160, alignment: .leading)
                    .background(Color.white.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2)))
                    .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 14)
        }
        .background(
            LinearGradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.9)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        )
    }
}

struct TimelineEntry: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String

    static let samples: [TimelineEntry] = [
        .init(title: "Meds", subtitle: "8:00 AM • taken"),
        .init(title: "Sleep", subtitle: "7h 20m • good"),
        .init(title: "Check-in", subtitle: "mood 6/10"),
        .init(title: "Hydration", subtitle: "5/8 cups")
    ]
}
