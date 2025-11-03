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
    @State private var showDetail: Bool = false
    @State private var navigateToPulse = false
    @State private var showingFront: Bool = true
    @State private var selectedDots: Set<String> = []
    
    var body: some View {
        ZStack {
            AnimatedBrandBackground().ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Section - Moved up for space optimization
                VStack(spacing: 6) {
                    Text("Where is your pain?")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Tap any green dot to report pain or discomfort")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                // Front/Back Toggle
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showingFront = true
                        }
                        Hx.tap()
                    } label: {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("Front")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(showingFront ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(showingFront ? Color.blue.opacity(0.6) : Color.white.opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .stroke(showingFront ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showingFront = false
                        }
                        Hx.tap()
                    } label: {
                        HStack {
                            Image(systemName: "person.fill.turn.down")
                            Text("Back")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(!showingFront ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(!showingFront ? Color.blue.opacity(0.6) : Color.white.opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .stroke(!showingFront ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 10)
                
                // Human Body Image with Dots - Made much bigger
                ZStack {
                    HumanBodyImageView(
                        showingFront: showingFront,
                        selectedRegion: $selectedRegion,
                        selectedDots: $selectedDots,
                        onRegionTap: { region in
                            selectedRegion = region
                            selectedDots.insert(region.regionPath)
                            showDetail = true
                            Hx.strong()
                        }
                    )
                    .frame(height: 650)
                    .padding(.horizontal, 16)
                }
            }
        }
        .sheet(isPresented: $showDetail) {
            if let region = selectedRegion {
                NavigationStack {
                    ScrollView {
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
                                showDetail = false
                                selectedRegion = nil
                                selectedDots.remove(region.regionPath)
                            }
                        )
                        .padding()
                    }
                    .background(AnimatedBrandBackground().ignoresSafeArea())
                    .navigationTitle(region.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showDetail = false
                                selectedRegion = nil
                            }
                            .foregroundStyle(.white)
                        }
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
        Task {
                // Format pain data with proper structure, spacing, and clear labels
                var context = "Location: \(region.name)\n"
                context += "Pain Level: \(Int(painLevel))/10\n"
                context += "Type: \(painType.rawValue.capitalized)\n"
                
                if !duration.isEmpty {
                    context += "Duration: \(duration)\n"
                } else {
                    context += "Duration: Not specified\n"
                }
                
                if !notes.isEmpty {
                    context += "Notes: \(notes)"
                } else {
                    context += "Notes: None"
                }
                
                UserDefaults.standard.set(context, forKey: "bodyMap.context")
            
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
    let regionPath: String
    let educationalBlurb: String
    let side: BodySide // Front or back
    
    init(name: String, systemName: String, regionPath: String, educationalBlurb: String, side: BodySide = .front) {
        self.name = name
        self.systemName = systemName
        self.regionPath = regionPath
        self.educationalBlurb = educationalBlurb
        self.side = side
    }
}

enum BodySide {
    case front, back
}

// MARK: - Human Body Image View with Clickable Dots

struct HumanBodyImageView: View {
    let showingFront: Bool
    @Binding var selectedRegion: BodyRegion?
    @Binding var selectedDots: Set<String>
    let onRegionTap: (BodyRegion) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Human body outline image placeholder (will use SF Symbol or generate shape)
                HumanBodyOutlineShape()
                    .fill(Color.white.opacity(0.85))
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                
                // Overlay clickable dots for body parts - Made bigger for easier tapping
                ForEach(getRelevantRegions(), id: \.id) { region in
                    if let dotPosition = getDotPosition(for: region, in: geometry.size) {
                        // Red if currently selected (sheet is open) - check both regionPath and side
                        let isCurrentlySelected = selectedRegion?.regionPath == region.regionPath && selectedRegion?.side == region.side
                        
                        // Fixed position - never changes
                        let fixedPosition = dotPosition
                        
                        Circle()
                            .fill(isCurrentlySelected ? Color.red : Color.green)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .shadow(color: .black.opacity(0.4), radius: 3)
                            )
                            .scaleEffect(isCurrentlySelected ? 1.4 : 1.0)
                            .animation(.spring(response: 0.2), value: isCurrentlySelected)
                            .background(
                                // Invisible tap target area for easier tapping
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 32, height: 32)
                            )
                            .position(fixedPosition) // Always use the fixed position
                            .onTapGesture {
                                selectedRegion = region
                                onRegionTap(region)
                                selectedDots.insert(region.regionPath)
                                Hx.tap()
                            }
                            .id(region.id) // Use stable region ID
                    }
                }
            }
        }
    }
    
    private func getRelevantRegions() -> [BodyRegion] {
        createBodyRegions().filter { region in
            region.side == (showingFront ? .front : .back)
        }
    }
    
    private func getDotPosition(for region: BodyRegion, in size: CGSize) -> CGPoint? {
        let centerX = size.width / 2
        let width = size.width * 0.50 // Increased from 0.35 to 0.50 to match bigger body
        
        // Positions for front view
        if showingFront {
            switch region.regionPath {
            // HEAD - Front
            case "head": return CGPoint(x: centerX, y: size.height * 0.12)
            case "forehead": return CGPoint(x: centerX, y: size.height * 0.09)
            case "leftTemple": return CGPoint(x: centerX - width * 0.08, y: size.height * 0.11)
            case "rightTemple": return CGPoint(x: centerX + width * 0.08, y: size.height * 0.11)
            case "chin": return CGPoint(x: centerX, y: size.height * 0.15)
            case "jaw": return CGPoint(x: centerX, y: size.height * 0.16)
                
            // NECK - Front
            case "neckFront": return CGPoint(x: centerX, y: size.height * 0.19)
                
            // SHOULDERS - Front
            case "leftShoulder": return CGPoint(x: centerX - width * 0.35, y: size.height * 0.23)
            case "rightShoulder": return CGPoint(x: centerX + width * 0.35, y: size.height * 0.23)
            case "leftClavicle": return CGPoint(x: centerX - width * 0.22, y: size.height * 0.22)
            case "rightClavicle": return CGPoint(x: centerX + width * 0.22, y: size.height * 0.22)
            case "leftDeltoid": return CGPoint(x: centerX - width * 0.34, y: size.height * 0.24)
            case "rightDeltoid": return CGPoint(x: centerX + width * 0.34, y: size.height * 0.24)
                
            // CHEST - Front
            case "chest": return CGPoint(x: centerX, y: size.height * 0.32)
            case "sternum": return CGPoint(x: centerX, y: size.height * 0.30)
            case "leftRibs": return CGPoint(x: centerX - width * 0.28, y: size.height * 0.33)
            case "rightRibs": return CGPoint(x: centerX + width * 0.28, y: size.height * 0.33)
            
            // ABDOMEN - Front
            case "abdomen": return CGPoint(x: centerX, y: size.height * 0.44)
            case "upperAbdomen": return CGPoint(x: centerX, y: size.height * 0.40)
            case "lowerAbdomen": return CGPoint(x: centerX, y: size.height * 0.48)
            
            // HIPS - Front
            case "hips": return CGPoint(x: centerX, y: size.height * 0.53)
            case "leftHip": return CGPoint(x: centerX - width * 0.26, y: size.height * 0.53)
            case "rightHip": return CGPoint(x: centerX + width * 0.26, y: size.height * 0.53)
            case "pelvis": return CGPoint(x: centerX, y: size.height * 0.54)
            
            // ARMS - Front
            case "leftUpperArm": return CGPoint(x: centerX - width * 0.42, y: size.height * 0.35)
            case "rightUpperArm": return CGPoint(x: centerX + width * 0.42, y: size.height * 0.35)
            case "leftBiceps": return CGPoint(x: centerX - width * 0.41, y: size.height * 0.33)
            case "rightBiceps": return CGPoint(x: centerX + width * 0.41, y: size.height * 0.33)
            case "leftTriceps": return CGPoint(x: centerX - width * 0.43, y: size.height * 0.37)
            case "rightTriceps": return CGPoint(x: centerX + width * 0.43, y: size.height * 0.37)
            case "leftElbow": return CGPoint(x: centerX - width * 0.42, y: size.height * 0.43)
            case "rightElbow": return CGPoint(x: centerX + width * 0.42, y: size.height * 0.43)
            case "leftForearm": return CGPoint(x: centerX - width * 0.46, y: size.height * 0.48)
            case "rightForearm": return CGPoint(x: centerX + width * 0.46, y: size.height * 0.48)
            case "leftWrist": return CGPoint(x: centerX - width * 0.47, y: size.height * 0.54)
            case "rightWrist": return CGPoint(x: centerX + width * 0.47, y: size.height * 0.54)
            case "leftHand": return CGPoint(x: centerX - width * 0.48, y: size.height * 0.58)
            case "rightHand": return CGPoint(x: centerX + width * 0.48, y: size.height * 0.58)
            case "leftPalm": return CGPoint(x: centerX - width * 0.47, y: size.height * 0.60)
            case "rightPalm": return CGPoint(x: centerX + width * 0.47, y: size.height * 0.60)
            
            // LEGS - Front - Better spaced out
            case "leftThigh": return CGPoint(x: centerX - width * 0.25, y: size.height * 0.67)
            case "rightThigh": return CGPoint(x: centerX + width * 0.25, y: size.height * 0.67)
            case "leftFemur": return CGPoint(x: centerX - width * 0.25, y: size.height * 0.69)
            case "rightFemur": return CGPoint(x: centerX + width * 0.25, y: size.height * 0.69)
            case "leftQuadriceps": return CGPoint(x: centerX - width * 0.24, y: size.height * 0.65)
            case "rightQuadriceps": return CGPoint(x: centerX + width * 0.24, y: size.height * 0.65)
            case "leftInnerThigh": return CGPoint(x: centerX - width * 0.20, y: size.height * 0.68)
            case "rightInnerThigh": return CGPoint(x: centerX + width * 0.20, y: size.height * 0.68)
            case "leftOuterThigh": return CGPoint(x: centerX - width * 0.30, y: size.height * 0.66)
            case "rightOuterThigh": return CGPoint(x: centerX + width * 0.30, y: size.height * 0.66)
            case "leftKnee": return CGPoint(x: centerX - width * 0.25, y: size.height * 0.76)
            case "rightKnee": return CGPoint(x: centerX + width * 0.25, y: size.height * 0.76)
            case "leftKneeCap": return CGPoint(x: centerX - width * 0.24, y: size.height * 0.75)
            case "rightKneeCap": return CGPoint(x: centerX + width * 0.24, y: size.height * 0.75)
            case "leftShin": return CGPoint(x: centerX - width * 0.25, y: size.height * 0.83)
            case "rightShin": return CGPoint(x: centerX + width * 0.25, y: size.height * 0.83)
            case "leftCalf": return CGPoint(x: centerX - width * 0.27, y: size.height * 0.84)
            case "rightCalf": return CGPoint(x: centerX + width * 0.27, y: size.height * 0.84)
            case "leftGastrocnemius": return CGPoint(x: centerX - width * 0.27, y: size.height * 0.87)
            case "rightGastrocnemius": return CGPoint(x: centerX + width * 0.27, y: size.height * 0.87)
            // Ankles and feet - Much better spaced out
            case "leftAnkle": return CGPoint(x: centerX - width * 0.26, y: size.height * 0.92)
            case "rightAnkle": return CGPoint(x: centerX + width * 0.26, y: size.height * 0.92)
            case "leftFoot": return CGPoint(x: centerX - width * 0.28, y: size.height * 0.96)
            case "rightFoot": return CGPoint(x: centerX + width * 0.28, y: size.height * 0.96)
            case "leftHeel": return CGPoint(x: centerX - width * 0.30, y: size.height * 0.98)
            case "rightHeel": return CGPoint(x: centerX + width * 0.30, y: size.height * 0.98)
            case "leftArch": return CGPoint(x: centerX - width * 0.24, y: size.height * 0.97)
            case "rightArch": return CGPoint(x: centerX + width * 0.24, y: size.height * 0.97)
                
            default: return nil
            }
        } else {
            // Positions for back view
            switch region.regionPath {
            // HEAD - Back
            case "head": return CGPoint(x: centerX, y: size.height * 0.12)
            case "leftTemple": return CGPoint(x: centerX - width * 0.08, y: size.height * 0.11)
            case "rightTemple": return CGPoint(x: centerX + width * 0.08, y: size.height * 0.11)
                
            // NECK - Back
            case "neckBack": return CGPoint(x: centerX, y: size.height * 0.19)
            case "cervicalSpine": return CGPoint(x: centerX, y: size.height * 0.20)
                
            // SHOULDERS - Back
            case "leftShoulder": return CGPoint(x: centerX - width * 0.35, y: size.height * 0.23)
            case "rightShoulder": return CGPoint(x: centerX + width * 0.35, y: size.height * 0.23)
            case "leftShoulderBlade": return CGPoint(x: centerX - width * 0.32, y: size.height * 0.27)
            case "rightShoulderBlade": return CGPoint(x: centerX + width * 0.32, y: size.height * 0.27)
            case "leftDeltoid": return CGPoint(x: centerX - width * 0.34, y: size.height * 0.24)
            case "rightDeltoid": return CGPoint(x: centerX + width * 0.34, y: size.height * 0.24)
            
            // BACK
            case "upperBack": return CGPoint(x: centerX, y: size.height * 0.31)
            case "middleBack": return CGPoint(x: centerX, y: size.height * 0.38)
            case "lowerBack": return CGPoint(x: centerX, y: size.height * 0.45)
            case "thoracicSpine": return CGPoint(x: centerX, y: size.height * 0.34)
            case "lumbarSpine": return CGPoint(x: centerX, y: size.height * 0.42)
            case "sacralSpine": return CGPoint(x: centerX, y: size.height * 0.49)
            
            // HIPS - Back
            case "hips": return CGPoint(x: centerX, y: size.height * 0.53)
            case "leftHip": return CGPoint(x: centerX - width * 0.26, y: size.height * 0.53)
            case "rightHip": return CGPoint(x: centerX + width * 0.26, y: size.height * 0.53)
            case "pelvis": return CGPoint(x: centerX, y: size.height * 0.54)
            
            // ARMS - Back
            case "leftUpperArm": return CGPoint(x: centerX - width * 0.42, y: size.height * 0.35)
            case "rightUpperArm": return CGPoint(x: centerX + width * 0.42, y: size.height * 0.35)
            case "leftTriceps": return CGPoint(x: centerX - width * 0.43, y: size.height * 0.37)
            case "rightTriceps": return CGPoint(x: centerX + width * 0.43, y: size.height * 0.37)
            case "leftElbow": return CGPoint(x: centerX - width * 0.42, y: size.height * 0.43)
            case "rightElbow": return CGPoint(x: centerX + width * 0.42, y: size.height * 0.43)
            case "leftElbowBack": return CGPoint(x: centerX - width * 0.43, y: size.height * 0.44)
            case "rightElbowBack": return CGPoint(x: centerX + width * 0.43, y: size.height * 0.44)
            case "leftForearm": return CGPoint(x: centerX - width * 0.46, y: size.height * 0.48)
            case "rightForearm": return CGPoint(x: centerX + width * 0.46, y: size.height * 0.48)
            case "leftForearmBack": return CGPoint(x: centerX - width * 0.47, y: size.height * 0.49)
            case "rightForearmBack": return CGPoint(x: centerX + width * 0.47, y: size.height * 0.49)
            case "leftWrist": return CGPoint(x: centerX - width * 0.47, y: size.height * 0.54)
            case "rightWrist": return CGPoint(x: centerX + width * 0.47, y: size.height * 0.54)
            case "leftHand": return CGPoint(x: centerX - width * 0.48, y: size.height * 0.58)
            case "rightHand": return CGPoint(x: centerX + width * 0.48, y: size.height * 0.58)
            
            // LEGS - Back - Better spaced out
            case "leftThigh": return CGPoint(x: centerX - width * 0.25, y: size.height * 0.67)
            case "rightThigh": return CGPoint(x: centerX + width * 0.25, y: size.height * 0.67)
            case "leftThighBack": return CGPoint(x: centerX - width * 0.27, y: size.height * 0.68)
            case "rightThighBack": return CGPoint(x: centerX + width * 0.27, y: size.height * 0.68)
            case "leftHamstring": return CGPoint(x: centerX - width * 0.27, y: size.height * 0.65)
            case "rightHamstring": return CGPoint(x: centerX + width * 0.27, y: size.height * 0.65)
            case "leftKnee": return CGPoint(x: centerX - width * 0.25, y: size.height * 0.76)
            case "rightKnee": return CGPoint(x: centerX + width * 0.25, y: size.height * 0.76)
            case "leftKneeBack": return CGPoint(x: centerX - width * 0.27, y: size.height * 0.77)
            case "rightKneeBack": return CGPoint(x: centerX + width * 0.27, y: size.height * 0.77)
            case "leftShin": return CGPoint(x: centerX - width * 0.25, y: size.height * 0.83)
            case "rightShin": return CGPoint(x: centerX + width * 0.25, y: size.height * 0.83)
            case "leftCalf": return CGPoint(x: centerX - width * 0.27, y: size.height * 0.84)
            case "rightCalf": return CGPoint(x: centerX + width * 0.27, y: size.height * 0.84)
            case "leftGastrocnemius": return CGPoint(x: centerX - width * 0.28, y: size.height * 0.87)
            case "rightGastrocnemius": return CGPoint(x: centerX + width * 0.28, y: size.height * 0.87)
            // Ankles and feet - Much better spaced out
            case "leftAnkle": return CGPoint(x: centerX - width * 0.26, y: size.height * 0.92)
            case "rightAnkle": return CGPoint(x: centerX + width * 0.26, y: size.height * 0.92)
            case "leftFoot": return CGPoint(x: centerX - width * 0.28, y: size.height * 0.96)
            case "rightFoot": return CGPoint(x: centerX + width * 0.28, y: size.height * 0.96)
            case "leftHeel": return CGPoint(x: centerX - width * 0.30, y: size.height * 0.98)
            case "rightHeel": return CGPoint(x: centerX + width * 0.30, y: size.height * 0.98)
                
            default: return nil
            }
        }
    }
}

