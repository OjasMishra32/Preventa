import SwiftUI
import HealthKit

// MARK: - Extensions

extension FoodEntry.MealType {
    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .purple
        case .snack: return .pink
        }
    }
}

// MARK: - Main View

struct HealthDashboardView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @EnvironmentObject var foodTracker: FoodTrackerManager
    @EnvironmentObject var waterTracker: WaterTrackerManager
    @State private var selectedTab: HealthTab = .today
    @State private var refreshTimer: Timer?
    @State private var showSettings = false
    
    enum HealthTab: String, CaseIterable {
        case today = "Today"
        case activity = "Activity"
        case nutrition = "Nutrition"
        case body = "Body"
        
        var icon: String {
            switch self {
            case .today: return "calendar"
            case .activity: return "figure.walk"
            case .nutrition: return "fork.knife"
            case .body: return "person.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            AnimatedBrandBackground().ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Enhanced Tab selector
                EnhancedTabSelector(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 12)
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Quick Stats Bar (always visible)
                        QuickHealthStatsBar(healthManager: healthManager)
                            .padding(.horizontal, 20)
                        
                        switch selectedTab {
                        case .today:
                            TodayTabView(
                                healthManager: healthManager,
                                foodTracker: foodTracker,
                                waterTracker: waterTracker
                            )
                        case .activity:
                            ActivityTabView(healthManager: healthManager)
                        case .nutrition:
                            NutritionTabView(
                                foodTracker: foodTracker,
                                waterTracker: waterTracker
                            )
                        case .body:
                            BodyTabView(healthManager: healthManager)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Health Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                Button {
                        Task {
                            await healthManager.loadHealthData()
                            await foodTracker.loadMeals()
                            await waterTracker.loadTodaysIntake()
                        }
                        Hx.ok()
                } label: {
                    Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                    
                    Button {
                        showSettings = true
                        Hx.tap()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            HealthSettingsView()
        }
        .task {
            // Load data immediately on appear with error handling
            do {
                await healthManager.loadHealthData()
            } catch {
                print("⚠️ HealthDashboard: Error loading health data: \(error.localizedDescription)")
            }
            
            do {
                await foodTracker.loadMeals()
            } catch {
                print("⚠️ HealthDashboard: Error loading meals: \(error.localizedDescription)")
            }
            
            do {
                await waterTracker.loadTodaysIntake()
            } catch {
                print("⚠️ HealthDashboard: Error loading water intake: \(error.localizedDescription)")
            }
            
            // Set up refresh timer
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
                Task {
                    do {
                        await healthManager.loadHealthData()
                    } catch {
                        print("⚠️ HealthDashboard: Error in timer refresh: \(error.localizedDescription)")
                    }
                }
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }
}

// MARK: - Enhanced Tab Selector

struct EnhancedTabSelector: View {
    @Binding var selectedTab: HealthDashboardView.HealthTab
    @Namespace private var tabAnimation
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HealthDashboardView.HealthTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                        Hx.tap()
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                // Enhanced glow for selected tab
                                if selectedTab == tab {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [
                                                    tabColor(tab).opacity(0.4),
                                                    tabColor(tab).opacity(0.2),
                                                    Color.clear
                                                ],
                                                center: .center,
                                                startRadius: 10,
                                                endRadius: 30
                                            )
                                        )
                                        .frame(width: 60, height: 60)
                                        .blur(radius: 8)
                                        .offset(y: 0) // Ensure centered
                                    
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 50, height: 50)
                                        .matchedGeometryEffect(id: "selectedTab", in: tabAnimation)
                                        .shadow(color: .purple.opacity(0.4), radius: 8, y: 4)
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                }
                                
                                Image(systemName: tab.icon)
                                    .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .medium))
                                    .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.7))
                            }
                            .frame(width: 50, height: 50)
                            .padding(.top, 8) // Add padding to prevent cutoff
                            .padding(.bottom, 0)
                            
                            Text(tab.rawValue)
                                .font(.caption.weight(selectedTab == tab ? .semibold : .regular))
                                .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.7))
                                .lineLimit(1)
                        }
                        .frame(width: 72)
                        .padding(.vertical, 8) // Add vertical padding to container
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8) // Add padding to ensure full visibility
        }
        .frame(height: 110) // Ensure enough height for glow effects
    }
    
    private func tabColor(_ tab: HealthDashboardView.HealthTab) -> Color {
        switch tab {
        case .today: return .purple
        case .activity: return .blue
        case .nutrition: return .orange
        case .body: return .green
        }
    }
}

// MARK: - Today Tab View

struct TodayTabView: View {
    @ObservedObject var healthManager: HealthKitManager
    @ObservedObject var foodTracker: FoodTrackerManager
    @ObservedObject var waterTracker: WaterTrackerManager
    @State private var insights: [HealthInsight] = []
    @State private var animateScore = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Comprehensive Health Score Card
            ComprehensiveHealthScoreCard(healthManager: healthManager, animateScore: $animateScore)
            
            // Steps and Miles at Top
            HStack(spacing: 16) {
                StepsMilesCard(
                    steps: healthManager.healthData.steps,
                    miles: healthManager.healthData.miles,
                    stepsGoal: healthManager.healthData.stepsGoal,
                    stepsProgress: healthManager.healthData.stepsProgress,
                    onEditSteps: { newGoal in
                        UserDefaults.standard.set(newGoal, forKey: "stepsGoal")
                        Task {
                            await healthManager.loadHealthData()
                        }
                    }
                )
            }
            
            // AI Insights Section
            if !insights.isEmpty {
                InsightsCard(insights: insights)
            }
            
