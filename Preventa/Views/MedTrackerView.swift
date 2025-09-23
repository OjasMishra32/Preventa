import SwiftUI
import UserNotifications
// MARK: - Models
enum IntakeStatus: String, Codable, CaseIterable {
    case pending
    case taken
    case skipped
    case late
}
struct MedTime: Identifiable, Codable, Hashable {
    let id: UUID
    var hour: Int
    var minute: Int
    init(id: UUID = UUID(), hour: Int, minute: Int) {
        self.id = id
        self.hour = hour
        self.minute = minute
    }
    var dateComponents: DateComponents {
        DateComponents(hour: hour, minute: minute)
    }
    var label: String {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
struct Medication: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var dose: String
    var note: String
    var times: [MedTime]
    var isCritical: Bool
    var colorIndex: Int
    init(
        id: UUID = UUID(),
        name: String,
        dose: String,
        note: String = "",
        times: [MedTime],
        isCritical: Bool = false,
        colorIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.dose = dose
        self.note = note
        self.times = times.sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
        self.isCritical = isCritical
        self.colorIndex = colorIndex
    }
}
struct MedIntakeLog: Identifiable, Codable, Hashable {
    let id: UUID
    var medID: UUID
    var timeID: UUID
    var dayKey: String
    var status: IntakeStatus
    var timestamp: Date
    init(
        id: UUID = UUID(),
        medID: UUID,
        timeID: UUID,
        dayKey: String,
        status: IntakeStatus,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.medID = medID
        self.timeID = timeID
        self.dayKey = dayKey
        self.status = status
        self.timestamp = timestamp
    }
}
struct ScheduledDose: Identifiable, Hashable {
    let id: UUID = UUID()
    let med: Medication
    let time: MedTime
    var status: IntakeStatus
}
// MARK: - Store
final class MedTrackerStore: ObservableObject {
    @Published var medications: [Medication] = [] {
        didSet { persist() }
    }
    @Published var logs: [String: [MedIntakeLog]] = [:] {
        didSet { persist() }
    }
    @Published var notificationsEnabled: Bool = false
    @Published var showConfetti: Bool = false
    @Published var selectedTab: Tab = .today
    enum Tab { case today, schedule, insights }
    private let storeKey = "medtracker.store.v1"
    private let themeColors: [[Color]] = [
        [Color.purple.opacity(0.9), Color.blue.opacity(0.8)],
        [Color.red.opacity(0.85), Color.orange.opacity(0.8)],
        [Color.mint.opacity(0.85), Color.cyan.opacity(0.8)],
        [Color.blue.opacity(0.9), Color.indigo.opacity(0.8)],
        [Color.pink.opacity(0.9), Color.purple.opacity(0.8)]
    ]
    init() {
        restore()
        Task { await refreshNotificationSetting() }
    }
    func colors(for index: Int) -> [Color] {
        let clamped = max(0, min(themeColors.count - 1, index))
        return themeColors[clamped]
    }
    func dayKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    func dosesForToday() -> [ScheduledDose] {
        let key = dayKey(for: Date())
        let items = medications.flatMap { med in
            med.times.map { mt in
                let status = logs[key]?.first(where: { $0.medID == med.id && $0.timeID == mt.id })?.status ?? .pending
                return ScheduledDose(med: med, time: mt, status: status)
            }
        }
        return items.sorted { lhs, rhs in
            (lhs.time.hour, lhs.time.minute, lhs.med.name) < (rhs.time.hour, rhs.time.minute, rhs.med.name)
        }
    }
    func doses(for date: Date) -> [ScheduledDose] {
        let key = dayKey(for: date)
        let items = medications.flatMap { med in
            med.times.map { mt in
                let status = logs[key]?.first(where: { $0.medID == med.id && $0.timeID == mt.id })?.status ?? .pending
                return ScheduledDose(med: med, time: mt, status: status)
            }
        }
        return items.sorted { ($0.time.hour, $0.time.minute) < ($1.time.hour, $1.time.minute) }
    }
    func mark(_ dose: ScheduledDose, as status: IntakeStatus) {
        let key = dayKey()
        var arr = logs[key] ?? []
        if let idx = arr.firstIndex(where: { $0.medID == dose.med.id && $0.timeID == dose.time.id }) {
            arr[idx].status = status
            arr[idx].timestamp = Date()
        } else {
            arr.append(MedIntakeLog(medID: dose.med.id, timeID: dose.time.id, dayKey: key, status: status))
        }
        logs[key] = arr
        checkCompletionForToday()
    }
    func snooze(_ dose: ScheduledDose, minutes: Int = 10) {
        Task { await scheduleOneOffSnooze(dose, minutes: minutes) }
    }
    func addMedication(_ med: Medication) {
        medications.append(med)
        Task { await scheduleNotifications(for: med) }
    }
    func updateMedication(_ med: Medication) {
        if let idx = medications.firstIndex(where: { $0.id == med.id }) {
            medications[idx] = med
            Task { await rescheduleNotifications(for: med) }
        }
    }
    func removeMedication(_ med: Medication) {
        medications.removeAll { $0.id == med.id }
        Task { await removeScheduledNotifications(for: med) }
    }
    func dailyCompletionFraction(date: Date = Date()) -> Double {
        let key = dayKey(for: date)
        let total = medications.reduce(0) { $0 + $1.times.count }
        if total == 0 { return 0 }
        let taken = logs[key]?.filter { $0.status == .taken }.count ?? 0
        return Double(taken) / Double(total)
    }
    func weekKeys(ending end: Date = Date(), days: Int = 7) -> [String] {
        let calendar = Calendar.current
        return (0..<days).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: end) ?? end
            return dayKey(for: date)
        }
    }
    func streak() -> Int {
        var count = 0
        let calendar = Calendar.current
        var date = calendar.startOfDay(for: Date())
        while true {
            let key = dayKey(for: date)
            let total = medications.reduce(0) { $0 + $1.times.count }
            if total == 0 { break }
            let fraction = dailyCompletionFraction(date: date)
            if fraction >= 1.0 {
                count += 1
                date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            } else {
                break
            }
        }
        return count
    }
    func onTimeRate(lastNDays n: Int = 14) -> Double {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -(n - 1), to: end) ?? end
        var onTime = 0
        var total = 0
        var d = start
        while d <= end {
            let key = dayKey(for: d)
            let arr = logs[key] ?? []
            for log in arr {
                total += 1
                if log.status == .taken { onTime += 1 }
            }
            d = calendar.date(byAdding: .day, value: 1, to: d) ?? end
        }
        if total == 0 { return 0 }
        return Double(onTime) / Double(total)
    }
    enum Bucket { case morning, day, evening, night }
    func timeBucket(hour: Int) -> Bucket {
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .day
        case 17..<22: return .evening
        default: return .night
        }
    }
    func slotBreakdown(for date: Date = Date()) -> (morning: Int, day: Int, evening: Int, night: Int) {
        let doses = doses(for: date)
        var morning = 0
        var day = 0
        var evening = 0
        var night = 0
        for d in doses {
            switch timeBucket(hour: d.time.hour) {
            case .morning: morning += 1
            case .day: day += 1
            case .evening: evening += 1
            case .night: night += 1
            }
        }
        return (morning, day, evening, night)
    }
    // MARK: Notifications
    func requestNotifications() async {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        notificationsEnabled = granted == true
        if notificationsEnabled { await rescheduleAll() }
    }
    func refreshNotificationSetting() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsEnabled = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }
    func scheduleNotifications(for med: Medication) async {
        guard notificationsEnabled else { return }
        let center = UNUserNotificationCenter.current()
        for t in med.times {
            let content = UNMutableNotificationContent()
            content.title = "Medication Reminder"
            content.body = "\(med.name) \(med.dose) at \(String(format: "%02d:%02d", t.hour, t.minute))"
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: t.dateComponents, repeats: true)
            let id = notifID(medID: med.id, timeID: t.id)
            let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(req)
        }
    }
    func removeScheduledNotifications(for med: Medication) async {
        let ids = med.times.map { notifID(medID: med.id, timeID: $0.id) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
    func rescheduleNotifications(for med: Medication) async {
        await removeScheduledNotifications(for: med)
        await scheduleNotifications(for: med)
    }
    func rescheduleAll() async {
        let center = UNUserNotificationCenter.current()
        await center.removeAllPendingNotificationRequests()
        for med in medications {
            await scheduleNotifications(for: med)
        }
    }
    func scheduleOneOffSnooze(_ dose: ScheduledDose, minutes: Int) async {
        guard notificationsEnabled else { return }
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Snoozed Medication"
        content.body = "\(dose.med.name) \(dose.med.dose)"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let id = "snooze-\(dose.med.id.uuidString)-\(dose.time.id.uuidString)-\(UUID().uuidString)"
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(req)
    }
    private func notifID(medID: UUID, timeID: UUID) -> String {
        "med-\(medID.uuidString)-time-\(timeID.uuidString)"
    }
    // MARK: Persistence
    private struct PersistBlob: Codable {
        var medications: [Medication]
        var logs: [String: [MedIntakeLog]]
    }
    private func persist() {
        let encoder = JSONEncoder()
        let obj = PersistBlob(medications: medications, logs: logs)
        if let data = try? encoder.encode(obj) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }
    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: storeKey) else { return }
        let decoder = JSONDecoder()
        if let obj = try? decoder.decode(PersistBlob.self, from: data) {
            medications = obj.medications
            logs = obj.logs
        }
    }
    private func checkCompletionForToday() {
        if dailyCompletionFraction() >= 1.0 {
            withAnimation(.easeOut(duration: 0.8)) { showConfetti = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation { self.showConfetti = false }
            }
        }
    }
}

