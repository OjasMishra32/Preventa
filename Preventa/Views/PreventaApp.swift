import SwiftUI
import Firebase
import FirebaseAuth

@main
struct PreventaApp: App {
    @StateObject private var quizManager = QuizManager()
    @StateObject private var medStore = MedTrackerStore()
    @State private var isLoggedIn = false

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if isLoggedIn {
                    HomeView()
                } else {
                    ContentView() // login page
                }
            }
            .environmentObject(quizManager)
            .environmentObject(medStore)
            .onAppear {
                // 🔑 Keep listening to login/logout state changes
                Auth.auth().addStateDidChangeListener { _, user in
                    if let user = user, user.isEmailVerified {
                        isLoggedIn = true
                    } else {
                        isLoggedIn = false
                    }
                }
            }
        }
    }
}
