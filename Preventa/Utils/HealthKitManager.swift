import Foundation
import HealthKit

final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var isAuthorized: Bool = false
    @Published var healthData: HealthData = HealthData()
    
    private let healthStore = HKHealthStore()
    
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .height)!,
        HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
        HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
        HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
        HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
        HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
        HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
        HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
        HKObjectType.quantityType(forIdentifier: .bloodAlcoholContent)!
    ]
    
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
        HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
        HKObjectType.quantityType(forIdentifier: .height)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!
    ]
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() async -> Bool {
        print("🔵 HealthKit: Starting authorization request...")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit: Health data not available on this device")
            DispatchQueue.main.async {
                self.isAuthorized = false
            }
            return false
        }
        
        print("🔵 HealthKit: Health data is available, requesting authorization...")
        
        return await withCheckedContinuation { continuation in
            // Request authorization on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    print("❌ HealthKit: Self is nil")
                    continuation.resume(returning: false)
                    return
                }
                
                print("🔵 HealthKit: Calling requestAuthorization with \(self.readTypes.count) read types and \(self.writeTypes.count) write types")
                
                self.healthStore.requestAuthorization(toShare: self.writeTypes, read: self.readTypes) { [weak self] success, error in
                    guard let self = self else {
                        print("❌ HealthKit: Self is nil in callback")
                        continuation.resume(returning: false)
                        return
                    }
                    
                    if let error = error {
                        print("❌ HealthKit: Authorization error: \(error.localizedDescription)")
                        continuation.resume(returning: false)
                        return
                    } else {
                        print("🔵 HealthKit: Authorization request completed. Success: \(success)")
                    }
                    
                    // Check authorization status with retry logic
                    // The system needs time to process the authorization
                    self.checkAuthorizationWithRetry(attempt: 1, maxAttempts: 5) { [weak self] isAuthorized in
                        guard let self = self else {
                            continuation.resume(returning: false)
                            return
                        }
                        
                        self.isAuthorized = isAuthorized
                        print("🔵 HealthKit: Final authorization status: \(isAuthorized)")
                        
                        // Always try to load data - sometimes authorization status is slow to update
                        // but we might already have access
                        if isAuthorized {
                            print("✅ HealthKit: Authorization successful, loading data...")
                            self.loadHealthData()
                        } else {
                            // Try loading anyway - user might have granted access
                            print("⚠️ HealthKit: Status check failed, but trying to load data anyway...")
                            self.loadHealthData()
                        }
                        
                        continuation.resume(returning: isAuthorized)
                    }
                }
            }
        }
    }
    
    private func checkAuthorizationWithRetry(attempt: Int, maxAttempts: Int, completion: @escaping (Bool) -> Void) {
        let delay = Double(attempt) * 0.3 // Increasing delay: 0.3s, 0.6s, 0.9s, etc.
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            
            var isAuthorized = false
            
            // Check multiple health types
            let typesToCheck: [HKQuantityTypeIdentifier] = [.stepCount, .heartRate, .activeEnergyBurned, .distanceWalkingRunning]
            
            for typeIdentifier in typesToCheck {
                if let type = HKObjectType.quantityType(forIdentifier: typeIdentifier) {
                    let status = self.healthStore.authorizationStatus(for: type)
                    print("🔵 HealthKit: \(typeIdentifier.rawValue) authorization status: \(status.rawValue)")
                    
                    // Check for sharing authorized (read permission)
                    if status == .sharingAuthorized {
                        isAuthorized = true
                        print("✅ HealthKit: Found authorized type: \(typeIdentifier.rawValue)")
                        break
                    }
                }
            }
            
            if isAuthorized {
                completion(true)
            } else if attempt < maxAttempts {
                // Retry if not authorized yet
                print("🔵 HealthKit: Retry \(attempt + 1)/\(maxAttempts) - checking authorization again...")
                self.checkAuthorizationWithRetry(attempt: attempt + 1, maxAttempts: maxAttempts, completion: completion)
            } else {
                // Final attempt - check one more time and return result
                print("⚠️ HealthKit: Max retries reached. Final status: \(isAuthorized)")
                completion(isAuthorized)
            }
        }
    }
    
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit: Health data not available")
            isAuthorized = false
            return
        }
        
        // Check authorization for multiple types
        var isAuthorized = false
        
        // Check multiple health types
        let typesToCheck: [HKQuantityTypeIdentifier] = [.stepCount, .heartRate, .activeEnergyBurned]
        
        for typeIdentifier in typesToCheck {
            if let type = HKObjectType.quantityType(forIdentifier: typeIdentifier) {
                let status = healthStore.authorizationStatus(for: type)
                if status == .sharingAuthorized {
                    isAuthorized = true
                    print("✅ HealthKit: Found authorized type: \(typeIdentifier.rawValue)")
                    break
                }
            }
        }
        
        self.isAuthorized = isAuthorized
        print("🔵 HealthKit: Current authorization status: \(isAuthorized)")
        
        // Also try to load data if authorized
        if isAuthorized {
            loadHealthData()
        }
    }
    
    func loadHealthData() {
        // Try loading data even if authorization status check hasn't updated yet
        // Sometimes the status is slow to update but we already have access
        print("🔵 HealthKit: Loading health data (authorized: \(isAuthorized))...")
        
        Task {
            // Load data in parallel where possible
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadSteps() }
                group.addTask { await self.loadHeartRate() }
                group.addTask { await self.loadActiveEnergy() }
                group.addTask { await self.loadSleep() }
                group.addTask { await self.loadBodyMetrics() }
                group.addTask { await self.loadWaterIntake() }
                group.addTask { await self.loadDietaryEnergy() }
                group.addTask { await self.loadWeeklyData() }
            }
            print("✅ HealthKit: Finished loading all health data")
            
            // After loading, check authorization status again - it might have updated
            DispatchQueue.main.async { [weak self] in
                self?.checkAuthorizationStatus()
                
                // Update progress when health data loads
                Task {
                    await ProgressCalculator.shared.calculateTodayProgress()
                }
            }
        }
    }
    
    private func loadSteps() async {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("❌ HealthKit: Step count type not available")
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ HealthKit: Error loading steps: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.healthData.steps = 0
                }
                return
            }
            
            if let sum = result?.sumQuantity() {
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                print("✅ HealthKit: Loaded \(steps) steps")
                DispatchQueue.main.async {
                    self.healthData.steps = steps
                }
            } else {
                print("⚠️ HealthKit: No step data available")
                DispatchQueue.main.async {
                    self.healthData.steps = 0
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func loadHeartRate() async {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            print("❌ HealthKit: Heart rate type not available")
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ HealthKit: Error loading heart rate: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.healthData.heartRate = 0
                }
                return
            }
            
            if let sample = samples?.first as? HKQuantitySample {
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                print("✅ HealthKit: Loaded heart rate: \(Int(heartRate)) bpm")
                DispatchQueue.main.async {
                    self.healthData.heartRate = Int(heartRate)
                }
            } else {
                print("⚠️ HealthKit: No heart rate data available")
                DispatchQueue.main.async {
                    self.healthData.heartRate = 0
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func loadActiveEnergy() async {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
            guard let self = self,
                  let sum = result?.sumQuantity() else { return }
            
            let calories = Int(sum.doubleValue(for: HKUnit.kilocalorie()))
            DispatchQueue.main.async {
                self.healthData.activeCalories = calories
            }
        }
        
        healthStore.execute(query)
    }
    
    private func loadSleep() async {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, _ in
            guard let self = self,
                  let sleepSamples = samples as? [HKCategorySample] else { return }
            
            var totalSleep: TimeInterval = 0
            for sample in sleepSamples where sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                totalSleep += sample.endDate.timeIntervalSince(sample.startDate)
            }
            
            let hours = totalSleep / 3600
            DispatchQueue.main.async {
                self.healthData.sleepHours = hours
            }
        }
        
        healthStore.execute(query)
    }
    
    private func loadBodyMetrics() async {
        // Load weight
        if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
                guard let self = self,
                      let sample = samples?.first as? HKQuantitySample else { return }
                
                let weight = sample.quantity.doubleValue(for: HKUnit.pound())
                DispatchQueue.main.async {
                    self.healthData.weight = weight
                }
            }
            healthStore.execute(query)
        }
        
        // Load height
        if let heightType = HKQuantityType.quantityType(forIdentifier: .height) {
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
                guard let self = self,
                      let sample = samples?.first as? HKQuantitySample else { return }
                
                let height = sample.quantity.doubleValue(for: HKUnit.inch())
                DispatchQueue.main.async {
                    self.healthData.height = height
                }
            }
            healthStore.execute(query)
        }
    }
    
    func loadWaterIntake() async {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: waterType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
            guard let self = self,
                  let sum = result?.sumQuantity() else { return }
            
            let milliliters = sum.doubleValue(for: HKUnit.literUnit(with: .milli))
            let ounces = milliliters / 29.5735
            DispatchQueue.main.async {
                self.healthData.waterIntakeOz = ounces
            }
        }
        
        healthStore.execute(query)
    }
    
    func loadDietaryEnergy() async {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
            guard let self = self,
                  let sum = result?.sumQuantity() else { return }
            
            let calories = Int(sum.doubleValue(for: HKUnit.kilocalorie()))
            DispatchQueue.main.async {
                self.healthData.dietaryCalories = calories
            }
        }
        
        healthStore.execute(query)
    }
    
    func loadWeeklyData() async {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        // Load steps for last 7 days
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: now, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: calendar.startOfDay(for: weekAgo),
            intervalComponents: DateComponents(day: 1)
        )
        
        query.initialResultsHandler = { [weak self] _, results, _ in
            guard let self = self, let results = results else { return }
            
            var weeklySteps: [Date: Int] = [:]
            results.enumerateStatistics(from: weekAgo, to: now) { statistic, _ in
                if let sum = statistic.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: HKUnit.count()))
                    weeklySteps[statistic.startDate] = steps
                }
            }
            
            DispatchQueue.main.async {
                self.healthData.weeklySteps = weeklySteps
            }
        }
        
        healthStore.execute(query)
    }
    
    func saveWaterIntake(ounces: Double) {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        
        let quantity = HKQuantity(unit: HKUnit.fluidOunceUS(), doubleValue: ounces)
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: Date(), end: Date())
        
        healthStore.save(sample) { [weak self] success, _ in
            if success {
                DispatchQueue.main.async {
                    self?.healthData.waterIntakeOz += ounces
                }
            }
        }
    }
    
    func saveFoodEntry(name: String, calories: Double) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else { return }
        
        let quantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
        let sample = HKQuantitySample(type: energyType, quantity: quantity, start: Date(), end: Date(), metadata: ["name": name])
        
        healthStore.save(sample) { [weak self] success, _ in
            if success {
                DispatchQueue.main.async {
                    self?.healthData.dietaryCalories += Int(calories)
                }
                // Wrap async call in a Task to avoid calling async from a non-async context
                Task { [weak self] in
                    await self?.loadDietaryEnergy()
                }
            }
        }
    }
    
    func saveHeight(inches: Double) async {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else { return }
        
        let quantity = HKQuantity(unit: HKUnit.inch(), doubleValue: inches)
        let sample = HKQuantitySample(type: heightType, quantity: quantity, start: Date(), end: Date())
        
        do {
            try await healthStore.save(sample)
            await MainActor.run {
                healthData.height = inches
            }
            print("✅ HealthKit: Saved height: \(inches) inches")
        } catch {
            print("❌ HealthKit: Error saving height: \(error.localizedDescription)")
        }
    }
    
    func saveWeight(pounds: Double) async {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let quantity = HKQuantity(unit: HKUnit.pound(), doubleValue: pounds)
        let sample = HKQuantitySample(type: weightType, quantity: quantity, start: Date(), end: Date())
        
        do {
            try await healthStore.save(sample)
            await MainActor.run {
                healthData.weight = pounds
            }
            print("✅ HealthKit: Saved weight: \(pounds) pounds")
        } catch {
            print("❌ HealthKit: Error saving weight: \(error.localizedDescription)")
        }
    }
    
    func getHealthDataSummary() -> String {
        var summary: [String] = []
        
        if healthData.steps > 0 {
            summary.append("Steps: \(healthData.steps) today")
        }
        if healthData.heartRate > 0 {
            summary.append("Heart Rate: \(healthData.heartRate) bpm")
        }
        if healthData.sleepHours > 0 {
            summary.append("Sleep: \(String(format: "%.1f", healthData.sleepHours)) hours")
        }
        if healthData.activeCalories > 0 {
            summary.append("Active Calories: \(healthData.activeCalories) kcal")
        }
        if healthData.dietaryCalories > 0 {
            summary.append("Food Calories: \(healthData.dietaryCalories) kcal")
        }
        if healthData.waterIntakeOz > 0 {
            summary.append("Water: \(String(format: "%.1f", healthData.waterIntakeOz)) oz")
        }
        
        return summary.joined(separator: ", ")
    }
}

struct HealthData: Equatable {
    var steps: Int = 0
    var heartRate: Int = 0
    var sleepHours: Double = 0
    var activeCalories: Int = 0
    var dietaryCalories: Int = 0
    var waterIntakeOz: Double = 0
    var weight: Double = 0
    var height: Double = 0
    var weeklySteps: [Date: Int] = [:]
    
    var bmi: Double? {
        guard weight > 0, height > 0 else { return nil }
        let heightInMeters = height * 0.0254 // Convert inches to meters
        let weightInKg = weight * 0.453592 // Convert pounds to kg
        return weightInKg / (heightInMeters * heightInMeters)
    }
    
    var totalCalories: Int {
        activeCalories + dietaryCalories
    }
    
    var waterIntakeGoal: Double {
        64.0 // Default 8 cups = 64 oz
    }
    
    var waterProgress: Double {
        guard waterIntakeGoal > 0 else { return 0 }
        return min(1.0, waterIntakeOz / waterIntakeGoal)
    }
    
    var stepsGoal: Int {
        10000 // Default goal
    }
    
    var stepsProgress: Double {
        guard stepsGoal > 0 else { return 0 }
        return min(1.0, Double(steps) / Double(stepsGoal))
    }
}
