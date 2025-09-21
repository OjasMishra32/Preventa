import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    private enum Step: Int, CaseIterable {
        case name, dob, email, password
        var title: String {
            switch self {
            case .name:     return "Create Your Account"
            case .dob:      return "Your Date of Birth"
            case .email:    return "Contact Email"
            case .password: return "Create a Password"
            }
        }
        var subtitle: String {
            switch self {
            case .name:     return "Tell us who you are so we can personalize Preventa."
            case .dob:      return "We’ll use this to tailor insights and reminders. You must be 13+."
            case .email:    return "We’ll send a verification link to confirm it’s you."
            case .password: return "Use at least 6 characters for a secure password."
            }
        }
    }

    // form
    @State private var step: Step = .name
    @State private var firstName = ""
    @State private var lastName  = ""
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -16, to: Date()) ?? Date()
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // ui
    @State private var isWorking = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    // sheets
    @State private var showVerifySheet = false
    @State private var lastVerificationError: String? = nil
    @State private var showSuccessSheet = false
    @State private var showAccountExistsSheet = false

    // nav (we now return to login after success, so no goHome here)
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.8)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    ProgressBar(progress: progress)
                        .frame(height: 6)
                        .padding(.top, 10)
                        .padding(.horizontal, 28)

                    VStack(spacing: 20) {
                        VStack(spacing: 6) {
                            Text(step.title)
                                .font(.system(.title, design: .rounded).weight(.bold))
                                .foregroundStyle(.white)
                            Text(step.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Group {
                            switch step {
                            case .name:     nameStep
                            case .dob:      dobStep
                            case .email:    emailStep
                            case .password: passwordStep
                            }
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.25), value: step)

                        HStack(spacing: 12) {
                            if step != .name {
                                Button(action: { withAnimation { previousStep() } }) {
                                    Text("Back")
                                        .font(.callout.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.95))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(.white.opacity(0.35), lineWidth: 1)
                                        )
                                }
                                .transition(.opacity)
                            }

                            if canGoNext {
                                Button(action: handleNext) {
                                    HStack(spacing: 8) {
                                        Text(step == .password ? "Create Account" : "Next")
                                            .font(.headline.weight(.bold))
                                        Image(systemName: step == .password ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                                            .imageScale(.large)
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                                                       startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                                }
                                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                            }
                        }
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: canGoNext)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.18), lineWidth: 1))
                    .shadow(color: .black.opacity(0.25), radius: 25, y: 12)
                    .padding(.horizontal, 28)

                    Spacer(minLength: 8)
                }
                .padding(.top, 24)
                .disabled(isWorking)
                .overlay {
                    if isWorking { ProgressView().progressViewStyle(.circular).tint(.white) }
                }
            }
            .alert("Preventa", isPresented: $showAlert) { Button("OK", role: .cancel) {} } message: { Text(alertMessage) }
            // verify email sheet stays up until verified
            .sheet(isPresented: $showVerifySheet) {
                VerifyEmailSheet(
                    email: email,
                    lastError: lastVerificationError,
                    onOpenMail: openMail,
                    onResend: { resendVerification() },
                    onCheckVerified: { checkVerification() }
                )
                .interactiveDismissDisabled(true)
                .presentationDetents([.height(460)])
            }
            // success sheet -> go to sign in
            .sheet(isPresented: $showSuccessSheet) {
                VerificationSuccessSheet {
                    signOutAndDismissToLogin()
                }
                .presentationDetents([.height(360)])
            }
            // account exists sheet -> go to sign in
            .sheet(isPresented: $showAccountExistsSheet) {
                AccountExistsSheet {
                    signOutAndDismissToLogin()
                }
                .presentationDetents([.height(340)])
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - step UIs

    private var nameStep: some View {
        VStack(spacing: 14) {
            AuthField(icon: "person.fill", placeholder: "First Name", text: $firstName, isSecure: .constant(false))
            AuthField(icon: "person.fill", placeholder: "Last Name",  text: $lastName,  isSecure: .constant(false))
        }
    }

    private var dobStep: some View {
        VStack(spacing: 12) {
            DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.18), lineWidth: 1))
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                Text("Age: \(age)").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                if age < 13 { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow).imageScale(.small) }
                Spacer()
            }

            Text("You must be 13 or older to create an account.")
                .font(.footnote)
                .foregroundStyle(age < 13 ? .yellow : .white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emailStep: some View {
        VStack(spacing: 14) {
            AuthField(icon: "envelope.fill", placeholder: "Email", text: $email, isSecure: .constant(false))
        }
    }

    private var passwordStep: some View {
        VStack(spacing: 14) {
            AuthField(icon: "lock.fill", placeholder: "Password (min 6)", text: $password, isSecure: .constant(true))
            AuthField(icon: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword, isSecure: .constant(true))
        }
    }

    // MARK: - computed

    private var age: Int {
        let comps = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date())
        return max(0, comps.year ?? 0)
    }

    private var canGoNext: Bool {
        switch step {
        case .name:
            return !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !lastName.trimmingCharacters(in: .whitespaces).isEmpty
        case .dob:
            return age >= 13
        case .email:
            return isValidEmail(email)
        case .password:
            return password.count >= 6 && password == confirmPassword
        }
    }

    private var progress: CGFloat {
        CGFloat(step.rawValue + 1) / CGFloat(Step.allCases.count)
    }

    // MARK: - nav

    private func handleNext() {
        if step == .password { register() } else { withAnimation { nextStep() } }
    }
    private func nextStep() { if let next = Step(rawValue: step.rawValue + 1) { step = next } }
    private func previousStep() { if let prev = Step(rawValue: step.rawValue - 1) { step = prev } }

    // MARK: - registration + verification

    private func register() {
        guard canGoNext else { return }
        setWorking(true)

        // safety timeout so spinner never hangs forever
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isWorking {
                self.setWorking(false)
                self.showVerifySheet = true
                self.lastVerificationError = "Timed out. You can request the email again."
            }
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let nsErr = error as NSError? {
                self.setWorking(false)
                if nsErr.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    // Offer clear path to sign in
                    self.showAccountExistsSheet = true
                    return
                }
                self.show("Registration failed: \(nsErr.localizedDescription)")
                return
            }

            guard let user = authResult?.user else {
                self.setWorking(false)
                self.show("Unexpected error occurred.")
                return
            }

            // show verify ui immediately
            self.setWorking(false)
            self.showVerifySheet = true

            // save profile (non-blocking)
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "dateOfBirth": Timestamp(date: dateOfBirth),
                "age": age,
                "createdAt": FieldValue.serverTimestamp()
            ]) { err in
                if let err = err { print("firestore save error: \(err.localizedDescription)") }
            }

            // send verification email
            self.sendVerification()
        }
    }

    private func sendVerification() {
        Auth.auth().useAppLanguage()
        let acs = ActionCodeSettings()
        acs.handleCodeInApp = false
        acs.setIOSBundleID(Bundle.main.bundleIdentifier ?? "")
        Auth.auth().currentUser?.sendEmailVerification(with: acs) { err in
            DispatchQueue.main.async { self.lastVerificationError = err?.localizedDescription }
        }
    }

    private func resendVerification() {
        setWorking(true)
        sendVerification()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.setWorking(false) }
    }

    private func checkVerification() {
        guard let user = Auth.auth().currentUser else { return }
        setWorking(true)
        user.reload { err in
            DispatchQueue.main.async {
                self.setWorking(false)
                if let err = err {
                    self.lastVerificationError = err.localizedDescription
                    return
                }
                if user.isEmailVerified {
                    // success -> show success sheet, keep user in control
                    self.showVerifySheet = false
                    self.showSuccessSheet = true
                } else {
                    // keep verify sheet open, just show note
                    self.lastVerificationError = "Still not verified. Tap the link in your email, then try again."
                }
            }
        }
    }

    // MARK: - helpers

    private func openMail() {
        // best-effort open Mail app
        if let url = URL(string: "message://") { UIApplication.shared.open(url, options: [:], completionHandler: nil) }
    }

    private func signOutAndDismissToLogin() {
        try? Auth.auth().signOut()
        dismiss()  // pop back to ContentView (login)
    }

    private func isValidEmail(_ email: String) -> Bool { email.contains("@") && email.contains(".") }
    private func show(_ message: String) { alertMessage = message; showAlert = true }
    private func setWorking(_ value: Bool) { isWorking = value }
}

