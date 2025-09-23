import SwiftUI
import Firebase
import FirebaseAuth

@main
struct PreventaApp: App {
    init() {
        FirebaseApp.configure()
    }

    @StateObject private var quizManager = QuizManager()
    @StateObject private var medStore = MedTrackerStore()
    @State private var isLoggedIn = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if isLoggedIn {
                    HomeView()
                        .environmentObject(quizManager)
                        .environmentObject(medStore)
                } else {
                    ContentView()
                        .environmentObject(quizManager)
                        .environmentObject(medStore)
                }
            }
            .onAppear {
                // ✅ check auth once at app start
                if let user = Auth.auth().currentUser,
                   user.isEmailVerified {
                    isLoggedIn = true
                }
            }
        }
    }
}
