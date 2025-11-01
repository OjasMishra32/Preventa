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
                // Enhanced Tab selector with better design
                EnhancedTabSelector(selectedTab: $selectedTab)
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Quick Stats Bar (always visible)
                        QuickHealthStatsBar(healthManager: healthManager)
                            .padding(.horizontal, 22)
                        
                        switch selectedTab {
                        case .today:
                            SophisticatedTodayView(
                                healthManager: healthManager,
                                foodTracker: foodTracker,
                                waterTracker: waterTracker
                            )
                        case .activity:
                            SophisticatedActivityView(healthManager: healthManager)
                        case .nutrition:
                            SophisticatedNutritionView(
                                foodTracker: foodTracker,
                                waterTracker: waterTracker
                            )
                        case .body:
                            SophisticatedBodyView(healthManager: healthManager)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Health Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                Button {
                    healthManager.loadHealthData()
                        foodTracker.loadMeals()
                        waterTracker.loadTodaysIntake()
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
            HealthSettingsView(
                healthManager: healthManager,
                waterTracker: waterTracker
            )
        }
        .onAppear {
            healthManager.loadHealthData()
            foodTracker.loadMeals()
            waterTracker.loadTodaysIntake()
            
            // Auto-refresh every 60 seconds
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                healthManager.loadHealthData()
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
        }
    }
}

// MARK: - Enhanced Tab Selector

struct EnhancedTabSelector: View {
    @Binding var selectedTab: HealthDashboardView.HealthTab
    @Namespace private var tabAnimation
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HealthDashboardView.HealthTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                        Hx.tap()
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                if selectedTab == tab {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .matchedGeometryEffect(id: "selectedTab", in: tabAnimation)
                                        .shadow(color: .purple.opacity(0.4), radius: 8, y: 4)
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                }
                                
                                Image(systemName: tab.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.7))
                            }
                            .frame(width: 44, height: 44)
                            
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: selectedTab == tab ? .bold : .semibold, design: .rounded))
                                .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.7))
                        }
                        .frame(width: 70)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Sophisticated Today View

struct SophisticatedTodayView: View {
    @ObservedObject var healthManager: HealthKitManager
    @ObservedObject var foodTracker: FoodTrackerManager
    @ObservedObject var waterTracker: WaterTrackerManager
    @State private var insights: [HealthInsight] = []
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header with date and summary
            TodayHeaderView(healthManager: healthManager)
            
            // AI Insights Section
            if !insights.isEmpty {
                SophisticatedInsightsSection(insights: insights)
            }
            
            // Key Metrics Grid - Enhanced with edit capabilities
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                EditableMetricCard(
                    title: "Steps",
                    value: healthManager.healthData.steps,
                    goal: healthManager.healthData.stepsGoal,
                    progress: healthManager.healthData.stepsProgress,
                    icon: "figure.walk",
                    colors: [.cyan, .blue],
                    unit: "steps",
                    onEdit: { newGoal in
                        // Allow editing goal
                    }
                )
                
                EditableMetricCard(
                    title: "Water",
                    value: Int(waterTracker.todaysIntake),
                    goal: Int(waterTracker.goal),
                    progress: waterTracker.progress,
                    icon: "drop.fill",
                    colors: [.blue, .cyan],
                    unit: "oz",
                    onEdit: { newGoal in
                        waterTracker.setGoal(Double(newGoal))
                    }
                )
                
                EditableMetricCard(
                    title: "Active Calories",
                    value: healthManager.healthData.activeCalories,
                    goal: 500,
                    progress: min(1.0, Double(healthManager.healthData.activeCalories) / 500.0),
                    icon: "flame.fill",
                    colors: [.orange, .red],
                    unit: "kcal",
                    onEdit: nil
                )
                
                EditableMetricCard(
                    title: "Food Calories",
                    value: foodTracker.todaysCalories,
                    goal: 2000,
                    progress: min(1.0, Double(foodTracker.todaysCalories) / 2000.0),
                    icon: "fork.knife",
                    colors: [.green, .mint],
                    unit: "kcal",
                    onEdit: nil
                )
            }
            
            // Health Metrics Row
            HStack(spacing: 16) {
            if healthManager.healthData.sleepHours > 0 {
                    SophisticatedSleepCard(hours: healthManager.healthData.sleepHours)
            }
            
            if healthManager.healthData.heartRate > 0 {
                    SophisticatedHeartRateCard(bpm: healthManager.healthData.heartRate)
                }
            }
            
            // Quick Actions - Enhanced
            SophisticatedQuickActions(
                waterTracker: waterTracker,
                foodTracker: foodTracker
            )
        }
        .task {
            // Generate AI-powered insights when view appears
            let aiInsights = await HealthInsightGenerator.shared.generateInsights(
                from: healthManager.healthData,
                weeklySteps: healthManager.healthData.weeklySteps
            )
            await MainActor.run {
                insights = aiInsights
            }
        }
        .onChange(of: healthManager.healthData.steps) { _, _ in
            // Regenerate insights when health data changes
            Task {
                let aiInsights = await HealthInsightGenerator.shared.generateInsights(
                    from: healthManager.healthData,
                    weeklySteps: healthManager.healthData.weeklySteps
                )
                await MainActor.run {
                    insights = aiInsights
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                animate = true
            }
        }
    }
}

// MARK: - Today Header

struct TodayHeaderView: View {
    @ObservedObject var healthManager: HealthKitManager
    @State private var currentTime = Date()
    
