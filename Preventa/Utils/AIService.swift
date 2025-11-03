import Foundation
import UIKit

// Centralized AI service for all AI functionality across the app
final class AIService {
    static let shared = AIService()
    
    private init() {}
    
    // MARK: - API Configuration
    
    private var apiKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              key.trimmingCharacters(in: .whitespacesAndNewlines) != "YOUR_GEMINI_API_KEY_HERE" else {
            return nil
        }
        return key.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private let model = "gemini-2.5-flash-lite"  // Gemini 2.5 Flash Lite with higher rate limits
    
    // MARK: - Generic AI Completion
    
    func generateCompletion(
        systemPrompt: String,
        userPrompt: String,
        context: [String: Any]? = nil,
        maxTokens: Int = 350,
        temperature: Double = 0.7
    ) async -> String? {
        guard let key = apiKey else {
            print("❌ AI: Gemini API key not found")
            return nil
        }
        
        var fullSystemPrompt = systemPrompt
        
        // Add context if provided
        if let context = context, !context.isEmpty {
            let contextStr = context.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            fullSystemPrompt += "\n\nContext:\n\(contextStr)"
        }
        
        // Gemini API endpoint - use v1beta with Gemini 2.5 Flash Lite
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(key)") else {
            print("❌ AI: Invalid Gemini API URL")
            return nil
        }
        
        // Build Gemini content structure
        let contents: [[String: Any]] = [
            [
                "role": "user",
                "parts": [
                    ["text": userPrompt]
                ]
            ]
        ]
        
        // System instruction
        let systemInstruction: [String: Any] = [
            "parts": [
                ["text": fullSystemPrompt]
            ]
        ]
        
        // Generation config
        let generationConfig: [String: Any] = [
            "temperature": temperature,
            "top_p": 1.0,
            "max_output_tokens": maxTokens
        ]
        
        let body: [String: Any] = [
            "contents": contents,
            "system_instruction": systemInstruction,
            "generation_config": generationConfig
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: body)
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.httpBody = data
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Preventa/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
            req.timeoutInterval = 90  // Increased timeout for better reliability
            req.cachePolicy = .reloadIgnoringLocalCacheData
            
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 90  // Increased for better reliability
            config.timeoutIntervalForResource = 120  // Increased total timeout
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            config.urlCache = nil
            config.waitsForConnectivity = true  // Wait for connectivity instead of failing immediately
            config.httpMaximumConnectionsPerHost = 2  // Allow multiple connections for retries
            config.networkServiceType = .default
            config.allowsCellularAccess = true
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
            let session = URLSession(configuration: config)
            
            let (respData, resp) = try await session.data(for: req)
            
