import SwiftUI
import CoreLocation
import MapKit

struct ResourcesView: View {
    @StateObject private var vm = ResourcesVM()
    @State private var showResourceDetail: HealthcareResource?
    
    enum ResourceCategory: String, CaseIterable {
        case urgentCare = "Urgent Care"
        case clinics = "Primary Care"
        case mentalHealth = "Mental Health"
        case hotlines = "Crisis Hotlines"
        case emergency = "Emergency"
        case specialists = "Specialists"
    }
    
    var body: some View {
        ZStack {
            AnimatedBrandBackground().ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Enhanced Header
                SophisticatedHeaderView(healthManager: HealthKitManager.shared)
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                
                // Enhanced Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(ResourceCategory.allCases, id: \.self) { category in
                            EnhancedCategoryPill(
                                category: category,
                                isSelected: vm.selectedCategory == category,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        vm.selectedCategory = category
                                    }
                                    Hx.tap()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 16)
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Location permission banner - Enhanced
                        if !vm.hasLocationPermission {
                            EnhancedLocationBanner(onRequest: vm.requestLocationPermission)
                                .padding(.horizontal, 22)
                        }
                        
                        // Quick Access Cards - NEW
                        if vm.hasLocationPermission {
                            QuickAccessResourcesSection()
                                .padding(.horizontal, 22)
                        }
                        
                        // Emergency Section - Always visible
                        EmergencyResourcesSection()
                            .padding(.horizontal, 22)
                        
                        if vm.isLoading {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.2)
                                .padding(.top, 60)
                        } else if vm.filteredResources.isEmpty && !vm.hasLocationPermission {
                            SophisticatedEmptyState(
                                icon: categoryIcon(vm.selectedCategory),
                                title: "No \(vm.selectedCategory.rawValue.lowercased()) found",
                                message: "Enable location access to find nearby healthcare providers, or use the emergency resources above."
                            )
                            .padding(.top, 60)
                        } else {
                            ForEach(vm.filteredResources) { resource in
                                SophisticatedResourceCard(
                                    resource: resource,
                                    onTap: {
                                        showResourceDetail = resource
                                        Hx.tap()
                                    },
                                    vm: vm
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Healthcare Resources")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $showResourceDetail) { resource in
            ResourceDetailSheet(resource: resource, vm: vm)
        }
        .onAppear {
            vm.loadResources()
            vm.checkLocationPermission()
        }
    }
    
    private func categoryIcon(_ category: ResourceCategory) -> String {
        switch category {
        case .urgentCare: return "cross.case.fill"
        case .clinics: return "stethoscope"
        case .mentalHealth: return "brain.head.profile"
        case .hotlines: return "phone.fill"
        case .emergency: return "exclamationmark.triangle.fill"
        case .specialists: return "person.crop.circle.badge.checkmark"
        }
    }
}

// MARK: - Sophisticated Header

struct SophisticatedHeaderView: View {
    @ObservedObject var healthManager: HealthKitManager
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.red.opacity(0.8), .orange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: .red.opacity(0.4), radius: 12, y: 4)
                    
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Healthcare Resources")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("Find nearby providers, clinics, and emergency services")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Enhanced Category Pill

struct EnhancedCategoryPill: View {
    let category: ResourcesView.ResourceCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 13, weight: .semibold))
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [categoryColor.opacity(0.7), categoryColor.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: categoryColor.opacity(0.4), radius: 8, y: 4)
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                    }
                }
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected
                            ? LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [.white.opacity(0.25), .white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: 1.5
                    )
            )
        }
    }
    
    private var categoryIcon: String {
        switch category {
        case .urgentCare: return "cross.case.fill"
        case .clinics: return "stethoscope"
        case .mentalHealth: return "brain.head.profile"
        case .hotlines: return "phone.fill"
        case .emergency: return "exclamationmark.triangle.fill"
        case .specialists: return "person.crop.circle.badge.checkmark"
        }
    }
    
    private var categoryColor: Color {
        switch category {
        case .urgentCare: return .red
        case .clinics: return .blue
        case .mentalHealth: return .purple
        case .hotlines: return .orange
        case .emergency: return .red
        case .specialists: return .cyan
        }
    }
}