            // Key Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                DashboardMetricCard(
                    title: "Active Calories",
                    value: healthManager.healthData.activeCalories,
                    goal: 500,
                    progress: min(1.0, Double(healthManager.healthData.activeCalories) / 500.0),
                    icon: "flame.fill",
                    colors: [.orange, .red],
                    unit: "kcal",
                    onEdit: { newGoal in
                        UserDefaults.standard.set(newGoal, forKey: "activeCaloriesGoal")
                        Task {
                            await healthManager.loadHealthData()
                        }
                    }
                )
                
                DashboardMetricCard(
                    title: "Exercise",
                    value: healthManager.healthData.exerciseMinutes,
                    goal: healthManager.healthData.exerciseGoal,
                    progress: healthManager.healthData.exerciseProgress,
                    icon: "figure.run",
                    colors: [.green, .mint],
                    unit: "min",
                    onEdit: { newGoal in
                        UserDefaults.standard.set(newGoal, forKey: "exerciseGoal")
                        Task {
                            await healthManager.loadHealthData()
                        }
                    }
                )
                
                DashboardMetricCard(
                    title: "Sleep",
                    value: Int(healthManager.healthData.sleepHours * 10) / 10,
                    goal: Int(healthManager.healthData.sleepGoal * 10) / 10,
                    progress: healthManager.healthData.sleepProgress,
                    icon: "bed.double.fill",
                    colors: [.indigo, .purple],
                    unit: "hrs",
                    valueFormatter: { v in
                        String(format: "%.1f", Double(v) / 10.0)
                    },
                    onEdit: { newGoal in
                        healthManager.saveSleepGoal(hours: Double(newGoal) / 10.0)
                    }
                )
                
                // Heart Rate Card - Always show
                HeartRateCard(bpm: healthManager.healthData.heartRate)
            }
            
            // Trend Charts Section
            HealthTrendChartsCard(healthManager: healthManager)
            
            // Additional Vital Signs
            if healthManager.healthData.systolicBP > 0 || healthManager.healthData.oxygenSaturation > 0 {
                VitalSignsCard(healthManager: healthManager)
            }
        }
        .task {
            let aiInsights = await HealthInsightGenerator.shared.generateInsights(
                from: healthManager.healthData,
                weeklySteps: healthManager.healthData.weeklySteps
            )
            await MainActor.run {
                insights = aiInsights
            }
            withAnimation(.spring(response: 0.8).delay(0.2)) {
                animateScore = true
            }
        }
    }
}

// MARK: - Today Header Card

struct TodayHeaderCard: View {
    @ObservedObject var healthManager: HealthKitManager
    @State private var currentTime = Date()
    
    var body: some View {
        GlassCard {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(formattedDate)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text(formattedTime)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    if healthManager.isAuthorized {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("Connected to Apple Health")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    } else {
                        Button {
                            Task { @MainActor in
                                let authorized = await healthManager.requestAuthorization()
                                healthManager.checkAuthorizationStatus()
                                
                                if authorized {
                                    Hx.ok()
                                } else {
                                    await healthManager.loadHealthData()
                                    Hx.warn()
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.circle.fill")
                                    .font(.caption)
                                Text("Connect Apple Health")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.3))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.green.opacity(0.6), lineWidth: 1.5)
                                    )
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Overall health score
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 10)
                            .frame(width: 75, height: 75)
                        
                        Circle()
                            .trim(from: 0, to: healthScore)
                            .stroke(
                            LinearGradient(
                                    colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 75, height: 75)
                        
                        Text("\(Int(healthScore * 100))")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Text("Health Score")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .padding(20)
        }
        .onAppear {
            let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentTime = Date()
            }
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: currentTime)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: currentTime)
    }
    
    private var healthScore: Double {
        var score = 0.0
        var count = 0
        
        if healthManager.healthData.steps > 0 {
            score += min(1.0, Double(healthManager.healthData.steps) / 10000.0)
            count += 1
        }
        
        if healthManager.healthData.activeCalories > 0 {
            score += min(1.0, Double(healthManager.healthData.activeCalories) / 500.0)
            count += 1
        }
        
        if healthManager.healthData.sleepHours > 0 {
            score += min(1.0, healthManager.healthData.sleepHours / 8.0)
            count += 1
        }
        
        if healthManager.healthData.waterIntakeOz > 0 {
            score += min(1.0, healthManager.healthData.waterIntakeOz / 64.0)
            count += 1
        }
        
        return count > 0 ? score / Double(count) : 0.5
    }
}

// MARK: - Metric Card

struct DashboardMetricCard: View {
    let title: String
    let value: Int
    let goal: Int
    let progress: Double
    let icon: String
    let colors: [Color]
    let unit: String
    let valueFormatter: ((Int) -> String)?
    let onEdit: ((Int) -> Void)?
    
    @State private var showEditSheet = false
    @State private var editedGoal: Int
    @State private var animateProgress = false
    @State private var pulse = false
    @State private var hover = false
    
    init(title: String, value: Int, goal: Int, progress: Double, icon: String, colors: [Color], unit: String, valueFormatter: ((Int) -> String)? = nil, onEdit: ((Int) -> Void)?) {
        self.title = title
        self.value = value
        self.goal = goal
        self.progress = progress
        self.icon = icon
        self.colors = colors
        self.unit = unit
        self.valueFormatter = valueFormatter
        self.onEdit = onEdit
        self._editedGoal = State(initialValue: goal)
    }
    
