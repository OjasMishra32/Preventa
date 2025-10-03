import SwiftUI

final class QuizManager: ObservableObject {
    @Published var completedQuizzes: Int = UserDefaults.standard.integer(forKey: "completedQuizzes")
    @Published var learningTime: TimeInterval = UserDefaults.standard.double(forKey: "learningTime")
    @Published var streak: Int = UserDefaults.standard.integer(forKey: "streak")
    @Published var lastPlayed: Date? = UserDefaults.standard.object(forKey: "lastPlayed") as? Date
    
    @Published var xp: Int = UserDefaults.standard.integer(forKey: "xp")
    @Published var level: Int = UserDefaults.standard.integer(forKey: "level") == 0 ? 1 : UserDefaults.standard.integer(forKey: "level")
    
    // ✅ New: Track unlocked levels per category (keyed by category ID or title)
    @Published var unlockedLevels: [String: Int] =
        (UserDefaults.standard.dictionary(forKey: "unlockedLevels") as? [String: Int]) ?? [:]
    
    private var sessionStart: Date?
    private var timer: Timer?
    
    private let xpPerCorrect = 10
    private let xpPerQuizCompletion = 25
    private let xpCostHint = 5
    
    // MARK: - Session Tracking
    func startSession() {
        sessionStart = Date()
        startTimer()
    }
    
    func endSession() {
        stopTimer()
        guard let start = sessionStart else { return }
        let elapsed = Date().timeIntervalSince(start)
        learningTime += elapsed
        UserDefaults.standard.set(learningTime, forKey: "learningTime")
        sessionStart = nil
    }
    
    // MARK: - Quiz Progress / XP
    func recordCorrectAnswer() { addXP(xpPerCorrect) }
    func recordHintUsed() { addXP(-xpCostHint) }
    
    func completeQuiz(title: String) {
        completedQuizzes += 1
        UserDefaults.standard.set(completedQuizzes, forKey: "completedQuizzes")
        addXP(xpPerQuizCompletion)
        updateStreak()
    }
    
    private func addXP(_ delta: Int) {
        xp = max(0, xp + delta)
        UserDefaults.standard.set(xp, forKey: "xp")
        while xp >= xpThreshold(for: level) {
            xp -= xpThreshold(for: level)
            level += 1
            UserDefaults.standard.set(level, forKey: "level")
        }
    }
    
    private func xpThreshold(for level: Int) -> Int {
        100 + (level - 1) * 25
    }
    
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastPlayed {
            let lastDay = Calendar.current.startOfDay(for: last)
            if Calendar.current.isDateInYesterday(lastDay) {
                streak += 1
            } else if lastDay != today {
                streak = 1
            }
        } else {
            streak = 1
        }
        lastPlayed = today
        UserDefaults.standard.set(streak, forKey: "streak")
        UserDefaults.standard.set(today, forKey: "lastPlayed")
    }
    
    // MARK: - Timer
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.sessionStart else { return }
            let elapsed = Date().timeIntervalSince(start)
            let total = UserDefaults.standard.double(forKey: "learningTime")
            DispatchQueue.main.async {
                self.learningTime = total + elapsed
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - 🔒 Level Unlocking
    func highestUnlockedLevel(for categoryKey: String) -> Int {
        max(1, unlockedLevels[categoryKey] ?? 1)
    }
    
    func unlockNextLevel(in categoryKey: String, currentLevel: Int) {
        let current = highestUnlockedLevel(for: categoryKey)
        guard currentLevel >= current, currentLevel < 5 else { return }
        unlockedLevels[categoryKey] = currentLevel + 1
        UserDefaults.standard.set(unlockedLevels, forKey: "unlockedLevels")
    }
}
