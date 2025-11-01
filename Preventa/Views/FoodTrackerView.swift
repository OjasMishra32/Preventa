import SwiftUI
import PhotosUI
import FirebaseAuth
import Vision
import UIKit

// Image processing extension for food detection
private extension UIImage {
    func downscaledIfNeeded(maxDimension: CGFloat) -> UIImage {
        let size = self.size
        let maxDim = max(size.width, size.height)
        
        guard maxDim > maxDimension else {
            return self
        }
        
        let scale = maxDimension / maxDim
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        return autoreleasepool {
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            defer { UIGraphicsEndImageContext() }
            
            self.draw(in: CGRect(origin: .zero, size: newSize))
            return UIGraphicsGetImageFromCurrentImageContext() ?? self
        }
    }
}

struct FoodTrackerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var foodTracker: FoodTrackerManager
    @StateObject private var vm = FoodTrackerVM()
    @State private var showPhotoPicker = false
    @State private var selectedMealType: FoodEntry.MealType = .snack
    @State private var showResult = false
    @State private var predictedCalories: Int?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        header
                        
                        if vm.isProcessing {
                            processingView
                        } else if let meal = vm.currentMeal {
                            mealResultView(meal: meal)
                        } else {
                            foodEntryView
                        }
                        
                        if !foodTracker.meals.isEmpty {
                            recentMealsSection
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Food Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                FoodPhotoPickerView(
                    onSelect: { image in
                        vm.processFoodPhoto(image: image)
                    }
                )
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Track Your Nutrition")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("Take a photo of your meal to get instant calorie estimates, or enter manually.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var foodEntryView: some View {
        VStack(spacing: 20) {
            // Photo upload card
            PhotoUploadCard(onTap: {
                Hx.tap()
                showPhotoPicker = true
            })
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Manual entry
            GlassCard {
                VStack(spacing: 16) {
                    Text("Or Enter Manually")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Meal type selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meal Type")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(FoodEntry.MealType.allCases, id: \.self) { type in
                                    MealTypeButton(
                                        type: type,
                                        isSelected: selectedMealType == type,
                                        action: {
                                            withAnimation(.spring()) {
                                                selectedMealType = type
                                            }
                                            Hx.tap()
                                        }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Food name
                    TextField("Food name", text: $vm.foodName)
                        .padding(12)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                    
                    // Calories
                    HStack {
                        Text("Calories")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        TextField("", value: $vm.calories, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .padding(12)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                            .frame(width: 100)
                    }
                    
                    // Save button
                    Button {
                        guard !vm.foodName.isEmpty, vm.calories > 0 else { return }
                        let meal = FoodEntry(
                            name: vm.foodName,
                            calories: vm.calories,
                            timestamp: Date(),
                            mealType: selectedMealType
                        )
                        foodTracker.addMeal(meal)
                        vm.reset()
                        Hx.ok()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Meal")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.green.opacity(0.9), .mint.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .disabled(vm.foodName.isEmpty || vm.calories <= 0)
                }
            }
        }
    }
    
    private var processingView: some View {
        GlassCard {
            VStack(spacing: 24) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                
                Text("Analyzing your meal...")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                Text("Using AI to predict calories from your photo")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(40)
        }
    }
    
    private func mealResultView(meal: FoodEntry) -> some View {
        VStack(spacing: 20) {
            // Predicted result card
            GlassCard {
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                        Text("AI Prediction")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    
                    if let image = vm.processedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    VStack(spacing: 12) {
                        Text(meal.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        
                        HStack(spacing: 24) {
                            VStack {
                                Text("\(meal.calories)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("calories")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                                .frame(height: 40)
                            
                            VStack {
                                Text(meal.mealType.rawValue)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("meal type")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            vm.editCalories()
                        } label: {
                            Text("Edit")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                                )
                        }
                        
                        Button {
                            foodTracker.addMeal(meal)
                            vm.reset()
                            Hx.ok()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.green.opacity(0.9), .mint.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                        }
                    }
                }
                .padding(20)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    private var recentMealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Meals")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
            
            ForEach(foodTracker.meals.prefix(5)) { meal in
                CompactMealCard(meal: meal) {
                    foodTracker.deleteMeal(meal)
                }
            }
        }
    }
}

struct PhotoUploadCard: View {
    let onTap: () -> Void
    @State private var pulse = false
    
    var body: some View {
        Button(action: onTap) {
            GlassCard {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.7), .mint.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .scaleEffect(pulse ? 1.08 : 1.0)
                            .shadow(color: .green.opacity(0.4), radius: pulse ? 24 : 12, x: 0, y: pulse ? 8 : 4)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.white)
                            .scaleEffect(pulse ? 1.05 : 1.0)
                    }
                    
                    Text("Take a Photo")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    Text("AI will analyze your meal and predict calories")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(32)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct MealTypeButton: View {
    let type: FoodEntry.MealType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.rawValue)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.green.opacity(0.4) : Color.white.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct CompactMealCard: View {
    let meal: FoodEntry
    let onDelete: () -> Void
    
    var body: some View {
        GlassCard(expand: false) {
            HStack(spacing: 14) {
                Image(systemName: meal.mealType.icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(meal.mealType.rawValue)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text("\(meal.calories) kcal")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Photo Picker

struct FoodPhotoPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    let onSelect: (UIImage) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding()
                        
                        Button {
                            onSelect(image)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Use Photo")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.green.opacity(0.9), .mint.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                        }
                        .padding(.horizontal)
                    } else {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            VStack(spacing: 16) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 64))
                                    .foregroundStyle(.white.opacity(0.8))
                                Text("Select Photo")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("Choose from your photo library")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                    )
                            )
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
    }
}


// MARK: - ViewModel

final class FoodTrackerVM: ObservableObject {
    @Published var foodName: String = ""
    @Published var calories: Int = 0
    @Published var isProcessing: Bool = false
    @Published var currentMeal: FoodEntry?
    @Published var processedImage: UIImage?
    
    private let foodTracker = FoodTrackerManager.shared
    
    func processFoodPhoto(image: UIImage) {
        isProcessing = true
        processedImage = image
        
        Task {
            // Use AI to predict food and calories
            let prediction = await predictFoodFromImage(image: image)
            
            await MainActor.run {
                isProcessing = false
                
                if let prediction = prediction {
                    currentMeal = FoodEntry(
                        name: prediction.name,
                        calories: prediction.calories,
                        timestamp: Date(),
                        mealType: .snack
                    )
                } else {
                    // Fallback: use manual entry
                    currentMeal = FoodEntry(
                        name: "Food Item",
                        calories: 300,
                        timestamp: Date(),
                        mealType: .snack
                    )
                }
            }
        }
    }
    
    private func predictFoodFromImage(image: UIImage) async -> (name: String, calories: Int)? {
        // Use Gemini Vision API to detect actual food from image
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              apiKey.trimmingCharacters(in: .whitespacesAndNewlines) != "YOUR_GEMINI_API_KEY_HERE" else {
            print("❌ FoodTracker: Gemini API key not found")
            return nil
        }
        
        // Prepare image for API (downscale to save bandwidth)
        let processedImage = image.downscaledIfNeeded(maxDimension: 1024)
        guard let jpegData = processedImage.jpegData(compressionQuality: 0.7),
              jpegData.count < 1_000_000 else {
            print("❌ FoodTracker: Image too large after processing")
            return nil
        }
        
        let base64Image = jpegData.base64EncodedString()
        
        // Build Gemini API request
        let model = "gemini-2.0-flash-lite-001"
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            print("❌ FoodTracker: Invalid API URL")
            return nil
        }
        
        let systemPrompt = """
        You are a food recognition AI. Analyze the food image and identify:
        1. The food name (be specific, e.g., "Grilled Chicken Breast with Rice" not just "Rice Bowl")
        2. Estimated calories (be reasonable based on portion size)
        
        Respond in this EXACT format:
        FOOD: [food name]
        CALORIES: [number]
        
        Example:
        FOOD: Grilled Chicken Breast with Steamed Rice and Vegetables
        CALORIES: 450
        """
        
        let userPrompt = "Analyze this food image and identify what it is and estimate calories."
        
        // Build request body with image
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": userPrompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "systemInstruction": [
                "parts": [
                    ["text": systemPrompt]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 200
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.httpBody = jsonData
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.timeoutInterval = 90
            
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 90
            config.timeoutIntervalForResource = 120
            let session = URLSession(configuration: config)
            
            let (respData, resp) = try await session.data(for: req)
            
            guard let httpResp = resp as? HTTPURLResponse,
                  (200...299).contains(httpResp.statusCode) else {
                print("❌ FoodTracker: HTTP error: \((resp as? HTTPURLResponse)?.statusCode ?? -1)")
                return nil
            }
            
            // Parse Gemini response
            guard let root = try JSONSerialization.jsonObject(with: respData) as? [String: Any],
                  let candidates = root["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                print("❌ FoodTracker: Invalid response format")
                return nil
            }
            
            // Parse food name and calories from response
            let lines = text.components(separatedBy: .newlines)
            var foodName: String?
            var calories: Int?
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("FOOD:") {
                    foodName = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                } else if trimmed.hasPrefix("CALORIES:") {
                    let calorieStr = String(trimmed.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines)
                    calories = Int(calorieStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
                }
            }
            
            // Fallback parsing if format doesn't match exactly
            if foodName == nil || calories == nil {
                // Try to extract from text more flexibly
                if foodName == nil {
                    // Look for food description in the text
                    let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".\n"))
                    foodName = sentences.first?.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                if calories == nil {
                    // Look for calorie number in text
                    let caloriePattern = #"(\d+)\s*(?:calories?|kcal)"#
                    if let range = text.range(of: caloriePattern, options: .regularExpression) {
                        let match = String(text[range])
                        calories = Int(match.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
                    }
                }
            }
            
            // Validate results
            guard let name = foodName, !name.isEmpty, let cals = calories, cals > 0, cals < 5000 else {
                print("⚠️ FoodTracker: Could not parse valid food name/calories from: \(text)")
                return nil
            }
            
            print("✅ FoodTracker: Detected \(name) with ~\(cals) calories")
            return (name, cals)
            
        } catch {
            print("❌ FoodTracker: Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func editCalories() {
        // Allow editing calories
        if let meal = currentMeal {
            calories = meal.calories
            foodName = meal.name
            currentMeal = nil
        }
    }
    
    func reset() {
        foodName = ""
        calories = 0
        isProcessing = false
        currentMeal = nil
        processedImage = nil
    }
}

#Preview {
    FoodTrackerView()
        .environmentObject(FoodTrackerManager.shared)
}

