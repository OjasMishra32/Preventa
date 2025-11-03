import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ActionsView: View {
    @StateObject private var vm = ActionsVM()
    @State private var showAddAction = false
    @State private var filterCategory: ActionItem.ActionCategory?
    @State private var showCompleted = true
    
    var body: some View {
        ZStack {
            AnimatedBrandBackground().ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Enhanced Header
                SophisticatedActionsHeader(
                    totalActions: vm.actions.count,
                    completedActions: vm.actions.filter { $0.isCompleted }.count
                )
                .padding(.horizontal, 22)
                .padding(.top, 12)
                
                // Filter Bar
                SophisticatedFilterBar(
                    selectedCategory: $filterCategory,
                    showCompleted: $showCompleted
                )
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                        if filteredActions.isEmpty {
                            SophisticatedEmptyActionsState {
                                showAddAction = true
                            }
                            .padding(.top, 80)
                    } else {
                            // Stats Overview
                            ActionStatsOverview(actions: filteredActions)
                                .padding(.horizontal, 22)
                            
                            ForEach(filteredActions) { action in
                                SophisticatedActionCard(
                                    action: action,
                                    onToggle: { vm.toggleAction(action) },
                                    onDelete: { vm.deleteAction(action) },
                                    onEdit: {
                                        // Edit action
                                        Hx.tap()
                                    }
                                )
                .padding(.horizontal, 22)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.bottom, 100)
                }
            }
            
            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        Hx.tap()
                        showAddAction = true
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
                                .shadow(color: .blue.opacity(0.4), radius: 16, y: 8)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Action Items")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddAction) {
            AddActionSheet(
                onSave: { action in
                    vm.addAction(action)
                    showAddAction = false
                    Hx.ok()
                },
                onCancel: {
                    showAddAction = false
                }
            )
        }
        .onAppear { vm.loadActions() }
    }
    
    // Computed property for filtered actions
    private var filteredActions: [ActionItem] {
        var filtered = vm.actions
        
        if let category = filterCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if !showCompleted {
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        return filtered.sorted { first, second in
            if first.isCompleted != second.isCompleted {
                return !first.isCompleted
            }
            if let firstDate = first.dueDate, let secondDate = second.dueDate {
                return firstDate < secondDate
            }
            return first.createdAt > second.createdAt
        }
    }
}

// MARK: - Sophisticated Header

struct SophisticatedActionsHeader: View {
    let totalActions: Int
    let completedActions: Int
    
    var body: some View {
        GlassCard {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.8), .mint.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: .green.opacity(0.4), radius: 12, y: 4)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Action Items")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 16) {
                        StatBadge(
                            value: "\(completedActions)",
                            label: "Completed",
                            color: .green
                        )
                        StatBadge(
                            value: "\(totalActions)",
                            label: "Total",
                            color: .blue
                        )
                        StatBadge(
                            value: "\(Int(totalActions > 0 ? Double(completedActions) / Double(totalActions) * 100 : 0))%",
                            label: "Progress",
                            color: .purple
                        )
                    }
                }
                
                Spacer()
            }
        }
    }
}

struct StatBadge: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.3))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.5), lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Filter Bar

struct SophisticatedFilterBar: View {
    @Binding var selectedCategory: ActionItem.ActionCategory?
    @Binding var showCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.spring()) {
                            selectedCategory = nil
                        }
                        Hx.tap()
                    } label: {
                        FilterChip(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            color: .blue
                        )
                    }
                    
                    ForEach(ActionItem.ActionCategory.allCases, id: \.self) { category in
                        Button {
                            withAnimation(.spring()) {
                                selectedCategory = category
                            }
                            Hx.tap()
                        } label: {
                            FilterChip(
                                title: category.displayName,
                                isSelected: selectedCategory == category,
                                color: category.color
                            )
                        }
                    }
                }
            }
            
            Spacer()
            
            // Toggle completed
            Button {
                withAnimation(.spring()) {
                    showCompleted.toggle()
                }
                Hx.tap()
            } label: {
                Image(systemName: showCompleted ? "eye.fill" : "eye.slash.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                            )
                    )
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.6) : Color.white.opacity(0.12))
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? color.opacity(0.8) : Color.white.opacity(0.25), lineWidth: 1.5)
                    )
            )
    }
}