    var body: some View {
        GlassCard {
        HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
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
                                print("🔵 UI: Authorization button tapped")
                                let authorized = await healthManager.requestAuthorization()
                                print("🔵 UI: Authorization result: \(authorized)")
                                
                                // Update authorization status manually in case it hasn't updated yet
                                healthManager.checkAuthorizationStatus()
                                
                                if authorized {
                                    Hx.ok()
                                } else {
                                    // Still try to load data - status might be slow to update
                                    healthManager.loadHealthData()
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
                VStack(spacing: 4) {
                    Text("\(healthScore)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: healthScoreColor,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Health Score")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .onAppear {
            // Update time every minute
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentTime = Date()
            }
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
    
    private var healthScore: Int {
        var score = 0
        let data = healthManager.healthData
        
        // Steps (0-30 points)
        score += min(30, Int(data.stepsProgress * 30))
        
        // Sleep (0-25 points)
        if data.sleepHours >= 7 && data.sleepHours <= 9 {
            score += 25
        } else if data.sleepHours >= 6 && data.sleepHours < 10 {
            score += 15
        } else {
            score += 5
        }
        
        // Heart Rate (0-20 points)
        if data.heartRate >= 60 && data.heartRate <= 100 {
            score += 20
        } else if data.heartRate > 0 {
            score += 10
        }
        
        // Activity (0-15 points)
        score += min(15, data.activeCalories / 33)
        
        // Water (0-10 points)
        let waterProgress = data.waterIntakeOz / 64.0
        score += Int(waterProgress * 10)
        
        return min(100, score)
    }
    
    private var healthScoreColor: [Color] {
        switch healthScore {
        case 80...100: return [.green.opacity(0.9), .mint.opacity(0.9)]
        case 60..<80: return [.blue.opacity(0.9), .cyan.opacity(0.9)]
        case 40..<60: return [.orange.opacity(0.9), .yellow.opacity(0.9)]
        default: return [.red.opacity(0.9), .pink.opacity(0.9)]
        }
    }
}

// MARK: - Editable Metric Card

struct EditableMetricCard: View {
    let title: String
    let value: Int
    let goal: Int
    let progress: Double
    let icon: String
    let colors: [Color]
    let unit: String
    let onEdit: ((Int) -> Void)?
    @State private var showEditSheet = false
    @State private var editedGoal: Int
    
    init(title: String, value: Int, goal: Int, progress: Double, icon: String, colors: [Color], unit: String, onEdit: ((Int) -> Void)?) {
        self.title = title
        self.value = value
        self.goal = goal
        self.progress = progress
        self.icon = icon
        self.colors = colors
        self.unit = unit
        self.onEdit = onEdit
        self._editedGoal = State(initialValue: goal)
    }
    
    var body: some View {
        GlassCard(expand: false) {
            VStack(alignment: .leading, spacing: 14) {
                // Header with icon and edit button
                HStack {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                                    colors: colors.map { $0.opacity(0.8) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                            .frame(width: 44, height: 44)
                            .shadow(color: colors[0].opacity(0.4), radius: 8, y: 4)
                
                        Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
                    Spacer()
                    
                    if onEdit != nil {
                        Button {
                            showEditSheet = true
                            Hx.tap()
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                
                // Value display
            VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(value)")
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
                    
                    Text("\(Int(progress * 100))% of \(goal) goal")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                // Progress bar with gradient
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                                    colors: colors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(progress), height: 8)
                    }
                }
                .frame(height: 8)
        }
        .padding(18)
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
                    VStack(spacing: 8) {
                        Text("Edit Goal")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Set your daily goal for \(title.lowercased())")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.top, 40)
                    
                    GlassCard {
                        VStack(spacing: 20) {
                            HStack {
                                Text("Current Goal")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                                Spacer()
                                Text("\(currentGoal) \(unit)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.2))
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("New Goal")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                
                                HStack(spacing: 16) {
                                    Button {
                                        if newGoal > 0 {
                                            newGoal = max(0, newGoal - 100)
                                        }
                                        Hx.tap()
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    
                                    TextField("", value: $newGoal, format: .number)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                    
                                    Text(unit)
                                        .font(.title3)
                                        .foregroundStyle(.white.opacity(0.7))
                                    
                                    Button {
                                        newGoal += 100
                                        Hx.tap()
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }
                                
                                // Quick set buttons
                                HStack(spacing: 12) {
                                    ForEach([500, 1000, 1500], id: \.self) { quickValue in
                                        Button {
                                            newGoal = quickValue
                                            Hx.tap()
                                        } label: {
                                            Text("\(quickValue)")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(newGoal == quickValue ? .white : .white.opacity(0.8))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
        .background(
                                                    Capsule()
                                                        .fill(newGoal == quickValue ? Color.purple.opacity(0.5) : Color.white.opacity(0.1))
                                                )
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Sophisticated Insights Section

struct SophisticatedInsightsSection: View {
    let insights: [HealthInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Text("AI Insights")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }
            
            ForEach(insights) { insight in
                SophisticatedInsightCard(insight: insight)
            }
        }
    }
}

struct SophisticatedInsightCard: View {
    let insight: HealthInsight
    @State private var isVisible = false
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                // Enhanced icon
                    ZStack {
                        Circle()
                            .fill(
                            RadialGradient(
                                colors: [
                                    insight.color.opacity(0.9),
                                    insight.color.opacity(0.6)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: insight.color.opacity(0.4), radius: 12, y: 4)
                    
                    Image(systemName: insight.icon)
                        .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(insight.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text(insight.message)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Priority badge
                VStack(spacing: 4) {
                    Circle()
                        .fill(
                            insight.priority == .high
                                ? LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [insight.color, insight.color.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 10, height: 10)
                        .shadow(color: insight.color.opacity(0.6), radius: 4)
                    
                    Text(insight.priority == .high ? "!" : "•")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(20)
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Sophisticated Sleep Card

struct SophisticatedSleepCard: View {
    let hours: Double
    @State private var animate = false
    
    var body: some View {
        GlassCard(expand: false) {
            VStack(spacing: 16) {
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
                            .frame(width: 50, height: 50)
                        
                    Image(systemName: "bed.double.fill")
                            .font(.title3)
                        .foregroundStyle(.white)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sleep")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(String(format: "%.1f", hours))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("hours")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                
                // Sleep quality indicator
                    HStack(spacing: 4) {
                        ForEach(0..<5) { i in
                            Circle()
                                .fill(i < 4 ? Color.white.opacity(0.9) : Color.white.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            withAnimation(.spring().delay(0.2)) {
                animate = true
            }
        }
    }
}

// MARK: - Sophisticated Heart Rate Card

struct SophisticatedHeartRateCard: View {
    let bpm: Int
    @State private var pulse = false
    
    var body: some View {
        GlassCard(expand: false) {
            VStack(spacing: 16) {
                HStack {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .scaleEffect(pulse ? 1.15 : 1.0)
                    
                    Image(systemName: "heart.fill")
                            .font(.title3)
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse, value: pulse)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Heart Rate")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(bpm)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("bpm")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text(statusText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(statusColor)
                        .padding(.top, 4)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            pulse = true
        }
    }
    
    private var statusText: String {
        switch bpm {
        case 0..<60: return "Resting"
        case 60..<100: return "Normal"
        case 100..<140: return "Active"
        default: return "Elevated"
        }
    }
    
    private var statusColor: Color {
        switch bpm {
        case 60..<100: return .green
        case 100..<140: return .orange
        default: return .red
        }
    }
}

// MARK: - Sophisticated Quick Actions

struct SophisticatedQuickActions: View {
    @ObservedObject var waterTracker: WaterTrackerManager
    @ObservedObject var foodTracker: FoodTrackerManager
    @State private var showFoodTracker = false
    @State private var showWaterPicker = false
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                Text("Quick Actions")
                        .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                }
                
                HStack(spacing: 12) {
                    // Water quick add
                    QuickActionButton(
                        icon: "drop.fill",
                        title: "Water",
                        subtitle: "Quick add",
                        color: .blue,
                        action: {
                            showWaterPicker = true
                        }
                    )
                    
                    // Food tracker
                    QuickActionButton(
                        icon: "fork.knife",
                        title: "Food",
                        subtitle: "Log meal",
                        color: .green,
                        action: {
                            showFoodTracker = true
                        }
                    )
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showFoodTracker) {
            NavigationStack {
            FoodTrackerView()
            }
        }
        .sheet(isPresented: $showWaterPicker) {
            WaterQuickAddSheet(tracker: waterTracker)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Hx.tap()
            action()
        }) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.6), color.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 50)
                    
                Image(systemName: icon)
                        .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                }
                
                VStack(spacing: 2) {
                Text(title)
                        .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
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
                            Image(systemName: "drop.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            Text("Add Water")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                            
                            // Amount selector
                            HStack(spacing: 16) {
                                Button {
                                    if selectedAmount > 0 {
                                        selectedAmount = max(0, selectedAmount - 4)
                                    }
                                    Hx.tap()
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                
                                VStack(spacing: 4) {
                                    Text(String(format: "%.0f", selectedAmount))
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text("ounces")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                
                                Button {
                                    selectedAmount += 4
                                    Hx.tap()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            
                            // Quick buttons
                            HStack(spacing: 12) {
                                ForEach([8.0, 16.0, 20.0], id: \.self) { amount in
                                    Button {
                                        selectedAmount = amount
                                        Hx.tap()
                                    } label: {
                                        Text("\(Int(amount))oz")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(selectedAmount == amount ? .white : .white.opacity(0.8))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                Capsule()
                                                    .fill(selectedAmount == amount ? Color.blue.opacity(0.5) : Color.white.opacity(0.1))
                                            )
                                    }
                                }
                            }
                            
                            Button {
                                tracker.addWater(ounces: selectedAmount)
                                dismiss()
                                Hx.ok()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Add \(String(format: "%.0f", selectedAmount)) oz")
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
                        }
                        .padding(28)
                    }
                    .padding(.horizontal, 22)
                }
                .padding(.top, 40)
            }
            .navigationTitle("Add Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Health Settings View

struct HealthSettingsView: View {
    @ObservedObject var healthManager: HealthKitManager
    @ObservedObject var waterTracker: WaterTrackerManager
    @Environment(\.dismiss) private var dismiss
    @State private var showHealthAuthorization = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Health Connection Status
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: healthManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(healthManager.isAuthorized ? .green : .red)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Apple Health")
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text(healthManager.isAuthorized ? "Connected" : "Not Connected")
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    
                                    Spacer()
                                }
                                
                                if !healthManager.isAuthorized {
                                    Button {
                                        showHealthAuthorization = true
                                        Hx.tap()
                                    } label: {
                                        HStack {
                                            Image(systemName: "link")
                                            Text("Connect Apple Health")
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            in: RoundedRectangle(cornerRadius: 12)
                                        )
                                    }
                                }
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 22)
                        
                        // Water Goal Settings
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Water Goal")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                
                                HStack {
                                    Text("Daily Goal")
                                        .foregroundStyle(.white.opacity(0.8))
                                    Spacer()
                                    Text("\(Int(waterTracker.goal)) oz")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                                
                                Button {
                                    // Edit water goal
                                    Hx.tap()
                                } label: {
                                    Text("Edit Goal")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.15))
                                        )
                                }
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 22)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Health Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .task {
                if showHealthAuthorization {
                    let authorized = await healthManager.requestAuthorization()
                    if authorized {
                        healthManager.loadHealthData()
                    }
                }
            }
        }
    }
}

// MARK: - Majestic Activity View

struct SophisticatedActivityView: View {
    @ObservedObject var healthManager: HealthKitManager
    @State private var animate = false
    @State private var selectedMetric: ActivityMetricType = .steps
    
    enum ActivityMetricType {
        case steps, distance, calories, heartRate
    }
    
    var body: some View {
        VStack(spacing: 28) {
            // Hero Metric Card - Large, prominent display
            MajesticHeroMetricCard(healthManager: healthManager, selectedMetric: $selectedMetric)
            
            // Weekly Steps Chart - Enhanced
            EnhancedWeeklyStepsChart(weeklySteps: healthManager.healthData.weeklySteps)
            
            // Interactive Metric Selector
            MetricTypeSelector(selectedMetric: $selectedMetric)
            
            // Detailed Metric Cards Grid - Innovative Layout
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 20) {
                MajesticActivityCard(
                    title: "Steps Today",
                    value: healthManager.healthData.steps,
                    formattedValue: formatSteps(healthManager.healthData.steps),
                    subtitle: "Goal: 10,000",
                    icon: "figure.walk",
                    colors: [.cyan, .blue],
                    progress: min(1.0, Double(healthManager.healthData.steps) / 10000.0),
                    secondaryInfo: "\(calculateStepsPercentile())% percentile"
                )
                
                MajesticActivityCard(
                    title: "Distance",
                    value: Int(Double(healthManager.healthData.steps) * 0.0005),
                    formattedValue: String(format: "%.2f mi", Double(healthManager.healthData.steps) * 0.0005),
                    subtitle: "miles walked",
                    icon: "map.fill",
                    colors: [.blue, .indigo],
                    progress: min(1.0, (Double(healthManager.healthData.steps) * 0.0005) / 5.0),
                    secondaryInfo: "≈ \(Int(Double(healthManager.healthData.steps) * 0.0005 * 5280)) ft"
                )
                
                MajesticActivityCard(
                    title: "Active Calories",
                    value: healthManager.healthData.activeCalories,
                    formattedValue: "\(healthManager.healthData.activeCalories) kcal",
                    subtitle: "energy burned",
                    icon: "flame.fill",
                    colors: [.orange, .red],
                    progress: min(1.0, Double(healthManager.healthData.activeCalories) / 500.0),
                    secondaryInfo: "≈ \(Int(Double(healthManager.healthData.activeCalories) / 3.5)) min jogging"
                )
                
                MajesticActivityCard(
                    title: "Heart Rate",
                    value: healthManager.healthData.heartRate,
                    formattedValue: healthManager.healthData.heartRate > 0 ? "\(healthManager.healthData.heartRate) bpm" : "-- bpm",
                    subtitle: "resting rate",
                    icon: "heart.fill",
                    colors: [.red, .pink],
                    progress: healthManager.healthData.heartRate > 0 ? 0.75 : 0.0,
                    secondaryInfo: healthManager.healthData.heartRate > 0 ? heartRateZone : "No data"
                )
            }
            
            // Activity Insights Card
            ActivityInsightsCard(healthManager: healthManager)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                animate = true
            }
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 10000 {
            return "\(steps / 1000)k+"
        } else if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
    
    private func calculateStepsPercentile() -> Int {
        let steps = healthManager.healthData.steps
        if steps >= 12000 { return 90 }
        if steps >= 10000 { return 75 }
        if steps >= 8000 { return 50 }
        if steps >= 5000 { return 25 }
        return 10
    }
    
    private var heartRateZone: String {
        let bpm = healthManager.healthData.heartRate
        if bpm >= 100 { return "Elevated" }
        if bpm >= 60 { return "Normal" }
        return "Low"
    }
}

// MARK: - Majestic Activity Components

struct MajesticHeroMetricCard: View {
    @ObservedObject var healthManager: HealthKitManager
    @Binding var selectedMetric: SophisticatedActivityView.ActivityMetricType
    @State private var pulse = false
    
    var currentValue: (value: String, icon: String, colors: [Color], progress: Double) {
        switch selectedMetric {
        case .steps:
            return (
                formatNumber(healthManager.healthData.steps),
                "figure.walk",
                [.cyan, .blue],
                min(1.0, Double(healthManager.healthData.steps) / 10000.0)
            )
        case .distance:
            let miles = Double(healthManager.healthData.steps) * 0.0005
            return (
                String(format: "%.2f", miles),
                "map.fill",
                [.blue, .indigo],
                min(1.0, miles / 5.0)
            )
        case .calories:
            return (
                "\(healthManager.healthData.activeCalories)",
                "flame.fill",
                [.orange, .red],
                min(1.0, Double(healthManager.healthData.activeCalories) / 500.0)
            )
        case .heartRate:
            return (
                healthManager.healthData.heartRate > 0 ? "\(healthManager.healthData.heartRate)" : "--",
                "heart.fill",
                [.red, .pink],
                0.75
            )
        }
    }
    
    var body: some View {
        GlassCard {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today's Activity")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(currentValue.value)
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: currentValue.colors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .contentTransition(.numericText())
                                .lineLimit(1)
                                .minimumScaleFactor(0.3)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(selectedMetric == .distance ? "mi" : selectedMetric == .calories ? "kcal" : "")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: currentValue.colors.map { $0.opacity(0.4) },
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)
                            .blur(radius: 20)
                            .opacity(pulse ? 0.8 : 0.6)
                            .scaleEffect(pulse ? 1.1 : 1.0)
                        
                        Image(systemName: currentValue.icon)
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: currentValue.colors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.pulse, value: pulse)
                    }
                }
                
                // Circular Progress Ring
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .trim(from: 0, to: currentValue.progress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: currentValue.colors + [currentValue.colors[0]]),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 140, height: 140)
                        .animation(.spring(response: 0.8), value: currentValue.progress)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(currentValue.progress * 100))%")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)
                        Text("of goal")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(28)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 10000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

struct MetricTypeSelector: View {
    @Binding var selectedMetric: SophisticatedActivityView.ActivityMetricType
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                MetricButton(
                    icon: "figure.walk",
                    title: "Steps",
                    isSelected: selectedMetric == .steps,
                    colors: [.cyan, .blue],
                    action: { selectedMetric = .steps }
                )
                
                MetricButton(
                    icon: "map.fill",
                    title: "Distance",
                    isSelected: selectedMetric == .distance,
                    colors: [.blue, .indigo],
                    action: { selectedMetric = .distance }
                )
                
                MetricButton(
                    icon: "flame.fill",
                    title: "Calories",
                    isSelected: selectedMetric == .calories,
                    colors: [.orange, .red],
                    action: { selectedMetric = .calories }
                )
                
                MetricButton(
                    icon: "heart.fill",
                    title: "Heart",
                    isSelected: selectedMetric == .heartRate,
                    colors: [.red, .pink],
                    action: { selectedMetric = .heartRate }
                )
            }
            .padding(.horizontal, 4)
        }
    }
}

struct MetricButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let colors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: colors.map { $0.opacity(0.6) },
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: colors[0].opacity(0.4), radius: 8, y: 4)
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    }
                }
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }
}

struct MajesticActivityCard: View {
    let title: String
    let value: Int
    let formattedValue: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    let progress: Double
    let secondaryInfo: String
    @State private var animatedProgress: Double = 0
    @State private var hover = false
    
    var body: some View {
        GlassCard(expand: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: colors.map { $0.opacity(0.7) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                            .shadow(color: colors[0].opacity(0.4), radius: 12, y: 4)
                            .scaleEffect(hover ? 1.05 : 1.0)
                        
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(formattedValue)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: colors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .fixedSize(horizontal: false, vertical: true)
                
                Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(subtitle)
                    .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    Text(secondaryInfo)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(colors[0].opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(colors[0].opacity(0.15))
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                // Enhanced Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: colors),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 60, height: 60)
                        .animation(.spring(response: 0.8), value: animatedProgress)
                }
            }
            .padding(20)
        }
        .scaleEffect(hover ? 1.02 : 1.0)
        .onAppear {
            withAnimation(.spring(response: 0.8).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onTapGesture {
            withAnimation(.spring()) {
                hover.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    hover = false
                }
            }
        }
    }
}

struct ActivityInsightsCard: View {
    @ObservedObject var healthManager: HealthKitManager
    
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
                    
                    Text("Activity Insights")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    InsightRow(
                        icon: "arrow.up.right",
                        text: calculateActivityTrend(),
                        color: .green
                    )
                    
                    InsightRow(
                        icon: "target",
                        text: calculateGoalStatus(),
                        color: .blue
                    )
                    
                    if healthManager.healthData.weeklySteps.count > 1 {
                        InsightRow(
                            icon: "chart.line.uptrend.xyaxis",
                            text: "Weekly average: \(formatSteps(weeklyAverage)) steps",
                            color: .purple
                        )
                    }
                }
            }
            .padding(20)
        }
    }
    
    private var weeklyAverage: Int {
        let values = healthManager.healthData.weeklySteps.values
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / values.count
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
    
    private func calculateActivityTrend() -> String {
        let today = healthManager.healthData.steps
        let avg = weeklyAverage
        if today > avg {
            let diff = Int((Double(today - avg) / Double(max(avg, 1))) * 100)
            return "\(diff)% above weekly average"
        } else if today < avg {
            let diff = Int((Double(avg - today) / Double(max(avg, 1))) * 100)
            return "\(diff)% below weekly average"
        }
        return "On track with weekly average"
    }
    
    private func calculateGoalStatus() -> String {
        let progress = healthManager.healthData.stepsProgress
        if progress >= 1.0 {
            return "Goal achieved! 🎉"
        } else if progress >= 0.75 {
            return "\(Int((1.0 - progress) * 100))% away from goal"
        } else {
            return "Keep going! \(Int(progress * 100))% complete"
        }
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            
            Spacer()
        }
    }
}

struct EnhancedWeeklyStepsChart: View {
    let weeklySteps: [Date: Int]
    @State private var animate = false
    @State private var selectedIndex: Int?
    
    var sortedData: [(Date, Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return (date, weeklySteps[date] ?? 0)
        }.reversed()
    }
    
    var maxSteps: Int {
        sortedData.map { $0.1 }.max() ?? 10000
    }
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                Text("Weekly Activity")
                            .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                
                        if let max = sortedData.map({ $0.1 }).max(), max > 0 {
                            Text("\(formatNumber(max)) steps max")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 8, height: 8)
                        Text("7 Days")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                ZStack(alignment: .topLeading) {
                    // Chart bars
                GeometryReader { geo in
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(sortedData.enumerated()), id: \.offset) { index, data in
                                VStack(spacing: 10) {
                                    ZStack(alignment: .top) {
                                        // Bar
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                                    colors: selectedIndex == index 
                                                        ? [.cyan.opacity(1.0), .blue.opacity(1.0)]
                                                        : [.cyan.opacity(0.9), .blue.opacity(0.9)],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(
                                                width: (geo.size.width - 48) / 7,
                                                height: max(20, geo.size.height * CGFloat(min(1.0, Double(data.1) / Double(max(maxSteps, 10000)))) * (animate ? 1.0 : 0))
                                            )
                                            .shadow(
                                                color: selectedIndex == index 
                                                    ? .cyan.opacity(0.6) 
                                                    : .cyan.opacity(0.4),
                                                radius: selectedIndex == index ? 8 : 4,
                                                y: selectedIndex == index ? 4 : 2
                                            )
                                            .scaleEffect(selectedIndex == index ? 1.05 : 1.0)
                                            .animation(.spring(response: 0.3), value: selectedIndex)
                                        
                                        // Value label above bar - properly positioned to prevent cutoff
                                        if animate && data.1 > 0 {
                                            Text(formatNumber(data.1))
                                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.black.opacity(0.6))
                                                        .overlay(
                                                            Capsule()
                                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                        )
                                                )
                                                .offset(y: -24)
                                                .lineLimit(1)
                                                .fixedSize(horizontal: true, vertical: false)
                                                .opacity(animate ? 1.0 : 0.0)
                                        }
                                    }
                                    
                                    // Day label
                                Text(dayLabel(data.0))
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(selectedIndex == index ? .white : .white.opacity(0.75))
                                        .lineLimit(1)
                                }
                                .frame(width: (geo.size.width - 48) / 7)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedIndex = selectedIndex == index ? nil : index
                                    }
                                    Hx.tap()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 200)
                }
                
                // Summary stats
                HStack(spacing: 20) {
                    StatSummary(
                        label: "Total",
                        value: formatNumber(sortedData.reduce(0) { $0 + $1.1 }),
                        icon: "figure.walk"
                    )
                    StatSummary(
                        label: "Avg/Day",
                        value: formatNumber(sortedData.isEmpty ? 0 : sortedData.reduce(0) { $0 + $1.1 } / sortedData.count),
                        icon: "chart.bar"
                    )
                    StatSummary(
                        label: "Trend",
                        value: calculateTrend(),
                        icon: "arrow.up.right"
                    )
                }
            }
            .padding(20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                animate = true
            }
        }
    }
    
    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            let k = Double(number) / 1000.0
            return String(format: "%.1fk", k)
        }
        return "\(number)"
    }
    
    private func calculateTrend() -> String {
        guard sortedData.count >= 2 else { return "--" }
        let recent = Array(sortedData.suffix(3)).map { $0.1 }.reduce(0, +)
        let earlier = Array(sortedData.prefix(3)).map { $0.1 }.reduce(0, +)
        
        if recent > earlier {
            let percent = Int((Double(recent - earlier) / Double(max(earlier, 1))) * 100)
            return "+\(percent)%"
        } else if recent < earlier {
            let percent = Int((Double(earlier - recent) / Double(max(earlier, 1))) * 100)
            return "-\(percent)%"
        }
        return "→"
    }
}

