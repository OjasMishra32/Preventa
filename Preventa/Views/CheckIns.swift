//
//  CheckIns.swift
//  Preventa
//
//  Created by Ojas Sarada on 10/3/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CheckInsView: View {
    @StateObject private var vm = CheckInsVM()
    @State private var showingNewCheckIn = false
    @State private var selectedFilter: FilterOption = .all
    @State private var showAnalytics = false
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        
        var predicate: (CheckIn) -> Bool {
            switch self {
            case .all: return { _ in true }
            case .today:
                let today = Calendar.current.startOfDay(for: Date())
                return { $0.timestamp >= today }
            case .week:
                let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                return { $0.timestamp >= weekAgo }
            case .month:
                let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                return { $0.timestamp >= monthAgo }
            }
        }
    }
    
    var filteredCheckIns: [CheckIn] {
        vm.checkIns.filter(selectedFilter.predicate)
    }
    
    var averageMood: Double {
        guard !filteredCheckIns.isEmpty else { return 0 }
        let sum = filteredCheckIns.reduce(0) { $0 + Double($1.mood) }
        return sum / Double(filteredCheckIns.count)
    }
    
    var body: some View {
        ZStack {
            AnimatedBrandBackground().ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Enhanced Header with Analytics
                    enhancedHeader
                    
                    // Quick Stats
                    if !vm.checkIns.isEmpty {
                        quickStatsBar
                    }
                    
                    // Filter Chips
                    if !vm.checkIns.isEmpty {
                        filterChips
                    }
                    
                    // Check-In Cards
                    if filteredCheckIns.isEmpty {
                        emptyState
                            .padding(.top, 60)
                    } else {
                        ForEach(filteredCheckIns) { checkIn in
                            EnhancedCheckInCard(checkIn: checkIn)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
            
            // Enhanced Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        Hx.tap()
                        showingNewCheckIn = true
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
        .navigationTitle("Check-Ins")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewCheckIn) {
            ModernNewCheckInView { newCheckIn in
                vm.addCheckIn(newCheckIn)
            }
        }
        .sheet(isPresented: $showAnalytics) {
            CheckInAnalyticsView(checkIns: vm.checkIns)
        }
        .onAppear { vm.loadCheckIns() }
    }
    
    // MARK: - Enhanced Header
    private var enhancedHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Daily Check-Ins")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("Track your mood, reflections, and progress over time")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Analytics Button
                if !vm.checkIns.isEmpty {
                    Button {
                        Hx.tap()
                        showAnalytics = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Quick Stats Bar
    private var quickStatsBar: some View {
        GlassCard(expand: false) {
            HStack(spacing: 20) {
                StatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(filteredCheckIns.count)",
                    label: "Entries",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.3))
                
                StatItem(
                    icon: "face.smiling.fill",
                    value: String(format: "%.1f", averageMood),
                    label: "Avg Mood",
                    color: .green
                )
                
                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.3))
                
                StatItem(
                    icon: "flame.fill",
                    value: "\(vm.currentStreak)",
                    label: "Day Streak",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                        ForEach(FilterOption.allCases, id: \.self) { filter in
                            CheckInFilterChip(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter,
                                count: filter == .all ? vm.checkIns.count : vm.checkIns.filter(filter.predicate).count,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedFilter = filter
                                    }
                                    Hx.tap()
                                }
                            )
                        }
            }
            .padding(.horizontal, 2)
        }
    }
    
    // MARK: - Empty State
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
                
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            VStack(spacing: 8) {
                Text("Start Your Journey")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                
                Text("Create your first check-in to track your mood, thoughts, and progress over time.")
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

// MARK: - Enhanced Check-In Card

struct EnhancedCheckInCard: View {
    let checkIn: CheckIn
    @State private var isExpanded = false
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header with Mood and Date
                HStack(alignment: .top, spacing: 14) {
                    // Mood Circle - Prominent
                    MoodCircle(mood: checkIn.mood, size: 56)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(checkIn.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            Text(checkIn.relativeDateString)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    // Tags
                    if !checkIn.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(checkIn.tags.prefix(2), id: \.self) { tag in
                                TagBadge(tag: tag, compact: true)
                            }
                            if checkIn.tags.count > 2 {
                                Text("+\(checkIn.tags.count - 2)")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.6))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                // Mood Progress Bar (Visual Indicator)
                MoodProgressBar(mood: checkIn.mood)
                
                // Notes Section
                if !checkIn.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(checkIn.notes)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(isExpanded ? nil : 3)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if checkIn.notes.count > 150 {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isExpanded.toggle()
                                }
                                Hx.tap()
                            } label: {
                                Text(isExpanded ? "Show Less" : "Read More")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

// MARK: - Mood Circle

struct MoodCircle: View {
    let mood: Int
    let size: CGFloat
    
    private var moodData: (emoji: String, color: Color, gradient: [Color]) {
        switch mood {
        case 1: return ("😞", .red, [.red.opacity(0.8), .red.opacity(0.6)])
        case 2: return ("😕", .orange, [.orange.opacity(0.8), .orange.opacity(0.6)])
        case 3: return ("😐", .yellow, [.yellow.opacity(0.8), .yellow.opacity(0.6)])
        case 4: return ("🙂", .green, [.green.opacity(0.8), .green.opacity(0.6)])
        case 5: return ("😃", .blue, [.blue.opacity(0.8), .cyan.opacity(0.6)])
        default: return ("😐", .gray, [.gray.opacity(0.8), .gray.opacity(0.6)])
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: moodData.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: moodData.color.opacity(0.4), radius: 12, y: 4)
            
            Text(moodData.emoji)
                .font(.system(size: size * 0.5))
        }
    }
}

// MARK: - Mood Progress Bar

struct MoodProgressBar: View {
    let mood: Int
    
    private var progress: Double {
        Double(mood) / 5.0
    }
    
    private var color: Color {
        switch mood {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 8)
                
                // Progress Fill
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: 8)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Modern Check-In Input View

struct ModernNewCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var mood: Int = 3
    @State private var selectedTags: Set<String> = []
    @State private var showTemplatePicker = false
    
    var onSave: (CheckIn) -> Void
    
    private let availableTags = ["Energy", "Sleep", "Stress", "Exercise", "Nutrition", "Pain", "Focus", "Social", "Work", "Hobbies"]
    
    private let templates = [
        CheckInTemplate(title: "Morning Check-In", notes: "How am I feeling this morning?", mood: 3),
        CheckInTemplate(title: "Afternoon Reflection", notes: "How has my day been so far?", mood: 3),
        CheckInTemplate(title: "Evening Review", notes: "What went well today? What challenged me?", mood: 3)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Template Quick Actions
                        templateSection
                        
                        // Mood Picker
                        GlassCard {
                            VStack(spacing: 20) {
                                Text("How are you feeling?")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                
                                CircularMoodPicker(selectedMood: $mood)
                            }
                        }
                        
                        // Title Field
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Title")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                TextField("", text: $title)
                                    .padding(14)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .foregroundStyle(.white)
                                    .font(.headline)
                                    .placeholder(when: title.isEmpty) {
                                        Text("Enter a title (optional)")
                                            .foregroundColor(.white.opacity(0.5))
                                            .padding(.leading, 4)
                                    }
                            }
                        }
                        
                        // Notes Field
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Notes")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                ZStack(alignment: .topLeading) {
                                    if notes.isEmpty {
                                        Text("Write your thoughts, reflections, or anything you'd like to remember...")
                                            .foregroundColor(.white.opacity(0.5))
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 16)
                                            .font(.subheadline)
                                    }
                                    TextEditor(text: $notes)
                                        .frame(minHeight: 160)
                                        .foregroundStyle(.white)
                                        .padding(14)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .scrollContentBackground(.hidden)
                                }
                            }
                        }
                        
                        // Tags Section
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Tags (Optional)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                FlowLayout(spacing: 10) {
                                    ForEach(availableTags, id: \.self) { tag in
                                        TagChip(
                                            tag: tag,
                                            isSelected: selectedTags.contains(tag),
                                            action: {
                                                Hx.tap()
                                                if selectedTags.contains(tag) {
                                                    selectedTags.remove(tag)
                                                } else {
                                                    selectedTags.insert(tag)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newCheckIn = CheckIn(
                            id: UUID().uuidString,
                            title: title.isEmpty ? "Untitled Check-In" : title,
                            notes: notes,
                            mood: mood,
                            tags: Array(selectedTags),
                            timestamp: Date()
                        )
                        onSave(newCheckIn)
                        Hx.ok()
                        dismiss()
                    }
                    .disabled(notes.isEmpty && title.isEmpty)
                    .foregroundStyle(notes.isEmpty && title.isEmpty ? .white.opacity(0.5) : .white)
                }
            }
            .navigationTitle("New Check-In")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var templateSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(templates, id: \.title) { template in
                    Button {
                        title = template.title
                        notes = template.notes
                        mood = template.mood
                        Hx.tap()
                    } label: {
                        GlassCard(expand: false) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(template.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                
                                Text(template.notes)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .lineLimit(2)
                            }
                            .frame(width: 180)
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
        }
    }
}

// MARK: - Circular Mood Picker

struct CircularMoodPicker: View {
    @Binding var selectedMood: Int
    
    private let moods: [(emoji: String, color: Color, label: String)] = [
        ("😞", .red, "Very Low"),
        ("😕", .orange, "Low"),
        ("😐", .yellow, "Neutral"),
        ("🙂", .green, "Good"),
        ("😃", .blue, "Great")
    ]
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(Array(moods.enumerated()), id: \.offset) { index, mood in
                VStack(spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMood = index + 1
                        }
                        Hx.tap()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    selectedMood == index + 1
                                        ? LinearGradient(
                                            colors: [mood.color.opacity(0.4), mood.color.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .frame(width: 64, height: 64)
                                .shadow(
                                    color: selectedMood == index + 1 ? mood.color.opacity(0.4) : Color.clear,
                                    radius: selectedMood == index + 1 ? 12 : 0,
                                    y: selectedMood == index + 1 ? 6 : 0
                                )
                            
                            Text(mood.emoji)
                                .font(.system(size: 32))
                                .scaleEffect(selectedMood == index + 1 ? 1.1 : 1.0)
                        }
                    }
                    
                    Text(mood.label)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(selectedMood == index + 1 ? 0.9 : 0.6))
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct CheckInFilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                
                Text("(\(count))")
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 1.5)
                    )
            )
        }
    }
}

