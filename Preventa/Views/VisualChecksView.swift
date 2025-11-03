import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseAuth
import UIKit

struct VisualChecksView: View {
    @StateObject private var vm = VisualChecksVM()
    @State private var selectedCategory: PhotoCategory = .skin
    @State private var showPicker = false
    @State private var showComparison: VisualPhoto?
    
    enum PhotoCategory: String, CaseIterable {
        case skin = "Skin"
        case eye = "Eye"
        case meal = "Meal"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .skin: return "person.fill"
            case .eye: return "eye.fill"
            case .meal: return "fork.knife"
            case .other: return "photo.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .skin: return .orange
            case .eye: return .blue
            case .meal: return .green
            case .other: return .purple
            }
        }
    }
    
    var body: some View {
        ZStack {
            AnimatedBrandBackground().ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern header with stats
                ModernVisualChecksHeader(
                    totalPhotos: vm.photos.count,
                    categoryPhotos: vm.filteredPhotos.count
                )
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Enhanced category filter
                ModernCategorySelector(
                    selectedCategory: $selectedCategory,
                    categories: PhotoCategory.allCases
                )
                .padding(.horizontal, 22)
                .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if vm.photos.isEmpty {
                            ModernEmptyState(
                                onAddPhoto: {
                                    Hx.tap()
                                    showPicker = true
                                }
                            )
                            .padding(.top, 80)
                        } else if vm.filteredPhotos.isEmpty {
                            EmptyCategoryState(
                                category: selectedCategory.rawValue,
                                onAddPhoto: {
                                    Hx.tap()
                                    showPicker = true
                                }
                            )
                            .padding(.top, 80)
                        } else {
                            // Modern grid layout
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16)
                                ],
                                spacing: 20
                            ) {
                                ForEach(vm.filteredPhotos) { photo in
                                    ModernPhotoCard(
                                        photo: photo,
                                        vm: vm,
                                        onCompare: {
                                            showComparison = photo
                                        },
                                        onDelete: {
                                            vm.deletePhoto(photo)
                                            Hx.warn()
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
                    .padding(.bottom, 120)
                }
            }
            
            // Majestic floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ModernFloatingActionButton {
                        Hx.tap()
                        showPicker = true
                    }
                    .padding(.trailing, 22)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Visual Checks")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPicker) {
            ModernPhotoPickerView(
                category: selectedCategory.rawValue,
                categoryColor: selectedCategory.color
            ) { image, category in
                vm.uploadPhoto(image: image, category: category)
                Hx.ok()
            }
        }
        .sheet(item: $showComparison) { photo in
            ModernComparisonView(
                photo: photo,
                allPhotos: vm.photos.filter { $0.category == photo.category },
                vm: vm
            )
        }
        .onAppear { vm.loadPhotos() }
    }
}

// MARK: - Modern Header

struct ModernVisualChecksHeader: View {
    let totalPhotos: Int
    let categoryPhotos: Int
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Visual Checks")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                
                HStack(spacing: 16) {
                    VisualStatBadge(
                        icon: "photo.on.rectangle",
                        value: "\(totalPhotos)",
                        label: "Total",
                        color: .blue
                    )
                    
                    VisualStatBadge(
                        icon: "sparkles",
                        value: "\(categoryPhotos)",
                        label: "This Category",
                        color: .purple
                    )
                }
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.4),
                                Color.blue.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }
}

struct VisualStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
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

// MARK: - Modern Category Selector

