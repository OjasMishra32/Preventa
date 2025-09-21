import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Forgot Password")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                Text("Enter your email to receive a password reset link.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.white.opacity(0.12))
                    .cornerRadius(12)
                    .foregroundStyle(.white)

                Button {
                    resetPassword()
                } label: {
                    PrimaryButtonLabel(title: "Send Reset Link")
                }

                Spacer()
            }
            .padding()
        }
        .alert("Preventa", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func resetPassword() {
        guard email.contains("@") && email.contains(".") else {
            show("Please enter a valid email.")
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                show("Failed to send reset email: \(error.localizedDescription)")
            } else {
                show("A password reset email has been sent to \(email).")
            }
        }
    }

    private func show(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    ForgotPasswordView()
}
