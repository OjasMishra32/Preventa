import SwiftUI

enum PainType: String, CaseIterable {
    case sharp, dull, burning, throbbing, aching
    
    var icon: String {
        switch self {
        case .sharp: return "bolt.fill"
        case .dull: return "circle.fill"
        case .burning: return "flame.fill"
        case .throbbing: return "waveform"
        case .aching: return "drop.fill"
        }
    }
}

struct BodyMapView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRegion: BodyRegion?
    @State private var painLevel: Double = 5.0
    @State private var painType: PainType = .dull
    @State private var duration: String = ""
    @State private var notes: String = ""
    @State private var isFrontView: Bool = true
    @State private var showDetail: Bool = false
    @State private var navigateToPulse = false
    
    
    var body: some View {
        ZStack {
            AnimatedBrandBackground().ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Flip view button
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.4)) {
                                isFrontView.toggle()
                                selectedRegion = nil
                            }
                            Hx.tap()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.left.arrow.right")
                                Text(isFrontView ? "Back" : "Front")
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                            )
                        }
                    }
                    .padding(.horizontal, 22)
                    
                    // Body map
                    BodySilhouette(
                        isFront: isFrontView,
                        selectedRegion: $selectedRegion,
                        onTap: { region in
                            withAnimation(.spring(response: 0.3)) {
                                selectedRegion = region
                                showDetail = true
                            }
                            Hx.strong()
                        }
                    )
                    .frame(height: 480)
                    .padding(.horizontal, 22)
                    
                    // Detail panel
                    if let region = selectedRegion, showDetail {
                        RegionDetailPanel(
                            region: region,
                            painLevel: $painLevel,
                            painType: $painType,
                            duration: $duration,
                            notes: $notes,
                            onSendToPulse: {
                                sendToPulse(region: region)
                            },
                            onDismiss: {
                                withAnimation {
                                    showDetail = false
                                    selectedRegion = nil
                                }
                            }
                        )
                        .padding(.horizontal, 22)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.vertical, 20)
            }
        }
        .navigationDestination(isPresented: $navigateToPulse) {
            PulseChatView()
        }
        .navigationTitle("Body Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
                    .foregroundStyle(.white)
            }
        }
    }
    
    private func sendToPulse(region: BodyRegion) {
        // Removed AI symptom analysis to save API usage
        // Send directly to Pulse chat for user-initiated AI conversation
        Task {
            // Create context without AI analysis
            let context = """
            Pain Location: \(region.name)
            Pain Level: \(Int(painLevel))/10
            Type: \(painType.rawValue)
            Duration: \(duration.isEmpty ? "Not specified" : duration)
            Notes: \(notes.isEmpty ? "None" : notes)
            """
            
            UserDefaults.standard.set(context, forKey: "bodyMap.context")
            
            // Navigate to Pulse
            await MainActor.run {
                Hx.ok()
                withAnimation(.spring(response: 0.4)) {
                    showDetail = false
                    selectedRegion = nil
                    navigateToPulse = true
                }
            }
        }
    }
}

struct BodyRegion: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let systemName: String
    let rect: CGRect
    let frontRect: CGRect?
    let backRect: CGRect?
    let educationalBlurb: String
    
    init(name: String, systemName: String, frontRect: CGRect? = nil, backRect: CGRect? = nil, educationalBlurb: String) {
        self.name = name
        self.systemName = systemName
        self.frontRect = frontRect
        self.backRect = backRect
        self.rect = frontRect ?? backRect ?? CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1)
        self.educationalBlurb = educationalBlurb
    }
}

// MARK: - Human Silhouette Shape

struct HumanSilhouetteShape: Shape {
    let isFront: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Proportional measurements based on human anatomy
        let headRadius: CGFloat = width * 0.12
        let headCenterX = width * 0.5
        let headCenterY = headRadius * 1.2
        