// MARK: - Human Body Outline Shape (Simple silhouette)

struct HumanBodyOutlineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.midX
        let width = rect.width * 0.50 // Increased from 0.35 to 0.50 for bigger body
        
        // Head (oval)
        let headRect = CGRect(x: centerX - width * 0.12, y: rect.height * 0.1 - 20, width: width * 0.24, height: 40)
        path.addEllipse(in: headRect)
        
        // Neck
        let neckRect = CGRect(x: centerX - width * 0.08, y: rect.height * 0.18, width: width * 0.16, height: 25)
        path.addRoundedRect(in: neckRect, cornerSize: CGSize(width: 8, height: 8))
        
        // Torso (chest and abdomen)
        let torsoTop = CGRect(x: centerX - width * 0.25, y: rect.height * 0.22, width: width * 0.5, height: rect.height * 0.32)
        path.addRoundedRect(in: torsoTop, cornerSize: CGSize(width: 15, height: 15))
        
        // Left Shoulder/Upper Arm
        let leftShoulderRect = CGRect(x: centerX - width * 0.48, y: rect.height * 0.22, width: width * 0.18, height: 25)
        path.addRoundedRect(in: leftShoulderRect, cornerSize: CGSize(width: 12, height: 12))
        
        // Right Shoulder/Upper Arm
        let rightShoulderRect = CGRect(x: centerX + width * 0.3, y: rect.height * 0.22, width: width * 0.18, height: 25)
        path.addRoundedRect(in: rightShoulderRect, cornerSize: CGSize(width: 12, height: 12))
        
        // Left Upper Arm
        let leftUpperArmRect = CGRect(x: centerX - width * 0.48, y: rect.height * 0.25, width: width * 0.08, height: rect.height * 0.18)
        path.addRoundedRect(in: leftUpperArmRect, cornerSize: CGSize(width: 4, height: 4))
        
        // Right Upper Arm
        let rightUpperArmRect = CGRect(x: centerX + width * 0.4, y: rect.height * 0.25, width: width * 0.08, height: rect.height * 0.18)
        path.addRoundedRect(in: rightUpperArmRect, cornerSize: CGSize(width: 4, height: 4))
        
        // Left Elbow
        let leftElbowRect = CGRect(x: centerX - width * 0.48, y: rect.height * 0.43, width: width * 0.12, height: 30)
        path.addEllipse(in: leftElbowRect)
        
        // Right Elbow
        let rightElbowRect = CGRect(x: centerX + width * 0.36, y: rect.height * 0.43, width: width * 0.12, height: 30)
        path.addEllipse(in: rightElbowRect)
        
        // Left Forearm
        let leftForearmRect = CGRect(x: centerX - width * 0.52, y: rect.height * 0.46, width: width * 0.06, height: rect.height * 0.18)
        path.addRoundedRect(in: leftForearmRect, cornerSize: CGSize(width: 3, height: 3))
        
        // Right Forearm
        let rightForearmRect = CGRect(x: centerX + width * 0.46, y: rect.height * 0.46, width: width * 0.06, height: rect.height * 0.18)
        path.addRoundedRect(in: rightForearmRect, cornerSize: CGSize(width: 3, height: 3))
        
        // Left Hand
        let leftHandRect = CGRect(x: centerX - width * 0.54, y: rect.height * 0.64, width: width * 0.12, height: 35)
        path.addEllipse(in: leftHandRect)
        
        // Right Hand
        let rightHandRect = CGRect(x: centerX + width * 0.42, y: rect.height * 0.64, width: width * 0.12, height: 35)
        path.addEllipse(in: rightHandRect)
        
        // Hips/Pelvis
        let hipRect = CGRect(x: centerX - width * 0.28, y: rect.height * 0.52, width: width * 0.56, height: 30)
        path.addRoundedRect(in: hipRect, cornerSize: CGSize(width: 15, height: 15))
        
        // Left Thigh
        let leftThighRect = CGRect(x: centerX - width * 0.28, y: rect.height * 0.65, width: width * 0.12, height: rect.height * 0.15)
        path.addRoundedRect(in: leftThighRect, cornerSize: CGSize(width: 6, height: 6))
        
        // Right Thigh
        let rightThighRect = CGRect(x: centerX + width * 0.16, y: rect.height * 0.65, width: width * 0.12, height: rect.height * 0.15)
        path.addRoundedRect(in: rightThighRect, cornerSize: CGSize(width: 6, height: 6))
        
        // Left Knee
        let leftKneeRect = CGRect(x: centerX - width * 0.28, y: rect.height * 0.75, width: width * 0.14, height: 35)
        path.addEllipse(in: leftKneeRect)
        
        // Right Knee
        let rightKneeRect = CGRect(x: centerX + width * 0.14, y: rect.height * 0.75, width: width * 0.14, height: 35)
        path.addEllipse(in: rightKneeRect)
        
        // Left Shin
        let leftShinRect = CGRect(x: centerX - width * 0.28, y: rect.height * 0.85, width: width * 0.1, height: rect.height * 0.1)
        path.addRoundedRect(in: leftShinRect, cornerSize: CGSize(width: 5, height: 5))
        
        // Right Shin
        let rightShinRect = CGRect(x: centerX + width * 0.18, y: rect.height * 0.85, width: width * 0.1, height: rect.height * 0.1)
        path.addRoundedRect(in: rightShinRect, cornerSize: CGSize(width: 5, height: 5))
        
        // Left Ankle
        let leftAnkleRect = CGRect(x: centerX - width * 0.28, y: rect.height * 0.935, width: width * 0.1, height: 20)
        path.addEllipse(in: leftAnkleRect)
        
        // Right Ankle
        let rightAnkleRect = CGRect(x: centerX + width * 0.18, y: rect.height * 0.935, width: width * 0.1, height: 20)
        path.addEllipse(in: rightAnkleRect)
        
        // Left Foot
        let leftFootRect = CGRect(x: centerX - width * 0.28, y: rect.height * 0.95, width: width * 0.12, height: 25)
        path.addRoundedRect(in: leftFootRect, cornerSize: CGSize(width: 8, height: 8))
        
        // Right Foot
        let rightFootRect = CGRect(x: centerX + width * 0.16, y: rect.height * 0.95, width: width * 0.12, height: 25)
        path.addRoundedRect(in: rightFootRect, cornerSize: CGSize(width: 8, height: 8))
        
        return path
    }
}

