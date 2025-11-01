import SwiftUI

struct CategoryDetailView: View {
    let category: QuizCategory
    @EnvironmentObject var quizManager: QuizManager
    
    var body: some View {
        let theme = topicThemes[category.topic] ??
            TopicTheme(colors: appGradient, icon: "questionmark.circle")
        
        ZStack {
            LinearGradient(colors: theme.colors,
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            BackgroundParticles(colors: theme.colors)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header(theme: theme)
                    
                    // Levels 1 → 5, locked sequentially
                    ForEach(category.levels.sorted(by: { $0.level < $1.level }), id: \.id) { quizLevel in
                        let unlocked = quizLevel.level <= quizManager.highestUnlockedLevel(for: category.id.uuidString)
                        
                        if unlocked {
                            NavigationLink {
                                QuizDetailView(category: category, level: quizLevel)
                                    .onDisappear {
                                        quizManager.unlockNextLevel(
                                            in: category.id.uuidString,
                                            currentLevel: quizLevel.level
                                        )
                                    }
                            } label: {
                                levelRow(theme: theme, level: quizLevel, locked: false)
                            }
                            .buttonStyle(QuizCardButtonStyle())
                            .padding(.horizontal)
                        } else {
                            // 🔒 Locked card (lock is already shown in levelRow, no need for overlay)
                            levelRow(theme: theme, level: quizLevel, locked: true)
                                .opacity(0.65)
                                .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical, 20)
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Modern Header
    private func header(theme: TopicTheme) -> some View {
        GlassCard {
            HStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.colors[0].opacity(0.5),
                                    theme.colors[1].opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 15,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .blur(radius: 15)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: theme.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: (theme.colors.last ?? .black).opacity(0.6), radius: 12, y: 6)
                    
                    Image(systemName: theme.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(category.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text(category.topic)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                    
                    HStack(spacing: 12) {
                        Label("\(category.levels.count) Levels", systemImage: "list.number")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                
                Spacer()
            }
            .padding(20)
        }
        .padding(.horizontal, 22)
    }
    
    // MARK: - Modern Level Row
    private func levelRow(theme: TopicTheme, level: QuizLevel, locked: Bool) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        locked
                            ? LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.4),
                                    Color.gray.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: theme.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(
                        color: locked
                            ? Color.black.opacity(0.2)
                            : (theme.colors.last ?? .black).opacity(0.5),
                        radius: locked ? 6 : 10,
                        y: locked ? 3 : 6
                    )
                
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                } else {
                    Text("\(level.level)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Level \(level.level)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                
                HStack(spacing: 8) {
                    if locked {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                            Text("Locked")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    } else {
                        Label("\(level.questions.count) questions", systemImage: "questionmark.circle")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            if !locked {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(locked ? 0.08 : 0.15),
                                    Color.white.opacity(locked ? 0.04 : 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(locked ? 0.12 : 0.25),
                                    Color.white.opacity(locked ? 0.06 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(
            color: locked ? Color.black.opacity(0.1) : Color.black.opacity(0.15),
            radius: locked ? 6 : 10,
            y: locked ? 3 : 5
        )
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }
}
