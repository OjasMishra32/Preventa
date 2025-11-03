import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

struct PlanView: View {
    @StateObject private var vm = PlanVM()
    @State private var showAddPlan = false
    
    var body: some View {
        ZStack {
            AnimatedBrandBackground().ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    
                    if vm.plans.isEmpty {
                        emptyState
                            .padding(.top, 80)
                    } else {
                        ForEach(vm.plans) { plan in
                            PlanCard(plan: plan, onToggle: { vm.togglePlan(plan) })
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 80)
            }
            
            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        Hx.tap()
                        showAddPlan = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddPlan) {
            AddPlanView { plan in
                vm.addPlan(plan)
            }
        }
        .onAppear { vm.loadPlans() }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Micro-Habits")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                Text("Build sustainable preventive health habits, one step at a time.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            // Stats row
            HStack(spacing: 16) {
                PlanStatChip(label: "Active", value: "\(vm.activeCount)")
                PlanStatChip(label: "Longest Streak", value: "\(vm.longestStreak)d")
                PlanStatChip(label: "This Week", value: "\(vm.weekCompletion)%")
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "target")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            VStack(spacing: 8) {
                Text("Start Building Habits")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                
                Text("Create your first micro-habit plan to build sustainable preventive health habits, one step at a time.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct PlanStatChip: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct PlanCard: View {
    let plan: MicroPlan
    let onToggle: () -> Void
    @State private var completed = false
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                        .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    Image(systemName: plan.icon)
                        .foregroundStyle(.white)
                        .font(.title3.weight(.semibold))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plan.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(plan.frequency)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    // Streak indicator
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("\(plan.streak) day streak")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    
                    // Progress bar
                    ProgressView(value: plan.todayProgress)
                        .tint(.purple)
                        .progressViewStyle(.linear)
                        .frame(height: 6)
                }
                
                // Toggle button
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        completed.toggle()
                        onToggle()
                        if completed {
                            Hx.ok()
                            // Subtle celebration effect
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.5)) {
                                    // Trigger visual feedback
                                }
                            }
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(completed ? Color.green : Color.white.opacity(0.15))
                            .frame(width: 32, height: 32)
                        if completed {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.white)
                                .font(.caption.weight(.bold))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear { completed = plan.isCompletedToday }
    }
}

// MARK: - Add Plan View