    var body: some View {
        GlassCard(expand: false) {
            VStack(alignment: .leading, spacing: 14) {
                // Header with icon and edit button
                HStack(alignment: .center) {
            ZStack {
                        // Enhanced glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        colors[0].opacity(0.6),
                                        colors[1].opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 60, height: 60)
                            .blur(radius: 8)
                            .opacity(pulse ? 0.8 : 0.5)
                        
                Circle()
                    .fill(
                        LinearGradient(
                                    colors: colors.map { $0.opacity(0.9) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                            .frame(width: 50, height: 50)
                            .shadow(color: colors[0].opacity(0.6), radius: pulse ? 12 : 8, y: 4)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                            .symbolEffect(.pulse, value: pulse)
            }
                    .scaleEffect(pulse ? 1.05 : 1.0)
            
                    Spacer()
                    
                    if onEdit != nil {
                        Button {
                            showEditSheet = true
                            Hx.tap()
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white.opacity(0.9), .white.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Value display with animation
            VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(valueFormatter?(value) ?? "\(value)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.95)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .fixedSize(horizontal: false, vertical: true)
                            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        Text(unit)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(1)
                    }
                    
                    Text("\(Int(progress * 100))% of \(goal) goal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Enhanced animated progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background with glow
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        // Animated progress fill
                        RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                                    colors: colors + [colors[0].opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: animateProgress ? geo.size.width * CGFloat(progress) : 0, height: 10)
                            .shadow(color: colors[0].opacity(0.5), radius: 4, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateProgress)
                    }
                }
                .frame(height: 10)
            }
            .padding(20)
        }
        .scaleEffect(hover ? 1.02 : 1.0)
        .shadow(color: colors[0].opacity(hover ? 0.3 : 0.15), radius: hover ? 16 : 8, y: hover ? 8 : 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hover)
        .onAppear {
            withAnimation(.spring(response: 0.8).delay(0.1)) {
                animateProgress = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onDisappear {
            pulse = false
            animateProgress = false
        }
        .sheet(isPresented: $showEditSheet) {
            if let onEdit = onEdit {
                EditGoalSheet(
                    title: title,
                    currentGoal: goal,
                    unit: unit,
                    onSave: { newGoal in
                        editedGoal = newGoal
                        onEdit(newGoal)
                        showEditSheet = false
                        Hx.ok()
                    },
                    onCancel: {
                        editedGoal = goal
                        showEditSheet = false
                    }
                )
            }
        }
    }
}

// MARK: - Edit Goal Sheet

struct EditGoalSheet: View {
    let title: String
    let currentGoal: Int
    let unit: String
    let onSave: (Int) -> Void
    let onCancel: () -> Void
    @State private var newGoal: Int
    @Environment(\.dismiss) private var dismiss
    
    init(title: String, currentGoal: Int, unit: String, onSave: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        self.title = title
        self.currentGoal = currentGoal
        self.unit = unit
        self.onSave = onSave
        self.onCancel = onCancel
        self._newGoal = State(initialValue: currentGoal)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                VStack(spacing: 24) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Edit \(title) Goal")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            
                            Text("Current goal: \(currentGoal) \(unit)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("New Goal")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                HStack {
                                    Button {
                                        if newGoal > 0 {
                                            newGoal = max(0, newGoal - (unit == "steps" ? 1000 : (unit == "oz" ? 8 : 100)))
                                        Hx.tap()
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    TextField("", value: $newGoal, format: .number)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(.plain)
                                        .frame(maxWidth: .infinity)
                                    
                                    Button {
                                        newGoal += (unit == "steps" ? 1000 : (unit == "oz" ? 8 : 100))
                                        Hx.tap()
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
        .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                )
                                
                                Text("Unit: \(unit)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 22)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button {
                            onCancel()
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.15))
                                )
                        }
                        
                        Button {
                            onSave(newGoal)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                            LinearGradient(
                                    colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Insights Card

struct InsightsCard: View {
    let insights: [HealthInsight]
    
    var body: some View {
        GlassCard {
        VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                Text("AI Insights")
                        .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            
            ForEach(insights) { insight in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(insight.color.opacity(0.3))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                                .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(insight.message)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Sleep Card

struct SleepCard: View {
    let hours: Double
    
    var body: some View {
        GlassCard(expand: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.indigo.opacity(0.8), .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                            .frame(width: 44, height: 44)
                            .shadow(color: .indigo.opacity(0.4), radius: 8, y: 4)
                        
                    Image(systemName: "bed.double.fill")
                            .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", hours))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("hrs")
                            .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    Text("\(Int((hours / 8.0) * 100))% of recommended")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.indigo, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(min(1.0, hours / 8.0)), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(18)
        }
    }
}

// MARK: - Heart Rate Card

struct HeartRateCard: View {
    let bpm: Int
    
    var body: some View {
        GlassCard(expand: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                ZStack {
                    Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.red.opacity(0.8), .pink.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: .red.opacity(0.4), radius: 8, y: 4)
                    
                    Image(systemName: "heart.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(bpm > 0 ? "\(bpm)" : "--")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .fixedSize(horizontal: false, vertical: true)
                    Text("bpm")
                            .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    Text("Resting heart rate")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                            LinearGradient(
                                    colors: [.red, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                            .frame(width: geo.size.width * CGFloat(bpm > 0 ? min(1.0, Double(bpm) / 100.0) : 0.7), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(18)
        }
    }
}

// MARK: - Quick Actions Card

// MARK: - Edit Meal Sheet

struct EditMealSheet: View {
    let meal: FoodEntry
    @ObservedObject var foodTracker: FoodTrackerManager
    @Environment(\.dismiss) private var dismiss
    @State private var editedName: String
    @State private var editedCalories: Int
    @State private var editedMealType: FoodEntry.MealType
    
    init(meal: FoodEntry, foodTracker: FoodTrackerManager) {
        self.meal = meal
        self.foodTracker = foodTracker
        self._editedName = State(initialValue: meal.name)
        self._editedCalories = State(initialValue: meal.calories)
        self._editedMealType = State(initialValue: meal.mealType)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                VStack(spacing: 24) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Edit Meal")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Food Name")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                TextField("Food name", text: $editedName)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                        .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Calories")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                TextField("", value: $editedCalories, format: .number)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Meal Type")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                        ForEach(FoodEntry.MealType.allCases, id: \.self) { type in
                                    Button {
                                                editedMealType = type
                                        Hx.tap()
                                    } label: {
                                                Text(type.rawValue)
                                            .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(editedMealType == type ? .white : .white.opacity(0.7))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                            .background(
                                                Capsule()
                                                            .fill(editedMealType == type ? type.color.opacity(0.5) : Color.white.opacity(0.1))
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 22)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                            Button {
                                dismiss()
                            } label: {
                            Text("Cancel")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.15))
                                )
                        }
                        
                                    Button {
                            let updatedMeal = FoodEntry(
                                id: meal.id,
                                name: editedName,
                                calories: editedCalories,
                                timestamp: meal.timestamp,
                                mealType: editedMealType
                            )
                            foodTracker.updateMeal(updatedMeal)
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
                        .disabled(editedName.isEmpty || editedCalories <= 0)
                        }
                        .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


// MARK: - Activity Tab View

struct ActivityTabView: View {
    @ObservedObject var healthManager: HealthKitManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Steps and Miles at Top
            StepsMilesCard(
                steps: healthManager.healthData.steps,
                miles: healthManager.healthData.miles,
                stepsGoal: healthManager.healthData.stepsGoal,
                stepsProgress: healthManager.healthData.stepsProgress,
                onEditSteps: { newGoal in
                    UserDefaults.standard.set(newGoal, forKey: "stepsGoal")
                    Task {
                        await healthManager.loadHealthData()
                    }
                }
            )
            
            // Activity Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                DashboardMetricCard(
                    title: "Active Calories",
                    value: healthManager.healthData.activeCalories,
                    goal: 500,
                    progress: min(1.0, Double(healthManager.healthData.activeCalories) / 500.0),
                    icon: "flame.fill",
                    colors: [.orange, .red],
                    unit: "kcal",
                    onEdit: nil
                )
                
                DashboardMetricCard(
                    title: "Exercise",
                    value: healthManager.healthData.exerciseMinutes,
                    goal: healthManager.healthData.exerciseGoal,
                    progress: healthManager.healthData.exerciseProgress,
                    icon: "figure.run",
                    colors: [.green, .mint],
                    unit: "min",
                    onEdit: { newGoal in
                        UserDefaults.standard.set(newGoal, forKey: "exerciseGoal")
                        Task {
                            await healthManager.loadHealthData()
                        }
                    }
                )
            }
            
            // Weekly Steps Chart
            let weeklyStepsArray = Array(healthManager.healthData.weeklySteps.values.sorted())
            if !weeklyStepsArray.isEmpty {
        GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("Weekly Steps")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                    Spacer()
                        }
                        
                        WeeklyStepsChart(steps: weeklyStepsArray)
                    }
                    .padding(24)
                }
            }
        }
    }
}

struct ActivityStatRow: View {
    let icon: String
    let label: String
    let value: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
                                HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 30)
                
                Text(label)
                    .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.8))
                
                                    Spacer()
                
                Text(value)
                    .font(.headline.weight(.bold))
                                        .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white.opacity(0.15))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(progress), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

struct WeeklyStepsChart: View {
    let steps: [Int]
    @State private var animateBars = false
    
    var maxSteps: Int {
        steps.max() ?? 1
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, stepCount in
                VStack(spacing: 8) {
                    ZStack(alignment: .bottom) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 36, height: 130)
                        
                        // Animated bar with glow
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.cyan.opacity(0.9),
                                        Color.blue.opacity(0.9),
                                        Color.cyan.opacity(0.8)
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(
                                width: 36,
                                height: animateBars ? max(6, CGFloat(stepCount) / CGFloat(maxSteps) * 120) : 0
                            )
                            .shadow(color: .cyan.opacity(0.5), radius: 6, x: 0, y: -2)
            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                            colors: [.white.opacity(0.4), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.1),
                                value: animateBars
                            )
                    }
                    
                    Text(dayAbbreviation(index))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .frame(height: 150)
        .onAppear {
            withAnimation {
                animateBars = true
            }
        }
    }
    
    private func dayAbbreviation(_ index: Int) -> String {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let dayIndex = (today - 7 + index) % 7
        return days[dayIndex]
    }
}

// MARK: - Nutrition Tab View

struct NutritionTabView: View {
    @ObservedObject var foodTracker: FoodTrackerManager
    @ObservedObject var waterTracker: WaterTrackerManager
    @State private var selectedMeal: FoodEntry?
    @State private var showEditMeal = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Water Card - Editable
            EditableWaterCard(
                waterTracker: waterTracker,
                onEdit: { newGoal in
                    waterTracker.setGoal(Double(newGoal))
                }
            )
            
            // Food Calories Card - Editable
            EditableFoodCaloriesCard(
                foodTracker: foodTracker,
                onEdit: { newGoal in
                    UserDefaults.standard.set(newGoal, forKey: "caloriesGoal")
                }
            )
            
            // Recent Meals - Editable
            if !foodTracker.meals.isEmpty {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                            Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                        colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                            Text("Recent Meals")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 12) {
                                ForEach(foodTracker.meals.prefix(10)) { meal in
                                    Button {
                                        selectedMeal = meal
                                        showEditMeal = true
                                        Hx.tap()
                                    } label: {
                                        MealRow(meal: meal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                    .padding(24)
                }
            }
        }
        .sheet(isPresented: $showEditMeal) {
            if let meal = selectedMeal {
                EditMealSheet(meal: meal, foodTracker: foodTracker)
            }
        }
    }
}

struct NutritionStatRow: View {
    let icon: String
    let label: String
    let value: String
    let goal: Int
    let color: Color
    
    var progress: Double {
        let cleanedValue = value.replacingOccurrences(of: " kcal", with: "")
            .replacingOccurrences(of: " oz", with: "")
            .replacingOccurrences(of: " mi", with: "")
        if let numValue = Double(cleanedValue) {
            return min(1.0, numValue / Double(goal))
        }
        return 0.0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 30)
            
                Text(label)
                .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            
            Spacer()
                
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(progress), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

struct MealRow: View {
    let meal: FoodEntry
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(meal.mealType.color.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: meal.mealType.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(meal.mealType.color)
                )
            
                    VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                        .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(meal.mealType.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
            Text("\(meal.calories) kcal")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Body Tab View

struct BodyTabView: View {
    @ObservedObject var healthManager: HealthKitManager
    @State private var showEditWeight = false
    @State private var showEditHeight = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let bmi = healthManager.healthData.bmi {
                BMICard(
                    bmi: bmi,
                    weight: healthManager.healthData.weight,
                    height: healthManager.healthData.height,
                    onEditWeight: { showEditWeight = true },
                    onEditHeight: { showEditHeight = true }
                )
            } else {
                // No BMI data
                GlassCard {
                    VStack(spacing: 20) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Text("No Body Metrics")
                            .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                        Text("Add your weight and height in Apple Health to see your BMI and body metrics here.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                }
            }
            
            // Body Metrics Grid
            if healthManager.healthData.weight > 0 || healthManager.healthData.height > 0 {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    if healthManager.healthData.weight > 0 {
                        BodyMetricCard(
                            label: "Weight",
                            value: String(format: "%.1f", healthManager.healthData.weight),
                            unit: "lbs",
                            icon: "scalemass.fill",
                            color: .blue,
                            onEdit: { showEditWeight = true }
                        )
                    }
                    
                    if healthManager.healthData.height > 0 {
                        BodyMetricCard(
                            label: "Height",
                            value: String(format: "%.1f", healthManager.healthData.height),
                            unit: "in",
                            icon: "ruler.fill",
                            color: .purple,
                            onEdit: { showEditHeight = true }
                        )
                    }
                }
            }
        }
    }
}

struct BMICard: View {
    let bmi: Double
    let weight: Double
    let height: Double
    let onEditWeight: () -> Void
    let onEditHeight: () -> Void
    @State private var animate = false
    
    var category: (String, Color) {
        switch bmi {
        case ..<18.5: return ("Underweight", .blue)
        case 18.5..<25: return ("Normal", .green)
        case 25..<30: return ("Overweight", .orange)
        default: return ("Obese", .red)
        }
    }
    
    var body: some View {
        GlassCard {
            VStack(spacing: 24) {
                HStack {
                    Text("Body Mass Index")
                        .font(.headline.weight(.semibold))
                                                .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text(category.0)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(category.1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                                                .background(
                                                    Capsule()
                                .fill(category.1.opacity(0.2))
                                                        .overlay(
                                                            Capsule()
                                        .stroke(category.1.opacity(0.5), lineWidth: 1.5)
                                )
                        )
                }
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 18)
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: animate ? min(1.0, bmi / 40.0) : 0)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [category.1, category.1.opacity(0.6)]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 150, height: 150)
                        .animation(.spring(response: 0.8), value: animate)
                    
                    VStack(spacing: 6) {
                        Text(String(format: "%.1f", bmi))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white)
                                        .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("BMI")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                HStack(spacing: 24) {
                    if weight > 0 {
                        VStack(spacing: 4) {
                            Text(String(format: "%.1f", weight))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                        .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Weight (lbs)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                            Button {
                                onEditWeight()
                                    Hx.tap()
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                    }
                    
                    if height > 0 {
                        VStack(spacing: 4) {
                            Text(String(format: "%.1f", height))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Height (in)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                            Button {
                                onEditHeight()
                                Hx.tap()
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.spring().delay(0.2)) {
                animate = true
            }
        }
    }
}

struct BodyMetricCard: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let onEdit: () -> Void
    
    var body: some View {
        GlassCard(expand: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.8), color.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: color.opacity(0.4), radius: 8, y: 4)
                        
            Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    Button {
                        onEdit()
                        Hx.tap()
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(unit)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
            
            Text(label)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
        }
    }
}

// MARK: - Quick Health Stats Bar

struct QuickHealthStatsBar: View {
    @ObservedObject var healthManager: HealthKitManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickStatPill(
                    icon: "figure.walk",
                    value: formatLargeNumber(healthManager.healthData.steps),
                    label: "Steps",
                    color: .cyan,
                    progress: healthManager.healthData.stepsProgress
                )
                
                QuickStatPill(
                    icon: "flame.fill",
                    value: "\(healthManager.healthData.activeCalories)",
                    label: "Cal",
                    color: .orange,
                    progress: min(1.0, Double(healthManager.healthData.activeCalories) / 500.0)
                )
                
                QuickStatPill(
                    icon: "heart.fill",
                    value: healthManager.healthData.heartRate > 0 ? "\(healthManager.healthData.heartRate)" : "--",
                    label: "BPM",
                    color: .red,
                    progress: 0.7
                )
                
                QuickStatPill(
                    icon: "drop.fill",
                    value: String(format: "%.0f", healthManager.healthData.waterIntakeOz),
                    label: "oz",
                    color: .blue,
                    progress: healthManager.healthData.waterProgress
                )
                
                QuickStatPill(
                    icon: "bed.double.fill",
                    value: String(format: "%.1f", healthManager.healthData.sleepHours),
                    label: "hrs",
                    color: .indigo,
                    progress: min(1.0, healthManager.healthData.sleepHours / 8.0)
                )
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func formatLargeNumber(_ number: Int) -> String {
        if number >= 10000 {
            let k = Double(number) / 1000.0
            return String(format: "%.1fk", k)
        } else if number >= 1000 {
            let k = Double(number) / 1000.0
            return String(format: "%.2fk", k)
        }
        return "\(number)"
    }
}

struct QuickStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let progress: Double
    @State private var animateProgress = false
    @State private var pulse = false
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                // Enhanced glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.5),
                                color.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 20
                        )
                    )
                    .frame(width: 40, height: 40)
                    .blur(radius: 4)
                    .opacity(pulse ? 0.8 : 0.5)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.4), color.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: color.opacity(0.4), radius: 4, y: 2)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .symbolEffect(.pulse, value: pulse)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }
            
            // Enhanced mini progress indicator
                ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.15)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 45, height: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: animateProgress ? 45 * CGFloat(min(1.0, progress)) : 0, height: 4)
                    .shadow(color: color.opacity(0.5), radius: 2, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateProgress)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Water Quick Add Sheet

struct WaterQuickAddSheet: View {
    @ObservedObject var tracker: WaterTrackerManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAmount: Double = 8.0
    
    var body: some View {
            NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                VStack(spacing: 24) {
        GlassCard {
                        VStack(spacing: 20) {
                            Text("Add Water")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                            
                            Text("\(Int(selectedAmount)) oz")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    ForEach([8.0, 12.0, 16.0, 20.0], id: \.self) { amount in
                                        Button {
                                            selectedAmount = amount
                                            Hx.tap()
                                        } label: {
                                            Text("\(Int(amount))")
                                                .font(.headline.weight(.semibold))
                                                .foregroundStyle(selectedAmount == amount ? .white : .white.opacity(0.7))
                                                .frame(width: 60, height: 50)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(selectedAmount == amount ? Color.blue.opacity(0.5) : Color.white.opacity(0.1))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                Slider(value: $selectedAmount, in: 4...32, step: 4)
                                    .tint(.blue)
                            }
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 22)
                    
                    Spacer()
                    
                    Button {
                        tracker.addWater(ounces: selectedAmount)
                        Hx.ok()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Add \(Int(selectedAmount)) oz")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue.opacity(0.9), .cyan.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
    }
}

// MARK: - Health Settings View

struct HealthSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthManager: HealthKitManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Health Settings")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.white)
                                
                                if healthManager.isAuthorized {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text("Apple Health Connected")
                                            .foregroundStyle(.white)
                                    }
                                } else {
                                    Button {
                                        Task {
                                            await healthManager.requestAuthorization()
                                            healthManager.checkAuthorizationStatus()
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "link.circle.fill")
                                            Text("Connect Apple Health")
                                        }
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.green.opacity(0.3))
                                        )
                                    }
                                }
                            }
                            .padding(24)
                        }
                        .padding(.horizontal, 22)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
    }
}