        let neckWidth: CGFloat = width * 0.14
        let neckHeight: CGFloat = height * 0.06
        
        let shoulderWidth: CGFloat = width * 0.48
        let shoulderY = headCenterY + headRadius + neckHeight
        
        let torsoWidth: CGFloat = width * 0.36
        let torsoHeight: CGFloat = height * 0.28
        
        let waistWidth: CGFloat = width * 0.28
        let waistY = shoulderY + torsoHeight
        
        let hipWidth: CGFloat = width * 0.32
        let hipHeight: CGFloat = height * 0.06
        
        let armWidth: CGFloat = width * 0.08
        let upperArmLength: CGFloat = height * 0.14
        let lowerArmLength: CGFloat = height * 0.12
        
        let legWidth: CGFloat = width * 0.12
        let upperLegLength: CGFloat = height * 0.22
        let lowerLegLength: CGFloat = height * 0.20
        let footLength: CGFloat = width * 0.14
        let footHeight: CGFloat = height * 0.04
        
        // HEAD (circular/oval)
        path.addEllipse(in: CGRect(
            x: headCenterX - headRadius,
            y: headCenterY - headRadius,
            width: headRadius * 2,
            height: headRadius * 1.8
        ))
        
        // NECK
        path.addRoundedRect(in: CGRect(
            x: headCenterX - neckWidth / 2,
            y: headCenterY + headRadius * 0.5,
            width: neckWidth,
            height: neckHeight
        ), cornerSize: CGSize(width: 4, height: 4))
        
        // SHOULDERS (slightly curved)
        let shoulderLeft = headCenterX - shoulderWidth / 2
        let shoulderRight = headCenterX + shoulderWidth / 2
        
        if isFront {
            path.move(to: CGPoint(x: shoulderLeft, y: shoulderY))
            path.addCurve(
                to: CGPoint(x: shoulderRight, y: shoulderY),
                control1: CGPoint(x: shoulderLeft, y: shoulderY - 8),
                control2: CGPoint(x: shoulderRight, y: shoulderY - 8)
            )
        } else {
            path.move(to: CGPoint(x: shoulderLeft, y: shoulderY))
            path.addCurve(
                to: CGPoint(x: shoulderRight, y: shoulderY),
                control1: CGPoint(x: shoulderLeft + 20, y: shoulderY + 8),
                control2: CGPoint(x: shoulderRight - 20, y: shoulderY + 8)
            )
        }
        
        // TORSO (trapezoid shape - wider at top, narrower at waist)
        path.move(to: CGPoint(x: headCenterX - torsoWidth / 2, y: shoulderY))
        path.addLine(to: CGPoint(x: headCenterX + torsoWidth / 2, y: shoulderY))
        path.addLine(to: CGPoint(x: headCenterX + waistWidth / 2, y: waistY))
        path.addLine(to: CGPoint(x: headCenterX - waistWidth / 2, y: waistY))
        path.closeSubpath()
        
        // HIPS
        path.addRoundedRect(in: CGRect(
            x: headCenterX - hipWidth / 2,
            y: waistY,
            width: hipWidth,
            height: hipHeight
        ), cornerSize: CGSize(width: 8, height: 8))
        
        // LEFT ARM
        let leftShoulderX = shoulderLeft
        let armStartY = shoulderY + 8
        
        // Upper arm
        path.addRoundedRect(in: CGRect(
            x: leftShoulderX - armWidth,
            y: armStartY,
            width: armWidth,
            height: upperArmLength
        ), cornerSize: CGSize(width: armWidth / 2, height: 4))
        
        // Lower arm
        path.addRoundedRect(in: CGRect(
            x: leftShoulderX - armWidth,
            y: armStartY + upperArmLength,
            width: armWidth,
            height: lowerArmLength
        ), cornerSize: CGSize(width: armWidth / 2, height: 4))
        
