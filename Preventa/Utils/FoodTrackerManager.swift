import Foundation
import FirebaseFirestore
import FirebaseAuth
import HealthKit
import UIKit

final class FoodTrackerManager: ObservableObject {
    static let shared = FoodTrackerManager()
    
    @Published var meals: [FoodEntry] = []
    @Published var todaysCalories: Int = 0
    @Published var isLoadingPhoto = false
    
    // Lazy property - only initialized when first accessed (after Firebase is configured)
    private lazy var db: Firestore = {
        Firestore.firestore()
    }()
    private var uid: String? { Auth.auth().currentUser?.uid }
    
    private init() {
        // Don't call loadMeals() in init - wait until Firebase is configured
        // loadMeals() will be called when needed or after Firebase is ready
    }
    
    // Call this after Firebase is configured
    func initialize() {
        loadMeals()
    }
    
    func loadMeals() {
        guard let uid else { return }
        let today = Calendar.current.startOfDay(for: Date())
        
        db.collection("users").document(uid).collection("meals")
            .whereField("timestamp", isGreaterThan: Timestamp(date: today))
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let docs = snapshot?.documents else { return }
                self.meals = docs.compactMap { doc in
                    try? doc.data(as: FoodEntry.self)
                }
                self.updateTodaysCalories()
            }
    }
    
    func addMeal(_ meal: FoodEntry) {
        guard let uid else { return }
        try? db.collection("users").document(uid).collection("meals")
            .document(meal.id)
            .setData(from: meal)
        
        // Save to HealthKit
        HealthKitManager.shared.saveFoodEntry(name: meal.name, calories: Double(meal.calories))
        
        // Removed AI meal analysis - not displayed to user, saves API calls
        
        // Update progress
        Task {
            await ProgressCalculator.shared.calculateTodayProgress()
        }
    }
    
    func deleteMeal(_ meal: FoodEntry) {
        guard let uid else { return }
        db.collection("users").document(uid).collection("meals")
            .document(meal.id)
            .delete()
        
        updateTodaysCalories()
    }
    
    func predictCalories(from image: UIImage) async -> (calories: Int?, analysis: String?) {
        isLoadingPhoto = true
        defer { isLoadingPhoto = false }
        
        // Note: Food detection is now handled in FoodTrackerVM.predictFoodFromImage()
        // This method is kept for backward compatibility but simplified
        // FoodTrackerVM uses Gemini Vision API directly for better results
        
        // Fallback: estimate based on image size
        let size = image.size
        let complexity = (size.width * size.height) / 10000.0
        let baseCalories = min(800, max(150, Int(complexity * 3)))
        
        return (baseCalories, nil)
    }
    
    private func updateTodaysCalories() {
        let today = Calendar.current.startOfDay(for: Date())
        todaysCalories = meals
            .filter { $0.timestamp >= today }
            .reduce(0) { $0 + $1.calories }
    }
}

struct FoodEntry: Identifiable, Codable {
    let id: String
    var name: String
    var calories: Int
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var imageURL: String?
    var timestamp: Date
    var mealType: MealType
    
    enum MealType: String, Codable, CaseIterable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
        
        var icon: String {
            switch self {
            case .breakfast: return "sunrise.fill"
            case .lunch: return "sun.max.fill"
            case .dinner: return "moon.stars.fill"
            case .snack: return "leaf.fill"
            }
        }
    }
    
    init(id: String = UUID().uuidString, name: String, calories: Int, protein: Double? = nil, carbs: Double? = nil, fat: Double? = nil, imageURL: String? = nil, timestamp: Date = Date(), mealType: MealType = .snack) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.imageURL = imageURL
        self.timestamp = timestamp
        self.mealType = mealType
    }
}