struct StatSummary: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
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
                    value: "\(formatLargeNumber(healthManager.healthData.steps))",
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
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            // Mini progress indicator
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 3)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(progress), height: 3)
                }
            }
            .frame(width: 40, height: 3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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

// MARK: - Majestic Nutrition View

struct SophisticatedNutritionView: View {
    @ObservedObject var foodTracker: FoodTrackerManager
    @ObservedObject var waterTracker: WaterTrackerManager
    @State private var showFoodTracker = false
    @State private var animate = false
    @State private var selectedView: NutritionViewType = .overview
    
    enum NutritionViewType {
        case overview, calories, water, meals
    }
    
    var body: some View {
        VStack(spacing: 28) {
            // Hero Nutrition Card - Majestic Design
            MajesticNutritionHeroCard(
                foodTracker: foodTracker,
                waterTracker: waterTracker
            )
            
            // Nutrition View Selector
            NutritionViewSelector(selectedView: $selectedView)
            
            // Content based on selection
            switch selectedView {
            case .overview:
                NutritionOverviewContent(
                    foodTracker: foodTracker,
                    waterTracker: waterTracker,
                    showFoodTracker: $showFoodTracker
                )
            case .calories:
                MajesticCaloriesView(foodTracker: foodTracker)
            case .water:
                MajesticWaterView(tracker: waterTracker)
            case .meals:
                MajesticMealsView(
                    foodTracker: foodTracker,
                    showFoodTracker: $showFoodTracker
                )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                animate = true
            }
        }
        .sheet(isPresented: $showFoodTracker) {
            NavigationStack {
            FoodTrackerView()
            }
        }
    }
}

// MARK: - Majestic Nutrition Components

struct MajesticNutritionHeroCard: View {
    @ObservedObject var foodTracker: FoodTrackerManager
    @ObservedObject var waterTracker: WaterTrackerManager
    @State private var pulse = false
    
    var totalCalories: Int {
        foodTracker.todaysCalories
    }
    
    var progress: Double {
        min(1.0, Double(totalCalories) / 2000.0)
    }
    
    var body: some View {
        GlassCard {
            VStack(spacing: 28) {
                HStack {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nutrition Today")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(totalCalories)")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .contentTransition(.numericText())
                            
                            Text("kcal")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        
                        Text("Goal: 2,000 kcal")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.green.opacity(0.4), .mint.opacity(0.3), .cyan.opacity(0.2)],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 25)
                            .opacity(pulse ? 0.8 : 0.6)
                            .scaleEffect(pulse ? 1.1 : 1.0)
                        
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.pulse, value: pulse)
                    }
                }
                
                // Majestic Progress Ring
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.green, .mint, .cyan, .blue, .green]),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 160, height: 160)
                        .animation(.spring(response: 0.8), value: progress)
                    
                    VStack(spacing: 6) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("of daily goal")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Text("\(2000 - totalCalories) remaining")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .padding(32)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct NutritionViewSelector: View {
    @Binding var selectedView: SophisticatedNutritionView.NutritionViewType
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                NutritionButton(
                    icon: "square.grid.2x2",
                    title: "Overview",
                    isSelected: selectedView == .overview,
                    colors: [.purple, .blue],
                    action: { selectedView = .overview }
                )
                
                NutritionButton(
                    icon: "flame.fill",
                    title: "Calories",
                    isSelected: selectedView == .calories,
                    colors: [.orange, .red],
                    action: { selectedView = .calories }
                )
                
                NutritionButton(
                    icon: "drop.fill",
                    title: "Water",
                    isSelected: selectedView == .water,
                    colors: [.blue, .cyan],
                    action: { selectedView = .water }
                )
                
                NutritionButton(
                    icon: "fork.knife",
                    title: "Meals",
                    isSelected: selectedView == .meals,
                    colors: [.green, .mint],
                    action: { selectedView = .meals }
                )
            }
            .padding(.horizontal, 4)
        }
    }
}