// MARK: - Comprehensive Health Score Card

struct ComprehensiveHealthScoreCard: View {
    @ObservedObject var healthManager: HealthKitManager
    @Binding var animateScore: Bool
    @State private var pulse = false
    @State private var glow = false
    
    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Health Score")
                            .font(.title2.weight(.bold))
                                .foregroundStyle(
                                    LinearGradient(
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        
                        Text(formattedDate)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    
                    Spacer()
                    
                    // Enhanced Animated Health Score Circle with glow
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: scoreColors.map { $0.opacity(0.3) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 120, height: 120)
                            .opacity(glow ? 0.8 : 0.4)
                        
                        // Background circle
                    Circle()
                        .stroke(
                            LinearGradient(
                                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                                lineWidth: 14
                        )
                            .frame(width: 110, height: 110)
                            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    
                        // Animated progress circle with glow
                    Circle()
                            .trim(from: 0, to: animateScore ? CGFloat(healthScore / 100.0) : 0)
                        .stroke(
                            AngularGradient(
                                    gradient: Gradient(colors: scoreColors + scoreColors),
                                center: .center,
                                    angle: .degrees(glow ? 360 : 0)
                            ),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                            .frame(width: 110, height: 110)
                            .shadow(color: scoreColors[0].opacity(0.6), radius: glow ? 12 : 8, x: 0, y: 4)
                            .animation(.spring(response: 1.2, dampingFraction: 0.8), value: animateScore)
                            .animation(.linear(duration: 3.0).repeatForever(autoreverses: false), value: glow)
                        
                        // Inner glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        scoreColors[0].opacity(0.4),
                                        scoreColors[1].opacity(0.2),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 110, height: 110)
                            .opacity(pulse ? 0.8 : 0.5)
                        
                        // Score text with enhanced styling
                        VStack(spacing: 4) {
                            Text("\(Int(healthScore))")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.95)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .fixedSize(horizontal: false, vertical: true)
                                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                            Text("/100")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                }
                
                // Enhanced Breakdown
                VStack(spacing: 12) {
                    HealthScoreBreakdownRow(
                        label: "Steps",
                        score: min(100, Int(healthManager.healthData.stepsProgress * 100)),
                        color: .cyan
                    )
                    HealthScoreBreakdownRow(
                        label: "Sleep",
                        score: min(100, Int(healthManager.healthData.sleepProgress * 100)),
                        color: .indigo
                    )
                    HealthScoreBreakdownRow(
                        label: "Exercise",
                        score: min(100, Int(healthManager.healthData.exerciseProgress * 100)),
                        color: .green
                    )
                    HealthScoreBreakdownRow(
                        label: "Water",
                        score: min(100, Int(healthManager.healthData.waterProgress * 100)),
                        color: .blue
                    )
                    if healthManager.healthData.heartRate > 0 {
                        HealthScoreBreakdownRow(
                            label: "Heart Rate",
                            score: healthManager.healthData.heartRate >= 60 && healthManager.healthData.heartRate <= 100 ? 100 : (healthManager.healthData.heartRate < 60 ? 80 : 70),
                            color: .red
                        )
                    }
                    if healthManager.healthData.systolicBP > 0 {
                        HealthScoreBreakdownRow(
                            label: "Blood Pressure",
                            score: healthManager.healthData.systolicBP < 120 && healthManager.healthData.diastolicBP < 80 ? 100 : (healthManager.healthData.systolicBP < 130 ? 80 : 60),
                            color: .orange
                        )
                    }
                    if healthManager.healthData.oxygenSaturation > 0 {
                        HealthScoreBreakdownRow(
                            label: "Oxygen",
                            score: healthManager.healthData.oxygenSaturation >= 98 ? 100 : (healthManager.healthData.oxygenSaturation >= 95 ? 80 : 60),
                            color: .cyan
                        )
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                glow = true
            }
        }
        .onDisappear {
            pulse = false
            glow = false
        }
    }
    
    private var healthScore: Double {
        healthManager.healthData.healthScore
    }
    
    private var scoreColors: [Color] {
        switch healthScore {
        case 80...100:
            return [.green, .mint, .cyan]
        case 60..<80:
            return [.yellow, .orange, .red.opacity(0.8)]
        default:
            return [.orange, .red, .pink]
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

struct HealthScoreBreakdownRow: View {
    let label: String
    let score: Int
    let color: Color
    @State private var animateProgress = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Enhanced background
                    RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    // Animated progress bar with glow
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        .frame(width: animateProgress ? geo.size.width * CGFloat(score) / 100.0 : 0, height: 8)
                        .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 2)
            .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animateProgress)
                }
            }
            .frame(height: 8)
            