// MARK: - Enhanced Location Banner

struct EnhancedLocationBanner: View {
    let onRequest: () -> Void
    @State private var pulse = false
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.8), .yellow.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: .orange.opacity(0.4), radius: pulse ? 16 : 8, y: 4)
                        .scaleEffect(pulse ? 1.08 : 1.0)
                    
                    Image(systemName: "location.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Enable Location Access")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Find nearby clinics, urgent care centers, and healthcare providers automatically")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Button {
                    onRequest()
                    Hx.tap()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "location.circle.fill")
                        Text("Enable")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [.orange.opacity(0.8), .yellow.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: .orange.opacity(0.4), radius: 8, y: 4)
                }
            }
            .padding(4)
        }
    }
}

// MARK: - Quick Access Resources Section

struct QuickAccessResourcesSection: View {
    var body: some View {
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
                Text("Quick Access")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ], spacing: 14) {
                QuickResourceButton(
                    icon: "cross.case.fill",
                    title: "Nearest Urgent Care",
                    subtitle: "Find now",
                    color: .red,
                    action: {
                        // Find nearest urgent care
                        Hx.tap()
                    }
                )
                
                QuickResourceButton(
                    icon: "map.fill",
                    title: "Hospital Locator",
                    subtitle: "Emergency",
                    color: .red,
                    action: {
                        // Open hospital locator
                        Hx.tap()
                    }
                )
                
                QuickResourceButton(
                    icon: "phone.fill",
                    title: "Call 911",
                    subtitle: "Emergency",
                    color: .red,
                    action: {
                        if let url = URL(string: "tel://911") {
                            UIApplication.shared.open(url)
                        }
                        Hx.strong()
                    }
                )
                
                QuickResourceButton(
                    icon: "calendar.badge.clock",
                    title: "Book Appointment",
                    subtitle: "Schedule",
                    color: .blue,
                    action: {
                        // Open appointment booking
                        Hx.tap()
                    }
                )
            }
        }
    }
}

struct QuickResourceButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    @State private var pressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pressed = false
            }
            action()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: color.opacity(0.4), radius: 8, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(color.opacity(0.3), lineWidth: 1.5)
                    )
            )
            .scaleEffect(pressed ? 0.96 : 1.0)
        }
    }
}

// MARK: - Emergency Resources Section

struct EmergencyResourcesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.red.opacity(0.9), .red.opacity(0.6)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Text("Emergency & Crisis Resources")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 12) {
                EmergencyResourceCard(
                    title: "National Suicide Prevention Lifeline",
                    description: "24/7 free and confidential support for people in distress",
                    phone: "988",
                    icon: "heart.fill",
                    color: .red
                )
                
                EmergencyResourceCard(
                    title: "Crisis Text Line",
                    description: "Free 24/7 crisis support via text message",
                    phone: "741741",
                    icon: "message.fill",
                    color: .purple
                )
                
                EmergencyResourceCard(
                    title: "SAMHSA National Helpline",
                    description: "Free, confidential treatment referral and information service",
                    phone: "1-800-662-4357",
                    icon: "phone.fill",
                    color: .blue
                )
                
                EmergencyResourceCard(
                    title: "National Domestic Violence Hotline",
                    description: "24/7 confidential support for victims of domestic violence",
                    phone: "1-800-799-7233",
                    icon: "shield.fill",
                    color: .orange
                )
                
                EmergencyResourceCard(
                    title: "988 Suicide & Crisis Lifeline",
                    description: "Call, text, or chat 988 for mental health crisis support",
                    phone: "988",
                    icon: "hand.raised.fill",
                    color: .green
                )
            }
        }
    }
}

struct EmergencyResourceCard: View {
    let title: String
    let description: String
    let phone: String
    let icon: String
    let color: Color
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: color.opacity(0.4), radius: 8, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Button {
                    if let url = URL(string: "tel://\(phone.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                    Hx.strong()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                        Text(phone)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [color.opacity(0.8), color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .shadow(color: color.opacity(0.4), radius: 6, y: 3)
                }
            }
            .padding(4)
        }
    }
}

// MARK: - Sophisticated Resource Card