        // LEFT HAND
        path.addEllipse(in: CGRect(
            x: leftShoulderX - armWidth - footLength * 0.3,
            y: armStartY + upperArmLength + lowerArmLength,
            width: footLength * 0.6,
            height: height * 0.06
        ))
        
        // RIGHT ARM
        let rightShoulderX = shoulderRight
        
        // Upper arm
        path.addRoundedRect(in: CGRect(
            x: rightShoulderX,
            y: armStartY,
            width: armWidth,
            height: upperArmLength
        ), cornerSize: CGSize(width: armWidth / 2, height: 4))
        
        // Lower arm
        path.addRoundedRect(in: CGRect(
            x: rightShoulderX,
            y: armStartY + upperArmLength,
            width: armWidth,
            height: lowerArmLength
        ), cornerSize: CGSize(width: armWidth / 2, height: 4))
        
        // RIGHT HAND
        path.addEllipse(in: CGRect(
            x: rightShoulderX + armWidth - footLength * 0.3,
            y: armStartY + upperArmLength + lowerArmLength,
            width: footLength * 0.6,
            height: height * 0.06
        ))
        
        // LEFT LEG
        let legStartY = waistY + hipHeight
        let leftLegX = headCenterX - hipWidth / 2 + hipWidth * 0.15
        
        // Upper leg
        path.addRoundedRect(in: CGRect(
            x: leftLegX,
            y: legStartY,
            width: legWidth,
            height: upperLegLength
        ), cornerSize: CGSize(width: legWidth / 2, height: 4))
        
        // Knee circle
        path.addEllipse(in: CGRect(
            x: leftLegX + legWidth * 0.2,
            y: legStartY + upperLegLength - height * 0.03,
            width: legWidth * 0.6,
            height: height * 0.06
        ))
        
        // Lower leg
        path.addRoundedRect(in: CGRect(
            x: leftLegX,
            y: legStartY + upperLegLength,
            width: legWidth,
            height: lowerLegLength
        ), cornerSize: CGSize(width: legWidth / 2, height: 4))
        
        // LEFT FOOT
        path.addEllipse(in: CGRect(
            x: leftLegX - footLength * 0.2,
            y: legStartY + upperLegLength + lowerLegLength,
            width: footLength,
            height: footHeight
        ))
        
        // RIGHT LEG
        let rightLegX = headCenterX + hipWidth / 2 - hipWidth * 0.15 - legWidth
        
        // Upper leg
        path.addRoundedRect(in: CGRect(
            x: rightLegX,
            y: legStartY,
            width: legWidth,
            height: upperLegLength
        ), cornerSize: CGSize(width: legWidth / 2, height: 4))
        
        // Knee circle
        path.addEllipse(in: CGRect(
            x: rightLegX + legWidth * 0.2,
            y: legStartY + upperLegLength - height * 0.03,
            width: legWidth * 0.6,
            height: height * 0.06
        ))
        
        // Lower leg
        path.addRoundedRect(in: CGRect(
            x: rightLegX,
            y: legStartY + upperLegLength,
            width: legWidth,
            height: lowerLegLength
        ), cornerSize: CGSize(width: legWidth / 2, height: 4))
        
        // RIGHT FOOT
        path.addEllipse(in: CGRect(
            x: rightLegX - footLength * 0.2,
            y: legStartY + upperLegLength + lowerLegLength,
            width: footLength,
            height: footHeight
        ))
        
        return path
    }
}

struct BodySilhouette: View {
    let isFront: Bool
    @Binding var selectedRegion: BodyRegion?
    let onTap: (BodyRegion) -> Void
    @State private var pulseAnimation = false
    