            Text("\(score)%")
                .font(.caption.weight(.bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, alignment: .trailing)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8).delay(0.2)) {
                animateProgress = true
            }
        }
    }
}

// MARK: - Steps and Miles Card

struct StepsMilesCard: View {
    let steps: Int
    let miles: Double
    let stepsGoal: Int
    let stepsProgress: Double
    let onEditSteps: (Int) -> Void
    @State private var showEditSheet = false
    @State private var editedGoal: Int
    @State private var animateProgress = false
    @State private var pulse = false
    
    init(steps: Int, miles: Double, stepsGoal: Int, stepsProgress: Double, onEditSteps: @escaping (Int) -> Void) {
        self.steps = steps
        self.miles = miles
        self.stepsGoal = stepsGoal
        self.stepsProgress = stepsProgress
        self.onEditSteps = onEditSteps
        self._editedGoal = State(initialValue: stepsGoal)
    }
    
    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                HStack {
                    ZStack {
                        // Enhanced glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.cyan.opacity(0.5),
                                        Color.blue.opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 35
                                )
                            )
                            .frame(width: 70, height: 70)
                            .blur(radius: 8)
                            .opacity(pulse ? 0.8 : 0.5)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.9), .blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: .cyan.opacity(0.5), radius: pulse ? 12 : 8, y: 4)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.4), .white.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        
                        Image(systemName: "figure.walk")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                            .symbolEffect(.pulse, value: pulse)
                    }
                    .scaleEffect(pulse ? 1.05 : 1.0)
                    
                    Text("Activity")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    Spacer()
                    
                    Button {
                        showEditSheet = true
                        Hx.tap()
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                    colors: [.white.opacity(0.9), .white.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
                
                HStack(spacing: 24) {
                    // Steps
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(steps)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("steps")
                                .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                        Text("\(Int(stepsProgress * 100))% of \(stepsGoal)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                        
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.15))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                            colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                                    .frame(width: geo.size.width * CGFloat(stepsProgress), height: 8)
                }
            }
            .frame(height: 8)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .frame(height: 60)
                    
                    // Miles
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", miles))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("mi")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        
                        Text("Distance")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showEditSheet) {
            EditGoalSheet(
                title: "Steps",
                currentGoal: stepsGoal,
                unit: "steps",
                onSave: { newGoal in
                    editedGoal = newGoal
                    onEditSteps(newGoal)
                    showEditSheet = false
                    Hx.ok()
                },
                onCancel: {
                    editedGoal = stepsGoal
                    showEditSheet = false
                }
            )
        }
    }
}