struct ModernCategorySelector: View {
    @Binding var selectedCategory: VisualChecksView.PhotoCategory
    let categories: [VisualChecksView.PhotoCategory]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    ModernCategoryPill(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedCategory = category
                            }
                            Hx.tap()
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct ModernCategoryPill: View {
    let category: VisualChecksView.PhotoCategory
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [
                                        category.color.opacity(0.6),
                                        category.color.opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
                }
                
                Text(category.rawValue)
                    .font(.system(size: 15, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [
                                    category.color.opacity(0.5),
                                    category.color.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected
                                    ? LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: isSelected ? 2 : 1.5
                            )
                    )
            )
            .shadow(
                color: isSelected ? category.color.opacity(0.3) : Color.black.opacity(0.1),
                radius: isSelected ? 12 : 6,
                y: isSelected ? 6 : 3
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Modern Photo Card

struct ModernPhotoCard: View {
    let photo: VisualPhoto
    @ObservedObject var vm: VisualChecksVM
    let onCompare: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    @State private var showMenu = false
    
    var categoryColor: Color {
        switch photo.category {
        case "Skin": return .orange
        case "Eye": return .blue
        case "Meal": return .green
        default: return .purple
        }
    }
    
    var body: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: 0) {
                // Image with overlay
                ZStack(alignment: .topTrailing) {
                    if let uiImage = vm.getImage(for: photo) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: .infinity, height: 200)
                            .clipped()
                    } else {
                        AsyncImage(url: URL(string: photo.imageURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ZStack {
                                Color.white.opacity(0.1)
                                ProgressView().tint(.white)
                            }
                        }
                        .frame(height: 200)
                        .clipped()
                    }
                    
                    // Gradient overlay
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Category badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(categoryColor.opacity(0.9))
                            .frame(width: 8, height: 8)
                        
                        Text(photo.category)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(12)
                    
                    // Menu button
                    Menu {
                        Button {
                            onCompare()
                            Hx.tap()
                        } label: {
                            Label("Compare", systemImage: "slider.horizontal.3")
                        }
                        
                        Button(role: .destructive) {
                            onDelete()
                            Hx.warn()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(12)
                }
                
                // Content area
                VStack(alignment: .leading, spacing: 10) {
                    // Date
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Text(formatDate(photo.createdAt))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    // AI Note
                    if let aiNote = photo.aiNote {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                            
                            Text(aiNote)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.yellow.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // User Note
                    if let note = photo.note, !note.isEmpty {
                        Text(note)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                }
                .padding(14)
            }
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture {
            withAnimation(.spring()) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Modern Empty State

struct ModernEmptyState: View {
    let onAddPhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.3),
                                Color.blue.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("Start Tracking Visually")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                
                Text("Capture photos of your skin, eyes, meals, or anything else to track changes over time with AI-powered insights.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }
            
            Button(action: onAddPhoto) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    
                    Text("Add Your First Photo")
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                )
                .shadow(color: .purple.opacity(0.4), radius: 12, y: 6)
            }
        }
    }
}

struct EmptyCategoryState: View {
    let category: String
    let onAddPhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.6))
            
            Text("No \(category) photos yet")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            
            Text("Start tracking \(category.lowercased()) changes by adding your first photo.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button(action: onAddPhoto) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Photo")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                )
            }
        }
    }
}

// MARK: - Modern Floating Action Button

struct ModernFloatingActionButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.5),
                                Color.purple.opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 15,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 15)
                    .opacity(isPressed ? 0.8 : 0.6)
                
                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.95), .purple.opacity(0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 15, y: 8)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                // Icon
                Image(systemName: "camera.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Modern Photo Picker

struct ModernPhotoPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    let category: String
    let categoryColor: Color
    let onSelect: (UIImage, String) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                VStack(spacing: 32) {
                    if let image = selectedImage {
                        // Preview
                        VStack(spacing: 24) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 400)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                                .padding()
                            
                            Button {
                                onSelect(image, category)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                    Text("Upload Photo")
                                        .font(.headline.weight(.semibold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [categoryColor.opacity(0.9), categoryColor.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                        )
                                )
                                .shadow(color: categoryColor.opacity(0.4), radius: 12, y: 6)
                            }
                            .padding(.horizontal, 22)
                        }
                    } else {
                        // Selection view
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            VStack(spacing: 24) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [
                                                    categoryColor.opacity(0.3),
                                                    categoryColor.opacity(0.1),
                                                    Color.clear
                                                ],
                                                center: .center,
                                                startRadius: 20,
                                                endRadius: 80
                                            )
                                        )
                                        .frame(width: 160, height: 160)
                                        .blur(radius: 20)
                                    
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 56, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [categoryColor, categoryColor.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                VStack(spacing: 12) {
                                    Text("Select Photo")
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(.white)
                                    
                                    Text("Choose from your photo library")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 80)
                            .background(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.15),
                                                        Color.white.opacity(0.05)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.25),
                                                        Color.white.opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 15, y: 8)
                        }
                        .padding(.horizontal, 22)
                    }
                }
                .padding(.vertical, 32)
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

// MARK: - Modern Comparison View