struct NutritionButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let colors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: colors.map { $0.opacity(0.6) },
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: colors[0].opacity(0.4), radius: 8, y: 4)
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    }
                }
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }
}

struct NutritionOverviewContent: View {
    @ObservedObject var foodTracker: FoodTrackerManager
    @ObservedObject var waterTracker: WaterTrackerManager
    @Binding var showFoodTracker: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Quick Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 20) {
                MajesticNutritionCard(
                    title: "Calories",
                    value: foodTracker.todaysCalories,
                    goal: 2000,
                    icon: "flame.fill",
                    colors: [.orange, .red],
                    unit: "kcal"
                )
                
                MajesticNutritionCard(
                    title: "Water",
                    value: Int(waterTracker.todaysIntake),
                    goal: Int(waterTracker.goal),
                    icon: "drop.fill",
                    colors: [.blue, .cyan],
                    unit: "oz"
                )
            }
            
            // Meals Section
            if !foodTracker.meals.isEmpty {
                MajesticMealsSection(
                    meals: foodTracker.meals,
                    showFoodTracker: $showFoodTracker,
                    onDelete: { meal in
                        foodTracker.deleteMeal(meal)
                    }
                )
            } else {
                EmptyMealsCard(showFoodTracker: $showFoodTracker)
            }
        }
    }
}