// MARK: - local ui components

private struct ProgressBar: View {
    let progress: CGFloat
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(.white.opacity(0.18))
            Capsule()
                .fill(LinearGradient(colors: [.blue.opacity(0.95), .purple.opacity(0.95)],
                                     startPoint: .leading, endPoint: .trailing))
                .mask(GeometryReader { geo in
                    Rectangle().frame(width: geo.size.width * max(0, min(1, progress)))
                })
                .animation(.easeInOut(duration: 0.25), value: progress)
        }
    }
}

private struct VerifyEmailSheet: View {
    let email: String
    let lastError: String?
    var onOpenMail: () -> Void
    var onResend: () -> Void
    var onCheckVerified: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.8)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(.white)

                Text("Verify Your Email")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("We sent a verification link to:\n\(email)\nIf you don’t see it, **check your spam or junk folder**.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.92))

                if let err = lastError {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.yellow)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }

                Button(action: onCheckVerified) {
                    Text("I’ve Verified")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                                                   startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                HStack(spacing: 12) {
                    Button(action: onResend) {
                        Text("Resend Email")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.95))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.35), lineWidth: 1))
                    }
                    Button(action: onOpenMail) {
                        Text("Open Mail")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.95))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.35), lineWidth: 1))
                    }
                }
            }
            .padding(24)
        }
    }
}

private struct VerificationSuccessSheet: View {
    var onGoToSignIn: () -> Void
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.8)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)

                Text("Email Verified")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("You’re all set. You can sign in with your email and password.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.95))

                Button(action: onGoToSignIn) {
                    Text("Go to Sign In")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                                                   startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(24)
        }
    }
}

private struct AccountExistsSheet: View {
    var onGoToSignIn: () -> Void
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.8)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(.white)

                Text("Account Already Exists")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("That email already has an account. Sign in or use Forgot Password.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.95))

                Button(action: onGoToSignIn) {
                    Text("Go to Sign In")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                                                   startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(24)
        }
    }
}

#Preview { SignUpView() }
