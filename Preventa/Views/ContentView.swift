import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSecure: Bool = true
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Logo and Title
                    VStack(spacing: 10) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Circle().fill(.white.opacity(0.15)))
                        Text("Preventa")
                            .font(.system(.largeTitle, design: .rounded)).bold()
                            .foregroundStyle(.white)
                        Text("Your proactive health companion")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.bottom, 10)

                    // Auth fields and buttons
                    VStack(spacing: 16) {
                        AuthField(icon: "envelope.fill", placeholder: "Email", text: $email, isSecure: .constant(false))
                        AuthField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: $isSecure)

                        HStack {
                            Spacer()
                            NavigationLink("Forgot password?") {
                                ForgotPasswordView()
                            }
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.white.opacity(0.9))
                        }

                        Button {
                            guard isValidEmail(email) else { show("Please enter a valid email."); return }
                            guard password.count >= 6 else { show("Password must be at least 6 characters."); return }
                            signIn(email: email, password: password)
                        } label: {
                            PrimaryButtonLabel(title: "Sign In")
                        }

                        OrDivider()

                        NavigationLink {
                            SignUpView()
                        } label: {
                            SecondaryButtonLabel(title: "Create Account")
                        }

                        Button {
                            show("Continuing as guest (demo).")
                        } label: {
                            Text("Continue as Guest")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.95))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(.white.opacity(0.35), lineWidth: 1.2)
                                )
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 25, y: 12)
                    .padding(.horizontal, 28)

                    Spacer()
                }
                .padding(.top, 40)
            }
            .alert("Preventa", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Helper Functions

    private func show(_ message: String) {
        alertMessage = message
        showAlert = true
    }

    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }

    private func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                show("Sign-in failed: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user else {
                show("User not found.")
                return
            }

            if user.isEmailVerified {
                show("Signed in successfully.")
            } else {
                show("Please verify your email before signing in.")
            }
        }
    }
}

#Preview {
    ContentView()
}
