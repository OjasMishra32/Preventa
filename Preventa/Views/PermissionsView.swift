import SwiftUI
import UserNotifications

struct PermissionsView: View {
    let showHealth: Bool
    let onDismiss: () -> Void
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var requestingHealth = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        onDismiss()
                    }
                }
            
            VStack(spacing: 0) {
                Spacer()
                
                GlassCard(expand: false) {
                    VStack(spacing: 24) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Enable Health Features")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        
                        Text("Connect with Apple Health to get personalized insights and track your wellness journey.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        
                        if showHealth {
                            Button {
                                print("🔵 UI: Connect Apple Health button tapped in PermissionsView")
                                requestingHealth = true
                                Task { @MainActor in
                                    let authorized = await healthManager.requestAuthorization()
                                    requestingHealth = false
                                    print("🔵 UI: Authorization result: \(authorized)")
                                    
                                    // Update authorization status manually
                                    healthManager.checkAuthorizationStatus()
                                    
                                    if authorized {
                                        Hx.ok()
                                        // Small delay to ensure state is updated
                                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                        withAnimation(.spring()) {
                                            onDismiss()
                                        }
                                    } else {
                                        // Still try to load data and dismiss - user might have granted access
                                        healthManager.loadHealthData()
                                        try? await Task.sleep(nanoseconds: 100_000_000)
                                        Hx.warn()
                                        withAnimation(.spring()) {
                                            onDismiss()
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    if requestingHealth {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "applewatch")
                                        Text("Connect Apple Health")
                                            .fontWeight(.semibold)
                                    }
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                            }
                            .disabled(requestingHealth)
                        }
                        
                        Button {
                            withAnimation(.spring()) {
                                onDismiss()
                            }
                        } label: {
                            Text("Maybe Later")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(28)
                }
                .padding(.horizontal, 32)
                .transition(.scale.combined(with: .opacity))
                
                Spacer()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showHealth)
    }
}

#Preview {
    PermissionsView(showHealth: true, onDismiss: {})
}

