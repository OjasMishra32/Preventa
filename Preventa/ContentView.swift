import SwiftUI

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
                            show("Signed in (demo).")
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
                            show("Continuing as guest (demo).)
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

    private func show(_ message: String) {
        alertMessage = message
        showAlert = true
    }

    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }
}

struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Binding var isSecure: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 22)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .foregroundStyle(.white)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.18), lineWidth: 1)
        )
        .overlay(alignment: .trailing) {
            if placeholder.lowercased().contains("password") {
                Button {
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.trailing, 10)
                }
            }
        }
    }
}

struct PrimaryButtonLabel: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
    }
}

struct SecondaryButtonLabel: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.25), lineWidth: 1)
            )
    }
}

struct OrDivider: View {
    var body: some View {
        HStack {
            Rectangle().fill(.white.opacity(0.25)).frame(height: 1)
            Text("or")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
            Rectangle().fill(.white.opacity(0.25)).frame(height: 1)
        }
        .padding(.vertical, 4)
    }
}

struct SignUpView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Create Account")
                .font(.largeTitle.weight(.bold))
            Text("This is a placeholder screen.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ForgotPasswordView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Forgot Password")
                .font(.largeTitle.weight(.bold))
            Text("Enter your email to reset password.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Forgot Password?")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
