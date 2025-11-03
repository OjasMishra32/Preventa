import SwiftUI

struct HealthStatsPreviewCard: View {
    let onTap: () -> Void
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var pulse = false
    
    var body: some View {
        Button(action: onTap) {
            GlassCard {
                HStack(spacing: 20) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.red.opacity(0.7), .pink.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 2))
                            .shadow(color: .red.opacity(0.3), radius: pulse ? 12 : 6)
                            .scaleEffect(pulse ? 1.05 : 1.0)
                        
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                            .symbolEffect(.pulse, value: pulse)
                    }
                    .onAppear {
                        pulse = true
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            pulse = false
                        }
                    }
                    .onDisappear {
                        pulse = false
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Health Stats")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        
                        if healthManager.isAuthorized {
                            HStack(spacing: 16) {
                                StatPreview(label: "Steps", value: "\(healthManager.healthData.steps)", icon: "figure.walk", color: .cyan)
                                StatPreview(label: "Sleep", value: String(format: "%.1f", healthManager.healthData.sleepHours), icon: "bed.double.fill", color: .indigo)
                            }
                        } else {
                            Text("Connect Apple Health to see your stats")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        
                        HStack(spacing: 8) {
                            Text("Swipe left or tap to view")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Image(systemName: "arrow.left")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(20)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width < -50 {
                        onTap()
                    }
                }
        )
    }
}

struct StatPreview: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text("\(value) \(label)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.12))
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
        )
    }
}

#Preview {
    HealthStatsPreviewCard(onTap: {})
}

