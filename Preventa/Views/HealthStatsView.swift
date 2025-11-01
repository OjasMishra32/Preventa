import SwiftUI
import HealthKit

struct HealthStatsView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var showPermissionSheet = false
    @State private var selectedMetric: MetricType = .steps
    
    enum MetricType: String, CaseIterable {
        case steps = "Steps"
        case heartRate = "Heart Rate"
        case sleep = "Sleep"
        case calories = "Calories"
        
        var icon: String {
            switch self {
            case .steps: return "figure.walk"
            case .heartRate: return "heart.fill"
            case .sleep: return "bed.double.fill"
            case .calories: return "flame.fill"
            }
        }
        
        var unit: String {
            switch self {
            case .steps: return ""
            case .heartRate: return " bpm"
            case .sleep: return " hrs"
            case .calories: return " kcal"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                if !healthManager.isAuthorized {
                    permissionView
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            header
                            
                            metricsGrid
                            
                            detailedMetricView
                            
                            weeklyChart
                        }
                        .padding(.horizontal, 22)
                        .padding(.vertical, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Health Stats")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if healthManager.isAuthorized {
                    healthManager.loadHealthData()
                }
            }
            .sheet(isPresented: $showPermissionSheet) {
                HealthKitPermissionView()
            }
        }
    }
    
    private var permissionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.8))
            
            Text("Connect Health Data")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
            
            Text("Sync with Apple Health and your Apple Watch to track your health metrics automatically.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showPermissionSheet = true
            } label: {
                HStack {
                    Image(systemName: "applewatch")
                    Text("Connect Apple Health")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
            }
            .padding(.horizontal, 40)
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(DateFormatter.dayFormatter.string(from: Date()))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            MetricCard(
                type: .steps,
                value: "\(healthManager.healthData.steps)",
                subtitle: "steps today",
                colors: [.cyan.opacity(0.8), .blue.opacity(0.8)]
            )
            
            MetricCard(
                type: .heartRate,
                value: healthManager.healthData.heartRate > 0 ? "\(healthManager.healthData.heartRate)" : "--",
                subtitle: "bpm",
                colors: [.red.opacity(0.8), .pink.opacity(0.8)]
            )
            
            MetricCard(
                type: .sleep,
                value: healthManager.healthData.sleepHours > 0 ? String(format: "%.1f", healthManager.healthData.sleepHours) : "--",
                subtitle: "hours",
                colors: [.indigo.opacity(0.8), .purple.opacity(0.8)]
            )
            
            MetricCard(
                type: .calories,
                value: "\(healthManager.healthData.activeCalories)",
                subtitle: "kcal burned",
                colors: [.orange.opacity(0.8), .yellow.opacity(0.8)]
            )
        }
    }
    
    private var detailedMetricView: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: selectedMetric.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                    Text(selectedMetric.rawValue)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                
                Text(getMetricValue(for: selectedMetric))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(getMetricDescription(for: selectedMetric))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }
    
    private var weeklyChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Last 7 Days")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                // Simplified chart (would use Charts framework in production)
                GeometryReader { geo in
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(0..<7) { day in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: (geo.size.width - 48) / 7, height: geo.size.height * CGFloat.random(in: 0.3...1.0))
                        }
                    }
                }
                .frame(height: 120)
            }
        }
    }
    
    private func getMetricValue(for metric: MetricType) -> String {
        switch metric {
        case .steps:
            return "\(healthManager.healthData.steps)\(metric.unit)"
        case .heartRate:
            return healthManager.healthData.heartRate > 0 ? "\(healthManager.healthData.heartRate)\(metric.unit)" : "--"
        case .sleep:
            return healthManager.healthData.sleepHours > 0 ? String(format: "%.1f%@", healthManager.healthData.sleepHours, metric.unit) : "--"
        case .calories:
            return "\(healthManager.healthData.activeCalories)\(metric.unit)"
        }
    }
    
    private func getMetricDescription(for metric: MetricType) -> String {
        switch metric {
        case .steps:
            return "Keep moving! Aim for 10,000 steps daily."
        case .heartRate:
            return "Your heart rate is being tracked by your Apple Watch."
        case .sleep:
            return "Aim for 7-9 hours of quality sleep."
        case .calories:
            return "Active calories burned through exercise and movement."
        }
    }
}

struct MetricCard: View {
    let type: HealthStatsView.MetricType
    let value: String
    let subtitle: String
    let colors: [Color]
    
    var body: some View {
        GlassCard(expand: false) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.2),
                in: RoundedRectangle(cornerRadius: 20)
            )
        }
    }
}

struct HealthKitPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthManager: HealthKitManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text("Enable Health Data")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        PermissionRow(icon: "figure.walk", text: "Steps and distance")
                        PermissionRow(icon: "heart.fill", text: "Heart rate")
                        PermissionRow(icon: "bed.double.fill", text: "Sleep analysis")
                        PermissionRow(icon: "flame.fill", text: "Active calories")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal, 40)
                    
                    Text("Your health data stays on your device and is only used to provide personalized health insights in Preventa Pulse conversations.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button {
                        print("🔵 UI: Authorize Health Data button tapped in HealthStatsView")
                        Task { @MainActor in
                            let authorized = await healthManager.requestAuthorization()
                            print("🔵 UI: Authorization result: \(authorized)")
                            
                            // Update authorization status manually
                            healthManager.checkAuthorizationStatus()
                            
                            if authorized {
                                Hx.ok()
                                // Small delay to ensure state is updated
                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                dismiss()
                            } else {
                                // Still try to load data and dismiss - user might have granted access
                                healthManager.loadHealthData()
                                try? await Task.sleep(nanoseconds: 100_000_000)
                                Hx.warn()
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Authorize Health Data")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                    }
                    .padding(.horizontal, 40)
                }
            }
            .navigationTitle("Health Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
    }
}

extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
}

#Preview {
    HealthStatsView()
}