struct TagBadge: View {
    let tag: String
    var compact: Bool = false
    
    var body: some View {
        Text(tag)
            .font(compact ? .caption2 : .caption)
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, compact ? 6 : 10)
            .padding(.vertical, compact ? 4 : 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue.opacity(0.4) : Color.white.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.blue.opacity(0.6) : Color.white.opacity(0.2), lineWidth: 1.5)
                        )
                )
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            size = CGSize(width: maxWidth,
                         height: currentY + lineHeight)
        }
    }
}

// MARK: - Analytics View

struct CheckInAnalyticsView: View {
    let checkIns: [CheckIn]
    @Environment(\.dismiss) private var dismiss
    
    var averageMood: Double {
        guard !checkIns.isEmpty else { return 0 }
        return Double(checkIns.reduce(0) { $0 + $1.mood }) / Double(checkIns.count)
    }
    
    var weeklyMoods: [(day: String, mood: Double)] {
        let calendar = Calendar.current
        let last7Days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
        
        return last7Days.map { day in
            let dayCheckIns = checkIns.filter {
                calendar.isDate($0.timestamp, inSameDayAs: day)
            }
            let avgMood = dayCheckIns.isEmpty ? 0.0 : Double(dayCheckIns.reduce(0) { $0 + $1.mood }) / Double(dayCheckIns.count)
            return (day: DateFormatter.checkInDayFormatter.string(from: day), mood: avgMood)
        }.reversed()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Average Mood
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("Average Mood")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                Text(String(format: "%.1f", averageMood))
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text("out of 5.0")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        
                        // Weekly Trend
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Weekly Trend")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                
                                if weeklyMoods.allSatisfy({ $0.mood == 0 }) {
                                    Text("No data for the past week")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                } else {
                                    GeometryReader { geo in
                                        HStack(alignment: .bottom, spacing: 8) {
                                            ForEach(weeklyMoods, id: \.day) { data in
                                                VStack(spacing: 8) {
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(
                                                            LinearGradient(
                                                                colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                                                startPoint: .top,
                                                                endPoint: .bottom
                                                            )
                                                        )
                                                        .frame(
                                                            width: (geo.size.width - 56) / 7,
                                                            height: data.mood > 0 ? max(20, geo.size.height * CGFloat(data.mood / 5.0)) : 0
                                                        )
                                                    
                                                    Text(data.day)
                                                        .font(.caption2)
                                                        .foregroundStyle(.white.opacity(0.7))
                                                }
                                            }
                                        }
                                    }
                                    .frame(height: 120)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Model Updates

struct CheckIn: Identifiable {
    let id: String
    let title: String
    let notes: String
    let mood: Int
    let tags: [String]
    let timestamp: Date
    
    var dateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, h:mm a"
        return fmt.string(from: timestamp)
    }
    
    var relativeDateString: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(timestamp) {
            return "Today"
        } else if calendar.isDateInYesterday(timestamp) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(timestamp) == true {
            return "This week"
        } else {
            return dateString
        }
    }
}

struct CheckInTemplate {
    let title: String
    let notes: String
    let mood: Int
}

// MARK: - ViewModel Updates

final class CheckInsVM: ObservableObject {
    @Published var checkIns: [CheckIn] = []
    
