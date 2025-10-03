import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit

// MARK: - HOME

struct HomeView: View {
    @StateObject private var vm = HomeVM()
    @State private var showSignOutAlert = false
    @State private var path = NavigationPath()
    @Environment(\.dismiss) private var dismiss

    // ✅ Make sure Learn gets its dependencies


    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {

                        HeaderGreeting(name: vm.displayFirstName, dateString: vm.todayString)
                            .padding(.horizontal, 22)
                            .padding(.top, 8)

                        // preventa pulse is my centerpiece; start chat goes to pulsechatview
                        PreventaPulseCard(
                            headline: "Preventa Pulse",
                            subheadline: "Tell me what you’re feeling or explore the body map. I’ll ask smart follow-ups, explain the why, and suggest safe next steps.",
                            onStart: { vm.hapticSuccess(); path.append(Route.guideChat) },
                            // for now i also route body map into the chat so it actually opens something
                            onBodyMap: { vm.hapticLight(); path.append(Route.guideBodyMap) }
                        )
                        .padding(.horizontal, 22)

                        TodayCard(
                            progress: vm.todayProgress,
                            itemsDue: vm.itemsDue,
                            onOpenMeds: { vm.hapticLight(); path.append(Route.medsToday) },
                            onOpenCheckIns: { vm.hapticLight(); path.append(Route.checkIns) }
                        )
                        .padding(.horizontal, 22)

                        // quick action “pulse” also goes straight to chat
                        QuickActionsRow(
                            onPulse: { vm.hapticLight(); path.append(Route.guideChat) },
                            onMeds:  { vm.hapticLight(); path.append(Route.meds) },
                            onLearn: { vm.hapticLight(); path.append(Route.learn) },
                            onPlan:  { vm.hapticLight(); path.append(Route.plan) }
                        )
                        .padding(.horizontal, 22)

                        FeatureGrid(navigate: { route in
                            vm.hapticLight()
                            path.append(route)
                        })
                        .padding(.horizontal, 22)
                        .padding(.bottom, 30)
                    }
                }
                .refreshable { await vm.refresh() }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        Image("Preventa Shield Logo Design")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.25), lineWidth: 0.8))
                        Text("Preventa")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            vm.hapticWarning()
                            showSignOutAlert = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        Button {
                            vm.hapticLight()
                            path.append(Route.settings)
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .symbolRenderingMode(.hierarchical)
                            .contentShape(Rectangle())
                    }
                }
            }
            .alert("Sign out of Preventa?", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    vm.signOut()
                    dismiss()
                }
            } message: {
                Text("You can sign back in anytime with your email and password.")
            }
            .onAppear { vm.load() }

            // === navigation: routes that should open the ai chat now push PulseChatView()
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .guideChat:
                    PulseChatView()                 // <- go to ai chat
                case .guideBodyMap:
                    PulseChatView()                 // <- for now also open chat (no dead-end)
                case .plan:
                    StubScreen(title: "Plan")
                case .meds:
                    MedTrackerView()
                case .medsToday:
                    MedTrackerView()
                case .learn:
                    // Create a local manager so we never crash if nothing was injected above.
                    LearningHubView()
                        .environmentObject(QuizManager())
                case .visualChecks:
                    StubScreen(title: "Visuals")
                case .checkIns:
                    StubScreen(title: "Check-ins")
                case .actionPlans:
                    StubScreen(title: "Actions")
                case .resources:
                    StubScreen(title: "Resources")
                case .me:
                    StubScreen(title: "Me")
                case .settings:
                    StubScreen(title: "Settings")
                }
            }
        }
    }
}

// MARK: - Routing

enum Route: Hashable {
    case guideChat, guideBodyMap
    case plan, meds, medsToday, learn
    case visualChecks, checkIns, actionPlans
    case resources, me, settings
}

// MARK: - ViewModel

final class HomeVM: ObservableObject {
    @Published var displayFirstName: String = "there"
    @Published var todayProgress: CGFloat = 0.62
    @Published var itemsDue: Int = 2

    var todayString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: Date())
    }

    func load() { fetchFirstName() }

    @MainActor
    func refresh() async {
        try? await Task.sleep(nanoseconds: 600_000_000)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
            todayProgress = min(0.95, todayProgress + 0.04)
        }
    }

    private func fetchFirstName() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { snap, _ in
            if let first = snap?.data()?["firstName"] as? String, !first.trimmingCharacters(in: .whitespaces).isEmpty {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.displayFirstName = first.components(separatedBy: " ").first ?? first
                    }
                }
            }
        }
    }

    func signOut() { try? Auth.auth().signOut() }
    func hapticLight()   { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    func hapticWarning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    func hapticSuccess() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}