struct MajesticNutritionCard: View {
    let title: String
    let value: Int
    let goal: Int
    let icon: String
    let colors: [Color]
    let unit: String
    @State private var animatedProgress: Double = 0
    
    var progress: Double {
        min(1.0, Double(value) / Double(goal))
    }
    
    var body: some View {
        GlassCard(expand: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: colors.map { $0.opacity(0.7) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: colors[0].opacity(0.4), radius: 12, y: 4)
                        
                        Image(systemName: icon)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(value)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: colors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    Text("\(value) / \(goal) \(unit)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: colors),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 70, height: 70)
                        .animation(.spring(response: 0.8), value: animatedProgress)
                }
            }
            .padding(22)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8).delay(0.2)) {
                animatedProgress = progress
            }
        }
    }
}

struct MajesticCaloriesView: View {
    @ObservedObject var foodTracker: FoodTrackerManager
    
    var body: some View {
        VStack(spacing: 24) {
            EnhancedCaloriesCard(
                consumed: foodTracker.todaysCalories,
                burned: 0,
                goal: 2000
            )
            
            // Calorie breakdown by meal type
            CalorieBreakdownCard(foodTracker: foodTracker)
        }
    }
}

struct CalorieBreakdownCard: View {
    @ObservedObject var foodTracker: FoodTrackerManager
    
