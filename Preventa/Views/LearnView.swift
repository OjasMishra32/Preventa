import SwiftUI

// MARK: - Data Models
struct Question: Identifiable {
    let id = UUID()
    let text: String
    let options: [String]
    let answer: String
    let explanation: String
    let hint: String?
}
struct Quiz: Identifiable {
    let id = UUID()
    let title: String
    let topic: String
    let questions: [Question]
}
struct QuizLevel: Identifiable {
    let id = UUID()
    let level: Int
    let questions: [Question]
}
struct QuizCategory: Identifiable {
    let id = UUID()
    let title: String
    let topic: String
    let levels: [QuizLevel]
}



// MARK: - Topic Themes
struct TopicTheme {
    let colors: [Color]
    let icon: String
}

// Fallback app theme
let appGradient = [Color.purple.opacity(0.9), Color.blue.opacity(0.8)]

let topicThemes: [String: TopicTheme] = [
    "First Aid": TopicTheme(
        colors: [Color.red.opacity(0.9), Color.orange.opacity(0.8)],
        icon: "cross.case.fill"
    ),
    "Immune System": TopicTheme(
        colors: [Color.teal.opacity(0.9), Color.green.opacity(0.8)],
        icon: "shield.checkerboard"
    ),
    "Mental Health": TopicTheme(
        colors: [Color.purple.opacity(0.9), Color.pink.opacity(0.85)],
        icon: "brain.head.profile"
    ),
    "Fitness": TopicTheme(
        colors: [Color.blue.opacity(0.9), Color.green.opacity(0.8)],
        icon: "figure.strengthtraining.traditional"
    ),
    "Cardiac Arrest": TopicTheme(
        colors: [Color.red.opacity(0.95), Color.pink.opacity(0.85)],
        icon: "heart.fill"
    ),
    "Headaches": TopicTheme(
        colors: [Color.orange.opacity(0.9), Color.yellow.opacity(0.75)],
        icon: "bolt.fill"
    ),
    "Nutrition": TopicTheme(
        colors: [Color.green.opacity(0.9), Color.mint.opacity(0.8)],
        icon: "fork.knife.circle.fill"
    ),
    "Sleep": TopicTheme(
        colors: [Color.indigo.opacity(0.9), Color.blue.opacity(0.8)],
        icon: "moon.stars.fill"
    ),
    "Diabetes": TopicTheme(
        colors: [Color.cyan.opacity(0.9), Color.blue.opacity(0.8)],
        icon: "drop.fill"
    ),
    "Blood Pressure": TopicTheme(
        colors: [Color.pink.opacity(0.9), Color.red.opacity(0.85)],
        icon: "waveform.path.ecg"
    )
]

// MARK: - Background Particles (safe)
struct BackgroundParticles: View {
    let colors: [Color]
    @State private var t: CGFloat = 0

    private var coreColor: Color { colors.first ?? .white }

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                let time = context.date.timeIntervalSinceReferenceDate
                let w = size.width, h = size.height
                for i in 0..<18 {
                    let speed = Double(20 + (i % 5) * 10)
                    let x = sin((time + Double(i)) / speed) * w * 0.3 + w * 0.5
                    let y = cos((time + Double(i)) / speed) * h * 0.25 + h * 0.5
                    let r = CGFloat(30 + (i % 6) * 8)
                    let rect = CGRect(x: x - Double(r/2), y: y - Double(r/2), width: Double(r), height: Double(r))
                    let path = Path(ellipseIn: rect)
                    ctx.fill(path, with: .radialGradient(
                        Gradient(colors: [coreColor.opacity(0.12), .clear]),
                        center: CGPoint(x: x, y: y),
                        startRadius: 2,
                        endRadius: r
                    ))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    var progress: CGFloat
    var thickness: CGFloat = 10
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: thickness))
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.white, .white.opacity(0.6), .white]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: thickness, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
        }
    }
}

// MARK: - Glow Button & Stat Card
struct GlowButton: View {
    let title: String
    var systemImage: String? = nil
    var gradient: [Color] = [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]
    var height: CGFloat = 52

    var body: some View {
        HStack(spacing: 10) {
            if let sys = systemImage {
                Image(systemName: sys).font(.headline.bold()).foregroundColor(.white)
            }
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(height: height)
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: (gradient.last ?? .black).opacity(0.55), radius: 14, x: 0, y: 8)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct GlowStatCard: View {
    let title: String
    let value: String
    var gradient: [Color] = [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold()).foregroundColor(.white)
            Text(title).font(.footnote.weight(.semibold)).foregroundColor(.white.opacity(0.85))
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.18), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: (gradient.last ?? .black).opacity(0.5), radius: 12, y: 6)
        )
        .padding(.horizontal, 2)
    }
}

// MARK: - Learning Hub
struct LearningHubView: View {
    @EnvironmentObject var quizManager: QuizManager

    var body: some View {
        ZStack {
            LinearGradient(colors: appGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            BackgroundParticles(colors: appGradient)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    stats
                    levelStrip
                    QuizListView(quizzes: allCategories)
                }
                .padding(.bottom, 42)
            }
        }
        .navigationTitle("Learning Hub")
        .navigationBarTitleDisplayMode(.inline)
    }


    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Empower Your Health Knowledge")
                .font(.largeTitle.bold()).foregroundColor(.white)
                .minimumScaleFactor(0.7)
            Text("Interactive health quizzes designed for your growth. Keep your streak alive and track your progress.")
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var stats: some View {
        HStack(spacing: 12) {
            GlowStatCard(title: "Courses Completed", value: "\(quizManager.completedQuizzes)")
            GlowStatCard(title: "Learning Time", value: formattedTime(quizManager.learningTime))
            GlowStatCard(title: "Streak", value: "\(quizManager.streak)")
        }
        .padding(.horizontal)
    }

    private var levelStrip: some View {
        HStack(spacing: 12) {
            ProgressRing(progress: CGFloat(min(1.0, Double(quizManager.xp) / Double(100 + (quizManager.level - 1)*25))))
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text("Level \(quizManager.level)")
                    .font(.headline).foregroundColor(.white)
                Text("XP: \(quizManager.xp) / \(100 + (quizManager.level - 1)*25)")
                    .font(.caption).foregroundColor(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.18), lineWidth: 1))
        )
        .padding(.horizontal)
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        let total = Int(time)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

// MARK: - Quiz List
struct QuizListView: View {
    let quizzes: [QuizCategory]
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Available Quizzes")
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.horizontal)
            LazyVStack(spacing: 14) {
                ForEach(quizzes) { category in
                    let theme = topicThemes[category.topic] ?? TopicTheme(colors: appGradient, icon: "questionmark.circle")
                    NavigationLink {
                        CategoryDetailView(category: category)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 48, height: 48)
                                    .shadow(color: (theme.colors.last ?? .white).opacity(0.6), radius: 10, y: 6)
                                Image(systemName: theme.icon).foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.title).font(.headline).foregroundColor(.white)
                                Text(category.topic).font(.caption).foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.9))
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.18), lineWidth: 1))
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(QuizCardButtonStyle())
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct CategoryDetailView: View {
    let category: QuizCategory

    var body: some View {
        let theme = topicThemes[category.topic] ?? TopicTheme(colors: appGradient, icon: "questionmark.circle")

        ZStack {
            LinearGradient(colors: theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            BackgroundParticles(colors: theme.colors)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header(theme: theme)

                    ForEach(category.levels.sorted(by: { $0.level < $1.level }), id: \.id) { level in
                        NavigationLink {
                            QuizDetailView(category: category, level: level)
                        } label: {
                            levelRow(theme: theme, level: level)
                        }
                        .buttonStyle(QuizCardButtonStyle())
                        .padding(.horizontal)
                    }
                    Spacer(minLength: 20)
                }
                .padding(.vertical, 20)
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(theme: TopicTheme) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                    .shadow(color: (theme.colors.last ?? .black).opacity(0.6), radius: 10, y: 6)
                Image(systemName: theme.icon).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(category.title).font(.title2.bold()).foregroundColor(.white)
                Text(category.topic).font(.caption).foregroundColor(.white.opacity(0.9))
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private func levelRow(theme: TopicTheme, level: QuizLevel) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 54, height: 54)
                    .shadow(color: (theme.colors.last ?? .black).opacity(0.5), radius: 8, y: 4)
                Text("\(level.level)")
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Level \(level.level)")
                    .font(.headline).foregroundColor(.white)
                Text("\(level.questions.count) questions")
                    .font(.caption).foregroundColor(.white.opacity(0.85))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.9))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.18), lineWidth: 1))
        )
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct QuizCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.0 : 0.25), radius: 8, y: 4)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Quiz Detail (uses questions from selected level)
struct QuizDetailView: View {
    @EnvironmentObject var quizManager: QuizManager
    @Environment(\.dismiss) var dismiss
    let category: QuizCategory
    let level: QuizLevel

    @State private var current = 0
    @State private var selected: String?
    @State private var reveal = false
    @State private var correctCount = 0
    @State private var completed = false
    @State private var showConfetti = false
    @State private var showHint = false
    @Namespace private var questionNS

    private var questions: [Question] { level.questions }
    private var hasQuestions: Bool { !questions.isEmpty }
    private var currentProgress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(current + 1) / Double(questions.count)
    }

    var body: some View {
        let theme = topicThemes[category.topic] ?? TopicTheme(colors: appGradient, icon: "questionmark.circle")

        ZStack {
            LinearGradient(colors: theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            BackgroundParticles(colors: theme.colors)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 22) {
                    header(theme: theme)

                    if !hasQuestions {
                        emptyState(theme: theme)
                    } else if !completed {
                        questionCard
                            .matchedGeometryEffect(id: "q-\(current)", in: questionNS)
                        answersStack(theme: theme)
                        feedbackAndControls(theme: theme)
                        progressSection
                    } else {
                        completionView(theme: theme)
                    }
                }
                .padding(.vertical, 18)
                .padding(.bottom, 24)
            }
        }
        .onAppear { quizManager.startSession() }
        .onDisappear { quizManager.endSession() }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(theme: TopicTheme) -> some View {
        HStack(spacing: 14) {
            ZStack {
                ProgressRing(progress: CGFloat(currentProgress))
                    .frame(width: 48, height: 48)
                Image(systemName: theme.icon).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(category.title).font(.headline).foregroundColor(.white)
                Text(category.topic).font(.caption).foregroundColor(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private func emptyState(theme: TopicTheme) -> some View {
        VStack(spacing: 12) {
            Text("No questions found")
                .font(.title3.bold()).foregroundColor(.white)
            Text("This level doesn’t have any questions yet.")
                .foregroundColor(.white.opacity(0.9))
            Button { dismiss() } label: {
                GlowButton(title: "Back", systemImage: "arrow.uturn.left.circle.fill", gradient: theme.colors, height: 50)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.18), lineWidth: 1))
        )
        .padding(.horizontal)
    }

    private var questionCard: some View {
        VStack(spacing: 8) {
            Text("Question \(current + 1) of \(questions.count)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.8))
            if questions.indices.contains(current) {
                Text(questions[current].text)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.18), lineWidth: 1))
        )
        .padding(.horizontal)
        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))))
        .animation(.easeInOut(duration: 0.45), value: current)
    }

    private func answersStack(theme: TopicTheme) -> some View {
        VStack(spacing: 12) {
            if questions.indices.contains(current) {
                ForEach(questions[current].options, id: \.self) { opt in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if selected == nil {
                                selected = opt
                                reveal = true
                                if opt == questions[current].answer {
                                    correctCount += 1
                                    quizManager.recordCorrectAnswer()
                                }
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(borderColor(for: opt), lineWidth: reveal ? 2 : 1)
                                        .shadow(color: borderColor(for: opt).opacity(reveal ? 0.6 : 0.0), radius: reveal ? 10 : 0, y: 6)
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(LinearGradient(colors: glossyTint(for: opt),
                                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .opacity(reveal ? 0.18 : 0.08)
                                )

                            HStack {
                                Text(opt)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if reveal && opt == questions[current].answer {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                        .opacity(0.9)
                                        .transition(.scale.combined(with: .opacity))
                                } else if reveal && selected == opt && opt != questions[current].answer {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.9))
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AnswerButtonStyle(isPressedScale: 0.98))
                    .padding(.horizontal)
                    .disabled(reveal)
                }
            }
        }
    }

    private func borderColor(for option: String) -> Color {
        guard reveal, questions.indices.contains(current) else { return Color.white.opacity(0.25) }
        if option == questions[current].answer { return .white }
        if selected == option { return .white.opacity(0.55) }
        return Color.white.opacity(0.20)
    }

    private func glossyTint(for option: String) -> [Color] {
        guard reveal, questions.indices.contains(current) else { return [Color.white.opacity(0.22), Color.white.opacity(0.05)] }
        if option == questions[current].answer {
            return [Color.white.opacity(0.40), Color.white.opacity(0.10)]
        } else if selected == option {
            return [Color.white.opacity(0.28), Color.white.opacity(0.08)]
        }
        return [Color.white.opacity(0.20), Color.white.opacity(0.06)]
    }

    private func feedbackAndControls(theme: TopicTheme) -> some View {
        VStack(spacing: 14) {
            if reveal, questions.indices.contains(current) {
                VStack(spacing: 8) {
                    let isCorrect = selected == questions[current].answer
                    Text(isCorrect ? "Correct" : "Incorrect")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .transition(.opacity)

                    DisclosureGroup(isCorrect ? "Why this is correct" : "What to learn from this") {
                        Text(questions[current].explanation)
                            .foregroundColor(.white.opacity(0.92))
                            .font(.subheadline)
                            .padding(.top, 6)
                    }
                    .tint(.white)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.18), lineWidth: 1))
                    )
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            goNext(theme: theme)
                        }
                    } label: {
                        GlowButton(
                            title: current < max(0, questions.count - 1) ? "Next Question" : "Finish Quiz",
                            systemImage: "arrow.right.circle.fill",
                            gradient: theme.colors,
                            height: 54
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                .animation(.easeInOut, value: reveal)
            } else {
                HStack(spacing: 12) {
                    if questions.indices.contains(current), let hint = questions[current].hint {
                        Button {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showHint.toggle()
                                if showHint { quizManager.recordHintUsed() }
                            }
                        } label: {
                            GlowButton(
                                title: showHint ? "Hide Hint" : "Show Hint",
                                systemImage: "lightbulb.fill",
                                gradient: [Color.white.opacity(0.35), Color.white.opacity(0.15)],
                                height: 46
                            )
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal)

                if showHint, questions.indices.contains(current), let hint = questions[current].hint {
                    Text(hint)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.92))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.18), lineWidth: 1))
                        )
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(min(current + 1, max(1, questions.count))), total: Double(max(1, questions.count)))
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .scaleEffect(x: 1, y: 1.6, anchor: .center)
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.5), value: current)

            Text("\(Int(currentProgress * 100))% complete")
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.top, 4)
    }

    private func goNext(theme: TopicTheme) {
        guard !questions.isEmpty else { return }
        if current < questions.count - 1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                current += 1
                selected = nil
                reveal = false
                showHint = false
            }
        } else {
            quizManager.completeQuiz(title: category.title)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                completed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.8)) { showConfetti = true }
            }
        }
    }

    // Final results card after finishing a level
    private func completionView(theme: TopicTheme) -> some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                VStack(spacing: 10) {
                    Text("Level Complete!")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("You answered \(correctCount) out of \(questions.count) correctly.")
                        .foregroundColor(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                    ProgressRing(progress: CGFloat(Double(correctCount) / max(1, Double(questions.count))))
                        .frame(width: 72, height: 72)
                        .padding(.top, 6)
                }
                .padding(20)
            }
            .padding(.horizontal)

            if showConfetti {
                ConfettiView()
                    .frame(height: 120)
                    .transition(.opacity)
            }

            VStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        current = 0
                        selected = nil
                        reveal = false
                        completed = false
                        showHint = false
                        correctCount = 0
                        showConfetti = false
                    }
                } label: {
                    GlowButton(
                        title: "Retake Level",
                        systemImage: "arrow.counterclockwise.circle.fill",
                        gradient: theme.colors,
                        height: 54
                    )
                }

                Button { dismiss() } label: {
                    GlowButton(
                        title: "Back to Levels",
                        systemImage: "list.bullet.circle.fill",
                        gradient: [Color.white.opacity(0.35), Color.white.opacity(0.18)],
                        height: 50
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Answer button press style
struct AnswerButtonStyle: ButtonStyle {
    let isPressedScale: CGFloat
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? isPressedScale : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

// MARK: - Confetti
struct ConfettiView: View {
    @State private var anim: Bool = false
    private let colors: [Color] = [.white.opacity(0.9), .yellow, .orange, .pink, .mint, .cyan]
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<36, id: \.self) { i in
                    let size = CGFloat(Int.random(in: 6...12))
                    Circle()
                        .fill(colors.randomElement() ?? .white)
                        .frame(width: size, height: size)
                        .position(x: CGFloat.random(in: 0...geo.size.width),
                                  y: anim ? geo.size.height + 30 : -30)
                        .rotationEffect(.degrees(anim ? Double.random(in: 180...720) : 0))
                        .animation(.interpolatingSpring(stiffness: 18, damping: 6).delay(Double(i) * 0.02), value: anim)
                }
            }
            .onAppear { anim = true }
        }
        .allowsHitTesting(false)
    }
}