// MARK: - Components

private struct AnimatedBrandBackground: View {
    @State private var phase: CGFloat = 0
    var body: some View {
        LinearGradient(
            colors: [Color.purple.opacity(0.92), Color.blue.opacity(0.86)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay(
            AngularGradient(
                gradient: Gradient(colors: [.white.opacity(0.08), .clear, .white.opacity(0.06), .clear]),
                center: .center,
                angle: .degrees(Double(phase))
            )
        )
        .onAppear {
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                phase = 360
            }
        }
    }
}

private struct HeaderGreeting: View {
    let name: String
    let dateString: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hi \(name),")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(dateString)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PreventaPulseCard: View {
    let headline: String
    let subheadline: String
    var onStart: () -> Void
    var onBodyMap: () -> Void

    @State private var pulse = false
    @State private var glow = false

    var body: some View {
        GlassCard { // full-width defaults to expand=true
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 72, height: 72)
                        .overlay(Circle().stroke(.white.opacity(0.22)))
                        .shadow(color: .blue.opacity(glow ? 0.45 : 0.15), radius: glow ? 18 : 6, y: 6)
                        .scaleEffect(pulse ? 1.06 : 0.94)
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)
                        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: glow)

                    Image(systemName: "sparkles")
                        .foregroundStyle(.white)
                        .font(.system(size: 22, weight: .semibold))
                }
                .onAppear { pulse = true; glow = true }

                VStack(alignment: .leading, spacing: 8) {
                    Text(headline)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)

                    Text(subheadline)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        PrimaryPill(title: "Start chat",
                                    systemImage: "bubble.left.and.bubble.right.fill",
                                    action: onStart)
                        SecondaryPill(title: "Body map",
                                      systemImage: "figure.arms.open",
                                      action: onBodyMap)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct TodayCard: View {
    let progress: CGFloat
    let itemsDue: Int
    var onOpenMeds: () -> Void
    var onOpenCheckIns: () -> Void

    @State private var animate = false

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                AnimatedProgressRing(progress: progress, animate: $animate)
                    .frame(width: 78, height: 78)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Good momentum today")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)

                    Text("You’ve got \(itemsDue) item\(itemsDue == 1 ? "" : "s") due now. Keep the streak going.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        LinkChip(title: "Meds due", icon: "pills.fill", action: onOpenMeds)
                        LinkChip(title: "Check-ins", icon: "checkmark.circle.fill", action: onOpenCheckIns)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.85).delay(0.05)) {
                animate = true
            }
        }
    }
}

private struct QuickActionsRow: View {
    var onPulse: () -> Void
    var onMeds: () -> Void
    var onLearn: () -> Void
    var onPlan: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ActionPill(title: "Pulse", icon: "sparkles", action: onPulse)
            ActionPill(title: "Meds", icon: "pills.fill", action: onMeds)
            ActionPill(title: "Learn", icon: "book.closed.fill", action: onLearn)
            ActionPill(title: "Plan", icon: "target", action: onPlan)
        }
    }
}

// ===== Model used by FeatureGrid/FeatureTile =====
struct FeatureItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let gradient: [Color]
    let route: Route
    let span: Int // 1 = half width, 2 = full width
}

// === Two-column grid with explicit rows (so half items sit side-by-side) ===
private struct FeatureGrid: View {
    let navigate: (Route) -> Void

    private let items: [FeatureItem] = [
        .init(title: "Plan",       icon: "target",
              gradient: [.blue.opacity(0.75), .purple.opacity(0.7)],
              route: .plan, span: 1),
        .init(title: "Meds",       icon: "pills.fill",
              gradient: [.cyan.opacity(0.75), .blue.opacity(0.7)],
              route: .meds, span: 1),
        .init(title: "Learn",      icon: "book.closed.fill",
              gradient: [.purple.opacity(0.75), .pink.opacity(0.7)],
              route: .learn, span: 1),
        .init(title: "Visuals",    icon: "camera.viewfinder",
              gradient: [.pink.opacity(0.75), .purple.opacity(0.7)],
              route: .visualChecks, span: 1),

        // full-width tiles
        .init(title: "Check-ins",  icon: "checkmark.circle.fill",
              gradient: [.teal.opacity(0.75), .blue.opacity(0.7)],
              route: .checkIns, span: 2),
        .init(title: "Resources",  icon: "stethoscope",
              gradient: [.mint.opacity(0.75), .teal.opacity(0.7)],
              route: .resources, span: 2),

        .init(title: "Actions",    icon: "list.bullet.rectangle.portrait",
              gradient: [.indigo.opacity(0.75), .blue.opacity(0.7)],
              route: .actionPlans, span: 1),
        .init(title: "Me",         icon: "person.crop.circle",
              gradient: [.orange.opacity(0.75), .pink.opacity(0.7)],
              route: .me, span: 1)
    ]