// MARK: - Views
struct MedTrackerView: View {
    @EnvironmentObject var store: MedTrackerStore   // ✅ use shared store from PreventaApp
    let theme = appGradient

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: theme, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                BackgroundParticles(colors: theme)

                VStack(spacing: 14) {
                    header
                    tabSwitcher

                    switch store.selectedTab {
                    case .today:
                        TodayList(store: store, theme: theme)
                    case .schedule:
                        ScheduleBoard(store: store, theme: theme)
                    case .insights:
                        InsightsBoard(store: store, theme: theme)
                    }
                }

                if store.showConfetti {
                    ConfettiBurstView()
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("Medication Tracker")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ProgressRing(progress: CGFloat(store.dailyCompletionFraction()), thickness: 10)
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Streak \(store.streak())")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                NavigationLink {
                    AddMedicationView(store: store, theme: theme)
                } label: {
                    GlowButton(title: "Add",
                               systemImage: "plus.circle.fill",
                               gradient: theme,
                               height: 44)
                }
                .frame(width: 120)
            }

            WeekStrip(store: store)
        }
        .padding(.horizontal)
        .padding(.top, 14)
    }

    private var tabSwitcher: some View {
        HStack(spacing: 10) {
            TabPill(title: "Schedule", selected: store.selectedTab == .schedule) {
                withAnimation(.easeInOut) { store.selectedTab = .schedule }
            }
            TabPill(title: "Insights", selected: store.selectedTab == .insights) {
                withAnimation(.easeInOut) { store.selectedTab = .insights }
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    MedTrackerView()
        .environmentObject(MedTrackerStore())   // ✅ preview works too
}

struct TabPill: View {
    let title: String
    let selected: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(selected ? .white.opacity(0.25) : .white.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(selected ? 0.25 : 0.15), lineWidth: 1)
                        )
                )
        }
    }
}
struct TodayList: View {
    @ObservedObject var store: MedTrackerStore
    let theme: [Color]
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                let doses = store.dosesForToday()
                if doses.isEmpty {
                    EmptyState(theme: theme)
                } else {
                    ForEach(doses) { dose in
                        DoseRow(
                            store: store,
                            dose: dose,
                            theme: store.colors(for: dose.med.colorIndex)
                        )
                    }
                }
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
}
struct DoseRow: View {
    @ObservedObject var store: MedTrackerStore
    let dose: ScheduledDose
    let theme: [Color]
    @State private var animateCheck: Bool = false
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: theme, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 54, height: 54)
                    .shadow(color: theme.last?.opacity(0.5) ?? .black.opacity(0.3), radius: 8, y: 4)
                Image(systemName: iconName)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(dose.med.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(dose.med.dose) • \(dose.time.label)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
            }
            Spacer()
            if dose.status == .taken {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .symbolEffect(.bounce, value: animateCheck)
                    .foregroundStyle(.white)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
        )
        .opacity(dose.status == .pending ? 1.0 : 0.9)
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    store.mark(dose, as: .taken)
                    animateCheck.toggle()
                }
            } label: {
                Label("Taken", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
            Button {
                withAnimation(.easeInOut) {
                    store.mark(dose, as: .skipped)
                }
            } label: {
                Label("Skip", systemImage: "xmark.circle.fill")
            }
            .tint(.red)
        }
        .swipeActions(edge: .leading) {
            Button {
                withAnimation(.easeInOut) {
                    store.snooze(dose)
                }
            } label: {
                Label("Snooze", systemImage: "bell.and.waveform")
            }
            .tint(.orange)
        }
    }
    private var iconName: String {
        dose.med.isCritical ? "cross.circle.fill" : "pills.fill"
    }
}
struct EmptyState: View {
    let theme: [Color]
    var body: some View {
        VStack(spacing: 18) {
            Text("No medications scheduled today")
                .foregroundColor(.white.opacity(0.9))
            Text("Add medications and times to see them here")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
        )
    }
}
struct WeekStrip: View {
    @ObservedObject var store: MedTrackerStore
    var body: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        HStack(spacing: 10) {
            ForEach(0..<7, id: \.self) { i in
                let date = calendar.date(byAdding: .day, value: -((6 - i)), to: today) ?? today
                let fraction = store.dailyCompletionFraction(date: date)
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.25), lineWidth: 6)
                            .frame(width: 32, height: 32)
                        Circle()
                            .trim(from: 0, to: fraction)
                            .stroke(
                                .white,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 32, height: 32)
                    }
                    Text(shortWeekday(date))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
    }
    private func shortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}