    private let regions: [BodyRegion] = [
        BodyRegion(name: "Head", systemName: "head", frontRect: CGRect(x: 0.44, y: 0.03, width: 0.12, height: 0.10), educationalBlurb: "The head houses your brain, eyes, ears, and sinuses. Stay hydrated and manage stress to support healthy function."),
        BodyRegion(name: "Neck", systemName: "neck", frontRect: CGRect(x: 0.43, y: 0.13, width: 0.14, height: 0.06), educationalBlurb: "The neck supports your head and protects the spinal cord. Gentle stretches and good posture help maintain flexibility."),
        BodyRegion(name: "Chest", systemName: "chest", frontRect: CGRect(x: 0.32, y: 0.19, width: 0.36, height: 0.18), educationalBlurb: "The chest houses your heart and lungs. Regular activity improves circulation and oxygen flow."),
        BodyRegion(name: "Abdomen", systemName: "abdomen", frontRect: CGRect(x: 0.36, y: 0.37, width: 0.28, height: 0.16), educationalBlurb: "Your abdomen contains digestive organs. Balanced nutrition and hydration support healthy digestion."),
        BodyRegion(name: "Lower Abdomen", systemName: "lower.abdomen", frontRect: CGRect(x: 0.37, y: 0.53, width: 0.26, height: 0.10), educationalBlurb: "The lower abdomen includes intestines and reproductive organs. Stay active and maintain a balanced diet."),
        BodyRegion(name: "Left Shoulder", systemName: "shoulder.left", frontRect: CGRect(x: 0.18, y: 0.20, width: 0.18, height: 0.12), educationalBlurb: "The shoulder allows wide range of motion. Posture and stretching help prevent stiffness."),
        BodyRegion(name: "Right Shoulder", systemName: "shoulder.right", frontRect: CGRect(x: 0.64, y: 0.20, width: 0.18, height: 0.12), educationalBlurb: "The shoulder allows wide range of motion. Posture and stretching help prevent stiffness."),
        BodyRegion(name: "Left Arm", systemName: "arm.left", frontRect: CGRect(x: 0.12, y: 0.32, width: 0.14, height: 0.26), educationalBlurb: "Arms enable daily tasks. Regular movement and strength exercises maintain function."),
        BodyRegion(name: "Right Arm", systemName: "arm.right", frontRect: CGRect(x: 0.74, y: 0.32, width: 0.14, height: 0.26), educationalBlurb: "Arms enable daily tasks. Regular movement and strength exercises maintain function."),
        BodyRegion(name: "Left Hand", systemName: "hand.left", frontRect: CGRect(x: 0.08, y: 0.58, width: 0.12, height: 0.08), educationalBlurb: "Hands are complex structures with many joints. Rest breaks and ergonomic tools help prevent strain."),
        BodyRegion(name: "Right Hand", systemName: "hand.right", frontRect: CGRect(x: 0.80, y: 0.58, width: 0.12, height: 0.08), educationalBlurb: "Hands are complex structures with many joints. Rest breaks and ergonomic tools help prevent strain."),
        BodyRegion(name: "Lower Back", systemName: "lower.back", frontRect: CGRect(x: 0.38, y: 0.50, width: 0.24, height: 0.12), backRect: CGRect(x: 0.38, y: 0.50, width: 0.24, height: 0.12), educationalBlurb: "The lower back supports your upper body. Core strength and proper lifting techniques protect it."),
        BodyRegion(name: "Left Hip", systemName: "hip.left", frontRect: CGRect(x: 0.33, y: 0.62, width: 0.16, height: 0.10), educationalBlurb: "Hips connect your torso to legs. Flexibility exercises and movement support hip health."),
        BodyRegion(name: "Right Hip", systemName: "hip.right", frontRect: CGRect(x: 0.51, y: 0.62, width: 0.16, height: 0.10), educationalBlurb: "Hips connect your torso to legs. Flexibility exercises and movement support hip health."),
        BodyRegion(name: "Left Leg", systemName: "leg.left", frontRect: CGRect(x: 0.35, y: 0.72, width: 0.14, height: 0.22), educationalBlurb: "Legs provide mobility and support. Regular walking and stretching maintain strength and flexibility."),
        BodyRegion(name: "Right Leg", systemName: "leg.right", frontRect: CGRect(x: 0.51, y: 0.72, width: 0.14, height: 0.22), educationalBlurb: "Legs provide mobility and support. Regular walking and stretching maintain strength and flexibility."),
        BodyRegion(name: "Left Knee", systemName: "knee.left", frontRect: CGRect(x: 0.37, y: 0.82, width: 0.10, height: 0.06), educationalBlurb: "Knees bear weight and enable movement. Low-impact activities and proper alignment protect them."),
        BodyRegion(name: "Right Knee", systemName: "knee.right", frontRect: CGRect(x: 0.53, y: 0.82, width: 0.10, height: 0.06), educationalBlurb: "Knees bear weight and enable movement. Low-impact activities and proper alignment protect them."),
        BodyRegion(name: "Left Foot", systemName: "foot.left", frontRect: CGRect(x: 0.32, y: 0.92, width: 0.14, height: 0.06), educationalBlurb: "Feet support your entire body. Proper footwear and foot exercises maintain health."),
        BodyRegion(name: "Right Foot", systemName: "foot.right", frontRect: CGRect(x: 0.54, y: 0.92, width: 0.14, height: 0.06), educationalBlurb: "Feet support your entire body. Proper footwear and foot exercises maintain health.")
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background with glass effect
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.white.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                
                // Human silhouette with gradient fill
                HumanSilhouetteShape(isFront: isFront)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.85, blue: 0.75).opacity(0.25),
                                Color(red: 0.90, green: 0.80, blue: 0.70).opacity(0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        HumanSilhouetteShape(isFront: isFront)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.25)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2.5
                            )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                
                // Tappable regions with improved hit testing
                ForEach(regions.filter { isFront ? $0.frontRect != nil : $0.backRect != nil }) { region in
                    let rect = isFront ? (region.frontRect ?? region.rect) : (region.backRect ?? region.rect)
                    BodyRegionButton(
                        region: region,
                        rect: CGRect(
                            x: rect.minX * geo.size.width,
                            y: rect.minY * geo.size.height,
                            width: rect.width * geo.size.width,
                            height: rect.height * geo.size.height
                        ),
                        isSelected: selectedRegion?.id == region.id,
                        onTap: { onTap(region) }
                    )
                }
                
                // Region labels on selection
                if let selected = selectedRegion {
                    let rect = isFront ? (selected.frontRect ?? selected.rect) : (selected.backRect ?? selected.rect)
                    VStack(spacing: 4) {
                        Text(selected.name)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.9)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        
                        Image(systemName: "arrow.down")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .position(
                        x: (rect.minX + rect.width / 2) * geo.size.width,
                        y: (rect.minY - 20) * geo.size.height
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

struct BodyRegionButton: View {
    let region: BodyRegion
    let rect: CGRect
    let isSelected: Bool
    let onTap: () -> Void
    @State private var pulse = false
    @State private var glow = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Pulsing glow effect when selected
                if isSelected {
                    RoundedRectangle(cornerRadius: rect.height * 0.3, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(0.6),
                                    Color.purple.opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: max(rect.width, rect.height) * 1.5
                            )
                        )
                        .scaleEffect(pulse ? 1.3 : 1.0)
                        .opacity(pulse ? 0.6 : 0.9)
                        .blur(radius: glow ? 12 : 8)
                }
                
                // Region highlight
                RoundedRectangle(cornerRadius: rect.height * 0.25, style: .continuous)
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.5),
                                    Color.purple.opacity(0.4)
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
                        RoundedRectangle(cornerRadius: rect.height * 0.25, style: .continuous)
                            .stroke(
                                isSelected
                                    ? LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.8),
                                            Color.white.opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.25),
                                            Color.white.opacity(0.15)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? .blue.opacity(0.5) : .clear,
                        radius: isSelected ? 12 : 0,
                        x: 0,
                        y: isSelected ? 6 : 0
                    )
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                
                // Region icon when selected
                if isSelected {
                    Image(systemName: region.systemName)
                        .font(.system(size: min(rect.width, rect.height) * 0.4))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        .onChange(of: isSelected) { newValue in
            if newValue {
                pulse = true
                glow = true
            } else {
                pulse = false
                glow = false
            }
        }
        .onAppear {
            if isSelected {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulse = true
                }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glow = true
                }
            }
        }
    }
}

