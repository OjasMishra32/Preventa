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
                            // 🔒 Locked card
                            levelRow(theme: theme, level: quizLevel, locked: true)
                                .overlay(
                                    Image(systemName: "lock.fill")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 20),
                                    alignment: .trailing
                                )
                                .opacity(0.6)
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
    
    // MARK: - Header
    private func header(theme: TopicTheme) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: theme.colors,
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                    .shadow(color: (theme.colors.last ?? .black).opacity(0.6),
                            radius: 10, y: 6)
                Image(systemName: theme.icon)
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text(category.topic)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Level Row
    private func levelRow(theme: TopicTheme, level: QuizLevel, locked: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: theme.colors,
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                    .frame(width: 54, height: 54)
                    .shadow(color: (theme.colors.last ?? .black).opacity(0.5),
                            radius: 8, y: 4)
                
                Text("\(level.level)")
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Level \(level.level)")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(locked ? "Locked" : "\(level.questions.count) questions")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
            }
            
            Spacer()
            
            Image(systemName: locked ? "lock.fill" : "chevron.right")
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }
}