struct ScheduleBoard: View {
    @ObservedObject var store: MedTrackerStore
    let theme: [Color]
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                let grouped = Dictionary(grouping: store.dosesForToday()) { dose in
                    store.timeBucket(hour: dose.time.hour)
                }
                SectionView(title: "Morning", doses: grouped[.morning] ?? [], store: store)
                SectionView(title: "Day", doses: grouped[.day] ?? [], store: store)
                SectionView(title: "Evening", doses: grouped[.evening] ?? [], store: store)
                SectionView(title: "Night", doses: grouped[.night] ?? [], store: store)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
}
struct SectionView: View {
    let title: String
    let doses: [ScheduledDose]
    @ObservedObject var store: MedTrackerStore
    var body: some View {
        if doses.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.horizontal, 6)
                ForEach(doses) { d in
                    DoseRow(
                        store: store,
                        dose: d,
                        theme: store.colors(for: d.med.colorIndex)
                    )
                }
            }
        }
    }
}
struct InsightsBoard: View {
    @ObservedObject var store: MedTrackerStore
    let theme: [Color]
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                StatRow(store: store, theme: theme)
                AdherenceBarChart(store: store)
                SlotBreakdownCard(store: store)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
}
struct StatRow: View {
    @ObservedObject var store: MedTrackerStore
    let theme: [Color]
    var body: some View {
        HStack(spacing: 12) {
            SolidStatCard(title: "On-time rate (14d)",
                          value: String(format: "%.0f%%", store.onTimeRate() * 100))
            SolidStatCard(title: "Today",
                          value: String(format: "%.0f%%", store.dailyCompletionFraction() * 100))
            SolidStatCard(title: "Streak",
                          value: "\(store.streak())")
        }
    }
}
struct MedStatCard: View {
    let title: String
    let value: String
    let gradient: [Color]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: gradient,
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
        )
    }
}
struct AdherenceBarChart: View {
    @ObservedObject var store: MedTrackerStore
    var body: some View {
        let keys = store.weekKeys(ending: Date(), days: 14)
        let values = keys.map { key -> Double in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let date = formatter.date(from: key) ?? Date()
            return store.dailyCompletionFraction(date: date)
        }
        VStack(alignment: .leading, spacing: 12) {
            Text("Adherence (last 14 days)")
                .font(.headline)
                .foregroundColor(.white)
            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(values.indices, id: \.self) { i in
                        let v = values[i]
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.9))
                            .frame(
                                width: (geo.size.width / CGFloat(values.count)) - 4,
                                height: max(2, v * geo.size.height)
                            )
                    }
                }
            }
        }
        .padding(14)
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: [Color.blue.opacity(0.55), Color.purple.opacity(0.55)],
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
        )
    }
}
struct SlotBreakdownCard: View {
    @ObservedObject var store: MedTrackerStore
    var body: some View {
        let s = store.slotBreakdown()
        let total = max(1, s.morning + s.day + s.evening + s.night)
        VStack(alignment: .leading, spacing: 12) {
            Text("Today by time of day")
                .font(.headline)
                .foregroundColor(.white)
            HStack(spacing: 16) {
                // ✅ Pie chart scaled down 20%
                PieChart(data: [
                    ("Morning", Double(s.morning), Color.green),
                    ("Day", Double(s.day), Color.blue),
                    ("Evening", Double(s.evening), Color.orange),
                    ("Night", Double(s.night), Color.purple)
                ], total: Double(total))
                .frame(width: 80, height: 80) // was 96x96
                // ✅ Legend aligned to the right side
                VStack(alignment: .leading, spacing: 8) {
                    LegendItem(color: .green, label: "Morning \(s.morning)")
                    LegendItem(color: .blue, label: "Day \(s.day)")
                    LegendItem(color: .orange, label: "Evening \(s.evening)")
                    LegendItem(color: .purple, label: "Night \(s.night)")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                // ✅ Match other solid stat cards
                .fill(LinearGradient(colors: [Color.blue.opacity(0.55), Color.purple.opacity(0.55)],
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
        )
    }
}
struct PieSlice: View {
    let value: Double
    let total: Double
    let color: Color
    var body: some View {
        GeometryReader { geo in
            let fraction = max(0, min(1, total > 0 ? (value / total) : 0))
            ZStack {
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: geo.size.height * 0.5, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(height: 30)
    }
}
struct PieLegendItem: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}
struct PieChart: View {
    let data: [(String, Double, Color)]
    let total: Double
    var body: some View {
        ZStack {
            ForEach(0..<data.count, id: \.self) { i in
                let start = data.prefix(i).map { $0.1 }.reduce(0, +) / total
                let end = (data.prefix(i + 1).map { $0.1 }.reduce(0, +)) / total
                Circle()
                    .trim(from: CGFloat(start), to: CGFloat(end))
                    .stroke(data[i].2, lineWidth: 22) // ✅ slimmer, cleaner
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}
struct LegendItem: View {
    let color: Color
    let label: String
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .foregroundColor(.white.opacity(0.9))
                .font(.footnote)
        }
    }
}
struct ThemedTextField: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        TextField(placeholder, text: $text)
            .padding(12)
            .foregroundColor(.white)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            )
    }
}
struct AddMedicationView: View {
    @ObservedObject var store: MedTrackerStore
    let theme: [Color]
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var dose: String = ""
    @State private var note: String = ""
    @State private var isCritical: Bool = false
    @State private var times: [MedTime] = [MedTime(hour: 8, minute: 0)]
    var body: some View {
        ZStack {
            LinearGradient(colors: theme,
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            BackgroundParticles(colors: theme)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Info card
                    VStack(spacing: 14) {
                        SolidInputField(placeholder: "Medication name", text: $name)
                        SolidInputField(placeholder: "Dosage (e.g., 10mg)", text: $dose)
                        SolidInputField(placeholder: "Notes (optional)", text: $note)
                        Toggle("Critical Medication", isOn: $isCritical)
                            .tint(.white)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.black.opacity(0.35))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(.white.opacity(0.25), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 10)
                    // Times card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Times")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button {
                                withAnimation(.spring()) {
                                    times.append(MedTime(hour: 12, minute: 0))
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        ForEach(times.indices, id: \.self) { i in
                            HStack {
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: {
                                            Calendar.current.date(
                                                from: DateComponents(
                                                    hour: times[i].hour,
                                                    minute: times[i].minute
                                                )
                                            ) ?? Date()
                                        },
                                        set: { date in
                                            let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                                            times[i].hour = comps.hour ?? 8
                                            times[i].minute = comps.minute ?? 0
                                        }
                                    ),
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                .colorScheme(.dark)
                                Spacer()
                                Button {
                                    withAnimation(.easeInOut) {
                                        if times.count > 1 {
                                            times.remove(at: i)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.black.opacity(0.35))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(.white.opacity(0.25), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 10)
                    // Save button
                    Button {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedDose = dose.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }
                        guard !trimmedDose.isEmpty else { return }
                        guard !times.isEmpty else { return }
                        let med = Medication(
                            name: trimmedName,
                            dose: trimmedDose,
                            note: note,
                            times: times,
                            isCritical: isCritical
                        )
                        store.addMedication(med)
                        // Reset fields
                        name = ""
                        dose = ""
                        note = ""
                        times = [MedTime(hour: 8, minute: 0)]
                        isCritical = false
                        dismiss()
                    } label: {
                        GlowButton(title: "Save",
                                   systemImage: "checkmark.circle.fill",
                                   gradient: theme,
                                   height: 54)
                    }
                    .padding(.horizontal, 10)
                }
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Add Medication")
        .navigationBarTitleDisplayMode(.inline)
    }
}
struct SolidStatCard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 80) // ✅ Uniform size
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: [Color.blue.opacity(0.55), Color.purple.opacity(0.55)],
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
        )
    }
}
struct SolidInputField: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.7)))
            .padding(12)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.5)],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            )
    }
}
struct ThemedInputField: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        TextField(placeholder, text: $text)
            .padding(12)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            )
    }
}
struct ConfettiBurstView: View {
    @State private var animate: Bool = false
    private let colors: [Color] = [
        .white.opacity(0.9),
        .yellow,
        .orange,
        .pink,
        .mint,
        .cyan
    ]
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<48, id: \.self) { i in
                    let size = CGFloat(Int.random(in: 6...12))
                    Circle()
                        .fill(colors.randomElement() ?? .white)
                        .frame(width: size, height: size)
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: animate ? geo.size.height + 30 : -30
                        )
                        .rotationEffect(.degrees(animate ? Double.random(in: 180...720) : 0))
                        .animation(
                            .interpolatingSpring(stiffness: 18, damping: 6)
                                .delay(Double(i) * 0.02),
                            value: animate
                        )
                }
            }
            .onAppear { animate = true }
        }
        .allowsHitTesting(false)
    }
}
#Preview {
    MedTrackerView()
}



