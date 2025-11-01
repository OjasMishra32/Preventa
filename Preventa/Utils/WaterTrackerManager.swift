import Foundation
import HealthKit

final class WaterTrackerManager: ObservableObject {
    static let shared = WaterTrackerManager()
    
    @Published var todaysIntake: Double = 0.0
    @Published var goal: Double = 64.0 // 8 cups = 64 oz
    
    private init() {
        loadTodaysIntake()
    }
    
    func loadTodaysIntake() {
        Task {
            await HealthKitManager.shared.loadWaterIntake()
            todaysIntake = HealthKitManager.shared.healthData.waterIntakeOz
        }
    }
    
    func addWater(ounces: Double) {
        todaysIntake += ounces
        HealthKitManager.shared.saveWaterIntake(ounces: ounces)
        Hx.ok()
        
        // Update progress
        Task {
            await ProgressCalculator.shared.calculateTodayProgress()
        }
    }
    
    func setGoal(_ ounces: Double) {
        goal = max(8, min(200, ounces))
    }
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, todaysIntake / goal)
    }
}