let firstAidCategory = QuizCategory(
    title: "First Aid",
    topic: "First Aid",
    levels: [
        // Level 1: Basics
        QuizLevel(level: 1, questions: [
            Question(text: "What is the first thing to do when you see someone injured?",
                     options: ["Check the scene for safety", "Call a friend", "Run away", "Move the person immediately"],
                     answer: "Check the scene for safety",
                     explanation: "Always make sure the environment is safe before providing help.",
                     hint: "Safety first before helping."),
            Question(text: "What number should you call in the US for emergency help?",
                     options: ["911", "411", "311", "611"],
                     answer: "911",
                     explanation: "Dial 911 for any life-threatening emergencies.",
                     hint: "Think emergency response."),
            Question(text: "If someone is bleeding, what is the first step?",
                     options: ["Apply direct pressure", "Wash with cold water", "Put on a band-aid", "Elevate legs"],
                     answer: "Apply direct pressure",
                     explanation: "Direct pressure helps stop bleeding quickly.",
                     hint: "How to slow blood loss?"),
            Question(text: "How long should you wash a minor wound with clean water?",
                     options: ["At least 5 minutes", "30 seconds", "10 minutes", "Until it looks clean"],
                     answer: "At least 5 minutes",
                     explanation: "Flushing with water removes debris and bacteria.",
                     hint: "Long enough to clean bacteria."),
            Question(text: "Which of these items should be in a first aid kit?",
                     options: ["Bandages", "Flashlight", "Sunscreen", "Umbrella"],
                     answer: "Bandages",
                     explanation: "Bandages are essential for covering wounds.",
                     hint: "Used to cover injuries.")
        ]),
        
        // Level 2: Intermediate
        QuizLevel(level: 2, questions: [
            Question(text: "What should you do if someone faints?",
                     options: ["Lay them flat and elevate legs", "Give them water immediately", "Make them run", "Ignore it"],
                     answer: "Lay them flat and elevate legs",
                     explanation: "This improves blood flow to the brain.",
                     hint: "Think circulation."),
            Question(text: "When treating a burn, what should you apply?",
                     options: ["Cool running water", "Ice directly", "Butter", "Oil"],
                     answer: "Cool running water",
                     explanation: "Cold water helps reduce damage; never use ice or butter.",
                     hint: "Cooling helps."),
            Question(text: "How do you help someone choking?",
                     options: ["Perform abdominal thrusts", "Give them water", "Lay them down", "Shake them"],
                     answer: "Perform abdominal thrusts",
                     explanation: "The Heimlich maneuver forces air out to dislodge the blockage.",
                     hint: "Classic maneuver."),
            Question(text: "Which sign indicates a possible fracture?",
                     options: ["Swelling and deformity", "Sneezing", "Itching", "Coughing"],
                     answer: "Swelling and deformity",
                     explanation: "These are common indicators of broken bones.",
                     hint: "Think bone injuries."),
            Question(text: "What is the recovery position used for?",
                     options: ["Unconscious breathing person", "Broken arm", "Burn injury", "Minor cut"],
                     answer: "Unconscious breathing person",
                     explanation: "It keeps the airway clear and prevents choking.",
                     hint: "Airway management.")
        ]),
        
        // Level 3: Advanced
        QuizLevel(level: 3, questions: [
            Question(text: "How do you treat a nosebleed?",
                     options: ["Lean forward and pinch nose", "Lean back and pinch nose", "Lay flat on the ground", "Put cotton deep inside"],
                     answer: "Lean forward and pinch nose",
                     explanation: "Leaning forward prevents blood from flowing into the throat.",
                     hint: "Position matters."),
            Question(text: "What should you NOT do for a snake bite?",
                     options: ["Try to suck out venom", "Keep victim calm", "Immobilize limb", "Call emergency services"],
                     answer: "Try to suck out venom",
                     explanation: "This is ineffective and may cause more harm.",
                     hint: "Avoid myths."),
            Question(text: "What should you check first if someone collapses?",
                     options: ["Responsiveness and breathing", "Their pockets", "Their temperature", "Their ID"],
                     answer: "Responsiveness and breathing",
                     explanation: "Always check consciousness and breathing first.",
                     hint: "Airway and breathing."),
            Question(text: "When performing CPR on an adult, the ratio of compressions to breaths is:",
                     options: ["30:2", "15:2", "20:5", "10:1"],
                     answer: "30:2",
                     explanation: "Perform 30 chest compressions followed by 2 rescue breaths.",
                     hint: "Standard CPR ratio."),
            Question(text: "Where should an epinephrine auto-injector be given?",
                     options: ["Outer thigh", "Arm vein", "Shoulder", "Chest"],
                     answer: "Outer thigh",
                     explanation: "Injecting into the outer thigh allows fast absorption.",
                     hint: "Muscle site.")
        ]),
        
        // Level 4: Expert
        QuizLevel(level: 4, questions: [
            Question(text: "What is the golden hour in trauma care?",
                     options: ["First 60 minutes after injury", "First 10 minutes after CPR", "First 24 hours", "First week"],
                     answer: "First 60 minutes after injury",
                     explanation: "The first hour is critical for survival after major trauma.",
                     hint: "Critical time."),
            Question(text: "How should you treat hypothermia?",
                     options: ["Warm gradually with blankets", "Give alcohol", "Rub the skin harshly", "Put in hot water"],
                     answer: "Warm gradually with blankets",
                     explanation: "Gradual warming prevents shock and arrhythmia.",
                     hint: "Slow warming."),
            Question(text: "What should you do for an amputated finger?",
                     options: ["Wrap it in moist gauze and cool it", "Wash it in hot water", "Throw it away", "Freeze it directly"],
                     answer: "Wrap it in moist gauze and cool it",
                     explanation: "Proper storage increases the chance of reattachment.",
                     hint: "Preserve tissue."),
            Question(text: "How often should you replace a first aid kit’s contents?",
                     options: ["Every 6–12 months", "Every 5 years", "Never", "Only after an emergency"],
                     answer: "Every 6–12 months",
                     explanation: "Medicines and supplies expire and need to be updated.",
                     hint: "Supplies expire."),
            Question(text: "What is the first step in using an AED?",
                     options: ["Turn it on", "Attach pads", "Shock immediately", "Check pulse"],
                     answer: "Turn it on",
                     explanation: "Turning it on provides step-by-step instructions.",
                     hint: "Start device first.")
        ]),
        
        // Level 5: Mastery
        QuizLevel(level: 5, questions: [
            Question(text: "Which type of bleeding is most life-threatening?",
                     options: ["Arterial", "Venous", "Capillary", "Nosebleed"],
                     answer: "Arterial",
                     explanation: "Arterial bleeding is bright red and spurts with heartbeats.",
                     hint: "Think high pressure."),
            Question(text: "What is the universal sign of choking?",
                     options: ["Hands clutching throat", "Coughing", "Wheezing", "Holding chest"],
                     answer: "Hands clutching throat",
                     explanation: "This gesture is recognized worldwide as choking.",
                     hint: "Widely known signal."),
            Question(text: "When applying a tourniquet, where should it be placed?",
                     options: ["Above the bleeding site", "Below the wound", "On the wound", "Near the heart"],
                     answer: "Above the bleeding site",
                     explanation: "Always apply above the injury to stop blood flow.",
                     hint: "Placement is key."),
            Question(text: "What is the first priority when treating a burn victim?",
                     options: ["Stop the burning process", "Apply ointment", "Cover with bandages", "Give them fluids"],
                     answer: "Stop the burning process",
                     explanation: "Ensuring the burn source is removed prevents further injury.",
                     hint: "Eliminate heat source."),
            Question(text: "What does FAST stand for in stroke recognition?",
                     options: ["Face, Arms, Speech, Time", "Feet, Airway, Speed, Treatment", "First Aid Safety Test", "Face, Air, Sugar, Temperature"],
                     answer: "Face, Arms, Speech, Time",
                     explanation: "FAST is a quick way to recognize stroke symptoms.",
                     hint: "Acronym for stroke signs.")
        ])
    ]
)
let immunityCategory = QuizCategory(
    title: "Boosting Immunity",
    topic: "Immune System",
    levels: [
        // Level 1: Basics
        QuizLevel(level: 1, questions: [
            Question(
                text: "Which vitamin supports immunity?",
                options: ["Vitamin C", "Vitamin A", "Vitamin K", "Vitamin E"],
                answer: "Vitamin C",
                explanation: "Vitamin C strengthens the immune system by boosting white blood cell activity.",
                hint: "It’s commonly found in oranges."
            ),
            Question(
                text: "The immune system’s first line of defense is:",
                options: ["Skin", "Lungs", "Stomach acid", "Brain"],
                answer: "Skin",
                explanation: "The skin acts as a physical barrier that blocks pathogens.",
                hint: "It’s your body’s outermost barrier."
            ),
            Question(
                text: "White blood cells primarily fight:",
                options: ["Infections", "Bones", "Muscles", "Oxygen"],
                answer: "Infections",
                explanation: "WBCs attack bacteria, viruses, and other harmful invaders.",
                hint: "Think bacteria and viruses."
            ),
            Question(
                text: "Vaccines work by:",
                options: ["Training immunity", "Killing bacteria", "Providing antibiotics", "Reducing fever"],
                answer: "Training immunity",
                explanation: "Vaccines train the immune system to recognize and fight threats.",
                hint: "They prepare your body ahead of time."
            ),
            Question(
                text: "Which lifestyle habit strengthens immunity?",
                options: ["Exercise", "Smoking", "Dehydration", "Skipping sleep"],
                answer: "Exercise",
                explanation: "Regular exercise enhances immune system function.",
                hint: "It involves physical activity."
            )
        ]),
        
        // Level 2: Intermediate
        QuizLevel(level: 2, questions: [
            Question(
                text: "Which organ produces immune cells called T-cells?",
                options: ["Thymus", "Heart", "Liver", "Kidneys"],
                answer: "Thymus",
                explanation: "The thymus gland is where T-cells mature.",
                hint: "It’s located in the chest behind the sternum."
            ),
            Question(
                text: "Which immune cells produce antibodies?",
                options: ["B-cells", "T-cells", "Neutrophils", "Macrophages"],
                answer: "B-cells",
                explanation: "B-cells are responsible for producing antibodies.",
                hint: "They start with the letter B."
            ),
            Question(
                text: "What is innate immunity?",
                options: ["Natural defenses present at birth", "Immunity from vaccines", "Transfer of antibodies", "Artificial drugs"],
                answer: "Natural defenses present at birth",
                explanation: "Innate immunity includes barriers and non-specific immune responses.",
                hint: "It’s the immunity you’re born with."
            ),
            Question(
                text: "Which mineral is essential for immune function?",
                options: ["Zinc", "Sodium", "Chlorine", "Magnesium"],
                answer: "Zinc",
                explanation: "Zinc supports immune enzymes and cell signaling.",
                hint: "It’s also used in sunscreen."
            ),
            Question(
                text: "Which type of immunity comes from recovering from an illness?",
                options: ["Active acquired immunity", "Passive immunity", "Innate immunity", "Genetic immunity"],
                answer: "Active acquired immunity",
                explanation: "Active acquired immunity develops after exposure to a pathogen.",
                hint: "You develop it after fighting off a disease."
            )
        ]),
        
        // Level 3: Advanced
        QuizLevel(level: 3, questions: [
            Question(
                text: "Autoimmune diseases occur when:",
                options: ["The immune system attacks its own body", "The immune system is too weak", "Pathogens mutate too fast", "Antibodies fail to bind"],
                answer: "The immune system attacks its own body",
                explanation: "Autoimmune disorders result from mistaken immune attacks on healthy tissue.",
                hint: "It’s when your body turns against itself."
            ),
            Question(
                text: "Which immune cells are known as 'big eaters'?",
                options: ["Macrophages", "B-cells", "T-cells", "Neutrophils"],
                answer: "Macrophages",
                explanation: "Macrophages engulf and destroy pathogens and debris.",
                hint: "Their name literally means 'big eaters.'"
            ),
            Question(
                text: "Which part of the body houses 70% of immune cells?",
                options: ["Gut", "Brain", "Skin", "Lungs"],
                answer: "Gut",
                explanation: "The gut microbiome is central to immune regulation.",
                hint: "It’s in your digestive system."
            ),
            Question(
                text: "Which organ filters blood and helps fight infections?",
                options: ["Spleen", "Pancreas", "Liver", "Appendix"],
                answer: "Spleen",
                explanation: "The spleen filters pathogens and old blood cells.",
                hint: "It’s located in the upper left abdomen."
            ),
            Question(
                text: "Which type of T-cell directly kills infected cells?",
                options: ["Cytotoxic T-cells", "Helper T-cells", "Memory T-cells", "Suppressor T-cells"],
                answer: "Cytotoxic T-cells",
                explanation: "Cytotoxic T-cells target and destroy infected host cells.",
                hint: "They’re also called killer T-cells."
            )
        ]),
        
        // Level 4: Expert
        QuizLevel(level: 4, questions: [
            Question(
                text: "What does immunodeficiency mean?",
                options: ["Weakened immune system", "Overactive immune system", "Genetic immunity", "No white blood cells"],
                answer: "Weakened immune system",
                explanation: "Immunodeficiency reduces the body’s ability to fight infections.",
                hint: "It’s the opposite of strong immunity."
            ),
            Question(
                text: "Which virus attacks immune cells directly?",
                options: ["HIV", "Influenza", "Hepatitis", "Herpes"],
                answer: "HIV",
                explanation: "HIV targets CD4 T-cells, weakening the immune system.",
                hint: "It causes AIDS."
            ),
            Question(
                text: "Which type of immunity is provided by breast milk?",
                options: ["Passive immunity", "Active immunity", "Innate immunity", "Artificial immunity"],
                answer: "Passive immunity",
                explanation: "Breast milk transfers maternal antibodies to infants.",
                hint: "The baby 'borrows' it."
            ),
            Question(
                text: "What are cytokines?",
                options: ["Immune signaling proteins", "Antibiotics", "Viruses", "Hormones"],
                answer: "Immune signaling proteins",
                explanation: "Cytokines regulate immune communication and responses.",
                hint: "They’re chemical messengers."
            ),
            Question(
                text: "Which immune disorder is caused by histamine overreaction?",
                options: ["Allergies", "Diabetes", "Arthritis", "Hypertension"],
                answer: "Allergies",
                explanation: "Allergies result from immune overreactions involving histamine release.",
                hint: "It’s common in springtime."
            )
        ]),
        
        // Level 5: Mastery
        QuizLevel(level: 5, questions: [
            Question(
                text: "Which vaccine type uses weakened pathogens?",
                options: ["Live attenuated vaccine", "Inactivated vaccine", "DNA vaccine", "Subunit vaccine"],
                answer: "Live attenuated vaccine",
                explanation: "Live attenuated vaccines contain weakened versions of pathogens.",
                hint: "It’s a live but weakened form."
            ),
            Question(
                text: "Which cells provide long-term immunity after infection?",
                options: ["Memory cells", "Neutrophils", "Macrophages", "Basophils"],
                answer: "Memory cells",
                explanation: "Memory B and T cells store information to fight future infections.",
                hint: "They help you remember the pathogen."
            ),
            Question(
                text: "What is herd immunity?",
                options: ["Community-wide protection when many are immune", "Natural immunity at birth", "Genetic resistance", "Resistance through exercise"],
                answer: "Community-wide protection when many are immune",
                explanation: "Herd immunity protects populations when enough people are immune.",
                hint: "It protects the whole group."
            ),
            Question(
                text: "Which immune response is slower but highly specific?",
                options: ["Adaptive immunity", "Innate immunity", "Passive immunity", "Mechanical defense"],
                answer: "Adaptive immunity",
                explanation: "Adaptive immunity develops slowly but targets pathogens with precision.",
                hint: "It adapts to specific invaders."
            ),
            Question(
                text: "Which therapy uses engineered antibodies to fight disease?",
                options: ["Monoclonal antibody therapy", "Chemotherapy", "Hormone therapy", "Stem cell therapy"],
                answer: "Monoclonal antibody therapy",
                explanation: "Monoclonal antibodies are lab-engineered proteins that target specific pathogens or cells.",
                hint: "It uses antibodies made in labs."
            )
        ])
    ]
)
let mentalHealthCategory = QuizCategory(
    title: "Mental Health",
    topic: "Mental Health",
    levels: [
        // Level 1: Basics
        QuizLevel(level: 1, questions: [
            Question(text: "Which is a common symptom of depression?",
                     options: ["Persistent sadness", "Increased energy", "Improved sleep", "Heightened appetite"],
                     answer: "Persistent sadness",
                     explanation: "Depression is often characterized by persistent sadness or loss of interest.",
                     hint: "Think of mood changes."),
            Question(text: "Which practice helps reduce anxiety?",
                     options: ["Mindfulness", "Smoking", "Isolation", "Excess caffeine"],
                     answer: "Mindfulness",
                     explanation: "Mindfulness and meditation reduce stress and anxiety.",
                     hint: "Focus on calm breathing."),
            Question(text: "Which disorder involves cycles of highs and lows?",
                     options: ["Bipolar disorder", "Depression", "Anxiety", "Schizophrenia"],
                     answer: "Bipolar disorder",
                     explanation: "Bipolar disorder cycles between manic highs and depressive lows.",
                     hint: "Think about mood swings."),
            Question(text: "PTSD often develops after:",
                     options: ["Trauma", "Exercise", "Dieting", "Dehydration"],
                     answer: "Trauma",
                     explanation: "Post-Traumatic Stress Disorder often develops after traumatic experiences.",
                     hint: "Linked to past events."),
            Question(text: "Which hormone is often called the 'stress hormone'?",
                     options: ["Cortisol", "Serotonin", "Oxytocin", "Dopamine"],
                     answer: "Cortisol",
                     explanation: "Cortisol is released during stress and regulates the body’s stress response.",
                     hint: "Produced by adrenal glands.")
        ]),
        
        // Level 2: Intermediate
        QuizLevel(level: 2, questions: [
            Question(text: "Which neurotransmitter is most linked to happiness?",
                     options: ["Serotonin", "Adrenaline", "Insulin", "Histamine"],
                     answer: "Serotonin",
                     explanation: "Serotonin plays a central role in regulating mood and happiness.",
                     hint: "Found in antidepressants."),
            Question(text: "What does CBT stand for?",
                     options: ["Cognitive Behavioral Therapy", "Chronic Behavioral Training", "Chemical Brain Therapy", "Controlled Balance Therapy"],
                     answer: "Cognitive Behavioral Therapy",
                     explanation: "CBT is a type of therapy that addresses negative thought patterns.",
                     hint: "Common therapy abbreviation."),
            Question(text: "Which disorder is associated with excessive worry?",
                     options: ["Generalized Anxiety Disorder", "Depression", "Schizophrenia", "PTSD"],
                     answer: "Generalized Anxiety Disorder",
                     explanation: "GAD is marked by chronic, excessive worry about everyday events.",
                     hint: "Worrying too much."),
            Question(text: "What is a common coping strategy for stress?",
                     options: ["Exercise", "Isolation", "Skipping meals", "Smoking"],
                     answer: "Exercise",
                     explanation: "Physical activity reduces stress and improves mood.",
                     hint: "Healthy outlet."),
            Question(text: "Which mental health issue is most common worldwide?",
                     options: ["Anxiety disorders", "Bipolar disorder", "Schizophrenia", "PTSD"],
                     answer: "Anxiety disorders",
                     explanation: "Anxiety disorders are the most common mental health conditions globally.",
                     hint: "Most people experience it.")
        ]),
        
        // Level 3: Advanced
        QuizLevel(level: 3, questions: [
            Question(text: "Which disorder is characterized by hallucinations and delusions?",
                     options: ["Schizophrenia", "Bipolar disorder", "PTSD", "Anxiety disorder"],
                     answer: "Schizophrenia",
                     explanation: "Schizophrenia is marked by distorted thinking, hallucinations, and delusions.",
                     hint: "Associated with psychosis."),
            Question(text: "Which therapy uses exposure to fears to reduce anxiety?",
                     options: ["Exposure therapy", "Group therapy", "Psychoanalysis", "Hypnosis"],
                     answer: "Exposure therapy",
                     explanation: "Exposure therapy helps patients gradually confront their fears.",
                     hint: "Facing fears."),
            Question(text: "What does ADHD stand for?",
                     options: ["Attention Deficit Hyperactivity Disorder", "Active Developmental Health Disorder", "Adaptive Delayed Hormonal Dysfunction", "Attention Delay Hormone Disorder"],
                     answer: "Attention Deficit Hyperactivity Disorder",
                     explanation: "ADHD affects focus, impulse control, and hyperactivity.",
                     hint: "Very common in children."),
            Question(text: "Which part of the brain regulates emotions?",
                     options: ["Amygdala", "Cerebellum", "Brainstem", "Thalamus"],
                     answer: "Amygdala",
                     explanation: "The amygdala plays a key role in emotional regulation.",
                     hint: "Located in limbic system."),
            Question(text: "Which disorder is linked to intrusive, repetitive thoughts and rituals?",
                     options: ["Obsessive-Compulsive Disorder", "Depression", "Bipolar disorder", "GAD"],
                     answer: "Obsessive-Compulsive Disorder",
                     explanation: "OCD involves repetitive obsessions and compulsions.",
                     hint: "Cleaning/checking rituals.")
        ]),
        
        // Level 4: Expert
        QuizLevel(level: 4, questions: [
            Question(text: "Which therapy is most effective for PTSD?",
                     options: ["Trauma-focused CBT", "Dietary changes", "Electroshock therapy", "Group exercise"],
                     answer: "Trauma-focused CBT",
                     explanation: "Trauma-focused CBT helps individuals process trauma safely.",
                     hint: "Type of cognitive therapy."),
            Question(text: "Which condition involves extreme mood swings, but less severe than bipolar disorder?",
                     options: ["Cyclothymia", "Schizophrenia", "OCD", "Depression"],
                     answer: "Cyclothymia",
                     explanation: "Cyclothymia is a milder form of bipolar disorder.",
                     hint: "Milder than bipolar."),
            Question(text: "SSRIs are a class of medication commonly used to treat:",
                     options: ["Depression", "Asthma", "Diabetes", "Arthritis"],
                     answer: "Depression",
                     explanation: "SSRIs (Selective Serotonin Reuptake Inhibitors) are commonly prescribed for depression.",
                     hint: "Type of antidepressant."),
            Question(text: "Which condition is associated with extreme fear of social situations?",
                     options: ["Social Anxiety Disorder", "PTSD", "OCD", "Cyclothymia"],
                     answer: "Social Anxiety Disorder",
                     explanation: "Social Anxiety Disorder involves intense fear of being judged or embarrassed.",
                     hint: "Fear of crowds."),
            Question(text: "What is the term for repeating harmful behaviors like cutting?",
                     options: ["Self-harm", "Addiction", "Compulsion", "Psychosis"],
                     answer: "Self-harm",
                     explanation: "Self-harm refers to intentional self-injury, often as a coping mechanism.",
                     hint: "Intentional injury.")
        ]),
        
        // Level 5: Mastery
        QuizLevel(level: 5, questions: [
            Question(text: "What is comorbidity in mental health?",
                     options: ["Presence of multiple disorders", "Treatment resistance", "Genetic inheritance", "Lack of symptoms"],
                     answer: "Presence of multiple disorders",
                     explanation: "Comorbidity refers to having more than one mental disorder at the same time.",
                     hint: "Two or more conditions."),
            Question(text: "Dialectical Behavior Therapy (DBT) was developed to treat:",
                     options: ["Borderline Personality Disorder", "ADHD", "OCD", "Schizophrenia"],
                     answer: "Borderline Personality Disorder",
                     explanation: "DBT was specifically designed for individuals with Borderline Personality Disorder.",
                     hint: "Developed by Linehan."),
            Question(text: "Which disorder involves alternating between eating too much and purging?",
                     options: ["Bulimia Nervosa", "Anorexia", "Binge Eating Disorder", "Depression"],
                     answer: "Bulimia Nervosa",
                     explanation: "Bulimia involves binge eating followed by purging to avoid weight gain.",
                     hint: "Eating disorder."),
            Question(text: "Which term describes the reduced ability to feel pleasure?",
                     options: ["Anhedonia", "Euphoria", "Hypomania", "Hyperarousal"],
                     answer: "Anhedonia",
                     explanation: "Anhedonia is the inability to feel pleasure, often linked to depression.",
                     hint: "Loss of joy."),
            Question(text: "What is the 'fight or flight' response controlled by?",
                     options: ["Sympathetic nervous system", "Parasympathetic nervous system", "Endocrine glands only", "Digestive system"],
                     answer: "Sympathetic nervous system",
                     explanation: "The sympathetic nervous system triggers the body's fight-or-flight response.",
                     hint: "Part of autonomic system.")
        ])
    ]
)
let exerciseCategory = QuizCategory(
    title: "Exercise & Fitness",
    topic: "Fitness",
    levels: [
        // Level 1: Basics
        QuizLevel(level: 1, questions: [
            Question(text: "How many minutes of moderate exercise per week are recommended?",
                     options: ["50", "100", "150", "300"],
                     answer: "150",
                     explanation: "Health guidelines recommend 150 minutes of moderate-intensity activity per week.",
                     hint: "Think in terms of weekly health guidelines."),
            Question(text: "Which of these is an example of aerobic exercise?",
                     options: ["Push-ups", "Jogging", "Bicep curls", "Bench press"],
                     answer: "Jogging",
                     explanation: "Jogging is aerobic exercise because it raises heart rate steadily.",
                     hint: "Cardio, not strength."),
            Question(text: "Which organ benefits the most directly from cardio exercise?",
                     options: ["Heart", "Liver", "Kidneys", "Stomach"],
                     answer: "Heart",
                     explanation: "Aerobic exercise strengthens the heart and improves circulation.",
                     hint: "The pump of your body."),
            Question(text: "What does stretching primarily improve?",
                     options: ["Flexibility", "Vision", "Digestion", "Skin health"],
                     answer: "Flexibility",
                     explanation: "Stretching improves flexibility and range of motion.",
                     hint: "Think mobility."),
            Question(text: "Which activity burns the most calories per hour?",
                     options: ["Walking", "Yoga", "Running", "Sleeping"],
                     answer: "Running",
                     explanation: "Running is one of the highest calorie-burning activities per hour.",
                     hint: "Most intense option.")
        ]),
        
        // Level 2: Intermediate
        QuizLevel(level: 2, questions: [
            Question(text: "What does BMI stand for?",
                     options: ["Body Mass Index", "Blood Muscle Indicator", "Body Motion Input", "Balance Muscle Index"],
                     answer: "Body Mass Index",
                     explanation: "BMI measures body weight relative to height.",
                     hint: "Used in health screenings."),
            Question(text: "Which macronutrient is most important for building muscle?",
                     options: ["Carbohydrates", "Protein", "Fats", "Fiber"],
                     answer: "Protein",
                     explanation: "Protein provides amino acids essential for muscle repair and growth.",
                     hint: "Think about muscle recovery."),
            Question(text: "Which type of exercise builds bone density?",
                     options: ["Resistance training", "Swimming", "Cycling", "Meditation"],
                     answer: "Resistance training",
                     explanation: "Lifting weights and resistance exercises strengthen bones.",
                     hint: "Involves lifting."),
            Question(text: "Which muscle group do squats primarily target?",
                     options: ["Quadriceps", "Biceps", "Triceps", "Deltoids"],
                     answer: "Quadriceps",
                     explanation: "Squats mainly strengthen the quadriceps in the thighs.",
                     hint: "Front of thighs."),
            Question(text: "What does 'repetition' (rep) mean in fitness?",
                     options: ["One complete movement", "One workout session", "One week of training", "A warm-up set"],
                     answer: "One complete movement",
                     explanation: "A repetition is a single full motion of an exercise.",
                     hint: "Think single motion.")
        ]),
        
        // Level 3: Advanced
        QuizLevel(level: 3, questions: [
            Question(text: "Which type of muscle fibers are used for endurance?",
                     options: ["Slow-twitch", "Fast-twitch", "Hybrid", "All"],
                     answer: "Slow-twitch",
                     explanation: "Slow-twitch fibers are fatigue-resistant and built for endurance.",
                     hint: "Think marathon running."),
            Question(text: "Which exercise is considered plyometric?",
                     options: ["Jump squats", "Walking", "Bicep curls", "Yoga"],
                     answer: "Jump squats",
                     explanation: "Plyometric exercises involve explosive movements, like jump squats.",
                     hint: "Jumping and explosive."),
            Question(text: "What is VO2 max a measure of?",
                     options: ["Oxygen uptake", "Heart size", "Lung capacity only", "Muscle strength"],
                     answer: "Oxygen uptake",
                     explanation: "VO2 max measures the maximum oxygen your body can use during exercise.",
                     hint: "Linked to endurance."),
            Question(text: "What does HIIT stand for?",
                     options: ["High Intensity Interval Training", "Heavy Intense Internal Training", "Heart Interval Integration Training", "High Internal Intensity Training"],
                     answer: "High Intensity Interval Training",
                     explanation: "HIIT alternates short bursts of intense activity with rest or low activity.",
                     hint: "Popular workout style."),
            Question(text: "Which mineral is important for muscle contraction?",
                     options: ["Calcium", "Iron", "Magnesium", "Zinc"],
                     answer: "Calcium",
                     explanation: "Calcium ions are crucial for the contraction of muscle fibers.",
                     hint: "Essential for bones too.")
        ]),
        
        // Level 4: Expert
        QuizLevel(level: 4, questions: [
            Question(text: "What does progressive overload mean in fitness?",
                     options: ["Increasing exercise intensity over time", "Changing exercises daily", "Reducing rest", "Working until failure"],
                     answer: "Increasing exercise intensity over time",
                     explanation: "Progressive overload involves gradually increasing stress to build strength.",
                     hint: "Gradual increase."),
            Question(text: "Which hormone is known as the 'growth hormone'?",
                     options: ["HGH", "Insulin", "Cortisol", "Melatonin"],
                     answer: "HGH",
                     explanation: "Human Growth Hormone (HGH) supports muscle and tissue growth.",
                     hint: "Abbreviation: HGH."),
            Question(text: "What energy system fuels short bursts of intense activity?",
                     options: ["ATP-PC system", "Aerobic system", "Fat oxidation", "Glycolysis only"],
                     answer: "ATP-PC system",
                     explanation: "The ATP-PC system fuels explosive effort lasting up to ~10 seconds.",
                     hint: "Quick energy."),
            Question(text: "What’s the recommended rest time between heavy lifting sets?",
                     options: ["2–3 minutes", "30 seconds", "10 minutes", "None"],
                     answer: "2–3 minutes",
                     explanation: "Heavy compound lifts often require 2–3 minutes of rest.",
                     hint: "Enough to recover."),
            Question(text: "Overtraining can lead to:",
                     options: ["Fatigue and injury", "Increased performance", "Faster recovery", "No effects"],
                     answer: "Fatigue and injury",
                     explanation: "Overtraining stresses the body beyond its ability to recover.",
                     hint: "Negative effects of too much training.")
        ]),
        
        // Level 5: Mastery
        QuizLevel(level: 5, questions: [
            Question(text: "What is periodization in training?",
                     options: ["Planned cycles of intensity and recovery", "Training daily with no break", "Random workouts", "Training only once per week"],
                     answer: "Planned cycles of intensity and recovery",
                     explanation: "Periodization structures training into cycles to optimize performance.",
                     hint: "Organized training cycles."),
            Question(text: "Which organelle in muscle cells produces ATP?",
                     options: ["Mitochondria", "Nucleus", "Ribosome", "Golgi apparatus"],
                     answer: "Mitochondria",
                     explanation: "Mitochondria are the 'powerhouses' of cells, generating ATP.",
                     hint: "Cell powerhouse."),
            Question(text: "What is DOMS in fitness?",
                     options: ["Delayed Onset Muscle Soreness", "Daily Optimal Muscle Strength", "Dynamic Oxygen Movement System", "Deep Oblique Muscle Stretch"],
                     answer: "Delayed Onset Muscle Soreness",
                     explanation: "DOMS is the soreness felt 24–72 hours after intense exercise.",
                     hint: "Post-workout soreness."),
            Question(text: "What is the lactate threshold?",
                     options: ["Point where lactic acid builds faster than clearance", "When you hit max heart rate", "When you can’t lift anymore", "Blood oxygen drops below 80%"],
                     answer: "Point where lactic acid builds faster than clearance",
                     explanation: "At lactate threshold, lactic acid accumulates, reducing endurance.",
                     hint: "Tied to buildup of acid."),
            Question(text: "What is functional fitness training?",
                     options: ["Training movements for daily life", "Training only aesthetics", "Exclusive bodybuilding", "Cardio-only training"],
                     answer: "Training movements for daily life",
                     explanation: "Functional training focuses on practical strength for everyday activities.",
                     hint: "Think real-life strength.")
        ])
    ]
)
let cardiacArrestCategory = QuizCategory(
    title: "Cardiac Arrest",
    topic: "Cardiac Arrest",
    levels: [
        // Level 1: Basics
        QuizLevel(level: 1, questions: [
            Question(text: "What is the first step in treating cardiac arrest?",
                     options: ["Call 911", "Start CPR", "Check pulse", "Give oxygen"],
                     answer: "Call 911",
                     explanation: "Activating emergency response ensures help arrives quickly.",
                     hint: "Think of emergency activation."),
            Question(text: "What does CPR stand for?",
                     options: ["Cardiac Pulse Recovery", "Cardio Pulmonary Resuscitation", "Circulatory Pressure Rescue", "Cardio Pressure Response"],
                     answer: "Cardio Pulmonary Resuscitation",
                     explanation: "CPR is the process of restoring breathing and circulation.",
                     hint: "It involves heart and lungs."),
            Question(text: "Where should CPR compressions be given?",
                     options: ["Upper sternum", "Lower half of sternum", "Left chest", "Right chest"],
                     answer: "Lower half of sternum",
                     explanation: "Hand placement on the lower sternum maximizes efficiency.",
                     hint: "Middle of the chest."),
            Question(text: "What device is most often used to shock the heart?",
                     options: ["EKG", "AED", "Ventilator", "Pacemaker"],
                     answer: "AED",
                     explanation: "AEDs deliver controlled shocks to restart normal rhythm.",
                     hint: "You see them in airports and gyms."),
            Question(text: "What should bystanders do if no pulse is felt?",
                     options: ["Wait for EMS", "Perform CPR", "Give oxygen", "Shake the person"],
                     answer: "Perform CPR",
                     explanation: "Chest compressions should start immediately if no pulse.",
                     hint: "Don’t wait, act fast.")
        ]),
        
        // Level 2: Intermediate
        QuizLevel(level: 2, questions: [
            Question(text: "What is the correct compression depth for adults?",
                     options: ["1 inch", "2 inches", "3 inches", "4 inches"],
                     answer: "2 inches",
                     explanation: "Guidelines recommend compressions at least 2 inches deep.",
                     hint: "About the width of a credit card stack."),
            Question(text: "What is the recommended CPR compression rate?",
                     options: ["80-100/min", "100-120/min", "120-140/min", "150/min"],
                     answer: "100-120/min",
                     explanation: "Maintains proper circulation without over-fatiguing rescuers.",
                     hint: "Think of the beat of 'Stayin’ Alive'."),
            Question(text: "What ratio of compressions to breaths is used in CPR for adults?",
                     options: ["10:1", "15:2", "20:2", "30:2"],
                     answer: "30:2",
                     explanation: "30 compressions followed by 2 breaths is standard.",
                     hint: "Most commonly taught ratio."),
            Question(text: "How should compressions be performed?",
                     options: ["Fast and shallow", "Slow and deep", "Hard and fast", "Gentle and slow"],
                     answer: "Hard and fast",
                     explanation: "High-quality compressions require force and speed.",
                     hint: "Firm and quick."),
            Question(text: "When should you switch roles during CPR?",
                     options: ["Every 30 sec", "Every 2 min", "Every 5 min", "Never"],
                     answer: "Every 2 min",
                     explanation: "Rescuers should rotate every 2 minutes to avoid fatigue.",
                     hint: "Often when AED prompts to analyze.")
        ]),
        
        // Level 3: Advanced
        QuizLevel(level: 3, questions: [
            Question(text: "What is the first rhythm typically seen in sudden cardiac arrest?",
                     options: ["Asystole", "Ventricular fibrillation", "Bradycardia", "Atrial flutter"],
                     answer: "Ventricular fibrillation",
                     explanation: "V-fib is the most common initial rhythm in sudden arrest.",
                     hint: "It’s a chaotic rhythm."),
            Question(text: "What should be done immediately after a shock is delivered?",
                     options: ["Check for pulse", "Resume CPR", "Give breaths only", "Wait 2 min"],
                     answer: "Resume CPR",
                     explanation: "Compressions must resume right away for circulation.",
                     hint: "Don’t pause for too long."),
            Question(text: "How soon should defibrillation occur for best outcomes?",
                     options: ["Within 1 min", "Within 3 min", "Within 5 min", "Within 10 min"],
                     answer: "Within 3 min",
                     explanation: "Survival decreases rapidly with each passing minute.",
                     hint: "Sooner is better."),
            Question(text: "What drug is recommended during cardiac arrest?",
                     options: ["Aspirin", "Epinephrine", "Atorvastatin", "Insulin"],
                     answer: "Epinephrine",
                     explanation: "Epinephrine helps restore spontaneous circulation.",
                     hint: "It’s adrenaline."),
            Question(text: "How often should epinephrine be administered during CPR?",
                     options: ["Every 1 min", "Every 3–5 min", "Every 10 min", "Only once"],
                     answer: "Every 3–5 min",
                     explanation: "ACLS guidelines recommend 1 mg every 3–5 minutes.",
                     hint: "Not too frequent, not too rare.")
        ]),
        
        // Level 4: Expert
        QuizLevel(level: 4, questions: [
            Question(text: "What airway device is used if intubation is delayed?",
                     options: ["Nasal cannula", "Bag-mask", "Oropharyngeal airway", "All of the above"],
                     answer: "All of the above",
                     explanation: "Temporary airway devices can maintain oxygenation.",
                     hint: "Multiple options work."),
            Question(text: "What does ROSC stand for?",
                     options: ["Return of Spontaneous Circulation", "Recovery of Sinus Cardio", "Rapid Oxygen Supply Control", "Respiratory Oxygen Support Care"],
                     answer: "Return of Spontaneous Circulation",
                     explanation: "ROSC indicates the heart has resumed effective beats.",
                     hint: "It means the pulse is back."),
            Question(text: "What is the purpose of capnography during CPR?",
                     options: ["Measure oxygen", "Measure chest depth", "Measure CO₂", "Measure pulse"],
                     answer: "Measure CO₂",
                     explanation: "It indicates CPR quality and possible ROSC.",
                     hint: "Exhaled gas."),
            Question(text: "What is a typical ETCO₂ goal during resuscitation?",
                     options: ["<10 mmHg", "15–20 mmHg", ">40 mmHg", "None"],
                     answer: "15–20 mmHg",
                     explanation: "A higher ETCO₂ is linked to better outcomes.",
                     hint: "Mid-teens to twenties."),
            Question(text: "Which electrolyte imbalance can cause cardiac arrest?",
                     options: ["Hyperkalemia", "Hypokalemia", "Both", "Neither"],
                     answer: "Both",
                     explanation: "Both extremes of potassium can trigger arrhythmias.",
                     hint: "Potassium levels matter.")
        ]),
        
        // Level 5: Mastery
        QuizLevel(level: 5, questions: [
            Question(text: "What is the survival rate drop per minute without CPR?",
                     options: ["2–3%", "5–7%", "7–10%", "15%"],
                     answer: "7–10%",
                     explanation: "Every minute without CPR reduces survival by up to 10%.",
                     hint: "It’s a big drop."),
            Question(text: "What cooling technique is used after ROSC?",
                     options: ["Hypothermia therapy", "Warm blankets", "IV fluids", "Epinephrine drip"],
                     answer: "Hypothermia therapy",
                     explanation: "Targeted temperature management improves neurological recovery.",
                     hint: "Cold therapy."),
            Question(text: "What rhythm is NOT shockable?",
                     options: ["V-fib", "Pulseless VT", "Asystole", "V-tach"],
                     answer: "Asystole",
                     explanation: "Asystole requires CPR and meds, not shocks.",
                     hint: "Flatline."),
            Question(text: "What is the key difference between adult and child CPR ratios?",
                     options: ["Adults need faster compressions", "Children may use 15:2 with 2 rescuers", "Children use only breaths", "No difference"],
                     answer: "Children may use 15:2 with 2 rescuers",
                     explanation: "Ratio differs when multiple rescuers are present.",
                     hint: "Team CPR for kids."),
            Question(text: "What advanced device may replace chest compressions in hospitals?",
                     options: ["ECMO", "Pacemaker", "Ventilator", "Dialysis machine"],
                     answer: "ECMO",
                     explanation: "Extracorporeal membrane oxygenation can support circulation.",
                     hint: "It’s heart-lung bypass.")
        ])
    ]
)
let headacheCategory = QuizCategory(
    title: "Headache Awareness",
    topic: "Headaches",
    levels: [
        // Level 1: Basics
        QuizLevel(level: 1, questions: [
            Question(text: "What is the most common type of headache?",
                     options: ["Tension", "Cluster", "Migraine", "Sinus"],
                     answer: "Tension",
                     explanation: "Tension headaches are the most frequent, often caused by stress.",
                     hint: "Think of stress-related headaches."),
            Question(text: "Migraines are usually:",
                     options: ["One-sided", "Both sides", "Back of head", "Top of head"],
                     answer: "One-sided",
                     explanation: "Migraines often affect one side of the head.",
                     hint: "Pain location matters."),
            Question(text: "Cluster headaches typically occur:",
                     options: ["At night", "In the morning", "After exercise", "After meals"],
                     answer: "At night",
                     explanation: "Cluster headaches often wake patients from sleep.",
                     hint: "They disturb sleep."),
            Question(text: "Which of these is a common migraine symptom?",
                     options: ["Nausea", "Fever", "Cough", "Rash"],
                     answer: "Nausea",
                     explanation: "Migraines are often accompanied by nausea and vomiting.",
                     hint: "It affects the stomach too."),
            Question(text: "Which common food can trigger migraines?",
                     options: ["Cheese", "Rice", "Apples", "Carrots"],
                     answer: "Cheese",
                     explanation: "Aged cheeses contain tyramine, a common migraine trigger.",
                     hint: "Think aged foods.")
        ]),
        
        // Level 2: Intermediate
        QuizLevel(level: 2, questions: [
            Question(text: "Which headache is considered 'suicidal headache' due to severity?",
                     options: ["Cluster headache", "Tension headache", "Migraine", "Sinus headache"],
                     answer: "Cluster headache",
                     explanation: "Cluster headaches cause excruciating pain, earning this nickname.",
                     hint: "The most severe kind."),
            Question(text: "What is a common visual symptom before a migraine?",
                     options: ["Aura", "Blurred vision", "Color blindness", "Double vision"],
                     answer: "Aura",
                     explanation: "Auras can include flashing lights or blind spots before migraine.",
                     hint: "Flashing lights or blind spots."),
            Question(text: "Tension headaches often feel like:",
                     options: ["A tight band", "Sharp stabbing", "Throbbing", "Burning"],
                     answer: "A tight band",
                     explanation: "They are commonly described as pressure or a band around the head.",
                     hint: "Feels like a band around the skull."),
            Question(text: "Which gender is more prone to migraines?",
                     options: ["Men", "Women", "Equal", "Children only"],
                     answer: "Women",
                     explanation: "Migraines are 2–3 times more common in women.",
                     hint: "Hormones play a role."),
            Question(text: "Which over-the-counter drug is often used first for headaches?",
                     options: ["Ibuprofen", "Insulin", "Antibiotics", "Steroids"],
                     answer: "Ibuprofen",
                     explanation: "NSAIDs like ibuprofen are first-line for common headaches.",
                     hint: "It’s an NSAID.")
        ]),
        
        // Level 3: Advanced
        QuizLevel(level: 3, questions: [
            Question(text: "Cluster headaches are associated with which nerve?",
                     options: ["Trigeminal nerve", "Facial nerve", "Optic nerve", "Vagus nerve"],
                     answer: "Trigeminal nerve",
                     explanation: "Cluster headaches involve trigeminal nerve activation.",
                     hint: "Main sensory nerve of the face."),
            Question(text: "Which symptom is most characteristic of cluster headaches?",
                     options: ["Tearing eye", "Nausea", "Neck stiffness", "Light sensitivity"],
                     answer: "Tearing eye",
                     explanation: "Cluster headaches cause tearing and nasal congestion.",
                     hint: "It affects the eye."),
            Question(text: "What is a common preventive treatment for chronic migraines?",
                     options: ["Beta-blockers", "Antibiotics", "Vitamin C", "Antifungals"],
                     answer: "Beta-blockers",
                     explanation: "Drugs like propranolol can reduce migraine frequency.",
                     hint: "Common heart medication."),
            Question(text: "Which vitamin deficiency is linked to migraines?",
                     options: ["Vitamin D", "Vitamin B2", "Vitamin C", "Vitamin K"],
                     answer: "Vitamin B2",
                     explanation: "Riboflavin (B2) deficiency has been linked to migraines.",
                     hint: "Also known as riboflavin."),
            Question(text: "Which headache type is worsened by bending forward?",
                     options: ["Sinus headache", "Tension headache", "Cluster headache", "Migraine"],
                     answer: "Sinus headache",
                     explanation: "Sinus headaches worsen when leaning forward due to pressure.",
                     hint: "Think nasal pressure.")
        ]),
        
        // Level 4: Expert
        QuizLevel(level: 4, questions: [
            Question(text: "Which drug class is commonly used to stop migraines once started?",
                     options: ["Triptans", "Beta-blockers", "Diuretics", "Calcium supplements"],
                     answer: "Triptans",
                     explanation: "Triptans (like sumatriptan) are migraine-specific abortive drugs.",
                     hint: "Migraine-specific drugs."),
            Question(text: "What is the average duration of an untreated migraine?",
                     options: ["30 min–2 hrs", "4–72 hrs", "1–2 days", "1 week"],
                     answer: "4–72 hrs",
                     explanation: "Migraines often last from hours to several days.",
                     hint: "Think multiple days."),
            Question(text: "Which imaging test is used to rule out serious headache causes?",
                     options: ["MRI", "X-ray", "Ultrasound", "PET scan"],
                     answer: "MRI",
                     explanation: "MRI scans help exclude structural brain problems.",
                     hint: "Most detailed brain scan."),
            Question(text: "Rebound headaches are caused by:",
                     options: ["Overuse of pain meds", "Dehydration", "Stress", "Lack of sleep"],
                     answer: "Overuse of pain meds",
                     explanation: "Frequent use of headache medicine can worsen headaches.",
                     hint: "Too much medication."),
            Question(text: "Which nerve block can be used in severe headache cases?",
                     options: ["Occipital nerve block", "Sciatic nerve block", "Median nerve block", "Vagus nerve block"],
                     answer: "Occipital nerve block",
                     explanation: "This can help with chronic migraine or cluster headaches.",
                     hint: "Nerve at the back of the head.")
        ]),
        
        // Level 5: Mastery
        QuizLevel(level: 5, questions: [
            Question(text: "Which gene mutations are linked to familial hemiplegic migraine?",
                     options: ["CACNA1A", "CFTR", "APOE", "BRCA1"],
                     answer: "CACNA1A",
                     explanation: "This calcium channel gene mutation causes rare inherited migraines.",
                     hint: "A calcium channel gene."),
            Question(text: "What is the gold standard treatment for acute cluster headaches?",
                     options: ["High-flow oxygen", "Ibuprofen", "Steroids", "Massage"],
                     answer: "High-flow oxygen",
                     explanation: "Inhaling pure oxygen can stop cluster headaches quickly.",
                     hint: "Delivered through a mask."),
            Question(text: "Which part of the brain is believed to trigger cluster headaches?",
                     options: ["Hypothalamus", "Cerebellum", "Frontal lobe", "Occipital lobe"],
                     answer: "Hypothalamus",
                     explanation: "The hypothalamus is implicated in circadian cluster patterns.",
                     hint: "Controls sleep and circadian rhythm."),
            Question(text: "What does CGRP stand for in migraine biology?",
                     options: ["Calcitonin Gene-Related Peptide", "Calcium Growth Receptor Protein", "Cognitive Gene Response Pathway", "Cortisol Growth Regulatory Protein"],
                     answer: "Calcitonin Gene-Related Peptide",
                     explanation: "CGRP is a neuropeptide that plays a central role in migraines.",
                     hint: "It’s a peptide."),
            Question(text: "Which new treatment directly blocks CGRP?",
                     options: ["Monoclonal antibodies", "NSAIDs", "Beta-blockers", "Steroids"],
                     answer: "Monoclonal antibodies",
                     explanation: "New CGRP-targeting antibodies are breakthroughs in migraine therapy.",
                     hint: "Engineered proteins for therapy.")
        ])
    ]
)
let nutritionCategory = QuizCategory(
    title: "Nutrition & Diet Awareness",
    topic: "Nutrition",
    levels: [
        // Level 1: Basics
        QuizLevel(level: 1, questions: [
            Question(text: "Which nutrient is the main source of energy for the body?",
                     options: ["Carbohydrates", "Proteins", "Fats", "Vitamins"],
                     answer: "Carbohydrates",
                     explanation: "Carbs are the body’s preferred energy source.",
                     hint: "Think bread, rice, and pasta."),
            Question(text: "Which vitamin is produced when your skin is exposed to sunlight?",
                     options: ["Vitamin D", "Vitamin C", "Vitamin B12", "Vitamin A"],
                     answer: "Vitamin D",
                     explanation: "Vitamin D is synthesized in the skin when exposed to sunlight.",
                     hint: "Called the 'sunshine vitamin'."),
            Question(text: "Which mineral is essential for healthy bones?",
                     options: ["Calcium", "Iron", "Sodium", "Potassium"],
                     answer: "Calcium",
                     explanation: "Calcium supports strong bones and teeth.",
                     hint: "Milk is rich in it."),
            Question(text: "Which nutrient builds and repairs body tissues?",
                     options: ["Proteins", "Carbohydrates", "Fats", "Water"],
                     answer: "Proteins",
                     explanation: "Proteins are the building blocks of body tissues.",
                     hint: "Found in meat, beans, and eggs."),
            Question(text: "Which of these is a healthy fat?",
                     options: ["Avocado", "Butter", "Lard", "Fried food"],
                     answer: "Avocado",
                     explanation: "Avocados are rich in healthy monounsaturated fats.",
                     hint: "It’s a green fruit.")
        ]),
        
        // Level 2: Intermediate
        QuizLevel(level: 2, questions: [
            Question(text: "Which vitamin is necessary for iron absorption?",
                     options: ["Vitamin C", "Vitamin D", "Vitamin A", "Vitamin K"],
                     answer: "Vitamin C",
                     explanation: "Vitamin C enhances the absorption of non-heme iron.",
                     hint: "Citrus fruits are full of it."),
            Question(text: "Which nutrient helps regulate fluid balance in the body?",
                     options: ["Sodium", "Calcium", "Iron", "Magnesium"],
                     answer: "Sodium",
                     explanation: "Sodium is critical for maintaining fluid balance.",
                     hint: "Too much of it raises blood pressure."),
            Question(text: "Which vitamin deficiency causes scurvy?",
                     options: ["Vitamin C", "Vitamin D", "Vitamin B1", "Vitamin K"],
                     answer: "Vitamin C",
                     explanation: "Lack of vitamin C leads to scurvy.",
                     hint: "Sailors once feared lacking it."),
            Question(text: "Omega-3 fatty acids are most commonly found in:",
                     options: ["Fish", "Pasta", "Bread", "Rice"],
                     answer: "Fish",
                     explanation: "Fish like salmon are rich in omega-3 fatty acids.",
                     hint: "Think salmon and tuna."),
            Question(text: "Which nutrient is most calorie-dense?",
                     options: ["Fats", "Proteins", "Carbohydrates", "Fiber"],
                     answer: "Fats",
                     explanation: "Fats provide 9 calories per gram, more than protein or carbs.",
                     hint: "Oil is mostly this nutrient.")
        ]),
        
        // Level 3: Advanced
        QuizLevel(level: 3, questions: [
            Question(text: "Which mineral deficiency causes anemia?",
                     options: ["Iron", "Calcium", "Magnesium", "Zinc"],
                     answer: "Iron",
                     explanation: "Iron deficiency leads to anemia.",
                     hint: "Red meat is a good source."),
            Question(text: "Which vitamin deficiency causes night blindness?",
                     options: ["Vitamin A", "Vitamin D", "Vitamin B12", "Vitamin E"],
                     answer: "Vitamin A",
                     explanation: "Vitamin A is essential for good vision.",
                     hint: "Carrots are rich in it."),
            Question(text: "Which nutrient helps maintain strong immunity?",
                     options: ["Zinc", "Sodium", "Chloride", "Iodine"],
                     answer: "Zinc",
                     explanation: "Zinc supports immune system function.",
                     hint: "Found in nuts and seeds."),
            Question(text: "Which nutrient helps carry oxygen in the blood?",
                     options: ["Iron", "Potassium", "Vitamin C", "Vitamin K"],
                     answer: "Iron",
                     explanation: "Iron is a component of hemoglobin.",
                     hint: "Linked to hemoglobin."),
            Question(text: "Which type of fiber helps lower cholesterol?",
                     options: ["Soluble fiber", "Insoluble fiber", "Refined fiber", "No fiber"],
                     answer: "Soluble fiber",
                     explanation: "Soluble fiber reduces LDL cholesterol levels.",
                     hint: "Oats are a great source.")
        ]),
        
        // Level 4: Expert
        QuizLevel(level: 4, questions: [
            Question(text: "Which vitamin is crucial for blood clotting?",
                     options: ["Vitamin K", "Vitamin C", "Vitamin D", "Vitamin A"],
                     answer: "Vitamin K",
                     explanation: "Vitamin K is essential for clotting factors.",
                     hint: "Green leafy vegetables are rich in it."),
            Question(text: "What is the recommended daily fiber intake for adults?",
                     options: ["25–30g", "10g", "40–50g", "5g"],
                     answer: "25–30g",
                     explanation: "Most adults need 25–30 grams of fiber per day.",
                     hint: "Think daily roughage intake."),
            Question(text: "Which mineral is important for thyroid function?",
                     options: ["Iodine", "Iron", "Calcium", "Magnesium"],
                     answer: "Iodine",
                     explanation: "Iodine is necessary for thyroid hormone production.",
                     hint: "Found in iodized salt."),
            Question(text: "Which nutrient helps maintain fluid and nerve function?",
                     options: ["Potassium", "Vitamin B12", "Vitamin D", "Calcium"],
                     answer: "Potassium",
                     explanation: "Potassium regulates nerve signals and fluid balance.",
                     hint: "Bananas are rich in it."),
            Question(text: "Which vitamin is stored in the liver and can be toxic in excess?",
                     options: ["Vitamin A", "Vitamin C", "Vitamin B6", "Vitamin B12"],
                     answer: "Vitamin A",
                     explanation: "Vitamin A is fat-soluble and stored in the liver.",
                     hint: "Fat-soluble vitamin.")
        ]),
        
        // Level 5: Mastery
        QuizLevel(level: 5, questions: [
            Question(text: "Which vitamin deficiency causes pernicious anemia?",
                     options: ["Vitamin B12", "Vitamin D", "Vitamin E", "Vitamin K"],
                     answer: "Vitamin B12",
                     explanation: "B12 deficiency leads to pernicious anemia.",
                     hint: "Often found in animal products."),
            Question(text: "Which condition is caused by lack of iodine?",
                     options: ["Goiter", "Rickets", "Scurvy", "Pellagra"],
                     answer: "Goiter",
                     explanation: "Iodine deficiency leads to an enlarged thyroid (goiter).",
                     hint: "Neck swelling disorder."),
            Question(text: "Which vitamin is essential for collagen synthesis?",
                     options: ["Vitamin C", "Vitamin K", "Vitamin D", "Vitamin E"],
                     answer: "Vitamin C",
                     explanation: "Vitamin C is needed for collagen production.",
                     hint: "Think citrus fruits."),
            Question(text: "Which fat-soluble vitamin also acts as an antioxidant?",
                     options: ["Vitamin E", "Vitamin C", "Vitamin B1", "Vitamin K"],
                     answer: "Vitamin E",
                     explanation: "Vitamin E protects cell membranes from oxidative damage.",
                     hint: "Protects cells from oxidation."),
            Question(text: "Which amino acid is essential and must come from diet?",
                     options: ["Lysine", "Alanine", "Glycine", "Glutamine"],
                     answer: "Lysine",
                     explanation: "Lysine is an essential amino acid obtained from food.",
                     hint: "One of nine essential amino acids.")
        ])
    ]
)
let sleepCategory = QuizCategory(
    title: "Sleep Health",
    topic: "Sleep",
    levels: [
        // Level 1: Basics
        QuizLevel(level: 1, questions: [
            Question(text: "How many hours of sleep does the average adult need?",
                     options: ["4-5", "5-6", "7-9", "10-12"],
                     answer: "7-9",
                     explanation: "Most adults need 7–9 hours of sleep each night.",
                     hint: "Think about what doctors recommend."),
            Question(text: "Which hormone regulates the sleep-wake cycle?",
                     options: ["Melatonin", "Insulin", "Cortisol", "Dopamine"],
                     answer: "Melatonin",
                     explanation: "Melatonin helps regulate the body’s internal clock.",
                     hint: "It’s called the sleep hormone."),
            Question(text: "What is the main role of sleep?",
                     options: ["Energy restoration", "Digestion", "Bone growth", "Hearing"],
                     answer: "Energy restoration",
                     explanation: "Sleep restores energy and supports healing.",
                     hint: "Why do you feel better after a good night’s rest?"),
            Question(text: "Which is a common cause of insomnia?",
                     options: ["Stress", "Exercise", "Hydration", "Eating fruit"],
                     answer: "Stress",
                     explanation: "Stress is one of the most frequent triggers of insomnia.",
                     hint: "Think about what keeps people awake at night."),
            Question(text: "What is the first stage of sleep?",
                     options: ["Light sleep", "Deep sleep", "REM sleep", "Dreaming"],
                     answer: "Light sleep",
                     explanation: "Light sleep is the transition from wakefulness to sleep.",
                     hint: "It’s the shallowest stage.")
        ]),
        
        // Level 2: Intermediate
        QuizLevel(level: 2, questions: [
            Question(text: "Which stage of sleep is most restorative?",
                     options: ["REM", "Deep sleep", "Light sleep", "Awake state"],
                     answer: "Deep sleep",
                     explanation: "Deep sleep restores energy and repairs tissues.",
                     hint: "It’s the slow-wave stage."),
            Question(text: "What does REM stand for in sleep?",
                     options: ["Rapid Eye Movement", "Restful Energy Mode", "Regular Eye Motion", "Reduced Energy Metabolism"],
                     answer: "Rapid Eye Movement",
                     explanation: "REM sleep is characterized by rapid eye movements and vivid dreams.",
                     hint: "The 'dreaming' stage."),
            Question(text: "Poor sleep is linked to which chronic condition?",
                     options: ["Diabetes", "Asthma", "Arthritis", "Hearing loss"],
                     answer: "Diabetes",
                     explanation: "Chronic sleep deprivation increases the risk of diabetes.",
                     hint: "It’s a condition involving blood sugar."),
            Question(text: "Which sleep disorder causes pauses in breathing?",
                     options: ["Sleep apnea", "Narcolepsy", "Insomnia", "Restless legs"],
                     answer: "Sleep apnea",
                     explanation: "Sleep apnea involves repeated pauses in breathing during sleep.",
                     hint: "Often treated with CPAP."),
            Question(text: "Which lifestyle habit disrupts healthy sleep the most?",
                     options: ["Caffeine late in the day", "Morning exercise", "Drinking water", "Reading before bed"],
                     answer: "Caffeine late in the day",
                     explanation: "Caffeine is a stimulant that delays sleep onset.",
                     hint: "Found in coffee, tea, and soda.")
        ]),
        
        // Level 3: Advanced
        QuizLevel(level: 3, questions: [
            Question(text: "What percentage of adult life is spent sleeping?",
                     options: ["About 25%", "About 33%", "About 50%", "About 60%"],
                     answer: "About 33%",
                     explanation: "Adults spend roughly one-third of their lives asleep.",
                     hint: "Think about 'a third of the day'."),
            Question(text: "Which brain waves are dominant during deep sleep?",
                     options: ["Delta waves", "Alpha waves", "Beta waves", "Theta waves"],
                     answer: "Delta waves",
                     explanation: "Slow delta waves are characteristic of deep sleep.",
                     hint: "They’re the slowest brain waves."),
            Question(text: "Which neurotransmitter promotes wakefulness?",
                     options: ["Orexin", "Melatonin", "Serotonin", "Insulin"],
                     answer: "Orexin",
                     explanation: "Orexin helps maintain wakefulness and alertness.",
                     hint: "It’s deficient in narcolepsy."),
            Question(text: "Narcolepsy is characterized by:",
                     options: ["Sudden sleep attacks", "Snoring", "Insomnia", "Sleepwalking"],
                     answer: "Sudden sleep attacks",
                     explanation: "Narcolepsy causes sudden, uncontrollable episodes of sleep.",
                     hint: "Think 'falling asleep suddenly'."),
            Question(text: "What type of cycle is the human sleep-wake pattern?",
                     options: ["Circadian rhythm", "Weekly rhythm", "Seasonal cycle", "Ultradian rhythm"],
                     answer: "Circadian rhythm",
                     explanation: "The circadian rhythm regulates daily biological cycles.",
                     hint: "It’s a ~24-hour cycle.")
        ]),
        
        // Level 4: Expert
        QuizLevel(level: 4, questions: [
            Question(text: "What is sleep hygiene?",
                     options: ["Healthy habits for better sleep", "Special pillows", "Taking medication", "Cleaning before bed"],
                     answer: "Healthy habits for better sleep",
                     explanation: "Sleep hygiene involves routines that improve sleep quality.",
                     hint: "Think routines, not cleaning."),
            Question(text: "Shift work disorder is caused by disruption of:",
                     options: ["Circadian rhythm", "REM cycles", "Hormone levels", "Memory"],
                     answer: "Circadian rhythm",
                     explanation: "Shift work disrupts the circadian rhythm, leading to sleep issues.",
                     hint: "It’s your body’s daily clock."),
            Question(text: "Which sleep stage is most associated with dreaming?",
                     options: ["REM", "Deep sleep", "Light sleep", "Transition"],
                     answer: "REM",
                     explanation: "REM sleep is when most vivid dreams occur.",
                     hint: "It’s in the name."),
            Question(text: "What is the average length of one full sleep cycle?",
                     options: ["30–45 minutes", "60–90 minutes", "2–3 hours", "4–5 hours"],
                     answer: "60–90 minutes",
                     explanation: "A sleep cycle lasts around 60–90 minutes.",
                     hint: "It’s about an hour and a half."),
            Question(text: "What is parasomnia?",
                     options: ["Abnormal sleep behavior", "Sleep hormone disorder", "Low-quality REM sleep", "Excessive napping"],
                     answer: "Abnormal sleep behavior",
                     explanation: "Parasomnias include sleepwalking, night terrors, etc.",
                     hint: "Think strange sleep behaviors.")
        ]),
        
        // Level 5: Mastery
        QuizLevel(level: 5, questions: [
            Question(text: "Which device is used to diagnose sleep apnea?",
                     options: ["Polysomnography", "X-ray", "EKG", "EEG only"],
                     answer: "Polysomnography",
                     explanation: "A sleep study (polysomnography) monitors breathing, brain activity, and oxygen.",
                     hint: "It’s a sleep study."),
            Question(text: "REM behavior disorder is characterized by:",
                     options: ["Acting out dreams", "Staying awake all night", "No REM sleep", "Sleep paralysis"],
                     answer: "Acting out dreams",
                     explanation: "In this disorder, people physically act out vivid dreams.",
                     hint: "People move when they’re dreaming."),
            Question(text: "Which gland produces melatonin?",
                     options: ["Pineal gland", "Adrenal gland", "Thyroid gland", "Pituitary gland"],
                     answer: "Pineal gland",
                     explanation: "The pineal gland secretes melatonin to regulate sleep.",
                     hint: "It’s deep inside the brain."),
            Question(text: "Which therapy is most effective for chronic insomnia?",
                     options: ["Cognitive behavioral therapy", "Antibiotics", "Iron supplements", "Surgery"],
                     answer: "Cognitive behavioral therapy",
                     explanation: "CBT-I is the gold-standard non-drug treatment for insomnia.",
                     hint: "CBT-I is the short form."),
            Question(text: "What is the role of glymphatic clearance during sleep?",
                     options: ["Removes brain waste", "Builds bone density", "Improves digestion", "Strengthens muscles"],
                     answer: "Removes brain waste",
                     explanation: "The glymphatic system clears metabolic waste during sleep.",
                     hint: "Think 'brain cleanup'.")
        ])
    ]
)
let diabetesCategory = QuizCategory(
    title: "Diabetes Awareness",
    topic: "Diabetes",
    levels: [
        // Level 1: Basics
        QuizLevel(level: 1, questions: [
            Question(text: "Which organ produces insulin?",
                     options: ["Liver", "Pancreas", "Kidneys", "Heart"],
                     answer: "Pancreas",
                     explanation: "The pancreas produces insulin to regulate blood sugar.",
                     hint: "It’s located behind the stomach."),
            Question(text: "A common symptom of diabetes is:",
                     options: ["Blurred vision", "Hair loss", "Hearing loss", "Skin rash"],
                     answer: "Blurred vision",
                     explanation: "High blood sugar can damage small blood vessels in the eyes.",
                     hint: "It involves eyesight."),
            Question(text: "Type 1 diabetes is primarily caused by:",
                     options: ["Autoimmune destruction", "Obesity", "Stress", "Poor diet"],
                     answer: "Autoimmune destruction",
                     explanation: "The immune system destroys insulin-producing cells in the pancreas.",
                     hint: "The immune system is involved."),
            Question(text: "Which of the following is a major risk factor for type 2 diabetes?",
                     options: ["Obesity", "Exercise", "Low salt intake", "Drinking water"],
                     answer: "Obesity",
                     explanation: "Being overweight significantly increases type 2 diabetes risk.",
                     hint: "It relates to body weight."),
            Question(text: "Which test measures long-term blood sugar levels?",
                     options: ["A1C test", "X-ray", "EKG", "Blood pressure"],
                     answer: "A1C test",
                     explanation: "The A1C test measures average glucose over 2–3 months.",
                     hint: "Doctors order this for monitoring control.")
        ]),
        
        // Level 2: Intermediate
        QuizLevel(level: 2, questions: [
            Question(text: "Which hormone lowers blood glucose?",
                     options: ["Insulin", "Glucagon", "Cortisol", "Epinephrine"],
                     answer: "Insulin",
                     explanation: "Insulin moves glucose from the blood into cells.",
                     hint: "It’s secreted after meals."),
            Question(text: "Which type of diabetes is most common?",
                     options: ["Type 1", "Type 2", "Gestational", "MODY"],
                     answer: "Type 2",
                     explanation: "Type 2 diabetes makes up 90–95% of all diabetes cases.",
                     hint: "It’s strongly linked with lifestyle."),
            Question(text: "Gestational diabetes occurs during:",
                     options: ["Pregnancy", "Childhood", "Old age", "After surgery"],
                     answer: "Pregnancy",
                     explanation: "Gestational diabetes develops in pregnancy and may resolve afterward.",
                     hint: "Think about expecting mothers."),
            Question(text: "Which of these is an early symptom of type 2 diabetes?",
                     options: ["Frequent urination", "Hearing loss", "Hair graying", "Nosebleeds"],
                     answer: "Frequent urination",
                     explanation: "Excess glucose pulls water into urine, causing frequent urination.",
                     hint: "It involves the bathroom."),
            Question(text: "Which macronutrient most directly affects blood sugar?",
                     options: ["Carbohydrates", "Protein", "Fat", "Fiber"],
                     answer: "Carbohydrates",
                     explanation: "Carbohydrates are broken down into glucose, raising blood sugar.",
                     hint: "Bread, rice, and pasta are examples.")
        ]),
        
        // Level 3: Advanced
        QuizLevel(level: 3, questions: [
            Question(text: "Which organ stores glucose as glycogen?",
                     options: ["Liver", "Heart", "Lungs", "Kidneys"],
                     answer: "Liver",
                     explanation: "The liver stores glucose and releases it when needed.",
                     hint: "It’s the largest internal organ."),
            Question(text: "Hypoglycemia refers to:",
                     options: ["Low blood sugar", "High blood sugar", "Low blood pressure", "High insulin"],
                     answer: "Low blood sugar",
                     explanation: "Hypoglycemia occurs when blood sugar levels drop too low.",
                     hint: "Think of 'hypo' meaning less."),
            Question(text: "Which diabetes complication affects the kidneys?",
                     options: ["Nephropathy", "Neuropathy", "Retinopathy", "Cardiomyopathy"],
                     answer: "Nephropathy",
                     explanation: "Diabetic nephropathy damages the kidneys over time.",
                     hint: "‘Nephro’ means kidney."),
            Question(text: "What is diabetic neuropathy?",
                     options: ["Nerve damage", "Eye disease", "Skin infection", "Lung damage"],
                     answer: "Nerve damage",
                     explanation: "High blood sugar damages nerves, especially in the extremities.",
                     hint: "It involves tingling or numbness."),
            Question(text: "Which test checks for diabetic eye disease?",
                     options: ["Retinal exam", "A1C test", "X-ray", "EEG"],
                     answer: "Retinal exam",
                     explanation: "Regular retinal exams detect diabetic retinopathy.",
                     hint: "It’s done by an eye doctor.")
        ]),
        
        // Level 4: Expert
        QuizLevel(level: 4, questions: [
            Question(text: "What is the function of glucagon?",
                     options: ["Raises blood sugar", "Lowers blood sugar", "Increases blood pressure", "Improves digestion"],
                     answer: "Raises blood sugar",
                     explanation: "Glucagon signals the liver to release glucose.",
                     hint: "It works opposite to insulin."),
            Question(text: "Insulin resistance occurs when:",
                     options: ["Cells don’t respond to insulin", "Pancreas stops producing insulin", "Kidneys stop filtering sugar", "The liver overproduces insulin"],
                     answer: "Cells don’t respond to insulin",
                     explanation: "In type 2 diabetes, cells become resistant to insulin’s effects.",
                     hint: "The hormone is there but not effective."),
            Question(text: "Which diabetes complication causes vision problems?",
                     options: ["Retinopathy", "Neuropathy", "Nephropathy", "Gastroparesis"],
                     answer: "Retinopathy",
                     explanation: "Diabetic retinopathy damages the blood vessels in the eyes.",
                     hint: "It’s related to the retina."),
            Question(text: "Which lifestyle change is most effective for type 2 diabetes prevention?",
                     options: ["Weight loss", "Taking vitamins", "Drinking more water", "Sleeping less"],
                     answer: "Weight loss",
                     explanation: "Losing weight and exercising reduces risk.",
                     hint: "Think diet and exercise."),
            Question(text: "Diabetic ketoacidosis (DKA) is most common in:",
                     options: ["Type 1 diabetes", "Type 2 diabetes", "Gestational diabetes", "Prediabetes"],
                     answer: "Type 1 diabetes",
                     explanation: "DKA is a serious complication of uncontrolled type 1 diabetes.",
                     hint: "It’s linked with insulin absence.")
        ]),
        
        // Level 5: Mastery
        QuizLevel(level: 5, questions: [
            Question(text: "What does HbA1c measure?",
                     options: ["Average blood sugar", "Daily insulin needs", "Cholesterol levels", "Blood pressure"],
                     answer: "Average blood sugar",
                     explanation: "HbA1c reflects average glucose over 2–3 months.",
                     hint: "It’s a long-term measure."),
            Question(text: "Which class of drugs helps the body use insulin better?",
                     options: ["Metformin", "Antibiotics", "Beta blockers", "Statins"],
                     answer: "Metformin",
                     explanation: "Metformin improves insulin sensitivity and reduces liver glucose output.",
                     hint: "It’s the #1 prescribed diabetes drug."),
            Question(text: "Which technology helps patients monitor blood sugar continuously?",
                     options: ["CGM", "MRI", "CT scan", "EKG"],
                     answer: "CGM",
                     explanation: "Continuous Glucose Monitors (CGMs) track blood sugar in real time.",
                     hint: "It uses sensors under the skin."),
            Question(text: "Which diabetes complication affects stomach emptying?",
                     options: ["Gastroparesis", "Nephropathy", "Retinopathy", "Neuropathy"],
                     answer: "Gastroparesis",
                     explanation: "Gastroparesis slows digestion due to nerve damage.",
                     hint: "It involves delayed stomach emptying."),
            Question(text: "Which hormone opposes the action of insulin?",
                     options: ["Glucagon", "Thyroxine", "Testosterone", "Cortisol"],
                     answer: "Glucagon",
                     explanation: "Glucagon raises blood sugar, working opposite to insulin.",
                     hint: "It comes from the pancreas too.")
        ])
    ]
)
let hypertensionCategory = QuizCategory(
    title: "Hypertension Basics",
    topic: "Blood Pressure",
    levels: [
        // Level 1: Basics
        QuizLevel(level: 1, questions: [
            Question(text: "What is the normal adult blood pressure?",
                     options: ["120/80 mmHg", "140/90 mmHg", "100/70 mmHg", "160/100 mmHg"],
                     answer: "120/80 mmHg",
                     explanation: "A blood pressure of 120/80 mmHg is considered normal.",
                     hint: "Think of the textbook ‘perfect’ reading."),
            Question(text: "High blood pressure is also called:",
                     options: ["Hypotension", "Hypertension", "Arrhythmia", "Tachycardia"],
                     answer: "Hypertension",
                     explanation: "The medical term for high blood pressure is hypertension.",
                     hint: "It starts with ‘Hyper’."),
            Question(text: "What organ pumps blood that creates blood pressure?",
                     options: ["Heart", "Liver", "Lungs", "Kidneys"],
                     answer: "Heart",
                     explanation: "The heart’s pumping creates blood pressure.",
                     hint: "It’s your main pump."),
            Question(text: "What instrument measures blood pressure?",
                     options: ["Stethoscope", "Sphygmomanometer", "Thermometer", "EKG"],
                     answer: "Sphygmomanometer",
                     explanation: "Blood pressure is measured with a sphygmomanometer.",
                     hint: "It’s that cuff they wrap on your arm."),
            Question(text: "Which number in blood pressure is systolic?",
                     options: ["Top number", "Bottom number", "Average", "Both"],
                     answer: "Top number",
                     explanation: "The top number is systolic, measuring pressure when the heart contracts.",
                     hint: "It’s the higher of the two numbers.")
        ]),
        
        // Level 2: Intermediate
        QuizLevel(level: 2, questions: [
            Question(text: "Which number in blood pressure is diastolic?",
                     options: ["Top number", "Bottom number", "Pulse", "Neither"],
                     answer: "Bottom number",
                     explanation: "Diastolic pressure is measured when the heart relaxes.",
                     hint: "It’s the lower number."),
            Question(text: "Which lifestyle factor increases hypertension risk?",
                     options: ["Smoking", "Drinking water", "Exercising", "Sleeping well"],
                     answer: "Smoking",
                     explanation: "Smoking damages blood vessels and raises blood pressure.",
                     hint: "It’s an unhealthy habit."),
            Question(text: "Excessive intake of which mineral can raise blood pressure?",
                     options: ["Sodium", "Calcium", "Potassium", "Iron"],
                     answer: "Sodium",
                     explanation: "Too much sodium causes water retention, raising blood pressure.",
                     hint: "It’s found in salt."),
            Question(text: "Which organ is most affected by uncontrolled hypertension?",
                     options: ["Heart", "Lungs", "Skin", "Muscles"],
                     answer: "Heart",
                     explanation: "High blood pressure forces the heart to work harder.",
                     hint: "It’s the same organ that pumps."),
            Question(text: "What is considered Stage 1 Hypertension?",
                     options: ["130–139/80–89", "110/70", "200/150", "Below 120/80"],
                     answer: "130–139/80–89",
                     explanation: "Stage 1 hypertension begins at systolic 130–139 or diastolic 80–89.",
                     hint: "It starts just above 120/80.")
        ]),
        
        // Level 3: Advanced
        QuizLevel(level: 3, questions: [
            Question(text: "Which hormone regulates blood pressure via the kidneys?",
                     options: ["Aldosterone", "Insulin", "Cortisol", "Melatonin"],
                     answer: "Aldosterone",
                     explanation: "Aldosterone increases sodium retention, raising blood pressure.",
                     hint: "It starts with an A."),
            Question(text: "What is a hypertensive crisis?",
                     options: ["180/120 or higher", "90/60", "120/80", "140/90"],
                     answer: "180/120 or higher",
                     explanation: "Blood pressure above 180/120 is considered a medical emergency.",
                     hint: "It’s a very high number."),
            Question(text: "Hypertension is known as the 'silent killer' because:",
                     options: ["It often has no symptoms", "It spreads like infection", "It causes pain early", "It lowers body temperature"],
                     answer: "It often has no symptoms",
                     explanation: "Most people don’t realize they have high blood pressure until complications occur.",
                     hint: "There are often no warning signs."),
            Question(text: "Which blood vessel damage is common in hypertension?",
                     options: ["Arteries", "Veins", "Capillaries", "Lymph vessels"],
                     answer: "Arteries",
                     explanation: "Hypertension damages arterial walls, causing stiffening and narrowing.",
                     hint: "It’s the thick, high-pressure vessels."),
            Question(text: "Hypertension increases risk of:",
                     options: ["Stroke", "Heart attack", "Kidney failure", "All of the above"],
                     answer: "All of the above",
                     explanation: "Uncontrolled hypertension can lead to severe complications across multiple organs.",
                     hint: "It affects multiple organs.")
        ]),
        
        // Level 4: Expert
        QuizLevel(level: 4, questions: [
            Question(text: "What is secondary hypertension?",
                     options: ["Caused by another disease", "Caused by obesity", "Genetic only", "Temporary stress rise"],
                     answer: "Caused by another disease",
                     explanation: "Secondary hypertension is due to another condition, like kidney disease.",
                     hint: "It’s not primary, it’s due to something else."),
            Question(text: "Which type of medication is often prescribed first for hypertension?",
                     options: ["Diuretics", "Antibiotics", "Insulin", "Antivirals"],
                     answer: "Diuretics",
                     explanation: "Diuretics help reduce blood pressure by decreasing fluid volume.",
                     hint: "They’re also called water pills."),
            Question(text: "Which organ produces renin, influencing blood pressure?",
                     options: ["Kidneys", "Liver", "Heart", "Pancreas"],
                     answer: "Kidneys",
                     explanation: "Renin triggers the renin-angiotensin-aldosterone system to raise BP.",
                     hint: "It filters blood and makes urine."),
            Question(text: "What is white coat hypertension?",
                     options: ["High BP only at the doctor’s office", "High BP while sleeping", "High BP in athletes", "Random spikes"],
                     answer: "High BP only at the doctor’s office",
                     explanation: "Anxiety at medical visits can temporarily raise blood pressure.",
                     hint: "It happens at the clinic."),
            Question(text: "Which type of exercise best lowers blood pressure?",
                     options: ["Aerobic", "Weightlifting only", "Yoga only", "None"],
                     answer: "Aerobic",
                     explanation: "Aerobic activities like walking, jogging, or swimming lower blood pressure effectively.",
                     hint: "It’s cardio-based.")
        ]),
        
        // Level 5: Mastery
        QuizLevel(level: 5, questions: [
            Question(text: "What is resistant hypertension?",
                     options: ["BP uncontrolled despite 3+ medications", "BP from stress only", "Temporary rise after coffee", "Inherited only"],
                     answer: "BP uncontrolled despite 3+ medications",
                     explanation: "Resistant hypertension persists even with multiple medications.",
                     hint: "Even medicine can’t lower it easily."),
            Question(text: "Which diet is best for lowering hypertension?",
                     options: ["DASH diet", "Keto diet", "High-salt diet", "Fasting"],
                     answer: "DASH diet",
                     explanation: "The DASH diet emphasizes fruits, vegetables, and low sodium.",
                     hint: "Its acronym stands for Dietary Approaches to Stop Hypertension."),
            Question(text: "Which sleep disorder is linked to hypertension?",
                     options: ["Sleep apnea", "Insomnia", "Narcolepsy", "Sleepwalking"],
                     answer: "Sleep apnea",
                     explanation: "Obstructive sleep apnea is strongly associated with high blood pressure.",
                     hint: "It involves pauses in breathing."),
            Question(text: "Which blood vessel measurement indicates arterial stiffness?",
                     options: ["Pulse wave velocity", "EKG", "Blood oxygen", "BMI"],
                     answer: "Pulse wave velocity",
                     explanation: "Pulse wave velocity measures how stiff arteries have become.",
                     hint: "It measures how quickly blood pulses travel."),
            Question(text: "Hypertensive encephalopathy affects which organ?",
                     options: ["Brain", "Kidneys", "Heart", "Liver"],
                     answer: "Brain",
                     explanation: "Severely high blood pressure can cause brain swelling and neurological symptoms.",
                     hint: "It controls your thoughts and nerves.")
        ])
    ]
)
let headachesCategory = QuizCategory(
    title: "Headaches",
    topic: "Headaches",
    levels: [
        // Level 1: Basics
        QuizLevel(level: 1, questions: [
            Question(
                text: "What is the most common type of headache?",
                options: ["Tension headache", "Cluster headache", "Migraine", "Sinus headache"],
                answer: "Tension headache",
                explanation: "Tension headaches are the most common, often caused by stress or muscle strain.",
                hint: "It feels like a tight band around your head."
            ),
            Question(
                text: "Which symptom usually comes with a migraine?",
                options: ["Throbbing pain on one side", "Runny nose", "Coughing", "Skin rash"],
                answer: "Throbbing pain on one side",
                explanation: "Migraines usually cause throbbing pain on one side of the head.",
                hint: "Migraines often affect only one side."
            ),
            Question(
                text: "Which lifestyle factor can commonly trigger headaches?",
                options: ["Dehydration", "Listening to music", "Walking daily", "Eating vegetables"],
                answer: "Dehydration",
                explanation: "Not drinking enough water is a common and preventable cause of headaches.",
                hint: "Think about water intake."
            ),
            Question(
                text: "What over-the-counter medicine is often used for mild headaches?",
                options: ["Ibuprofen", "Insulin", "Antibiotics", "Antihistamines"],
                answer: "Ibuprofen",
                explanation: "Ibuprofen and acetaminophen are common medications used for pain relief.",
                hint: "It’s an NSAID pain reliever."
            ),
            Question(
                text: "What’s the best immediate step for a stress headache?",
                options: ["Rest and relaxation", "Running a marathon", "Eating sugar", "Taking antibiotics"],
                answer: "Rest and relaxation",
                explanation: "Tension headaches often respond well to rest, hydration, and relaxation techniques.",
                hint: "Think about stress relief."
            )
        ]),
        
        // Level 2: Intermediate
        QuizLevel(level: 2, questions: [
            Question(
                text: "Cluster headaches usually occur:",
                options: ["In cyclical patterns", "Only once in life", "Every morning", "After eating sugar"],
                answer: "In cyclical patterns",
                explanation: "Cluster headaches come in cycles or 'clusters' over weeks or months.",
                hint: "They follow a repeating pattern."
            ),
            Question(
                text: "What is photophobia?",
                options: ["Sensitivity to light", "Fear of phones", "Fear of doctors", "Sensitivity to sound"],
                answer: "Sensitivity to light",
                explanation: "Photophobia (light sensitivity) is common with migraines.",
                hint: "It’s a reaction to brightness."
            ),
            Question(
                text: "Which mineral deficiency is sometimes linked to migraines?",
                options: ["Magnesium", "Iron", "Zinc", "Calcium"],
                answer: "Magnesium",
                explanation: "Some studies suggest magnesium deficiency can trigger migraines.",
                hint: "It’s a mineral often found in leafy greens."
            ),
            Question(
                text: "Which headache type often wakes people from sleep?",
                options: ["Cluster headache", "Tension headache", "Migraine", "Sinus headache"],
                answer: "Cluster headache",
                explanation: "Cluster headaches are known for waking people at night with severe pain.",
                hint: "It’s the most painful type."
            ),
            Question(
                text: "Which non-drug method can relieve sinus headaches?",
                options: ["Steam inhalation", "Drinking coffee", "Sleeping more", "Taking antibiotics always"],
                answer: "Steam inhalation",
                explanation: "Warm steam helps open nasal passages and relieve sinus pressure.",
                hint: "It involves warm vapor."
            )
        ]),
        
        // Level 3: Advanced
        QuizLevel(level: 3, questions: [
            Question(
                text: "What’s an aura in relation to migraines?",
                options: ["Visual or sensory disturbance before the headache", "Sudden fainting", "High fever", "Loud ringing in the ears"],
                answer: "Visual or sensory disturbance before the headache",
                explanation: "Aura can involve flashing lights, blind spots, or tingling sensations before a migraine.",
                hint: "It happens before the migraine begins."
            ),
            Question(
                text: "Which neurotransmitter is most associated with migraines?",
                options: ["Serotonin", "Dopamine", "GABA", "Epinephrine"],
                answer: "Serotonin",
                explanation: "Fluctuations in serotonin are strongly linked with migraines.",
                hint: "It’s the 'happiness' neurotransmitter."
            ),
            Question(
                text: "Rebound headaches are often caused by:",
                options: ["Overuse of pain medication", "Too much exercise", "Too much water", "Allergic reactions"],
                answer: "Overuse of pain medication",
                explanation: "Overusing headache medication can cause rebound headaches, making pain worse.",
                hint: "Ironically, too much medicine can trigger them."
            ),
            Question(
                text: "Which headache type is often localized behind one eye?",
                options: ["Cluster headache", "Tension headache", "Sinus headache", "Migraine with aura"],
                answer: "Cluster headache",
                explanation: "Cluster headaches cause severe pain often centered around one eye.",
                hint: "It’s the most excruciating headache."
            ),
            Question(
                text: "What daily habit is most protective against tension headaches?",
                options: ["Regular sleep schedule", "Skipping meals", "Overuse of caffeine", "Working nonstop"],
                answer: "Regular sleep schedule",
                explanation: "Consistent sleep reduces stress and prevents tension headaches.",
                hint: "Think bedtime routines."
            )
        ]),
        
        // Level 4: Expert
        QuizLevel(level: 4, questions: [
            Question(
                text: "Which of these foods is a common migraine trigger?",
                options: ["Aged cheese", "Rice", "Bananas", "Apples"],
                answer: "Aged cheese",
                explanation: "Aged cheese contains tyramine, a common migraine trigger.",
                hint: "It’s a dairy product that’s aged."
            ),
            Question(
                text: "Which gender is more affected by migraines?",
                options: ["Women", "Men", "Equal", "Children only"],
                answer: "Women",
                explanation: "Migraines affect women more, likely due to hormonal influences.",
                hint: "Hormonal cycles play a role."
            ),
            Question(
                text: "What’s the main difference between sinus headaches and migraines?",
                options: ["Sinus headaches include nasal symptoms", "Migraines cause tooth pain", "Sinus headaches never recur", "Migraines always happen at night"],
                answer: "Sinus headaches include nasal symptoms",
                explanation: "Sinus headaches involve congestion and pressure in the face.",
                hint: "It’s about the nose."
            ),
            Question(
                text: "Which imaging test may be ordered for unexplained severe headaches?",
                options: ["MRI", "X-ray", "Ultrasound", "CT of abdomen"],
                answer: "MRI",
                explanation: "An MRI or CT scan of the brain can help rule out structural issues.",
                hint: "It’s advanced brain imaging."
            ),
            Question(
                text: "Which headache type is sometimes called 'suicide headache'?",
                options: ["Cluster headache", "Migraine with aura", "Tension headache", "Sinus headache"],
                answer: "Cluster headache",
                explanation: "Cluster headaches are extremely painful, earning the nickname 'suicide headache.'",
                hint: "It’s the most severe type of headache."
            )
        ]),
        
        // Level 5: Mastery
        QuizLevel(level: 5, questions: [
            Question(
                text: "Which medication is specifically designed for migraines?",
                options: ["Triptans", "Antibiotics", "Beta blockers", "NSAIDs"],
                answer: "Triptans",
                explanation: "Triptans are a class of drugs developed specifically for migraines.",
                hint: "Their names usually end in -triptan."
            ),
            Question(
                text: "What’s the most effective acute treatment for cluster headaches?",
                options: ["High-flow oxygen therapy", "Drinking coffee", "Cold showers", "Sleeping"],
                answer: "High-flow oxygen therapy",
                explanation: "Inhaling pure oxygen can quickly relieve cluster headaches.",
                hint: "It’s a gas you breathe in."
            ),
            Question(
                text: "Which preventive medication is often used for chronic migraines?",
                options: ["Beta blockers", "Antibiotics", "Antihistamines", "Steroids"],
                answer: "Beta blockers",
                explanation: "Beta blockers like propranolol are commonly prescribed for migraine prevention.",
                hint: "They are also used for heart conditions."
            ),
            Question(
                text: "Which part of the brain is strongly linked with migraine onset?",
                options: ["Brainstem", "Cerebellum", "Amygdala", "Hippocampus"],
                answer: "Brainstem",
                explanation: "The brainstem plays a central role in migraine initiation and regulation.",
                hint: "It connects the brain and spinal cord."
            ),
            Question(
                text: "Status migrainosus is:",
                options: ["A migraine lasting longer than 72 hours", "A type of sinus infection", "A rare type of tension headache", "A migraine with aura only"],
                answer: "A migraine lasting longer than 72 hours",
                explanation: "Status migrainosus is a prolonged migraine requiring urgent medical attention.",
                hint: "It lasts more than 3 days."
            )
        ])
    ]
)
let allCategories: [QuizCategory] = [
    cardiacArrestCategory,
    headachesCategory,
    nutritionCategory,
    sleepCategory,
    diabetesCategory,
    hypertensionCategory,
    exerciseCategory,
    mentalHealthCategory,
    immunityCategory,
    firstAidCategory,
    
]



