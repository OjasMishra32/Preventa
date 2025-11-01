import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Comprehensive progress calculator that tracks user activity across the app
final class ProgressCalculator: ObservableObject {
    static let shared = ProgressCalculator()
    
    @Published var todayProgress: CGFloat = 0.0
    
    private let db = Firestore.firestore()
    private var uid: String? { Auth.auth().currentUser?.uid }
    
    // Default goals (can be customized per user)
    private struct DefaultGoals {
        static let stepsGoal: Int = 10000
        static let caloriesGoal: Int = 500
        static let sleepHoursGoal: Double = 8.0
        static let waterOzGoal: Double = 64.0
    }
    
    private init() {
        Task {
            await calculateTodayProgress()
        }
    }
    
    /// Calculate comprehensive progress for today
    func calculateTodayProgress() async {
        guard let uid = uid else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        var totalScore: Double = 0.0
        var maxScore: Double = 0.0
        
        // MARK: 1. Health Goals (40% weight)
        let healthWeight = 0.40
        maxScore += healthWeight
        
        let healthScore = await calculateHealthProgress(startOfDay: startOfDay)
        totalScore += healthScore * healthWeight
        
        // MARK: 2. Learning Activity (15% weight)
        let learningWeight = 0.15
        maxScore += learningWeight
        
        let learningScore = await calculateLearningProgress(startOfDay: startOfDay, uid: uid)
        totalScore += learningScore * learningWeight
        
        // MARK: 3. Visual Checks (10% weight)
        let visualWeight = 0.10
        maxScore += visualWeight
        
        let visualScore = await calculateVisualChecksProgress(startOfDay: startOfDay, uid: uid)
        totalScore += visualScore * visualWeight
        
        // MARK: 4. Medications Adherence (15% weight)
        let medicationWeight = 0.15
        maxScore += medicationWeight
        
        let medicationScore = await calculateMedicationProgress(startOfDay: startOfDay, uid: uid)
        totalScore += medicationScore * medicationWeight
        
        // MARK: 5. Action Plans Completion (10% weight)
        let actionWeight = 0.10
        maxScore += actionWeight
        
        let actionScore = await calculateActionPlansProgress(startOfDay: startOfDay, uid: uid)
        totalScore += actionScore * actionWeight
        
        // MARK: 6. Check-ins (10% weight)
        let checkinWeight = 0.10
        maxScore += checkinWeight
        
        let checkinScore = await calculateCheckInsProgress(startOfDay: startOfDay, uid: uid)
        totalScore += checkinScore * checkinWeight
        
        // Calculate final percentage (0.0 to 1.0)
        let finalProgress = maxScore > 0 ? (totalScore / maxScore) : 0.0
        
        await MainActor.run {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                self.todayProgress = min(1.0, max(0.0, CGFloat(finalProgress)))
            }
            
            // Generate AI insight about progress
            Task {
                let activities: [String: Any] = [
                    "Health Goals": String(format: "%.0f%%", healthScore * 100),
                    "Learning": String(format: "%.0f%%", learningScore * 100),
                    "Visual Checks": String(format: "%.0f%%", visualScore * 100),
                    "Medications": String(format: "%.0f%%", medicationScore * 100),
                    "Action Plans": String(format: "%.0f%%", actionScore * 100),
                    "Check-ins": String(format: "%.0f%%", checkinScore * 100)
                ]
                
                // Removed AI progress insight to save API usage
            }
        }
    }
    
    // MARK: - Health Progress Calculation
    
    private func calculateHealthProgress(startOfDay: Date) async -> Double {
        let healthManager = HealthKitManager.shared
        let waterTracker = WaterTrackerManager.shared
        
        // Wait for data to load if needed
        if healthManager.healthData.steps == 0 {
            healthManager.loadHealthData()
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second
        }
        
        var healthScore: Double = 0.0
        var healthMax: Double = 0.0
        
        // Steps Progress (25% of health score)
        let stepsProgress = min(1.0, Double(healthManager.healthData.steps) / Double(DefaultGoals.stepsGoal))
        healthScore += stepsProgress * 0.25
        healthMax += 0.25
        
        // Active Calories Progress (25% of health score)
        let caloriesProgress = min(1.0, Double(healthManager.healthData.activeCalories) / Double(DefaultGoals.caloriesGoal))
        healthScore += caloriesProgress * 0.25
        healthMax += 0.25
        
        // Sleep Progress (25% of health score)
        let sleepProgress = min(1.0, healthManager.healthData.sleepHours / DefaultGoals.sleepHoursGoal)
        healthScore += sleepProgress * 0.25
        healthMax += 0.25
        
        // Water Intake Progress (25% of health score)
        let waterProgress = min(1.0, waterTracker.todaysIntake / DefaultGoals.waterOzGoal)
        healthScore += waterProgress * 0.25
        healthMax += 0.25
        
        // Bonus: Heart rate tracking (small bonus if tracked)
        if healthManager.healthData.heartRate > 0 {
            healthScore += 0.05 // 5% bonus
            healthMax += 0.05
        }
        
        return healthMax > 0 ? (healthScore / healthMax) : 0.0
    }
    
    // MARK: - Learning Progress Calculation
    
    private func calculateLearningProgress(startOfDay: Date, uid: String) async -> Double {
        do {
            // Check for quizzes completed today
            let snapshot = try await db.collection("users").document(uid)
                .collection("quizCompletions")
                .whereField("completedAt", isGreaterThan: Timestamp(date: startOfDay))
                .getDocuments()
            
            let completionsCount = snapshot.documents.count
            
            // 1 quiz = 25%, 2 = 50%, 3+ = 100%
            if completionsCount >= 3 {
                return 1.0
            } else if completionsCount == 2 {
                return 0.5
            } else if completionsCount == 1 {
                return 0.25
            } else {
                // Check if they spent time learning (even without completion)
                let quizManager = QuizManager()
                let learningTimeMinutes = Int(quizManager.learningTime / 60)
                
                // 15+ minutes = 50%, 30+ = 75%
                if learningTimeMinutes >= 30 {
                    return 0.75
                } else if learningTimeMinutes >= 15 {
                    return 0.50
                } else if learningTimeMinutes >= 5 {
                    return 0.25
                }
                
                return 0.0
            }
        } catch {
            print("Error calculating learning progress: \(error)")
            return 0.0
        }
    }
    
    // MARK: - Visual Checks Progress Calculation
    
    private func calculateVisualChecksProgress(startOfDay: Date, uid: String) async -> Double {
        do {
            let snapshot = try await db.collection("users").document(uid)
                .collection("visualPhotos")
                .whereField("createdAt", isGreaterThan: Timestamp(date: startOfDay))
                .getDocuments()
            
            let photosCount = snapshot.documents.count
            
            // 1 photo = 50%, 2+ = 100%
            if photosCount >= 2 {
                return 1.0
            } else if photosCount == 1 {
                return 0.5
            }
            
            return 0.0
        } catch {
            print("Error calculating visual checks progress: \(error)")
            return 0.0
        }
    }
    
    // MARK: - Medication Progress Calculation
    
    private func calculateMedicationProgress(startOfDay: Date, uid: String) async -> Double {
        do {
            // Get all medications
            let medsSnapshot = try await db.collection("users").document(uid)
                .collection("medications")
                .getDocuments()
            
            let totalMeds = medsSnapshot.documents.count
            
            if totalMeds == 0 {
                // No medications set = full score (no penalty)
                return 1.0
            }
            
            // Get today's medication logs
            let logsSnapshot = try await db.collection("users").document(uid)
                .collection("medicationLogs")
                .whereField("timestamp", isGreaterThan: Timestamp(date: startOfDay))
                .getDocuments()
            
            let loggedCount = logsSnapshot.documents.count
            
            // Calculate adherence percentage
            let adherence = totalMeds > 0 ? Double(loggedCount) / Double(totalMeds) : 1.0
            
            // Minimum 2 doses expected per day (can be adjusted)
            let expectedDoses = totalMeds * 2
            let actualDoses = loggedCount
            
            if actualDoses >= expectedDoses {
                return 1.0
            } else if actualDoses >= expectedDoses / 2 {
                return 0.75
            } else if actualDoses >= 1 {
                return 0.5
            }
            
            return min(1.0, adherence)
        } catch {
            print("Error calculating medication progress: \(error)")
            return 0.0
        }
    }
    
    // MARK: - Action Plans Progress Calculation
    
    private func calculateActionPlansProgress(startOfDay: Date, uid: String) async -> Double {
        do {
            // Get action plans due today or recently completed
            let today = Date()
            let cal = Calendar.current
            let tomorrow = cal.date(byAdding: .day, value: 1, to: startOfDay) ?? today
            
            let snapshot = try await db.collection("users").document(uid)
                .collection("actionPlans")
                .whereField("dueDate", isGreaterThan: Timestamp(date: startOfDay))
                .whereField("dueDate", isLessThan: Timestamp(date: tomorrow))
                .getDocuments()
            
            let plansDueToday = snapshot.documents.compactMap { doc -> ActionPlan? in
                try? doc.data(as: ActionPlan.self)
            }
            
            if plansDueToday.isEmpty {
                // No action plans = full score
                return 1.0
            }
            
            let completedToday = plansDueToday.filter { plan in
                // Check if completed today
                if let completedAt = plan.completedAt {
                    return Calendar.current.isDate(completedAt, inSameDayAs: today)
                }
                return plan.isCompleted
            }
            
            let completionRate = plansDueToday.count > 0 
                ? Double(completedToday.count) / Double(plansDueToday.count)
                : 1.0
            
            return completionRate
        } catch {
            print("Error calculating action plans progress: \(error)")
            return 0.0
        }
    }
    
    // MARK: - Check-ins Progress Calculation
    
    private func calculateCheckInsProgress(startOfDay: Date, uid: String) async -> Double {
        do {
            let snapshot = try await db.collection("users").document(uid)
                .collection("checkIns")
                .whereField("timestamp", isGreaterThan: Timestamp(date: startOfDay))
                .getDocuments()
            
            let checkInsCount = snapshot.documents.count
            
            // 1 check-in = 50%, 2+ = 100%
            if checkInsCount >= 2 {
                return 1.0
            } else if checkInsCount == 1 {
                return 0.5
            }
            
            return 0.0
        } catch {
            print("Error calculating check-ins progress: \(error)")
            return 0.0
        }
    }
    
}

// MARK: - Supporting Models

struct ActionPlan: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let dueDate: Date
    let isCompleted: Bool
    let completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description
        case dueDate = "dueDate"
        case isCompleted, completedAt
    }
}