// MARK: - Stats Overview

struct ActionStatsOverview: View {
    let actions: [ActionItem]
    
    var completedCount: Int {
        actions.filter { $0.isCompleted }.count
    }
    
    var dueTodayCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return actions.filter { action in
            guard let dueDate = action.dueDate else { return false }
            return Calendar.current.isDateInToday(dueDate) && !action.isCompleted
        }.count
    }
    
    var overdueCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return actions.filter { action in
            guard let dueDate = action.dueDate else { return false }
            return dueDate < today && !action.isCompleted
        }.count
    }
    
    var body: some View {
        if !actions.isEmpty {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                OverviewStatCard(
                    value: "\(completedCount)",
                    label: "Done",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                OverviewStatCard(
                    value: "\(dueTodayCount)",
                    label: "Due Today",
                    icon: "calendar",
                    color: dueTodayCount > 0 ? .orange : .blue
                )
                
                OverviewStatCard(
                    value: "\(overdueCount)",
                    label: "Overdue",
                    icon: "exclamationmark.triangle.fill",
                    color: overdueCount > 0 ? .red : .gray
                )
            }
        }
    }
}

struct OverviewStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        GlassCard(expand: false) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Text(value)
                    .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Sophisticated Action Card

struct SophisticatedActionCard: View {
    let action: ActionItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    @State private var completed = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        GlassCard {
            HStack(spacing: 18) {
                // Enhanced Category Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: action.category.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: action.category.colors[0].opacity(0.4), radius: 10, y: 4)
                    
                    Image(systemName: action.category.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .overlay(
                    Group {
                        if completed {
                            Circle()
                                .fill(.green)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                )
                                .offset(x: 20, y: -20)
                        }
                    }
                )
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(action.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .strikethrough(completed)
                    
                    if !action.description.isEmpty {
                        Text(action.description)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)
                    }
                    
                    // Metadata
                    HStack(spacing: 14) {
                        if let dueDate = action.dueDate {
                            DueDateBadge(date: dueDate, isCompleted: completed)
                        }
                        
                        if let source = action.source {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.caption2)
                                Text(source)
                                    .font(.caption2)
                            }
                                .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            )
                        }
                        
                        Text(action.category.displayName)
                            .font(.caption2)
                            .foregroundStyle(action.category.colors[0])
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(action.category.colors[0].opacity(0.2))
                                    .overlay(Capsule().stroke(action.category.colors[0].opacity(0.4), lineWidth: 1))
                            )
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            completed.toggle()
                            onToggle()
                            if completed {
                                Hx.ok()
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    completed
                                        ? LinearGradient(
                                            colors: [.green.opacity(0.9), .mint.opacity(0.9)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .frame(width: 36, height: 36)
                                .shadow(color: completed ? .green.opacity(0.4) : .clear, radius: 8, y: 4)
                            
                            if completed {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 2.5)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                    
                    Menu {
                        Button {
                            onEdit()
                            Hx.tap()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                    }
                    
                        Button(role: .destructive) {
                            showDeleteAlert = true
                            Hx.warn()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .padding(20)
        }
        .opacity(completed ? 0.7 : 1.0)
        .onAppear { completed = action.isCompleted }
        .alert("Delete Action?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
                Hx.ok()
            }
        } message: {
            Text("This will permanently delete this action item.")
        }
    }
}

struct DueDateBadge: View {
    let date: Date
    let isCompleted: Bool
    
    var isOverdue: Bool {
        !isCompleted && date < Date()
    }
    
    var isDueToday: Bool {
        !isCompleted && Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)
            Text(dateText)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(backgroundColor)
                .overlay(
                    Capsule()
                        .stroke(borderColor, lineWidth: 1.5)
                )
        )
    }
    
    private var iconName: String {
        if isOverdue { return "exclamationmark.triangle.fill" }
        if isDueToday { return "clock.fill" }
        return "calendar"
    }
    
    private var dateText: String {
        if isDueToday { return "Today" }
        if isOverdue {
            let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
            return "\(days)d overdue"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private var foregroundColor: Color {
        if isOverdue { return .white }
        if isDueToday { return .white }
        return .white.opacity(0.9)
    }
    
    private var backgroundColor: Color {
        if isOverdue { return Color.red.opacity(0.4) }
        if isDueToday { return Color.orange.opacity(0.4) }
        return Color.white.opacity(0.12)
    }
    
    private var borderColor: Color {
        if isOverdue { return Color.red.opacity(0.8) }
        if isDueToday { return Color.orange.opacity(0.8) }
        return Color.white.opacity(0.25)
    }
}

// MARK: - Empty State

struct SophisticatedEmptyActionsState: View {
    let onCreate: () -> Void
    
    var body: some View {
        GlassCard {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(spacing: 8) {
                    Text("No Action Items Yet")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("Actions will appear here from your Preventa Pulse conversations, or create your own action items to track health-related tasks.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Button {
                    onCreate()
                    Hx.tap()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Action Item")
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
                    .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)
                }
            }
            .padding(32)
        }
    }
}