struct SophisticatedResourceCard: View {
    let resource: HealthcareResource
    let onTap: () -> Void
    let vm: ResourcesVM
    
    var body: some View {
        Button(action: onTap) {
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        // Enhanced icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [resourceCategoryColor.opacity(0.7), resourceCategoryColor.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .shadow(color: resourceCategoryColor.opacity(0.4), radius: 8, y: 4)
                            
                            Image(systemName: "stethoscope")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(resource.name)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                            
                            if let address = resource.address {
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.85))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            
                            HStack(spacing: 12) {
                                if let distance = resource.distance {
                                    Label("\(String(format: "%.1f", distance)) mi", systemImage: "location.fill")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.15))
                                                .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                                        )
                                }
                                
                                if resource.phone != nil || resource.website != nil {
                                    Text("Tap for details")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    // Action buttons
                    HStack(spacing: 10) {
                        if let phone = resource.phone {
                            ResourceActionButton(
                                icon: "phone.fill",
                                title: "Call",
                                color: .green,
                                action: {
                                    if let url = URL(string: "tel://\(phone)") {
                                        UIApplication.shared.open(url)
                                    }
                                    Hx.ok()
                                }
                            )
                        }
                        
                        if resource.website != nil {
                            ResourceActionButton(
                                icon: "safari",
                                title: "Website",
                                color: .blue,
                                action: {
                                    if let url = resource.website, let webURL = URL(string: url) {
                                        UIApplication.shared.open(webURL)
                                    }
                                    Hx.tap()
                                }
                            )
                        }
                        
                        if resource.location != nil {
                            ResourceActionButton(
                                icon: "map.fill",
                                title: "Directions",
                                color: .purple,
                                action: {
                                    vm.openInMaps(resource: resource)
                                    Hx.tap()
                                }
                            )
                        }
                    }
                }
                .padding(20)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var resourceCategoryColor: Color {
        switch resource.category {
        case "Urgent Care": return .red
        case "Primary Care": return .blue
        case "Mental Health": return .purple
        case "Hotlines": return .orange
        case "Emergency": return .red
        default: return .cyan
        }
    }
}

struct ResourceActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.6), color.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    )
            )
            .shadow(color: color.opacity(0.3), radius: 6, y: 3)
        }
    }
}

// MARK: - Resource Detail Sheet

struct ResourceDetailSheet: View {
    let resource: HealthcareResource
    let vm: ResourcesVM
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .blue.opacity(0.4), radius: 16, y: 6)
                                
                                Image(systemName: "stethoscope")
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            
                            Text(resource.name)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Details
                        VStack(spacing: 16) {
                            if let address = resource.address {
                                DetailRow(icon: "mappin.circle.fill", title: "Address", value: address, color: .blue)
                            }
                            
                            if let phone = resource.phone {
                                DetailRow(icon: "phone.fill", title: "Phone", value: phone, color: .green)
                            }
                            
                            if let distance = resource.distance {
                                DetailRow(icon: "location.fill", title: "Distance", value: "\(String(format: "%.1f", distance)) miles away", color: .orange)
                            }
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            if let phone = resource.phone {
                                ActionButton(
                                    icon: "phone.fill",
                                    title: "Call \(resource.name)",
                                    subtitle: phone,
                                    color: .green,
                                    action: {
                                        if let url = URL(string: "tel://\(phone)") {
                                            UIApplication.shared.open(url)
                                        }
                                        Hx.ok()
                                    }
                                )
                            }
                            
                            if let website = resource.website {
                                ActionButton(
                                    icon: "safari",
                                    title: "Visit Website",
                                    subtitle: "Open in browser",
                                    color: .blue,
                                    action: {
                                        if let url = URL(string: website) {
                                            UIApplication.shared.open(url)
                                        }
                                        Hx.tap()
                                    }
                                )
                            }
                            
                            if resource.location != nil {
                                ActionButton(
                                    icon: "map.fill",
                                    title: "Get Directions",
                                    subtitle: "Open in Maps",
                                    color: .purple,
                                    action: {
                                        vm.openInMaps(resource: resource)
                                        Hx.tap()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Resource Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        GlassCard(expand: false) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.6), color.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                    Text(value)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: color.opacity(0.4), radius: 8, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(color.opacity(0.4), lineWidth: 1.5)
                    )
            )
        }
    }
}

