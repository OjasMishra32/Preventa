import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    // User info
    @State private var firstName = ""
    @State private var middleName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = Date()
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // Address info
    @State private var streetAddress = ""
    @State private var city = ""
    @State private var country = ""
    @State private var zipCode = ""

    // UI states
    @State private var agreeToDisclaimer = false
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

            ScrollView {
                VStack(spacing: 18) {
                    Text("Create Account")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Group {
                        AuthField(icon: "person.fill", placeholder: "First Name", text: $firstName, isSecure: .constant(false))
                        AuthField(icon: "person.fill", placeholder: "Middle Name", text: $middleName, isSecure: .constant(false))
                        AuthField(icon: "person.fill", placeholder: "Last Name", text: $lastName, isSecure: .constant(false))

                        DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.12)))
                            .foregroundStyle(.white)

                        AuthField(icon: "envelope.fill", placeholder: "Email", text: $email, isSecure: .constant(false))
                        AuthField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: .constant(true))
                        AuthField(icon: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword, isSecure: .constant(true))
                    }

                    Group {
                        AuthField(icon: "house.fill", placeholder: "Street Address", text: $streetAddress, isSecure: .constant(false))
                        AuthField(icon: "building.2.fill", placeholder: "City", text: $city, isSecure: .constant(false))
                        AuthField(icon: "globe", placeholder: "Country", text: $country, isSecure: .constant(false))
                        AuthField(icon: "number", placeholder: "Zip Code", text: $zipCode, isSecure: .constant(false))
                    }

                    Toggle(isOn: $agreeToDisclaimer) {
                        Text("I understand this app is not a certified medical tool.")
                            .font(.footnote)
                            .foregroundStyle(.white)
                    }

                    Button {
                        handleSignUp()
                    } label: {
                        PrimaryButtonLabel(title: "Register")
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.18), lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: 25, y: 12)
                .padding(.horizontal, 28)
                .padding(.top, 40)
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Preventa", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func handleSignUp() {
        guard !firstName.isEmpty, !lastName.isEmpty else { show("Please enter your name."); return }
        guard isValidEmail(email) else { show("Enter a valid email."); return }
        guard password.count >= 6 else { show("Password must be at least 6 characters."); return }
        guard password == confirmPassword else { show("Passwords do not match."); return }
        guard !streetAddress.isEmpty, !city.isEmpty, !country.isEmpty, !zipCode.isEmpty else { show("Complete your address."); return }
        guard agreeToDisclaimer else { show("Accept the disclaimer to proceed."); return }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                show("Registration failed: \(error.localizedDescription)")
                return
            }

            guard let user = authResult?.user else {
                show("Unexpected error occurred.")
                return
            }

            user.sendEmailVerification { error in
                if let error = error {
                    show("Could not send verification email: \(error.localizedDescription)")
                    return
                }

                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "firstName": firstName,
                    "middleName": middleName,
                    "lastName": lastName,
                    "email": email,
                    "dateOfBirth": Timestamp(date: dateOfBirth),
                    "street": streetAddress,
                    "city": city,
                    "country": country,
                    "zipCode": zipCode
                ]) { error in
                    if let error = error {
                        show("Failed to save user info: \(error.localizedDescription)")
                    } else {
                        show("Account created. A verification email has been sent to \(email).")
                    }
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }

    private func show(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    SignUpView()
}
