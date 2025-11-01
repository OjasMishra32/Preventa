import Foundation
import HealthKit
import SwiftUI

// MARK: - Health Insight Model

struct HealthInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let icon: String
    let color: Color
    let priority: Priority
    
    enum InsightType {
        case trend
        case recommendation
        case achievement
        case warning
    }
    
    enum Priority {
        case high
        case medium
        case low
    }
}

// MARK: - Health Insight Generator

class HealthInsightGenerator {
    static let shared = HealthInsightGenerator()
    
    private init() {}
    
    func generateInsights(from healthData: HealthData, weeklySteps: [Date: Int]) async -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Generate AI-powered insights first
        if let aiInsight = await generateAIInsight(healthData: healthData, weeklySteps: weeklySteps) {
            insights.append(aiInsight)
        }
        
        // Add rule-based insights as backup/enhancement
        insights.append(contentsOf: analyzeSteps(healthData: healthData, weeklySteps: weeklySteps))
        insights.append(contentsOf: analyzeSleep(healthData: healthData))
        insights.append(contentsOf: analyzeHeartRate(healthData: healthData))
        insights.append(contentsOf: analyzeActivity(healthData: healthData))
        insights.append(contentsOf: analyzeHydration(healthData: healthData))
        insights.append(contentsOf: analyzeCorrelations(healthData: healthData))
        
        // Sort by priority
        insights.sort { $0.priority.rawValue > $1.priority.rawValue }
        