// MARK: - Vital Signs Card

struct VitalSignsCard: View {
    @ObservedObject var healthManager: HealthKitManager
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Vital Signs")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    if healthManager.healthData.systolicBP > 0 {
                        VitalSignMetric(
                            icon: "waveform.path.ecg",
                            label: "Blood Pressure",
                            value: "\(healthManager.healthData.systolicBP)/\(healthManager.healthData.diastolicBP)",
                            unit: "mmHg",
                            color: .red
                        )
                    }
                    
                    if healthManager.healthData.oxygenSaturation > 0 {
                        VitalSignMetric(
                            icon: "lungs.fill",
                            label: "Oxygen",
                            value: String(format: "%.1f", healthManager.healthData.oxygenSaturation),
                            unit: "%",
                        color: .blue
                    )
                    }
                    
                    if healthManager.healthData.respiratoryRate > 0 {
                        VitalSignMetric(
                            icon: "wind",
                            label: "Respiratory Rate",
                            value: "\(healthManager.healthData.respiratoryRate)",
                            unit: "/min",
                        color: .cyan
                    )
                    }
                    
                    if healthManager.healthData.bodyTemperature > 0 {
                        VitalSignMetric(
                            icon: "thermometer",
                            label: "Temperature",
                            value: String(format: "%.1f", healthManager.healthData.bodyTemperature),
                            unit: "°F",
                            color: .orange
                        )
                    }
                }
            }
            .padding(24)
        }
    }
}