    var mealBreakdown: [(type: String, calories: Int, icon: String, color: Color)] {
        var breakdown: [String: Int] = [:]
        for meal in foodTracker.meals {
            breakdown[meal.mealType.rawValue, default: 0] += meal.calories
        }
        
        return breakdown.map { key, value in
            let type = FoodEntry.MealType(rawValue: key) ?? .snack
            return (key, value, type.icon, type.color)
        }.sorted { $0.calories > $1.calories }
    }
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Calorie Breakdown")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                }
                
                if !mealBreakdown.isEmpty {
                    ForEach(Array(mealBreakdown.enumerated()), id: \.offset) { _, item in
                        CalorieBreakdownRow(
                            mealType: item.type,
                            calories: item.calories,
                            icon: item.icon,
                            color: item.color,
                            total: foodTracker.todaysCalories
                        )
                    }
                } else {
                    Text("No meals logged yet")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
            }
            .padding(22)
        }
    }
}

struct CalorieBreakdownRow: View {
    let mealType: String
    let calories: Int
    let icon: String
    let color: Color
    let total: Int
    
    var percentage: Double {
        total > 0 ? Double(calories) / Double(total) : 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.3))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mealType)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        
                        Text("\(calories) kcal")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Text("\(Int(percentage * 100))%")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(percentage), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Water View