// MARK: - Add Action Sheet

struct AddActionSheet: View {
    let onSave: (ActionItem) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: ActionItem.ActionCategory = .other
    @State private var dueDate: Date?
    @State private var showDatePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("New Action Item")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 40)
                        
                        GlassCard {
                            VStack(spacing: 20) {
                                // Title
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Title")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    TextField("Enter action title", text: $title)
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.white.opacity(0.1))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                                )
                                        )
                                        .foregroundStyle(.white)
                                }
                                
                                // Description
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description (Optional)")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    TextField("Add details...", text: $description, axis: .vertical)
                                        .lineLimit(3...6)
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.white.opacity(0.1))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                                )
                                        )
                                        .foregroundStyle(.white)
                                }
                                
                                // Category
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Category")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: 10),
                                        GridItem(.flexible(), spacing: 10),
                                        GridItem(.flexible(), spacing: 10)
                                    ], spacing: 10) {
                                        ForEach(ActionItem.ActionCategory.allCases, id: \.self) { cat in
                                            CategorySelectionButton(
                                                category: cat,
                                                isSelected: category == cat,
                                                action: {
                                                    category = cat
                                                    Hx.tap()
                                                }
                                            )
                                        }
                                    }
                                }
                                
                                // Due Date
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Due Date (Optional)")
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        if dueDate != nil {
                                            Button {
                                                dueDate = nil
                                                Hx.tap()
                                            } label: {
                                                Text("Clear")
                                                    .font(.caption)
                                                    .foregroundStyle(.red)
                                            }
                                        }
                                    }
                                    
                                    if let date = dueDate {
                                        HStack {
                                            Text(formatDate(date))
                                                .font(.subheadline)
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Image(systemName: "calendar")
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.white.opacity(0.1))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                                )
                                        )
                                    } else {
                                        Button {
                                            showDatePicker = true
                                            Hx.tap()
                                        } label: {
                                            HStack {
                                                Image(systemName: "calendar.badge.plus")
                                                Text("Set Due Date")
                                                    .fontWeight(.medium)
                                            }
                                            .foregroundStyle(.white.opacity(0.8))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(Color.white.opacity(0.1))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                            .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                                    )
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(24)
                        }
                        .padding(.horizontal, 22)
                        
                        // Save Button
                        Button {
                            let newAction = ActionItem(
                                title: title,
                                description: description,
                                category: category,
                                isCompleted: false,
                                dueDate: dueDate,
                                source: "Manual",
                                createdAt: Date()
                            )
                            onSave(newAction)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Create Action")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 18)
                            )
                            .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)
                        }
                        .disabled(title.isEmpty)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("New Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(
                    selectedDate: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ),
                    onCancel: { showDatePicker = false },
                    onSave: { date in
                        dueDate = date
                        showDatePicker = false
                        Hx.ok()
                    }
                )
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
        }
    }
}