    private var rows: [[FeatureItem]] {
        var rows: [[FeatureItem]] = []
        var buffer: FeatureItem? = nil
        for item in items {
            if item.span == 2 {
                if let b = buffer { rows.append([b]); buffer = nil }
                rows.append([item])
            } else {
                if let b = buffer {
                    rows.append([b, item]); buffer = nil
                } else {
                    buffer = item
                }
            }
        }
        if let b = buffer { rows.append([b]) }
        return rows
    }

    var body: some View {
        Grid(horizontalSpacing: 14, verticalSpacing: 14) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    if row.count == 1 {
                        FeatureTile(item: row[0])
                            .onTapGesture { navigate(row[0].route) }
                            .gridCellColumns(row[0].span)
                    } else {
                        FeatureTile(item: row[0])
                            .onTapGesture { navigate(row[0].route) }
                        FeatureTile(item: row[1])
                            .onTapGesture { navigate(row[1].route) }
                    }
                }
            }
        }
    }
}

// feature card
private struct FeatureTile: View {
    let item: FeatureItem
    @State private var hover = false

    var body: some View {
        GlassCard(expand: false) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: item.gradient,
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.22), lineWidth: 0.6))
                        .shadow(color: .black.opacity(0.25),
                                radius: hover ? 12 : 6, y: 6)
                        .scaleEffect(hover ? 1.03 : 1.0)
                    Image(systemName: item.icon)
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
                .frame(width: 44, height: 44)

                Text(item.title)
                    .foregroundStyle(.white)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.6))
                    .font(.footnote.weight(.semibold))
                    .fixedSize()
            }
        }
        .frame(height: 104)
        .scaleEffect(hover ? 0.985 : 1.0)
        .animation(.spring(response: 0.38, dampingFraction: 0.85), value: hover)
        .onAppear { withAnimation(.easeInOut(duration: 0.45)) { hover = true } }
        .onDisappear { hover = false }
    }
}

// MARK: - Shared UI bits

private struct GlassCard<Content: View>: View {
    let expand: Bool
    let content: Content
    init(expand: Bool = true, @ViewBuilder content: () -> Content) {
        self.expand = expand
        self.content = content()
    }
    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: expand ? .infinity : nil, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1))
            .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

private struct AnimatedProgressRing: View {
    let progress: CGFloat
    @Binding var animate: Bool

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.18), lineWidth: 10)
            Circle()
                .trim(from: 0, to: animate ? max(0, min(1, progress)) : 0)
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [.blue.opacity(0.95), .purple.opacity(0.95), .blue.opacity(0.95)]),
                                    center: .center),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: animate)

            Text("\(Int(progress * 100))%")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
        }
    }
}

private struct PrimaryPill: View {
    let title: String
    let systemImage: String
    var action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { pressed = false }
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImage).imageScale(.medium)
                Text(title).font(.footnote.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                LinearGradient(colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                               startPoint: .leading, endPoint: .trailing)
                    .clipShape(Capsule())
            )
            .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 0.6))
            .shadow(color: .purple.opacity(0.18), radius: 6, y: 3)
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

private struct SecondaryPill: View {
    let title: String
    let systemImage: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage).imageScale(.medium)
                Text(title).font(.footnote.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.95))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .overlay(Capsule().stroke(.white.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct LinkChip: View {
    let title: String
    let icon: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).imageScale(.small)
                Text(title).font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(.white.opacity(0.14)))
            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.6))
        }
        .buttonStyle(.plain)
    }
}

private struct ActionPill: View {
    let title: String
    let icon: String
    var action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { pressed = false }
            action()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.22), lineWidth: 0.6))
                    Image(systemName: icon)
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
                .frame(height: 42)
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.18), lineWidth: 1))
            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

private struct StubScreen: View {
    let title: String
    var body: some View {
        ZStack {
            AnimatedBrandBackground().ignoresSafeArea()
            Text(title)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

#Preview { HomeView() }