struct VitalSignMetric: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: icon)
                .font(.title3)
                            .foregroundStyle(color)
            
            Text(label)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Editable Water Card

struct EditableWaterCard: View {
    @ObservedObject var waterTracker: WaterTrackerManager
    let onEdit: (Int) -> Void
    @State private var showEditSheet = false
    @State private var showWaterPicker = false
    @State private var editedGoal: Int
    
    init(waterTracker: WaterTrackerManager, onEdit: @escaping (Int) -> Void) {
        self.waterTracker = waterTracker
        self.onEdit = onEdit
        self._editedGoal = State(initialValue: Int(waterTracker.goal))
    }
    
    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "drop.fill")
                        .font(.title)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Water Intake")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    
                    Button {
                        showEditSheet = true
                        Hx.tap()
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                
                VStack(spacing: 16) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.0f", waterTracker.todaysIntake))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("oz")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Text("\(Int(waterTracker.progress * 100))% of \(Int(waterTracker.goal)) oz goal")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                        colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                                .frame(width: geo.size.width * CGFloat(waterTracker.progress), height: 12)
                        }
                    }
                    .frame(height: 12)
                    
                    // Quick Add Water Button
                        Button {
                        showWaterPicker = true
                            Hx.tap()
                        } label: {
                        HStack {
                                Image(systemName: "plus.circle.fill")
                            Text("Add Water")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                            .background(
                                        LinearGradient(
                                colors: [.blue.opacity(0.9), .cyan.opacity(0.9)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showEditSheet) {
            EditGoalSheet(
                title: "Water",
                currentGoal: Int(waterTracker.goal),
                unit: "oz",
                onSave: { newGoal in
                    editedGoal = newGoal
                    onEdit(newGoal)
                    showEditSheet = false
                    Hx.ok()
                },
                onCancel: {
                    editedGoal = Int(waterTracker.goal)
                    showEditSheet = false
                }
            )
        }
        .sheet(isPresented: $showWaterPicker) {
            WaterQuickAddSheet(tracker: waterTracker)
        }
    }
}

// MARK: - Editable Food Calories Card

struct EditableFoodCaloriesCard: View {
    @ObservedObject var foodTracker: FoodTrackerManager
    let onEdit: (Int) -> Void
    @State private var showEditSheet = false
    @State private var showFoodTracker = false
    @State private var editedGoal: Int
    
    init(foodTracker: FoodTrackerManager, onEdit: @escaping (Int) -> Void) {
        self.foodTracker = foodTracker
        self.onEdit = onEdit
        let caloriesGoal = UserDefaults.standard.integer(forKey: "caloriesGoal")
        self._editedGoal = State(initialValue: caloriesGoal > 0 ? caloriesGoal : 2000)
    }
    
    var caloriesGoal: Int {
        UserDefaults.standard.integer(forKey: "caloriesGoal") > 0 ? UserDefaults.standard.integer(forKey: "caloriesGoal") : 2000
    }
    
    var progress: Double {
        min(1.0, Double(foodTracker.todaysCalories) / Double(caloriesGoal))
    }
    
    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "fork.knife")
                        .font(.title)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Food Calories")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                
                Button {
                        showEditSheet = true
                        Hx.tap()
                } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                
                VStack(spacing: 16) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(foodTracker.todaysCalories)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("kcal")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Text("\(Int(progress * 100))% of \(caloriesGoal) kcal goal")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 12)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                                .frame(width: geo.size.width * CGFloat(progress), height: 12)
                        }
                    }
                    .frame(height: 12)
                    
                    // Add Food Button
                Button {
                    showFoodTracker = true
                    Hx.tap()
                } label: {
                        HStack {
                        Image(systemName: "plus.circle.fill")
                            Text("Add Food")
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
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showEditSheet) {
            EditGoalSheet(
                title: "Food Calories",
                currentGoal: caloriesGoal,
                unit: "kcal",
                onSave: { newGoal in
                    editedGoal = newGoal
                    onEdit(newGoal)
                    showEditSheet = false
                    Hx.ok()
                },
                onCancel: {
                    editedGoal = caloriesGoal
                    showEditSheet = false
                }
            )
        }
        .sheet(isPresented: $showFoodTracker) {
            NavigationStack {
                FoodTrackerView()
            }
        }
    }
}