struct MajesticWaterView: View {
    @ObservedObject var tracker: WaterTrackerManager
    
    var body: some View {
        VStack(spacing: 24) {
            EnhancedWaterCard(tracker: tracker)
            
            // Water intake history
            WaterHistoryCard(tracker: tracker)
        }
    }
}

struct WaterHistoryCard: View {
    @ObservedObject var tracker: WaterTrackerManager
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Today's Progress")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                }
                
                VStack(spacing: 16) {
                    WaterProgressRow(
                        time: "Morning",
                        amount: tracker.todaysIntake * 0.4,
                        color: .blue
                    )
                    
                    WaterProgressRow(
                        time: "Afternoon",
                        amount: tracker.todaysIntake * 0.35,
                        color: .cyan
                    )
                    
                    WaterProgressRow(
                        time: "Evening",
                        amount: tracker.todaysIntake * 0.25,
                        color: .indigo
                    )
                }
            }
            .padding(22)
        }
    }
}

struct WaterProgressRow: View {
    let time: String
    let amount: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(time)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 16)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(min(1.0, amount / 20.0)), height: 16)
                }
            }
            .frame(height: 16)
            
            Text(String(format: "%.0f oz", amount))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 50, alignment: .trailing)
        }
    }
}

struct MajesticMealsView: View {
    @ObservedObject var foodTracker: FoodTrackerManager
    @Binding var showFoodTracker: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            if !foodTracker.meals.isEmpty {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                    Text("Today's Meals")
                            .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Button {
                            showFoodTracker = true
                            Hx.tap()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Meal")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.green.opacity(0.6), .mint.opacity(0.6)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                    )
                            )
                        }
                    }
                    
                    ForEach(foodTracker.meals) { meal in
                        MajesticMealCard(meal: meal) {
                            foodTracker.deleteMeal(meal)
                        }
                    }
                }
            } else {
                EmptyMealsCard(showFoodTracker: $showFoodTracker)
            }
        }
    }
}

struct MajesticMealCard: View {
    let meal: FoodEntry
    let onDelete: () -> Void
    @State private var showDeleteAlert = false
    @State private var hover = false
    