        return Array(insights.prefix(5)) // Return top 5 insights
    }
    
    // MARK: - AI-Powered Insight Generation (Disabled to save API calls)
    
    private func generateAIInsight(healthData: HealthData, weeklySteps: [Date: Int]) async -> HealthInsight? {
        // AI insight generation disabled to reduce API usage
        // Rule-based insights below provide sufficient functionality
        return nil
    }
    
    private func analyzeWeeklyTrends(weeklySteps: [Date: Int]) -> String {
        guard weeklySteps.count >= 3 else { return "Not enough data" }
        
        let sorted = weeklySteps.sorted { $0.key < $1.key }
        let recent = sorted.suffix(3).map { $0.value }
        let earlier = sorted.prefix(3).map { $0.value }
        
        let recentAvg = recent.reduce(0, +) / recent.count
        let earlierAvg = earlier.reduce(0, +) / earlier.count
        
        if Double(recentAvg) > Double(earlierAvg) * 1.1 {
            let percent = Int((Double(recentAvg - earlierAvg) / Double(max(earlierAvg, 1))) * 100)
            return "Steps increasing (+\(percent)%)"
        } else if Double(recentAvg) < Double(earlierAvg) * 0.9 {
            return "Steps decreasing"
        } else {
            return "Steps stable"
        }
    }
    
    // MARK: - Analysis Methods
    
    private func analyzeSteps(healthData: HealthData, weeklySteps: [Date: Int]) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Today's steps vs goal
        if healthData.steps > 0 {
            let progress = healthData.stepsProgress
            if progress >= 1.0 {
                insights.append(HealthInsight(
                    type: .achievement,
                    title: "Steps Goal Achieved!",
                    message: "You've reached your daily step goal of \(healthData.stepsGoal) steps. Great job staying active!",
                    icon: "figure.walk",
                    color: .green,
                    priority: .high
                ))
            } else if progress >= 0.8 {
                insights.append(HealthInsight(
                    type: .recommendation,
                    title: "Almost There!",
                    message: "You're at \(Int(progress * 100))% of your step goal. Just \(healthData.stepsGoal - healthData.steps) more steps to reach it!",
                    icon: "figure.walk",
                    color: .orange,
                    priority: .medium
                ))
            } else if progress < 0.5 {
                insights.append(HealthInsight(
                    type: .recommendation,
                    title: "Boost Your Activity",
                    message: "You've taken \(healthData.steps) steps today. Try a short walk to increase your activity level.",
                    icon: "figure.walk",
                    color: .blue,
                    priority: .medium
                ))
            }
        }
        
        // Weekly trend
        if weeklySteps.count >= 3 {
            let sortedSteps = weeklySteps.sorted { $0.key < $1.key }
            let recentAvg = sortedSteps.suffix(3).map { $0.value }.reduce(0, +) / 3
            let earlierAvg = sortedSteps.prefix(3).map { $0.value }.reduce(0, +) / 3
            
            if Double(recentAvg) > Double(earlierAvg) * 1.15 {
                insights.append(HealthInsight(
                    type: .trend,
                    title: "Activity Trend: Upward",
                    message: "Your average daily steps have increased by \(Int((Double(recentAvg) / Double(earlierAvg) - 1.0) * 100))% this week. Keep it up!",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    priority: .high
                ))
            } else if Double(recentAvg) < Double(earlierAvg) * 0.85 {
                insights.append(HealthInsight(
                    type: .warning,
                    title: "Activity Decreasing",
                    message: "Your step count has decreased recently. Consider adding a daily walk to maintain your activity level.",
                    icon: "chart.line.downtrend.xyaxis",
                    color: .orange,
                    priority: .medium
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeSleep(healthData: HealthData) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        if healthData.sleepHours > 0 {
            if healthData.sleepHours >= 7 && healthData.sleepHours <= 9 {
                insights.append(HealthInsight(
                    type: .achievement,
                    title: "Great Sleep Last Night",
                    message: "You got \(String(format: "%.1f", healthData.sleepHours)) hours of sleep. This is within the recommended 7-9 hour range for adults.",
                    icon: "bed.double.fill",
                    color: .green,
                    priority: .high
                ))
            } else if healthData.sleepHours < 6 {
                insights.append(HealthInsight(
                    type: .warning,
                    title: "Insufficient Sleep",
                    message: "You got only \(String(format: "%.1f", healthData.sleepHours)) hours of sleep. Aim for 7-9 hours for optimal health.",
                    icon: "bed.double.fill",
                    color: .orange,
                    priority: .high
                ))
            } else if healthData.sleepHours > 10 {
                insights.append(HealthInsight(
                    type: .recommendation,
                    title: "Excessive Sleep",
                    message: "You slept \(String(format: "%.1f", healthData.sleepHours)) hours. While rest is important, too much sleep may indicate underlying issues.",
                    icon: "bed.double.fill",
                    color: .blue,
                    priority: .medium
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeHeartRate(healthData: HealthData) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        if healthData.heartRate > 0 {
            // Normal resting heart rate is 60-100 bpm
            if healthData.heartRate < 60 {
                insights.append(HealthInsight(
                    type: .recommendation,
                    title: "Low Resting Heart Rate",
                    message: "Your resting heart rate is \(healthData.heartRate) bpm. This is low and may indicate good cardiovascular fitness.",
                    icon: "heart.fill",
                    color: .green,
                    priority: .low
                ))
            } else if healthData.heartRate > 100 {
                insights.append(HealthInsight(
                    type: .warning,
                    title: "Elevated Heart Rate",
                    message: "Your heart rate is \(healthData.heartRate) bpm. If this persists at rest, consider consulting a healthcare provider.",
                    icon: "heart.fill",
                    color: .orange,
                    priority: .high
                ))
            } else {
                insights.append(HealthInsight(
                    type: .achievement,
                    title: "Healthy Heart Rate",
                    message: "Your resting heart rate of \(healthData.heartRate) bpm is within the normal range (60-100 bpm).",
                    icon: "heart.fill",
                    color: .green,
                    priority: .low
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeActivity(healthData: HealthData) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        if healthData.activeCalories > 0 {
            // Typical daily active calories for sedentary: 200-400, active: 600-1000+
            if healthData.activeCalories >= 600 {
                insights.append(HealthInsight(
                    type: .achievement,
                    title: "Active Day!",
                    message: "You've burned \(healthData.activeCalories) active calories today. Your body is getting great movement!",
                    icon: "flame.fill",
                    color: .orange,
                    priority: .medium
                ))
            } else if healthData.activeCalories < 300 {
                insights.append(HealthInsight(
                    type: .recommendation,
                    title: "Increase Movement",
                    message: "Try to increase your daily activity. Even a 10-minute walk can help boost your active calorie burn.",
                    icon: "figure.walk",
                    color: .blue,
                    priority: .medium
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeHydration(healthData: HealthData) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        if healthData.waterIntakeOz > 0 {
            let progress = healthData.waterProgress
            if progress >= 1.0 {
                insights.append(HealthInsight(
                    type: .achievement,
                    title: "Hydration Goal Met!",
                    message: "You've consumed \(String(format: "%.1f", healthData.waterIntakeOz)) oz of water today. Excellent hydration!",
                    icon: "drop.fill",
                    color: .cyan,
                    priority: .medium
                ))
            } else if progress < 0.5 {
                insights.append(HealthInsight(
                    type: .recommendation,
                    title: "Stay Hydrated",
                    message: "You're at \(Int(progress * 100))% of your hydration goal. Try drinking more water throughout the day.",
                    icon: "drop.fill",
                    color: .blue,
                    priority: .medium
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeCorrelations(healthData: HealthData) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Sleep and steps correlation
        if healthData.sleepHours >= 7 && healthData.sleepHours <= 9 && healthData.steps >= healthData.stepsGoal * Int(0.8) {
            insights.append(HealthInsight(
                type: .achievement,
                title: "Great Balance!",
                message: "You're maintaining a healthy balance of sleep and activity. This combination supports overall wellness.",
                icon: "star.fill",
                color: .purple,
                priority: .high
            ))
        }
        
        // Activity and calories
        if healthData.activeCalories >= 500 && healthData.dietaryCalories > 0 {
            let ratio = Double(healthData.activeCalories) / Double(healthData.dietaryCalories)
            if ratio > 0.3 {
                insights.append(HealthInsight(
                    type: .trend,
                    title: "Active Lifestyle",
                    message: "Your activity level is well-matched with your calorie intake. Keep maintaining this balance!",
                    icon: "figure.run",
                    color: .green,
                    priority: .medium
                ))
            }
        }
        
        return insights
    }
}

extension HealthInsight.Priority: Comparable {
    var rawValue: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    static func < (lhs: HealthInsight.Priority, rhs: HealthInsight.Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