// MARK: - Health Trend Charts Card

struct HealthTrendChartsCard: View {
    @ObservedObject var healthManager: HealthKitManager
    @State private var selectedChart: TrendChartType = .steps
    
    enum TrendChartType: String, CaseIterable {
        case steps = "Steps"
        case calories = "Calories"
        case sleep = "Sleep"
        case heartRate = "Heart Rate"
        
        var icon: String {
            switch self {
            case .steps: return "figure.walk"
            case .calories: return "flame.fill"
            case .sleep: return "bed.double.fill"
            case .heartRate: return "heart.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .steps: return .cyan
            case .calories: return .orange
            case .sleep: return .indigo
            case .heartRate: return .red
            }
        }
    }
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    Text("Health Trends")
                        .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                    Spacer()
                    }
                
                // Chart Type Selector
                ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                        ForEach(TrendChartType.allCases, id: \.self) { chartType in
                        Button {
                            withAnimation(.spring()) {
                                    selectedChart = chartType
                                }
                                Hx.tap()
                        } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: chartType.icon)
                                        .font(.caption)
                                    Text(chartType.rawValue)
                                .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(selectedChart == chartType ? .white : .white.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(selectedChart == chartType ? chartType.color.opacity(0.5) : Color.white.opacity(0.1))
                                )
                        }
                    }
                }
            }
                
                // Chart Display
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 200)
                    
                    switch selectedChart {
                    case .steps:
                        WeeklyStepsTrendChart(steps: healthManager.healthData.weeklySteps)
                    case .calories:
                        CaloriesTrendChart(healthManager: healthManager)
                    case .sleep:
                        SleepTrendChart(healthManager: healthManager)
                    case .heartRate:
                        HeartRateTrendChart(healthManager: healthManager)
                    }
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Trend Chart Components

struct WeeklyStepsTrendChart: View {
    let steps: [Date: Int]
    
    var sortedSteps: [(Date, Int)] {
        steps.sorted { $0.key < $1.key }
    }
    
    var maxSteps: Int {
        sortedSteps.map { $0.1 }.max() ?? 1
    }
    
    var body: some View {
        if !sortedSteps.isEmpty {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(sortedSteps.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 30, height: max(4, CGFloat(item.1) / CGFloat(maxSteps) * 160))
                        
                        Text(dayAbbreviation(index))
                            .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 8)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.5))
                Text("No data available")
                        .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func dayAbbreviation(_ index: Int) -> String {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let dayIndex = (today - 7 + index) % 7
        return days[dayIndex]
    }
}

struct CaloriesTrendChart: View {
    @ObservedObject var healthManager: HealthKitManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                        LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 50, height: CGFloat(min(150, Double(healthManager.healthData.activeCalories) / 5.0)))
                    
                    Text("Active")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 50, height: CGFloat(min(150, Double(healthManager.healthData.dietaryCalories) / 10.0)))
                    
                    Text("Food")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(height: 170)
            
            Text("Today's Calories")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct SleepTrendChart: View {
    @ObservedObject var healthManager: HealthKitManager
    
    var body: some View {
        VStack(spacing: 12) {
                ZStack {
                    Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 16)
                    .frame(width: 120, height: 120)
                    
                    Circle()
                    .trim(from: 0, to: CGFloat(healthManager.healthData.sleepHours / 8.0))
                        .stroke(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                
                        VStack(spacing: 4) {
                    Text(String(format: "%.1f", healthManager.healthData.sleepHours))
                        .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                    Text("hours")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            Text("Last Night's Sleep")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
        .frame(maxWidth: .infinity)
    }
}

struct HeartRateTrendChart: View {
    @ObservedObject var healthManager: HealthKitManager
    
    var body: some View {
        VStack(spacing: 12) {
                ZStack {
                    Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 16)
                    .frame(width: 120, height: 120)
                
                if healthManager.healthData.heartRate > 0 {
                    Circle()
                        .trim(from: 0, to: CGFloat(Double(healthManager.healthData.heartRate) / 100.0))
                        .stroke(
                            LinearGradient(
                                colors: [.red, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                }
                
                VStack(spacing: 4) {
                    Text(healthManager.healthData.heartRate > 0 ? "\(healthManager.healthData.heartRate)" : "--")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text("bpm")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
            }
            
            Text("Resting Heart Rate")
                .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
        .frame(maxWidth: .infinity)
    }
}