    private let db = Firestore.firestore()
    private var uid: String? { Auth.auth().currentUser?.uid }
    
    private var checkInsListener: ListenerRegistration?
    
    var currentStreak: Int {
        guard !checkIns.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        while true {
            let hasCheckIn = checkIns.contains { calendar.isDate($0.timestamp, inSameDayAs: checkDate) }
            if hasCheckIn {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }
    
    deinit {
        stopListening()
    }
    
    func loadCheckIns() {
        stopListening()
        
        guard let uid else { return }
        checkInsListener = db.collection("users").document(uid).collection("checkIns")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let docs = snapshot?.documents else { return }
                self.checkIns = docs.compactMap { doc in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let notes = data["notes"] as? String,
                          let mood = data["mood"] as? Int,
                          let ts = data["timestamp"] as? Timestamp else { return nil }
                    
                    let tags = data["tags"] as? [String] ?? []
                    
                    return CheckIn(
                        id: doc.documentID,
                        title: title,
                        notes: notes,
                        mood: mood,
                        tags: tags,
                        timestamp: ts.dateValue()
                    )
                }
            }
    }
    
    func stopListening() {
        checkInsListener?.remove()
        checkInsListener = nil
    }
    
    func addCheckIn(_ checkIn: CheckIn) {
        guard let uid else { return }
        db.collection("users").document(uid).collection("checkIns")
            .document(checkIn.id)
            .setData([
                "title": checkIn.title,
                "notes": checkIn.notes,
                "mood": checkIn.mood,
                "tags": checkIn.tags,
                "timestamp": checkIn.timestamp
            ])
    }
}

// MARK: - DateFormatter Extension for CheckIns

extension DateFormatter {
    static let checkInDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
}

// MARK: - Shared UI (keeping existing definitions)

struct AnimatedBrandBackground: View {
    @State private var phase: CGFloat = 0
    @State private var animationActive = false
    
    var body: some View {
        LinearGradient(
            colors: [Color.purple.opacity(0.92), Color.blue.opacity(0.86)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay(
            AngularGradient(
                gradient: Gradient(colors: [.white.opacity(0.08), .clear, .white.opacity(0.06), .clear]),
                center: .center,
                angle: .degrees(Double(phase))
            )
        )
        .onAppear {
            if !animationActive {
                animationActive = true
                withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                    phase = 360
                }
            }
        }
        .onDisappear {
            animationActive = false
            phase = 0
        }
    }
}

struct GlassCard<Content: View>: View {
    let expand: Bool
    let content: Content
    init(expand: Bool = true, @ViewBuilder content: () -> Content) {
        self.expand = expand
        self.content = content()
    }
    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: expand ? .infinity : nil, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1))
            .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}
