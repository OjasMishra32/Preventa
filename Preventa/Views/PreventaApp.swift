import SwiftUI
import Firebase
import FirebaseAuth
import UserNotifications

@main
struct PreventaApp: App {
    @StateObject private var quizManager = QuizManager()
    @StateObject private var medStore = MedTrackerStore()
    @State private var isLoggedIn = false
    @State private var showPermissions = false
    
    // Singletons - don't use @StateObject, pass directly to environment
    private let healthManager = HealthKitManager.shared
    private let foodTracker = FoodTrackerManager.shared
    private let waterTracker = WaterTrackerManager.shared

    init() {
        FirebaseApp.configure()
        requestNotificationPermission()
        // Check initial auth state immediately
        checkInitialAuthState()
    }
    
    private func checkInitialAuthState() {
        if let user = Auth.auth().currentUser, user.isEmailVerified {
            isLoggedIn = true
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if isLoggedIn {
                    ZStack {
                        HomeView()
                        
                        if showPermissions {
                            PermissionsView(
                                showHealth: !healthManager.isAuthorized,
                                onDismiss: { showPermissions = false }
                            )
                            .transition(.opacity)
                            .zIndex(1)
                        }
                    }
                } else {
                    ContentView() // login page
                }
            }
            .environmentObject(quizManager)
            .environmentObject(medStore)
            .environmentObject(healthManager)
            .environmentObject(foodTracker)
            .environmentObject(waterTracker)
            .task {
                // Refresh authorization status when app opens
                healthManager.checkAuthorizationStatus()
                
                // Initialize FoodTrackerManager after Firebase is configured
                if let user = Auth.auth().currentUser, user.isEmailVerified {
                    foodTracker.initialize()
                }
                
                // 🔑 Keep listening to login/logout state changes
                Auth.auth().addStateDidChangeListener { _, user in
                    if let user = user, user.isEmailVerified {
                        isLoggedIn = true
                        // Initialize food tracker when user logs in
                        foodTracker.initialize()
                        
                        // Refresh authorization status on login
                        healthManager.checkAuthorizationStatus()
                        
                        // Only show permissions if truly not authorized (after checking status)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            // Double-check authorization status after a brief delay
                            healthManager.checkAuthorizationStatus()
                            if !healthManager.isAuthorized {
                                showPermissions = true
                            }
                        }
                    } else {
                        isLoggedIn = false
                    }
                }
            }
            .onAppear {
                // Refresh authorization status when app appears
                healthManager.checkAuthorizationStatus()
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}