// MARK: - Body Regions Data

func createBodyRegions() -> [BodyRegion] {
    [
        // HEAD REGIONS (visible from both sides)
        BodyRegion(name: "Head", systemName: "head", regionPath: "head", educationalBlurb: "The head houses your brain, eyes, ears, and sinuses. Stay hydrated and manage stress to support healthy function.", side: .front),
        BodyRegion(name: "Forehead", systemName: "head", regionPath: "forehead", educationalBlurb: "Forehead tension often relates to stress or headaches. Rest and hydration can help.", side: .front),
        BodyRegion(name: "Left Temple", systemName: "head", regionPath: "leftTemple", educationalBlurb: "Temple pain can indicate migraines, tension headaches, or sinus issues.", side: .front),
        BodyRegion(name: "Right Temple", systemName: "head", regionPath: "rightTemple", educationalBlurb: "Temple pain can indicate migraines, tension headaches, or sinus issues.", side: .front),
        BodyRegion(name: "Left Temple", systemName: "head", regionPath: "leftTemple", educationalBlurb: "Temple pain can indicate migraines, tension headaches, or sinus issues.", side: .back),
        BodyRegion(name: "Right Temple", systemName: "head", regionPath: "rightTemple", educationalBlurb: "Temple pain can indicate migraines, tension headaches, or sinus issues.", side: .back),
        BodyRegion(name: "Head", systemName: "head", regionPath: "head", educationalBlurb: "The head houses your brain, eyes, ears, and sinuses. Stay hydrated and manage stress to support healthy function.", side: .back),
        BodyRegion(name: "Chin", systemName: "face", regionPath: "chin", educationalBlurb: "Chin pain may relate to jaw issues or TMJ disorders. Gentle exercises can help.", side: .front),
        BodyRegion(name: "Jaw", systemName: "jaw", regionPath: "jaw", educationalBlurb: "Jaw pain often relates to TMJ disorders. Avoid clenching and consider gentle stretches.", side: .front),
        
        // NECK
        BodyRegion(name: "Neck Front", systemName: "neck", regionPath: "neckFront", educationalBlurb: "Front neck pain may relate to thyroid or muscle tension. Good posture helps.", side: .front),
        BodyRegion(name: "Neck Back", systemName: "neck", regionPath: "neckBack", educationalBlurb: "Back neck pain often relates to posture. Strengthening exercises can help.", side: .back),
        BodyRegion(name: "Cervical Spine", systemName: "back", regionPath: "cervicalSpine", educationalBlurb: "Cervical spine (neck) issues can cause pain radiating to arms. Good posture is crucial.", side: .back),
        
        // SHOULDERS AND UPPER BODY - Front
        BodyRegion(name: "Left Clavicle", systemName: "shoulder.left", regionPath: "leftClavicle", educationalBlurb: "Clavicle (collar bone) pain may result from injury or posture. Rest if injured.", side: .front),
        BodyRegion(name: "Right Clavicle", systemName: "shoulder.right", regionPath: "rightClavicle", educationalBlurb: "Clavicle (collar bone) pain may result from injury or posture. Rest if injured.", side: .front),
        BodyRegion(name: "Left Shoulder", systemName: "shoulder.left", regionPath: "leftShoulder", educationalBlurb: "Shoulder pain can stem from rotator cuff issues. Range of motion exercises help.", side: .front),
        BodyRegion(name: "Right Shoulder", systemName: "shoulder.right", regionPath: "rightShoulder", educationalBlurb: "Shoulder pain can stem from rotator cuff issues. Range of motion exercises help.", side: .front),
        BodyRegion(name: "Left Deltoid", systemName: "shoulder.left", regionPath: "leftDeltoid", educationalBlurb: "Deltoid (shoulder muscle) pain may relate to overuse. Range of motion exercises help.", side: .front),
        BodyRegion(name: "Right Deltoid", systemName: "shoulder.right", regionPath: "rightDeltoid", educationalBlurb: "Deltoid (shoulder muscle) pain may relate to overuse. Range of motion exercises help.", side: .front),
        
        // SHOULDERS - Back
        BodyRegion(name: "Left Shoulder", systemName: "shoulder.left", regionPath: "leftShoulder", educationalBlurb: "Shoulder pain can stem from rotator cuff issues. Range of motion exercises help.", side: .back),
        BodyRegion(name: "Right Shoulder", systemName: "shoulder.right", regionPath: "rightShoulder", educationalBlurb: "Shoulder pain can stem from rotator cuff issues. Range of motion exercises help.", side: .back),
        BodyRegion(name: "Left Shoulder Blade", systemName: "shoulder.left", regionPath: "leftShoulderBlade", educationalBlurb: "Shoulder blade pain often relates to posture or muscle tension. Stretching helps.", side: .back),
        BodyRegion(name: "Right Shoulder Blade", systemName: "shoulder.right", regionPath: "rightShoulderBlade", educationalBlurb: "Shoulder blade pain often relates to posture or muscle tension. Stretching helps.", side: .back),
        BodyRegion(name: "Left Deltoid", systemName: "shoulder.left", regionPath: "leftDeltoid", educationalBlurb: "Deltoid (shoulder muscle) pain may relate to overuse. Range of motion exercises help.", side: .back),
        BodyRegion(name: "Right Deltoid", systemName: "shoulder.right", regionPath: "rightDeltoid", educationalBlurb: "Deltoid (shoulder muscle) pain may relate to overuse. Range of motion exercises help.", side: .back),
        
        // CHEST AND BACK
        BodyRegion(name: "Chest", systemName: "chest", regionPath: "chest", educationalBlurb: "Chest pain requires immediate medical attention if severe. May relate to heart, lungs, or muscle.", side: .front),
        BodyRegion(name: "Sternum", systemName: "chest", regionPath: "sternum", educationalBlurb: "Sternum (breastbone) pain may relate to costochondritis or injury.", side: .front),
        BodyRegion(name: "Left Ribs", systemName: "chest", regionPath: "leftRibs", educationalBlurb: "Rib pain may indicate injury, inflammation, or muscle strain. Rest if severe.", side: .front),
        BodyRegion(name: "Right Ribs", systemName: "chest", regionPath: "rightRibs", educationalBlurb: "Rib pain may indicate injury, inflammation, or muscle strain. Rest if severe.", side: .front),
        BodyRegion(name: "Upper Back", systemName: "back", regionPath: "upperBack", educationalBlurb: "Upper back pain often relates to posture. Strengthening exercises help.", side: .back),
        BodyRegion(name: "Middle Back", systemName: "back", regionPath: "middleBack", educationalBlurb: "Middle back pain may relate to posture or muscle strain. Core exercises help.", side: .back),
        BodyRegion(name: "Lower Back", systemName: "lower.back", regionPath: "lowerBack", educationalBlurb: "Lower back pain is common. Core strength and proper lifting techniques protect it.", side: .back),
        BodyRegion(name: "Thoracic Spine", systemName: "back", regionPath: "thoracicSpine", educationalBlurb: "Thoracic spine (mid-back) pain often relates to posture. Stretching helps.", side: .back),
        BodyRegion(name: "Lumbar Spine", systemName: "lower.back", regionPath: "lumbarSpine", educationalBlurb: "Lumbar spine (lower back) supports the upper body. Core strength protects it.", side: .back),
        BodyRegion(name: "Sacral Spine", systemName: "lower.back", regionPath: "sacralSpine", educationalBlurb: "Sacral spine pain may relate to posture or sitting. Movement and stretches help.", side: .back),
        
        // ABDOMEN - Front
        BodyRegion(name: "Abdomen", systemName: "abdomen", regionPath: "abdomen", educationalBlurb: "Abdominal pain may relate to digestive issues. Note other symptoms.", side: .front),
        BodyRegion(name: "Upper Abdomen", systemName: "abdomen", regionPath: "upperAbdomen", educationalBlurb: "Upper abdominal pain may relate to stomach, liver, or gallbladder issues.", side: .front),
        BodyRegion(name: "Lower Abdomen", systemName: "abdomen", regionPath: "lowerAbdomen", educationalBlurb: "Lower abdominal pain may relate to intestines or reproductive organs.", side: .front),
        
        // HIPS AND PELVIS
        BodyRegion(name: "Hips", systemName: "hip", regionPath: "hips", educationalBlurb: "Hip pain may relate to joint issues, bursitis, or muscle strain. Movement helps.", side: .front),
        BodyRegion(name: "Left Hip", systemName: "hip.left", regionPath: "leftHip", educationalBlurb: "Left hip pain may relate to joint or muscle issues. Stretching helps.", side: .front),
        BodyRegion(name: "Right Hip", systemName: "hip.right", regionPath: "rightHip", educationalBlurb: "Right hip pain may relate to joint or muscle issues. Stretching helps.", side: .front),
        BodyRegion(name: "Pelvis", systemName: "pelvis", regionPath: "pelvis", educationalBlurb: "Pelvic pain may relate to joint, muscle, or reproductive health. Consult healthcare provider if persistent.", side: .front),
        BodyRegion(name: "Hips", systemName: "hip", regionPath: "hips", educationalBlurb: "Hip pain may relate to joint issues, bursitis, or muscle strain. Movement helps.", side: .back),
        BodyRegion(name: "Left Hip", systemName: "hip.left", regionPath: "leftHip", educationalBlurb: "Left hip pain may relate to joint or muscle issues. Stretching helps.", side: .back),
        BodyRegion(name: "Right Hip", systemName: "hip.right", regionPath: "rightHip", educationalBlurb: "Right hip pain may relate to joint or muscle issues. Stretching helps.", side: .back),
        BodyRegion(name: "Pelvis", systemName: "pelvis", regionPath: "pelvis", educationalBlurb: "Pelvic pain may relate to joint, muscle, or reproductive health. Consult healthcare provider if persistent.", side: .back),
        
        // ARMS - UPPER - Front
        BodyRegion(name: "Left Upper Arm", systemName: "arm.left", regionPath: "leftUpperArm", educationalBlurb: "Upper arm pain may relate to muscle strain or overuse. Rest if needed.", side: .front),
        BodyRegion(name: "Right Upper Arm", systemName: "arm.right", regionPath: "rightUpperArm", educationalBlurb: "Upper arm pain may relate to muscle strain or overuse. Rest if needed.", side: .front),
        BodyRegion(name: "Left Biceps", systemName: "arm.left", regionPath: "leftBiceps", educationalBlurb: "Biceps pain often relates to overuse or strain. Rest and gentle stretches help.", side: .front),
        BodyRegion(name: "Right Biceps", systemName: "arm.right", regionPath: "rightBiceps", educationalBlurb: "Biceps pain often relates to overuse or strain. Rest and gentle stretches help.", side: .front),
        BodyRegion(name: "Left Triceps", systemName: "arm.left", regionPath: "leftTriceps", educationalBlurb: "Triceps pain may relate to overuse. Rest and gentle stretching help.", side: .front),
        BodyRegion(name: "Right Triceps", systemName: "arm.right", regionPath: "rightTriceps", educationalBlurb: "Triceps pain may relate to overuse. Rest and gentle stretching help.", side: .front),
        BodyRegion(name: "Left Upper Arm", systemName: "arm.left", regionPath: "leftUpperArm", educationalBlurb: "Upper arm pain may relate to muscle strain or overuse. Rest if needed.", side: .back),
        BodyRegion(name: "Right Upper Arm", systemName: "arm.right", regionPath: "rightUpperArm", educationalBlurb: "Upper arm pain may relate to muscle strain or overuse. Rest if needed.", side: .back),
        BodyRegion(name: "Left Triceps", systemName: "arm.left", regionPath: "leftTriceps", educationalBlurb: "Triceps pain may relate to overuse. Rest and gentle stretching help.", side: .back),
        BodyRegion(name: "Right Triceps", systemName: "arm.right", regionPath: "rightTriceps", educationalBlurb: "Triceps pain may relate to overuse. Rest and gentle stretching help.", side: .back),
        
        // ARMS - ELBOWS
        BodyRegion(name: "Left Elbow", systemName: "elbow.left", regionPath: "leftElbow", educationalBlurb: "Elbow pain may relate to tennis elbow, golfer's elbow, or overuse. Rest helps.", side: .front),
        BodyRegion(name: "Right Elbow", systemName: "elbow.right", regionPath: "rightElbow", educationalBlurb: "Elbow pain may relate to tennis elbow, golfer's elbow, or overuse. Rest helps.", side: .front),
        BodyRegion(name: "Left Elbow", systemName: "elbow.left", regionPath: "leftElbow", educationalBlurb: "Elbow pain may relate to tennis elbow, golfer's elbow, or overuse. Rest helps.", side: .back),
        BodyRegion(name: "Right Elbow", systemName: "elbow.right", regionPath: "rightElbow", educationalBlurb: "Elbow pain may relate to tennis elbow, golfer's elbow, or overuse. Rest helps.", side: .back),
        BodyRegion(name: "Left Elbow", systemName: "elbow.left", regionPath: "leftElbowBack", educationalBlurb: "Back of elbow pain may relate to triceps strain or overuse. Rest helps.", side: .back),
        BodyRegion(name: "Right Elbow", systemName: "elbow.right", regionPath: "rightElbowBack", educationalBlurb: "Back of elbow pain may relate to triceps strain or overuse. Rest helps.", side: .back),
        
        // ARMS - FOREARMS
        BodyRegion(name: "Left Forearm", systemName: "forearm.left", regionPath: "leftForearm", educationalBlurb: "Forearm pain may relate to repetitive strain. Ergonomic adjustments help.", side: .front),
        BodyRegion(name: "Right Forearm", systemName: "forearm.right", regionPath: "rightForearm", educationalBlurb: "Forearm pain may relate to repetitive strain. Ergonomic adjustments help.", side: .front),
        BodyRegion(name: "Left Forearm", systemName: "forearm.left", regionPath: "leftForearm", educationalBlurb: "Forearm pain may relate to repetitive strain. Ergonomic adjustments help.", side: .back),
        BodyRegion(name: "Right Forearm", systemName: "forearm.right", regionPath: "rightForearm", educationalBlurb: "Forearm pain may relate to repetitive strain. Ergonomic adjustments help.", side: .back),
        BodyRegion(name: "Left Forearm", systemName: "forearm.left", regionPath: "leftForearmBack", educationalBlurb: "Back of forearm pain may relate to muscle strain. Rest helps.", side: .back),
        BodyRegion(name: "Right Forearm", systemName: "forearm.right", regionPath: "rightForearmBack", educationalBlurb: "Back of forearm pain may relate to muscle strain. Rest helps.", side: .back),
        
        // ARMS - WRISTS AND HANDS
        BodyRegion(name: "Left Wrist", systemName: "wrist.left", regionPath: "leftWrist", educationalBlurb: "Wrist pain may relate to carpal tunnel or repetitive strain. Ergonomic setups help.", side: .front),
        BodyRegion(name: "Right Wrist", systemName: "wrist.right", regionPath: "rightWrist", educationalBlurb: "Wrist pain may relate to carpal tunnel or repetitive strain. Ergonomic setups help.", side: .front),
        BodyRegion(name: "Left Hand", systemName: "hand.left", regionPath: "leftHand", educationalBlurb: "Hand pain may relate to arthritis, overuse, or injury. Rest breaks help.", side: .front),
        BodyRegion(name: "Right Hand", systemName: "hand.right", regionPath: "rightHand", educationalBlurb: "Hand pain may relate to arthritis, overuse, or injury. Rest breaks help.", side: .front),
        BodyRegion(name: "Left Palm", systemName: "hand.left", regionPath: "leftPalm", educationalBlurb: "Palm pain may relate to repetitive strain. Ergonomic tools help.", side: .front),
        BodyRegion(name: "Right Palm", systemName: "hand.right", regionPath: "rightPalm", educationalBlurb: "Palm pain may relate to repetitive strain. Ergonomic tools help.", side: .front),
        BodyRegion(name: "Left Wrist", systemName: "wrist.left", regionPath: "leftWrist", educationalBlurb: "Wrist pain may relate to carpal tunnel or repetitive strain. Ergonomic setups help.", side: .back),
        BodyRegion(name: "Right Wrist", systemName: "wrist.right", regionPath: "rightWrist", educationalBlurb: "Wrist pain may relate to carpal tunnel or repetitive strain. Ergonomic setups help.", side: .back),
        BodyRegion(name: "Left Hand", systemName: "hand.left", regionPath: "leftHand", educationalBlurb: "Hand pain may relate to arthritis, overuse, or injury. Rest breaks help.", side: .back),
        BodyRegion(name: "Right Hand", systemName: "hand.right", regionPath: "rightHand", educationalBlurb: "Hand pain may relate to arthritis, overuse, or injury. Rest breaks help.", side: .back),
        
        // LEGS - THIGHS - Front
        BodyRegion(name: "Left Thigh", systemName: "leg.left", regionPath: "leftThigh", educationalBlurb: "Thigh pain may relate to muscle strain or overuse. Stretching helps.", side: .front),
        BodyRegion(name: "Right Thigh", systemName: "leg.right", regionPath: "rightThigh", educationalBlurb: "Thigh pain may relate to muscle strain or overuse. Stretching helps.", side: .front),
        BodyRegion(name: "Left Femur", systemName: "leg.left", regionPath: "leftFemur", educationalBlurb: "Femur (thigh bone) pain requires medical attention. May indicate serious injury.", side: .front),
        BodyRegion(name: "Right Femur", systemName: "leg.right", regionPath: "rightFemur", educationalBlurb: "Femur (thigh bone) pain requires medical attention. May indicate serious injury.", side: .front),
        BodyRegion(name: "Left Quadriceps", systemName: "leg.left", regionPath: "leftQuadriceps", educationalBlurb: "Quadriceps (front thigh) pain often relates to overuse. Rest and stretching help.", side: .front),
        BodyRegion(name: "Right Quadriceps", systemName: "leg.right", regionPath: "rightQuadriceps", educationalBlurb: "Quadriceps (front thigh) pain often relates to overuse. Rest and stretching help.", side: .front),
        BodyRegion(name: "Left Inner Thigh", systemName: "leg.left", regionPath: "leftInnerThigh", educationalBlurb: "Inner thigh pain may relate to groin strain. Gentle stretches help.", side: .front),
        BodyRegion(name: "Right Inner Thigh", systemName: "leg.right", regionPath: "rightInnerThigh", educationalBlurb: "Inner thigh pain may relate to groin strain. Gentle stretches help.", side: .front),
        BodyRegion(name: "Left Outer Thigh", systemName: "leg.left", regionPath: "leftOuterThigh", educationalBlurb: "Outer thigh pain may relate to IT band issues. Foam rolling helps.", side: .front),
        BodyRegion(name: "Right Outer Thigh", systemName: "leg.right", regionPath: "rightOuterThigh", educationalBlurb: "Outer thigh pain may relate to IT band issues. Foam rolling helps.", side: .front),
        
        // LEGS - THIGHS - Back
        BodyRegion(name: "Left Thigh", systemName: "leg.left", regionPath: "leftThigh", educationalBlurb: "Thigh pain may relate to muscle strain or overuse. Stretching helps.", side: .back),
        BodyRegion(name: "Right Thigh", systemName: "leg.right", regionPath: "rightThigh", educationalBlurb: "Thigh pain may relate to muscle strain or overuse. Stretching helps.", side: .back),
        BodyRegion(name: "Left Thigh", systemName: "leg.left", regionPath: "leftThighBack", educationalBlurb: "Back of thigh pain may relate to hamstring strain. Gentle stretching helps.", side: .back),
        BodyRegion(name: "Right Thigh", systemName: "leg.right", regionPath: "rightThighBack", educationalBlurb: "Back of thigh pain may relate to hamstring strain. Gentle stretching helps.", side: .back),
        BodyRegion(name: "Left Hamstring", systemName: "leg.left", regionPath: "leftHamstring", educationalBlurb: "Hamstring (back thigh) pain often relates to strain. Gentle stretching helps.", side: .back),
        BodyRegion(name: "Right Hamstring", systemName: "leg.right", regionPath: "rightHamstring", educationalBlurb: "Hamstring (back thigh) pain often relates to strain. Gentle stretching helps.", side: .back),
        
        // LEGS - KNEES
        BodyRegion(name: "Left Knee", systemName: "knee.left", regionPath: "leftKnee", educationalBlurb: "Knee pain may relate to injury, arthritis, or overuse. Low-impact activities help.", side: .front),
        BodyRegion(name: "Right Knee", systemName: "knee.right", regionPath: "rightKnee", educationalBlurb: "Knee pain may relate to injury, arthritis, or overuse. Low-impact activities help.", side: .front),
        BodyRegion(name: "Left Knee Cap", systemName: "knee.left", regionPath: "leftKneeCap", educationalBlurb: "Kneecap pain may relate to patellofemoral syndrome. Strengthening exercises help.", side: .front),
        BodyRegion(name: "Right Knee Cap", systemName: "knee.right", regionPath: "rightKneeCap", educationalBlurb: "Kneecap pain may relate to patellofemoral syndrome. Strengthening exercises help.", side: .front),
        BodyRegion(name: "Left Knee", systemName: "knee.left", regionPath: "leftKnee", educationalBlurb: "Knee pain may relate to injury, arthritis, or overuse. Low-impact activities help.", side: .back),
        BodyRegion(name: "Right Knee", systemName: "knee.right", regionPath: "rightKnee", educationalBlurb: "Knee pain may relate to injury, arthritis, or overuse. Low-impact activities help.", side: .back),
        BodyRegion(name: "Left Knee", systemName: "knee.left", regionPath: "leftKneeBack", educationalBlurb: "Back of knee pain may relate to popliteal issues. Rest and gentle stretching help.", side: .back),
        BodyRegion(name: "Right Knee", systemName: "knee.right", regionPath: "rightKneeBack", educationalBlurb: "Back of knee pain may relate to popliteal issues. Rest and gentle stretching help.", side: .back),
        
        // LEGS - SHINS AND CALVES
        BodyRegion(name: "Left Shin", systemName: "shin.left", regionPath: "leftShin", educationalBlurb: "Shin pain may relate to shin splints. Rest and proper footwear help.", side: .front),
        BodyRegion(name: "Right Shin", systemName: "shin.right", regionPath: "rightShin", educationalBlurb: "Shin pain may relate to shin splints. Rest and proper footwear help.", side: .front),
        BodyRegion(name: "Left Calf", systemName: "leg.left", regionPath: "leftCalf", educationalBlurb: "Calf pain may relate to strain or tightness. Gentle stretching helps.", side: .front),
        BodyRegion(name: "Right Calf", systemName: "leg.right", regionPath: "rightCalf", educationalBlurb: "Calf pain may relate to strain or tightness. Gentle stretching helps.", side: .front),
        BodyRegion(name: "Left Gastrocnemius", systemName: "leg.left", regionPath: "leftGastrocnemius", educationalBlurb: "Gastrocnemius (calf muscle) pain may relate to strain. Rest and stretching help.", side: .front),
        BodyRegion(name: "Right Gastrocnemius", systemName: "leg.right", regionPath: "rightGastrocnemius", educationalBlurb: "Gastrocnemius (calf muscle) pain may relate to strain. Rest and stretching help.", side: .front),
        BodyRegion(name: "Left Shin", systemName: "shin.left", regionPath: "leftShin", educationalBlurb: "Shin pain may relate to shin splints. Rest and proper footwear help.", side: .back),
        BodyRegion(name: "Right Shin", systemName: "shin.right", regionPath: "rightShin", educationalBlurb: "Shin pain may relate to shin splints. Rest and proper footwear help.", side: .back),
        BodyRegion(name: "Left Calf", systemName: "leg.left", regionPath: "leftCalf", educationalBlurb: "Calf pain may relate to strain or tightness. Gentle stretching helps.", side: .back),
        BodyRegion(name: "Right Calf", systemName: "leg.right", regionPath: "rightCalf", educationalBlurb: "Calf pain may relate to strain or tightness. Gentle stretching helps.", side: .back),
        BodyRegion(name: "Left Gastrocnemius", systemName: "leg.left", regionPath: "leftGastrocnemius", educationalBlurb: "Gastrocnemius (calf muscle) pain may relate to strain. Rest and stretching help.", side: .back),
        BodyRegion(name: "Right Gastrocnemius", systemName: "leg.right", regionPath: "rightGastrocnemius", educationalBlurb: "Gastrocnemius (calf muscle) pain may relate to strain. Rest and stretching help.", side: .back),
        
        // LEGS - ANKLES AND FEET
        BodyRegion(name: "Left Ankle", systemName: "ankle.left", regionPath: "leftAnkle", educationalBlurb: "Ankle pain may relate to sprain, arthritis, or overuse. Rest and proper footwear help.", side: .front),
        BodyRegion(name: "Right Ankle", systemName: "ankle.right", regionPath: "rightAnkle", educationalBlurb: "Ankle pain may relate to sprain, arthritis, or overuse. Rest and proper footwear help.", side: .front),
        BodyRegion(name: "Left Foot", systemName: "foot.left", regionPath: "leftFoot", educationalBlurb: "Foot pain may relate to plantar fasciitis, injury, or overuse. Proper footwear helps.", side: .front),
        BodyRegion(name: "Right Foot", systemName: "foot.right", regionPath: "rightFoot", educationalBlurb: "Foot pain may relate to plantar fasciitis, injury, or overuse. Proper footwear helps.", side: .front),
        BodyRegion(name: "Left Heel", systemName: "foot.left", regionPath: "leftHeel", educationalBlurb: "Heel pain often relates to plantar fasciitis. Stretching and proper footwear help.", side: .front),
        BodyRegion(name: "Right Heel", systemName: "foot.right", regionPath: "rightHeel", educationalBlurb: "Heel pain often relates to plantar fasciitis. Stretching and proper footwear help.", side: .front),
        BodyRegion(name: "Left Arch", systemName: "foot.left", regionPath: "leftArch", educationalBlurb: "Arch pain may relate to plantar fasciitis or flat feet. Proper footwear helps.", side: .front),
        BodyRegion(name: "Right Arch", systemName: "foot.right", regionPath: "rightArch", educationalBlurb: "Arch pain may relate to plantar fasciitis or flat feet. Proper footwear helps.", side: .front),
        BodyRegion(name: "Left Ankle", systemName: "ankle.left", regionPath: "leftAnkle", educationalBlurb: "Ankle pain may relate to sprain, arthritis, or overuse. Rest and proper footwear help.", side: .back),
        BodyRegion(name: "Right Ankle", systemName: "ankle.right", regionPath: "rightAnkle", educationalBlurb: "Ankle pain may relate to sprain, arthritis, or overuse. Rest and proper footwear help.", side: .back),
        BodyRegion(name: "Left Foot", systemName: "foot.left", regionPath: "leftFoot", educationalBlurb: "Foot pain may relate to plantar fasciitis, injury, or overuse. Proper footwear helps.", side: .back),
        BodyRegion(name: "Right Foot", systemName: "foot.right", regionPath: "rightFoot", educationalBlurb: "Foot pain may relate to plantar fasciitis, injury, or overuse. Proper footwear helps.", side: .back),
        BodyRegion(name: "Left Heel", systemName: "foot.left", regionPath: "leftHeel", educationalBlurb: "Heel pain often relates to plantar fasciitis. Stretching and proper footwear help.", side: .back),
        BodyRegion(name: "Right Heel", systemName: "foot.right", regionPath: "rightHeel", educationalBlurb: "Heel pain often relates to plantar fasciitis. Stretching and proper footwear help.", side: .back)
    ]
}

// MARK: - Detail Panel

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
            ScrollView {
                VStack(spacing: 20) {
                    // Enhanced Header with Icon
                    VStack(spacing: 12) {
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
                            }
                            
                            Spacer()
                            
                            Button(action: onDismiss) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        
                        // Description in its own section for full visibility
                        Text(region.educationalBlurb)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
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
                                        Group {
                                            if painType == type {
                                        Capsule()
                                            .fill(
                                                        LinearGradient(
                                                        colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.4)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                    )
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                            } else {
                                                Capsule()
                                                    .fill(Color.white.opacity(0.1))
                                            .overlay(
                                                Capsule()
                                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                                    )
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                
                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text("Duration")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    
                    TextField("e.g., 2 hours, 3 days", text: $duration)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .foregroundStyle(.white)
                                .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text("Notes")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    
                    TextField("Additional details...", text: $notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .foregroundStyle(.white)
                        .lineLimit(3...6)
                                .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                }
                
                // Send to Pulse button
                Button {
                    onSendToPulse()
                    Hx.strong()
                    buttonTapCount += 1
                } label: {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Send to Pulse Chat")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                }
                .padding(20)
            }
        }
    }
}