struct CategorySelectionButton: View {
    let category: ActionItem.ActionCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: category.colors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.white.opacity(0.5) : Color.white.opacity(0.25),
                                    lineWidth: isSelected ? 2.5 : 1.5
                                )
                        )
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Text(category.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(isSelected ? 1.0 : 0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? category.colors[0].opacity(0.2) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isSelected ? category.colors[0].opacity(0.5) : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let onCancel: () -> Void
    let onSave: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                VStack(spacing: 24) {
                    DatePicker(
                        "Select Due Date",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Set Due Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedDate)
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Model Extensions

extension ActionItem.ActionCategory {
    var displayName: String {
        switch self {
        case .hydration: return "Hydration"
        case .sleep: return "Sleep"
        case .exercise: return "Exercise"
        case .nutrition: return "Nutrition"
        case .medication: return "Medication"
        case .checkup: return "Checkup"
        case .habit: return "Habit"
        case .other: return "Other"
        }
    }
    
    var color: Color {
        switch self {
        case .hydration: return .cyan
        case .sleep: return .indigo
        case .exercise: return .green
        case .nutrition: return .orange
        case .medication: return .red
        case .checkup: return .blue
        case .habit: return .purple
        case .other: return .gray
        }
    }
}

// MARK: - Model

struct ActionItem: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var category: ActionCategory
    var isCompleted: Bool
    var dueDate: Date?
    var source: String?
    var createdAt: Date
    
    enum ActionCategory: String, Codable, CaseIterable {
        case hydration, sleep, exercise, nutrition, medication, checkup, habit, other
        
        var icon: String {
            switch self {
            case .hydration: return "drop.fill"
            case .sleep: return "bed.double.fill"
            case .exercise: return "figure.walk"
            case .nutrition: return "leaf.fill"
            case .medication: return "pills.fill"
            case .checkup: return "stethoscope"
            case .habit: return "sparkles"
            case .other: return "circle.fill"
            }
        }
        
        var colors: [Color] {
            switch self {
            case .hydration: return [.cyan.opacity(0.8), .blue.opacity(0.8)]
            case .sleep: return [.indigo.opacity(0.8), .purple.opacity(0.8)]
            case .exercise: return [.green.opacity(0.8), .mint.opacity(0.8)]
            case .nutrition: return [.orange.opacity(0.8), .yellow.opacity(0.8)]
            case .medication: return [.red.opacity(0.8), .pink.opacity(0.8)]
            case .checkup: return [.blue.opacity(0.8), .cyan.opacity(0.8)]
            case .habit: return [.purple.opacity(0.8), .pink.opacity(0.8)]
            case .other: return [.gray.opacity(0.8), .gray.opacity(0.6)]
            }
        }
    }
    
    init(id: String = UUID().uuidString, title: String, description: String = "", category: ActionCategory, isCompleted: Bool = false, dueDate: Date? = nil, source: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.source = source
        self.createdAt = createdAt
    }
}

// MARK: - ViewModel

final class ActionsVM: ObservableObject {
    @Published var actions: [ActionItem] = []
    
    private let db = Firestore.firestore()
    private var uid: String? { Auth.auth().currentUser?.uid }
    
    // Store listener reference for cleanup
    private var actionsListener: ListenerRegistration?
    
    deinit {
        stopListening()
    }
    
    func loadActions() {
        // Remove existing listener if any
        stopListening()
        
        guard let uid else { return }
        actionsListener = db.collection("users").document(uid).collection("actions")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let docs = snapshot?.documents else { return }
                self.actions = docs.compactMap { doc in
                    try? doc.data(as: ActionItem.self)
                }
            }
    }
    
    func stopListening() {
        actionsListener?.remove()
        actionsListener = nil
    }
    
    func toggleAction(_ action: ActionItem) {
        guard let uid else { return }
        var updated = action
        updated.isCompleted.toggle()
        try? db.collection("users").document(uid).collection("actions")
            .document(action.id)
            .setData(from: updated)
    }
    
    func deleteAction(_ action: ActionItem) {
        guard let uid else { return }
        db.collection("users").document(uid).collection("actions")
            .document(action.id)
            .delete()
    }
    
    func addAction(_ action: ActionItem) {
        guard let uid else { return }
        try? db.collection("users").document(uid).collection("actions")
            .document(action.id)
            .setData(from: action)
    }
}

#Preview {
    NavigationStack {
    ActionsView()
}
}