struct AddPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var frequency: Frequency = .daily
    @State private var icon: String = "drop.fill"
    @State private var description: String = ""
    
    enum Frequency: String, CaseIterable {
        case daily, weekly, custom
    }
    
    let onSave: (MicroPlan) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        GlassCard {
                            VStack(spacing: 16) {
                                TextField("Habit name", text: $name)
                                    .padding(12)
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                                
                                TextField("Description (optional)", text: $description, axis: .vertical)
                                    .lineLimit(2...4)
                                    .padding(12)
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                                
                                // Frequency
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Frequency")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Picker("", selection: $frequency) {
                                        ForEach(Frequency.allCases, id: \.self) { freq in
                                            Text(freq.rawValue.capitalized).tag(freq)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                                
                                // Icon picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Icon")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(["drop.fill", "bed.double.fill", "figure.walk", "heart.fill", "brain.head.profile", "hand.raised.fill"], id: \.self) { iconName in
                                                Button {
                                                    icon = iconName
                                                    Hx.tap()
                                                } label: {
                                                    Image(systemName: iconName)
                                                        .font(.title2)
                                                        .foregroundStyle(icon == iconName ? .white : .white.opacity(0.6))
                                                        .frame(width: 44, height: 44)
                                                        .background(
                                                            Circle()
                                                                .fill(icon == iconName ? Color.purple.opacity(0.4) : Color.white.opacity(0.1))
                                                        )
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        
                        // Save button
                        Button {
                            guard !name.isEmpty else { return }
                            let plan = MicroPlan(
                                name: name,
                                frequency: frequency.rawValue,
                                icon: icon,
                                description: description,
                                streak: 0,
                                isCompletedToday: false,
                                todayProgress: 0.0
                            )
                            onSave(plan)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Create Plan")
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
                        .disabled(name.isEmpty)
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("New Plan")
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

// MARK: - Model

struct MicroPlan: Identifiable, Codable {
    let id: String
    var name: String
    var frequency: String
    var icon: String
    var description: String
    var streak: Int
    var isCompletedToday: Bool
    var todayProgress: Double
    var createdAt: Date
    var reminderTimes: [ReminderTime] // Times for daily reminders
    var reminderEnabled: Bool
    
    init(id: String = UUID().uuidString, name: String, frequency: String, icon: String, description: String, streak: Int, isCompletedToday: Bool, todayProgress: Double, createdAt: Date = Date(), reminderTimes: [ReminderTime] = [], reminderEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.frequency = frequency
        self.icon = icon
        self.description = description
        self.streak = streak
        self.isCompletedToday = isCompletedToday
        self.todayProgress = todayProgress
        self.createdAt = createdAt
        self.reminderTimes = reminderTimes.isEmpty ? [ReminderTime(hour: 9, minute: 0)] : reminderTimes
        self.reminderEnabled = reminderEnabled
    }
}

struct ReminderTime: Codable, Identifiable {
    var id: String
    var hour: Int
    var minute: Int
    
    init(id: String = UUID().uuidString, hour: Int, minute: Int) {
        self.id = id
        self.hour = hour
        self.minute = minute
    }
    
    var dateComponents: DateComponents {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return components
    }
}

// MARK: - ViewModel

final class PlanVM: ObservableObject {
    @Published var plans: [MicroPlan] = []
    
    private let db = Firestore.firestore()
    private var uid: String? { Auth.auth().currentUser?.uid }
    
    // Store listener reference for cleanup
    private var plansListener: ListenerRegistration?
    
    var activeCount: Int { plans.filter { !$0.isCompletedToday || $0.streak > 0 }.count }
    var longestStreak: Int { plans.map { $0.streak }.max() ?? 0 }
    var weekCompletion: Int {
        let completed = plans.filter { $0.isCompletedToday }.count
        return plans.isEmpty ? 0 : Int((Double(completed) / Double(plans.count)) * 100)
    }
    
    deinit {
        stopListening()
    }
    
    func loadPlans() {
        // Remove existing listener if any
        stopListening()
        
        guard let uid else { return }
        plansListener = db.collection("users").document(uid).collection("plans")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let docs = snapshot?.documents else { return }
                self.plans = docs.compactMap { doc in
                    try? doc.data(as: MicroPlan.self)
                }
            }
    }
    
    func stopListening() {
        plansListener?.remove()
        plansListener = nil
    }
    
    func addPlan(_ plan: MicroPlan) {
        guard let uid else { return }
        try? db.collection("users").document(uid).collection("plans")
            .document(plan.id)
            .setData(from: plan)
        
        // Schedule notifications for the plan
        if plan.reminderEnabled {
            Task {
                await scheduleNotifications(for: plan)
            }
        }
    }
    
    // MARK: - Notifications
    
    func requestNotifications() async {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        // Notifications will be scheduled if granted
    }
    
    func scheduleNotifications(for plan: MicroPlan) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        var isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        
        if !isAuthorized {
            // Request permission if not granted
            await requestNotifications()
            let newSettings = await center.notificationSettings()
            isAuthorized = newSettings.authorizationStatus == .authorized || newSettings.authorizationStatus == .provisional
        }
        
        guard isAuthorized else { return }
        
        // Remove existing notifications for this plan
        await removeNotifications(for: plan)
        
        // Schedule new notifications for each reminder time
        for reminderTime in plan.reminderTimes {
            let content = UNMutableNotificationContent()
            content.title = "Plan Reminder"
            content.body = "Time to: \(plan.name)"
            content.sound = .default
            content.userInfo = ["planId": plan.id]
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: reminderTime.dateComponents, repeats: true)
            let id = "plan-\(plan.id)-reminder-\(reminderTime.id)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            
            try? await center.add(request)
        }
    }
    
    func removeNotifications(for plan: MicroPlan) async {
        let ids = plan.reminderTimes.map { "plan-\(plan.id)-reminder-\($0.id)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
    
    func rescheduleNotifications(for plan: MicroPlan) async {
        await removeNotifications(for: plan)
        await scheduleNotifications(for: plan)
    }
    
    func togglePlan(_ plan: MicroPlan) {
        guard let uid else { return }
        var updated = plan
        updated.isCompletedToday.toggle()
        updated.todayProgress = updated.isCompletedToday ? 1.0 : 0.0
        if updated.isCompletedToday {
            updated.streak += 1
        } else {
            updated.streak = max(0, updated.streak - 1)
        }
        try? db.collection("users").document(uid).collection("plans")
            .document(plan.id)
            .setData(from: updated)
        
        // Reschedule notifications if reminder times changed
        if updated.reminderEnabled {
            Task {
                await rescheduleNotifications(for: updated)
            }
        }
    }
}

#Preview {
    PlanView()
}