struct ModernComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    let photo: VisualPhoto
    let allPhotos: [VisualPhoto]
    @ObservedObject var vm: VisualChecksVM
    @State private var sliderValue: Double = 0.5
    
    var sortedPhotos: [VisualPhoto] {
        allPhotos.sorted { $0.createdAt < $1.createdAt }
    }
    
    var beforePhoto: VisualPhoto? {
        guard let currentIndex = sortedPhotos.firstIndex(where: { $0.id == photo.id }),
              currentIndex > 0 else { return nil }
        return sortedPhotos[currentIndex - 1]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if let before = beforePhoto {
                        // Comparison slider
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                // Before image (background)
                                ComparisonImageView(photo: before, vm: vm)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                
                                // After image (foreground with mask)
                                ComparisonImageView(photo: photo, vm: vm)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                    .mask(
                                        HStack(spacing: 0) {
                                            Rectangle()
                                                .frame(width: geo.size.width * CGFloat(sliderValue))
                                            Spacer()
                                        }
                                    )
                            }
                            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                        }
                        .frame(height: 450)
                        .padding(.horizontal, 22)
                        
                        // Control panel
                        VStack(spacing: 16) {
                            // Slider
                            HStack(spacing: 16) {
                                Text("Before")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .frame(width: 60, alignment: .trailing)
                                
                                Slider(value: $sliderValue, in: 0...1)
                                    .tint(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text("After")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .frame(width: 60, alignment: .leading)
                            }
                            
                            // Date info
                            HStack(spacing: 24) {
                                DateInfo(
                                    label: "Before",
                                    date: before.createdAt
                                )
                                
                                Spacer()
                                
                                DateInfo(
                                    label: "After",
                                    date: photo.createdAt
                                )
                            }
                            .padding(.horizontal, 22)
                        }
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                )
                        )
                        .padding(.horizontal, 22)
                    } else {
                        Text("No previous photos to compare")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.top, 100)
                    }
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Compare")
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

struct ComparisonImageView: View {
    let photo: VisualPhoto
    @ObservedObject var vm: VisualChecksVM
    
    var body: some View {
        Group {
            if let uiImage = vm.getImage(for: photo) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                AsyncImage(url: URL(string: photo.imageURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ZStack {
                        Color.white.opacity(0.1)
                        ProgressView().tint(.white)
                    }
                }
            }
        }
    }
}

struct DateInfo: View {
    let label: String
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
            
            Text(formatDate(date))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Model

struct VisualPhoto: Identifiable, Codable {
    let id: String
    let imageURL: String
    let category: String
    let note: String?
    let aiNote: String?
    let createdAt: Date
    
    init(id: String = UUID().uuidString, imageURL: String, category: String, note: String? = nil, aiNote: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.imageURL = imageURL
        self.category = category
        self.note = note
        self.aiNote = aiNote
        self.createdAt = createdAt
    }
}

// MARK: - ViewModel

final class VisualChecksVM: ObservableObject {
    @Published var photos: [VisualPhoto] = []
    @Published var localImages: [String: UIImage] = [:]
    
    private let db = Firestore.firestore()
    private var uid: String? { Auth.auth().currentUser?.uid }
    
    // Store listener reference for cleanup
    private var photosListener: ListenerRegistration?
    
    var filteredPhotos: [VisualPhoto] {
        photos.filter { $0.category == selectedCategory.rawValue }
    }
    
    var selectedCategory: VisualChecksView.PhotoCategory = .skin
    
    deinit {
        stopListening()
    }
    
    func loadPhotos() {
        // Remove existing listener if any
        stopListening()
        
        guard let uid else { return }
        photosListener = db.collection("users").document(uid).collection("visualPhotos")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let docs = snapshot?.documents else { return }
                self.photos = docs.compactMap { doc in
                    try? doc.data(as: VisualPhoto.self)
                }
            }
    }
    
    func stopListening() {
        photosListener?.remove()
        photosListener = nil
    }
    
    func uploadPhoto(image: UIImage, category: String) {
        guard let uid = uid else { return }
        
        guard let imageData = image.jpegData(compressionQuality: 0.7),
              let base64String = imageData.base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        let photo = VisualPhoto(
            imageURL: "data:image/jpeg;base64,\(base64String)",
            category: category,
            aiNote: nil
        )
        
        localImages[photo.id] = image
        
        // Get previous notes for this category
        let previousNotes = photos
            .filter { $0.category == category && $0.aiNote != nil }
            .compactMap { $0.aiNote }
            .suffix(3)
        
        // Removed AI visual photo analysis to save API usage
        // User can still add manual notes - just save the photo
        Task {
            try? db.collection("users").document(uid).collection("visualPhotos")
                .document(photo.id)
                .setData(from: photo)
        }
        
        // Update progress
        Task {
            await ProgressCalculator.shared.calculateTodayProgress()
        }
    }
    
    func deletePhoto(_ photo: VisualPhoto) {
        guard let uid else { return }
        db.collection("users").document(uid).collection("visualPhotos")
            .document(photo.id)
            .delete()
        
        localImages.removeValue(forKey: photo.id)
    }
    
    func getImage(for photo: VisualPhoto) -> UIImage? {
        if let cached = localImages[photo.id] {
            return cached
        }
        
        if photo.imageURL.hasPrefix("data:image") {
            if let commaIndex = photo.imageURL.firstIndex(of: ",") {
                let base64String = String(photo.imageURL[photo.imageURL.index(after: commaIndex)...])
                if let data = Data(base64Encoded: base64String),
                   let image = UIImage(data: data) {
                    localImages[photo.id] = image
                    return image
                }
            }
        }
        
        return nil
    }
}

#Preview {
    VisualChecksView()
}
