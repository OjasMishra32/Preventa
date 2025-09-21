import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSecure: Bool = true
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var goHome = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.8)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())                 // makes the whole bg tappable
                    .onTapGesture { dismissKeyboard() }        // tap outside to hide keyboard

                VStack(spacing: 24) {
                    // logo/title
                    VStack(spacing: 10) {
                        Image("Preventa Shield Logo Design")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.2)))

                        Text("Preventa")
                            .font(.system(.largeTitle, design: .rounded).bold())
                            .foregroundStyle(.white)
                        Text("Your proactive health companion")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.bottom, 10)

                    // fields + actions
                    VStack(spacing: 16) {
                        AuthField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $email,
                            isSecure: .constant(false)
                        )

                        AuthField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $password,
                            isSecure: $isSecure
                        )

                        HStack {
                            Spacer()
                            NavigationLink("Forgot password?") { ForgotPasswordView() }
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.white.opacity(0.9))
                        }

                        Button {
                            dismissKeyboard()
                            signIn(email: email, password: password)
                        } label: {
                            PrimaryButtonLabel(title: "Sign In")
                        }

                        OrDivider()

                        NavigationLink { SignUpView() } label: {
                            SecondaryButtonLabel(title: "Create Account")
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.18), lineWidth: 1))
                    .shadow(color: .black.opacity(0.25), radius: 25, y: 12)
                    .padding(.horizontal, 28)

                    Spacer()
                }
                .padding(.top, 40)
            }
            .alert("Preventa", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            // modern navigation (replaces hidden NavigationLink)
            .navigationDestination(isPresented: $goHome) {
                HomeView()
            }
            // Adds a "Done" button above the keyboard to dismiss it
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { dismissKeyboard() }
                }
            }
        }
    }

    // MARK: - Helpers

    private func show(_ message: String) {
        alertMessage = message
        showAlert = true
        dismissKeyboard()
    }

    private func dismissKeyboard() {
        // Works reliably even when the TextField is inside a custom view
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    private func signIn(email: String, password: String) {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanEmail.contains("@"), cleanPassword.count >= 6 else {
            show("Enter a valid email and password.")
            return
        }

        Auth.auth().signIn(withEmail: cleanEmail, password: cleanPassword) { _, error in
            if let error = error {
                show("Sign-in failed: \(error.localizedDescription)")
                return
            }

            guard let user = Auth.auth().currentUser else {
                show("User not found.")
                return
            }

            user.reload { err in
                if let err = err {
                    show("Couldn’t refresh account: \(err.localizedDescription)")
                    return
                }

                if user.isEmailVerified {
                    goHome = true
                } else {
                    show("Please verify your email before signing in. Check your inbox and spam folder for the verification email.")
                }
            }
        }
    }
}

#Preview { ContentView() }