            if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                print("❌ AI: Gemini HTTP \(http.statusCode)")
                if let bodyStr = String(data: respData, encoding: .utf8) {
                    print("❌ AI: Error response: \(bodyStr.prefix(200))")
                }
                return nil
            }
            
            // Parse Gemini response format
            guard let root = try JSONSerialization.jsonObject(with: respData) as? [String: Any],
                  let candidates = root["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                print("❌ AI: Invalid Gemini response format")
                return nil
            }
            
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("❌ AI: Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Health Insights
    
    func generateHealthInsight(
        metrics: [String: Any],
        recentTrends: String = ""
    ) async -> String? {
        let systemPrompt = """
        You are a health coach AI assistant. Analyze health metrics and provide personalized insights.
        Be encouraging, specific, and actionable. Focus on trends and safe recommendations.
        Keep responses under 150 words.
        """
        
        let userPrompt = """
        Analyze these health metrics:
        \(metrics.map { "\($0.key): \($0.value)" }.joined(separator: "\n"))
        
        Recent trends: \(recentTrends)
        
        Provide a personalized health insight with actionable recommendations.
        """
        
        return await generateCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 200
        )
    }
    
    // MARK: - Visual Check Analysis
    
    func analyzeVisualPhoto(
        category: String,
        previousNotes: [String] = []
    ) async -> String? {
        let systemPrompt = """
        You are a medical AI assistant analyzing visual health photos.
        Provide observations about changes, patterns, or notable features.
        Do NOT diagnose. Frame observations neutrally.
        Keep responses under 100 words.
        """
        
        let userPrompt = """
        Analyze a \(category) photo.
        Previous observations: \(previousNotes.isEmpty ? "None" : previousNotes.joined(separator: "; "))
        
        Provide observational notes about any notable features or changes.
        """
        
        return await generateCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 150
        )
    }
    
    // MARK: - Food/Meal Analysis
    
    func analyzeMeal(
        mealName: String,
        calories: Int,
        mealType: String,
        recentMeals: [String] = []
    ) async -> String? {
        let systemPrompt = """
        You are a nutrition AI assistant. Analyze meals and provide nutritional insights.
        Be encouraging and educational. Suggest improvements when helpful.
        Keep responses under 120 words.
        """
        
        let userPrompt = """
        Meal: \(mealName)
        Calories: \(calories)
        Type: \(mealType)
        Recent meals: \(recentMeals.isEmpty ? "None today" : recentMeals.joined(separator: ", "))
        
        Provide nutritional insights and suggestions.
        """
        
        return await generateCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 150
        )
    }
    
    // MARK: - Progress Insights
    
    func generateProgressInsight(
        progress: Double,
        activities: [String: Any],
        goals: [String: Any] = [:]
    ) async -> String? {
        let systemPrompt = """
        You are a health coach AI. Analyze daily progress and provide motivational insights.
        Celebrate achievements and suggest areas for improvement.
        Be encouraging and specific.
        Keep responses under 100 words.
        """
        
        let userPrompt = """
        Today's progress: \(Int(progress * 100))%
        Activities completed: \(activities.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
        Goals: \(goals.isEmpty ? "Default goals" : goals.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
        
        Provide a motivational insight about today's progress.
        """
        
        return await generateCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 150
        )
    }
    
    // MARK: - Symptom Analysis (Body Map)
    
    func analyzeSymptom(
        bodyRegion: String,
        symptomDescription: String,
        painLevel: Int? = nil,
        duration: String? = nil,
        context: String = ""
    ) async -> String? {
        let systemPrompt = """
        You are a medical AI assistant analyzing symptoms and pain reports.
        Provide guidance on potential causes and safe next steps.
        Do NOT diagnose. Suggest when to see a healthcare provider.
        Keep responses under 150 words.
        """
        
        var userPrompt = """
        Body region: \(bodyRegion)
        Symptom: \(symptomDescription)
        """
        
        if let painLevel = painLevel {
            userPrompt += "\nPain level (1-10): \(painLevel)"
        }
        
        if let duration = duration {
            userPrompt += "\nDuration: \(duration)"
        }
        
        if !context.isEmpty {
            userPrompt += "\nContext: \(context)"
        }
        
        userPrompt += "\n\nProvide guidance on possible causes and safe next steps."
        
        return await generateCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 200
        )
    }
    
    // MARK: - Medication Advice
    
    func provideMedicationAdvice(
        medicationName: String,
        timing: String,
        adherence: Double,
        notes: String = ""
    ) async -> String? {
        let systemPrompt = """
        You are a medication management AI assistant.
        Provide reminders, adherence encouragement, and safety tips.
        Keep responses under 100 words.
        """
        
        let userPrompt = """
        Medication: \(medicationName)
        Timing: \(timing)
        Adherence: \(Int(adherence * 100))%
        Notes: \(notes.isEmpty ? "None" : notes)
        
        Provide helpful advice about medication management.
        """
        
        return await generateCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 120
        )
    }
    
    // MARK: - Learning Explanation
    
    func explainQuizAnswer(
        question: String,
        correctAnswer: String,
        userAnswer: String?,
        explanation: String = ""
    ) async -> String? {
        let systemPrompt = """
        You are an educational AI assistant. Explain quiz answers in a clear, engaging way.
        Help users understand concepts better. Use simple language.
        Keep responses under 150 words.
        """
        
        var userPrompt = """
        Question: \(question)
        Correct answer: \(correctAnswer)
        """
        
        if let userAnswer = userAnswer {
            userPrompt += "\nUser answered: \(userAnswer)"
            userPrompt += "\nWas correct: \(userAnswer == correctAnswer ? "Yes" : "No")"
        }
        
        if !explanation.isEmpty {
            userPrompt += "\nGiven explanation: \(explanation)"
        }
        
        userPrompt += "\n\nProvide an enhanced explanation to help the user understand better."
        
        return await generateCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 200
        )
    }
    
    // MARK: - Action Plan Suggestion
    
    func suggestActionPlan(
        context: String,
        currentPlans: [String] = [],
        goals: [String] = []
    ) async -> String? {
        let systemPrompt = """
        You are a health planning AI assistant. Suggest actionable health action plans.
        Make suggestions specific, achievable, and relevant.
        Keep responses under 100 words.
        """
        
        let userPrompt = """
        Context: \(context)
        Current plans: \(currentPlans.isEmpty ? "None" : currentPlans.joined(separator: ", "))
        Goals: \(goals.isEmpty ? "General health improvement" : goals.joined(separator: ", "))
        
        Suggest a specific, actionable health plan.
        """
        
        return await generateCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 150
        )
    }
    
    // MARK: - Check-in Response
    
    func generateCheckInResponse(
        mood: String?,
        energy: String?,
        symptoms: [String] = [],
        activities: [String] = []
    ) async -> String? {
        let systemPrompt = """
        You are a supportive health AI assistant responding to daily check-ins.
        Be empathetic, encouraging, and provide helpful suggestions.
        Keep responses under 120 words.
        """
        
        var userPrompt = "Daily check-in:\n"
        
        if let mood = mood {
            userPrompt += "Mood: \(mood)\n"
        }
        
        if let energy = energy {
            userPrompt += "Energy: \(energy)\n"
        }
        
        if !symptoms.isEmpty {
            userPrompt += "Symptoms: \(symptoms.joined(separator: ", "))\n"
        }
        
        if !activities.isEmpty {
            userPrompt += "Activities: \(activities.joined(separator: ", "))\n"
        }
        
        userPrompt += "\nProvide a supportive response with helpful suggestions."
        
        return await generateCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 150
        )
    }
    
    // MARK: - Weekly Summary
    
    func generateWeeklySummary(
        metrics: [String: [Double]],
        achievements: [String] = [],
        improvements: [String] = []
    ) async -> String? {
        let systemPrompt = """
        You are a health coach AI creating weekly health summaries.
        Highlight achievements, trends, and provide encouraging insights.
        Keep responses under 200 words.
        """
        
        let userPrompt = """
        Weekly metrics:
        \(metrics.map { "\($0.key): \($0.value)" }.joined(separator: "\n"))
        
        Achievements: \(achievements.isEmpty ? "Keep working!" : achievements.joined(separator: ", "))
        Improvements: \(improvements.isEmpty ? "None noted" : improvements.joined(separator: ", "))
        
        Provide a weekly summary with insights and encouragement.
        """
        
        return await generateCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 250
        )
    }
    
    // MARK: - Goal Suggestions
    
    func suggestHealthGoals(
        currentActivity: [String: Any],
        healthData: [String: Any]
    ) async -> String? {
        let systemPrompt = """
        You are a health coaching AI. Suggest realistic, personalized health goals.
        Base suggestions on current activity levels.
        Keep suggestions specific and achievable.
        Keep responses under 150 words.
        """
        
        let userPrompt = """
        Current activity:
        \(currentActivity.map { "\($0.key): \($0.value)" }.joined(separator: "\n"))
        
        Health data:
        \(healthData.map { "\($0.key): \($0.value)" }.joined(separator: "\n"))
        
        Suggest 2-3 personalized health goals.
        """
        
        return await generateCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 200
        )
    }
}