    var body: some View {
        GlassCard(expand: false) {
            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [meal.mealType.color.opacity(0.7), meal.mealType.color.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: meal.mealType.color.opacity(0.4), radius: 10, y: 4)
                        .scaleEffect(hover ? 1.05 : 1.0)
                    
                    Image(systemName: meal.mealType.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(meal.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 16) {
                        Label(meal.mealType.rawValue, systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Text(formatTime(meal.timestamp))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(meal.calories)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [meal.mealType.color, meal.mealType.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("kcal")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Button {
                    showDeleteAlert = true
                    Hx.warn()
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(8)
                }
            }
            .padding(20)
        }
        .scaleEffect(hover ? 1.01 : 1.0)
        .onTapGesture {
            withAnimation(.spring()) {
                hover.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    hover = false
                }
            }
        }
        .alert("Delete Meal?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
                Hx.ok()
            }
        } message: {
            Text("This will permanently delete this meal entry.")
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MajesticMealsSection: View {
    let meals: [FoodEntry]
    @Binding var showFoodTracker: Bool
    let onDelete: (FoodEntry) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Recent Meals")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button {
                    showFoodTracker = true
                    Hx.tap()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.6), .mint.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                    )
                }
            }
            
            ForEach(meals.prefix(5)) { meal in
                MajesticMealCard(meal: meal) {
                    onDelete(meal)
                }
            }
        }
    }
}

struct EnhancedCaloriesCard: View {
    let consumed: Int
    let burned: Int
    let goal: Int
    @State private var animate = false
    
    var net: Int {
        consumed - burned
    }
    
    var progress: Double {
        min(1.0, Double(consumed) / Double(goal))
    }
    
    var body: some View {
        GlassCard {
            VStack(spacing: 28) {
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Daily Calories")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(consumed)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("/ \(goal)")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                // Majestic Progress Ring
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: animate ? progress : 0)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.green, .mint, .cyan, .blue, .green]),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 150, height: 150)
                        .animation(.spring(response: 0.8), value: animate)
                    
                    VStack(spacing: 6) {
                    Text("\(Int(progress * 100))%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        Text("of goal")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                HStack(spacing: 32) {
                    CalorieStatBox(
                        value: "\(consumed)",
                        label: "Consumed",
                        color: .green
                    )
                    
                    CalorieStatBox(
                        value: "\(net)",
                        label: "Net",
                        color: .blue
                    )
                    
                    CalorieStatBox(
                        value: "\(goal - consumed)",
                        label: "Remaining",
                        color: .purple
                    )
                }
            }
            .padding(28)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8).delay(0.2)) {
                animate = true
            }
        }
    }
}

struct CalorieStatBox: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 1.5)
                )
        )
    }
}

struct EnhancedWaterCard: View {
    @ObservedObject var tracker: WaterTrackerManager
    @State private var animate = false
    
    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Water Intake")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(String(format: "%.1f / %.0f oz", tracker.todaysIntake, tracker.goal))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "drop.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                // Enhanced progress bar
                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 44)
                        
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geo.size.width * CGFloat(animate ? tracker.progress : 0),
                                height: 44
                            )
                            .animation(.spring(response: 0.6), value: animate)
                        
                        Text("\(Int(tracker.progress * 100))%")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 44)
                
                // Quick add buttons
                HStack(spacing: 12) {
                    ForEach([8.0, 16.0, 24.0], id: \.self) { amount in
                        Button {
                            tracker.addWater(ounces: amount)
                            Hx.ok()
                            withAnimation(.spring()) {
                                animate.toggle()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    animate.toggle()
                                }
                            }
                        } label: {
                            Text("\(Int(amount))oz")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.3))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                        )
                                )
                        }
                    }
                }
            }
            .padding(22)
        }
        .onAppear {
            withAnimation {
                animate = true
            }
        }
    }
}

struct EnhancedMealCard: View {
    let meal: FoodEntry
    let onDelete: () -> Void
    @State private var showDeleteAlert = false
    
    var body: some View {
        GlassCard(expand: false) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.7), .mint.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: meal.mealType.icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(meal.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 12) {
                    Text(meal.mealType.rawValue)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        
                        Text(formatTime(meal.timestamp))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(meal.calories)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("kcal")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Button {
                    showDeleteAlert = true
                    Hx.warn()
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(18)
        }
        .alert("Delete Meal?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
                Hx.ok()
            }
        } message: {
            Text("This will permanently delete this meal entry.")
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EmptyMealsCard: View {
    @Binding var showFoodTracker: Bool
    
    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.7))
                
                Text("No meals logged today")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                Text("Start tracking your nutrition by adding meals")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button {
                    showFoodTracker = true
                    Hx.tap()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Meal")
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
                    .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
                }
            }
            .padding(32)
        }
    }
}

// MARK: - Sophisticated Body View

struct SophisticatedBodyView: View {
    @ObservedObject var healthManager: HealthKitManager
    @State private var showEditWeight = false
    @State private var showEditHeight = false
    
    var body: some View {
        VStack(spacing: 24) {
            if let bmi = healthManager.healthData.bmi {
                EnhancedBMICard(
                    bmi: bmi,
                    weight: healthManager.healthData.weight,
                    height: healthManager.healthData.height,
                    onEditWeight: { showEditWeight = true },
                    onEditHeight: { showEditHeight = true }
                )
            } else {
                // No BMI data - prompt to add
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
                        BodyMetricEditCard(
                            label: "Weight",
                            value: String(format: "%.1f", healthManager.healthData.weight),
                            unit: "lbs",
                            icon: "scalemass.fill",
                            color: .blue,
                            onEdit: { showEditWeight = true }
                        )
                    }
                    
                    if healthManager.healthData.height > 0 {
                        BodyMetricEditCard(
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

struct EnhancedBMICard: View {
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
                            Text("Weight (lbs)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Button {
                                onEditWeight()
                                Hx.tap()
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    if height > 0 {
                        VStack(spacing: 4) {
                            Text(String(format: "%.1f", height))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Height (in)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Button {
                                onEditHeight()
                                Hx.tap()
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
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

struct BodyMetricEditCard: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let onEdit: () -> Void
    
    var body: some View {
        GlassCard(expand: false) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                VStack(spacing: 4) {
                    Text(value)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Text(label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Button {
                    onEdit()
                    Hx.tap()
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, 4)
            }
            .padding(18)
        }
    }
}

#Preview {
    NavigationStack {
    HealthDashboardView()
    }
}
