import SwiftUI

struct BodyMapView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected: String?

    var body: some View {
        VStack(spacing: 14) {
            Text("Tap an area to start")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            ZStack {
                // Placeholder for now — can replace with real body silhouette later
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 360)
                    .overlay(
                        Text("3D Silhouette Placeholder")
                            .foregroundStyle(.white.opacity(0.6))
                    )
            }

            if let s = selected {
                Text("Selected: \(s)").foregroundStyle(.white)
                Button("Use this area") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.9)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        )
    }
}