struct SophisticatedEmptyState: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 52))
                    .foregroundStyle(.white.opacity(0.7))
                
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
    }
}

// MARK: - Model

struct HealthcareResource: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let address: String?
    let phone: String?
    let website: String?
    let distance: Double?
    let location: CLLocationCoordinate2D?
    
    init(name: String, category: String, address: String? = nil, phone: String? = nil, website: String? = nil, distance: Double? = nil, location: CLLocationCoordinate2D? = nil) {
        self.name = name
        self.category = category
        self.address = address
        self.phone = phone
        self.website = website
        self.distance = distance
        self.location = location
    }
}

// MARK: - ViewModel

final class ResourcesVM: NSObject, ObservableObject {
    @Published var resources: [HealthcareResource] = []
    @Published var hasLocationPermission: Bool = false
    @Published var isLoading: Bool = false
    @Published var selectedCategory: ResourcesView.ResourceCategory = .urgentCare
    
    private let locationManager = CLLocationManager()
    
    var filteredResources: [HealthcareResource] {
        resources.filter { $0.category == selectedCategory.rawValue || ($0.category == "Hotlines" && selectedCategory == .hotlines) }
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func checkLocationPermission() {
        hasLocationPermission = locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func loadResources() {
        isLoading = true
        
        // Always load hotlines (don't need location)
        let defaultHotlines = [
            HealthcareResource(name: "National Suicide Prevention Lifeline", category: "Hotlines", phone: "988"),
            HealthcareResource(name: "Crisis Text Line", category: "Hotlines", phone: "741741"),
            HealthcareResource(name: "SAMHSA National Helpline", category: "Hotlines", phone: "1-800-662-4357"),
            HealthcareResource(name: "National Domestic Violence Hotline", category: "Hotlines", phone: "1-800-799-7233"),
        ]
        
        resources.append(contentsOf: defaultHotlines)
        
        // Load local resources if location is available
        if hasLocationPermission, let location = locationManager.location {
            searchNearbyResources(location: location)
        } else {
            isLoading = false
        }
    }
    
    private func searchNearbyResources(location: CLLocation) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "urgent care OR hospital OR clinic"
        searchRequest.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] response, _ in
            guard let self = self, let mapItems = response?.mapItems else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
                return
            }
            
            let mapped = mapItems.prefix(15).map { [weak self] item -> HealthcareResource in
                guard let self = self else {
                    return HealthcareResource(name: "Unknown", category: "Primary Care")
                }
                let distance = location.distance(from: CLLocation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)) / 1609.34
                return HealthcareResource(
                    name: item.name ?? "Unknown",
                    category: self.determineCategory(item),
                    address: item.placemark.formattedAddress,
                    phone: item.phoneNumber?.replacingOccurrences(of: " ", with: ""),
                    website: item.url?.absoluteString,
                    distance: distance,
                    location: item.placemark.coordinate
                )
            }
            
            DispatchQueue.main.async {
                self.resources.append(contentsOf: mapped)
                self.isLoading = false
            }
        }
    }
    
    private func determineCategory(_ item: MKMapItem) -> String {
        let name = (item.name ?? "").lowercased()
        if name.contains("urgent") || name.contains("emergency") {
            return "Urgent Care"
        } else if name.contains("hospital") {
            return "Emergency"
        } else if name.contains("clinic") || name.contains("medical") {
            return "Primary Care"
        } else {
            return "Primary Care"
        }
    }
    
    func openInMaps(resource: HealthcareResource) {
        guard let location = resource.location else { return }
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location))
        mapItem.name = resource.name
        mapItem.openInMaps()
    }
}

extension ResourcesVM: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationPermission()
        if hasLocationPermission {
            loadResources()
        }
    }
}

extension MKPlacemark {
    var formattedAddress: String? {
        guard let postalAddress = postalAddress else { return nil }
        return "\(postalAddress.street), \(postalAddress.city), \(postalAddress.state) \(postalAddress.postalCode)"
    }
}

#Preview {
    NavigationStack {
        ResourcesView()
    }
}