struct RegionDetailPanel: View {
    let region: BodyRegion
    @Binding var painLevel: Double
    @Binding var painType: PainType
    @Binding var duration: String
    @Binding var notes: String
    let onSendToPulse: () -> Void
    let onDismiss: () -> Void
    @State private var painColor: Color = .purple
    @State private var buttonTapCount: Int = 0
    
    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                // Enhanced Header with Icon
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.6),
                                        Color.purple.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: region.systemName)
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(region.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text(region.educationalBlurb)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                Divider()
                    .background(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                // Enhanced Pain level with visual feedback
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption)
                            .foregroundStyle(painColor)
                        
                        Text("Pain Level")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Text("\(Int(painLevel))/10")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [painColor, painColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    // Visual pain indicator
                    HStack(spacing: 4) {
                        ForEach(0..<10, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(index < Int(painLevel) ? painColor : Color.white.opacity(0.15))
                                .frame(height: 8)
                                .animation(.spring(response: 0.3), value: painLevel)
                        }
                    }
                    
                    Slider(value: $painLevel, in: 0...10, step: 1)
                        .tint(painColor)
                }
                .onChange(of: painLevel) { _, newValue in
                    withAnimation(.spring()) {
                        if newValue >= 7 {
                            painColor = .red
                        } else if newValue >= 4 {
                            painColor = .orange
                        } else {
                            painColor = .purple
                        }
                    }
                }
                
                // Enhanced Pain type selection
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "waveform.path")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text("Pain Type")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(PainType.allCases, id: \.self) { type in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        painType = type
                                    }
                                    Hx.tap()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: type.icon)
                                            .font(.caption.weight(.semibold))
                                        Text(type.rawValue.capitalized)
                                            .font(.subheadline.weight(.medium))
                                    }
                                    .foregroundStyle(painType == type ? .white : .white.opacity(0.7))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(
                                                painType == type
                                                    ? LinearGradient(
                                                        colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.4)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                    : LinearGradient(
                                                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                            )
                                            .overlay(
                                                Capsule()
                                                    .stroke(
                                                        painType == type
                                                            ? LinearGradient(
                                                                colors: [Color.white.opacity(0.6), Color.white.opacity(0.4)],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                            : LinearGradient(
                                                                colors: [Color.white.opacity(0.25), Color.white.opacity(0.15)],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            ),
                                                        lineWidth: painType == type ? 2 : 1
                                                    )
                                            )
                                    )
                                    .shadow(
                                        color: painType == type ? .purple.opacity(0.4) : .clear,
                                        radius: painType == type ? 8 : 0,
                                        x: 0,
                                        y: painType == type ? 4 : 0
                                    )
                                    .scaleEffect(painType == type ? 1.05 : 1.0)
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                
                // Enhanced Duration field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text("Duration")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    
                    TextField("e.g., 3 days, 2 hours, since yesterday", text: $duration)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .foregroundStyle(.white)
                }
                
                // Enhanced Notes field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text("Additional Notes")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    
                    TextField("Describe your symptoms, triggers, or any other details...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .foregroundStyle(.white)
                }
                
                // Enhanced Action button
                Button(action: {
                    buttonTapCount += 1
                    onSendToPulse()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.headline)
                            .symbolEffect(.pulse, value: buttonTapCount)
                        
                        Text("Send to Preventa Pulse")
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
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    BodyMapView()
}

