import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit

struct MeView: View {
    @StateObject private var vm = MeVM()
    @State private var showSignOutAlert = false
    @State private var showDeleteAlert = false
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false
    @State private var showEditProfile = false
    @State private var showChangePassword = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AnimatedBrandBackground().ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    profileHeader
                    
                    accountSection
                    
                    dataSection
                    
                    privacySection
                    
                    aboutSection
                    
                    signOutButton
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.loadProfile() }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack {
                PrivacyPolicyView()
            }
        }
        .sheet(isPresented: $showTerms) {
            NavigationStack {
                TermsOfServiceView()
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(vm: vm)
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                vm.signOut()
                dismiss()
            }
        } message: {
            Text("You can sign back in anytime with your email and password.")
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                vm.deleteAccount()
                dismiss()
            }
        } message: {
            Text("This will permanently delete your account and all data. This cannot be undone.")
        }
    }
    
    private var profileHeader: some View {
        GlassCard {
            HStack(spacing: 20) {
                // Enhanced profile image placeholder
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)
                    
                    Text(String(vm.displayName.prefix(1)).uppercased())
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(vm.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text(vm.email)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                    
                    HStack(spacing: 12) {
                        Label("\(vm.storageUsed) MB", systemImage: "externaldrive.fill")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                
                Spacer()
            }
            .padding(4)
        }
    }
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Settings")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            
            GlassCard(expand: false) {
                VStack(spacing: 0) {
                    EnhancedSettingRow(
                        icon: "person.fill",
                        title: "Edit Profile",
                        subtitle: "Update your personal information",
                        iconColor: .blue,
                        action: { showEditProfile = true }
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    EnhancedSettingRow(
                        icon: "lock.fill",
                        title: "Change Password",
                        subtitle: "Update your account password",
                        iconColor: .purple,
                        action: { showChangePassword = true }
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    EnhancedSettingRow(
                        icon: "bell.fill",
                        title: "Notifications",
                        subtitle: "Manage notification preferences",
                        iconColor: .orange,
                        action: { vm.openNotifications() }
                    )
                }
            }
        }
    }
    
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data & Storage")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            
            GlassCard(expand: false) {
                VStack(spacing: 0) {
                    EnhancedSettingRow(
                        icon: "square.and.arrow.down.fill",
                        title: "Export Data",
                        subtitle: "Download your health data",
                        iconColor: .green,
                        action: { vm.exportData() }
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    EnhancedSettingRow(
                        icon: "externaldrive.fill",
                        title: "Storage",
                        subtitle: "\(vm.storageUsed) MB used",
                        iconColor: .cyan,
                        action: nil
                    )
                }
            }
        }
    }
    
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Legal & Privacy")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            
            GlassCard(expand: false) {
                VStack(spacing: 0) {
                    EnhancedSettingRow(
                        icon: "hand.raised.fill",
                        title: "Privacy Policy",
                        subtitle: "How we protect your data",
                        iconColor: .blue,
                        action: { 
                            vm.openPrivacyPolicy()
                            showPrivacyPolicy = true
                        }
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    EnhancedSettingRow(
                        icon: "doc.text.fill",
                        title: "Terms of Service",
                        subtitle: "App usage terms and conditions",
                        iconColor: .purple,
                        action: { 
                            vm.openTerms()
                            showTerms = true
                        }
                    )
                }
            }
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            
            GlassCard(expand: false) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Version")
                            .foregroundStyle(.white.opacity(0.9))
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    HStack {
                        Text("Build")
                            .foregroundStyle(.white.opacity(0.9))
                        Spacer()
                        Text("1")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
    }
    
    private var signOutButton: some View {
        VStack(spacing: 12) {
            Button {
                Hx.warn()
                showSignOutAlert = true
            } label: {
                Text("Sign Out")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            
            Button {
                Hx.warn()
                showDeleteAlert = true
            } label: {
                Text("Delete Account")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.vertical, 12)
        }
        .disabled(action == nil)
        .buttonStyle(.plain)
    }
}

struct EnhancedSettingRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let iconColor: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 16) {
                // Enhanced icon with background
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [iconColor.opacity(0.6), iconColor.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 4)
        }
        .disabled(action == nil)
        .buttonStyle(.plain)
    }
}

// MARK: - ViewModel

final class MeVM: ObservableObject {
    @Published var displayName: String = "User"
    @Published var email: String = ""
    @Published var storageUsed: Int = 0
    
    private let db = Firestore.firestore()
    var uid: String? { Auth.auth().currentUser?.uid }
    
    @Published var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @Published var height: Double = 0 // in inches (from Firestore, synced to HealthKit)
    @Published var weight: Double = 0 // in pounds (from Firestore, synced to HealthKit)
    
    // Computed property for age
    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }
    
    // Computed property for BMI
    var bmi: Double? {
        guard height > 0, weight > 0 else { return nil }
        let heightInMeters = height * 0.0254 // Convert inches to meters
        let weightInKg = weight * 0.453592 // Convert pounds to kg
        return weightInKg / (heightInMeters * heightInMeters)
    }
    
    func loadProfile() {
        guard let user = Auth.auth().currentUser else { return }
        email = user.email ?? ""
        
        guard let uid = uid else { return }
        db.collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let self = self,
                  let data = snapshot?.data() else { return }
            
            DispatchQueue.main.async {
                if let firstName = data["firstName"] as? String,
                   let lastName = data["lastName"] as? String {
                    self.displayName = "\(firstName) \(lastName)"
                } else if let firstName = data["firstName"] as? String {
                    self.displayName = firstName
                }
                
                // Load health information
                if let dobTimestamp = data["dateOfBirth"] as? Timestamp {
                    self.dateOfBirth = dobTimestamp.dateValue()
                }
                
                if let heightValue = data["height"] as? Double {
                    self.height = heightValue
                    // Sync to HealthKitManager if not already set
                    if HealthKitManager.shared.healthData.height == 0 {
                        HealthKitManager.shared.healthData.height = heightValue
                    }
                }
                
                if let weightValue = data["weight"] as? Double {
                    self.weight = weightValue
                    // Sync to HealthKitManager if not already set
                    if HealthKitManager.shared.healthData.weight == 0 {
                        HealthKitManager.shared.healthData.weight = weightValue
                    }
                }
            }
        }
        
        calculateStorage()
    }
    
    func signOut() {
        try? Auth.auth().signOut()
    }
    
    func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        // Delete Firestore data
        guard let uid = uid else { return }
        db.collection("users").document(uid).delete()
        
        // Delete auth account
        user.delete { error in
            if let error = error {
                print("Error deleting account: \(error.localizedDescription)")
            }
        }
    }
    
    func editProfile() {
        Hx.tap()
        // Handled by sheet in MeView
    }
    
    func changePassword() {
        Hx.tap()
        // Handled by sheet in MeView
    }
    
    func openNotifications() {
        Hx.tap()
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    func exportData() {
        Hx.tap()
        // Generate JSON export of user data
        guard let uid = uid else { return }
        
        let db = Firestore.firestore()
        var exportData: [String: Any] = [
            "displayName": displayName,
            "email": email,
            "exportDate": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Export meals
        db.collection("users").document(uid).collection("meals")
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    let meals = docs.compactMap { doc -> [String: Any]? in
                        var data = doc.data()
                        data["id"] = doc.documentID
                        return data
                    }
                    exportData["meals"] = meals
                }
                
                // Export medications
                db.collection("users").document(uid).collection("medications")
                    .getDocuments { snapshot, error in
                        if let docs = snapshot?.documents {
                            let meds = docs.compactMap { doc -> [String: Any]? in
                                var data = doc.data()
                                data["id"] = doc.documentID
                                return data
                            }
                            exportData["medications"] = meds
                        }
                        
                        // Export check-ins
                        db.collection("users").document(uid).collection("checkIns")
                            .getDocuments { snapshot, error in
                                if let docs = snapshot?.documents {
                                    let checkIns = docs.compactMap { doc -> [String: Any]? in
                                        var data = doc.data()
                                        data["id"] = doc.documentID
                                        return data
                                    }
                                    exportData["checkIns"] = checkIns
                                }
                                
                                // Generate JSON string
                                if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
                                   let jsonString = String(data: jsonData, encoding: .utf8) {
                                    DispatchQueue.main.async {
                                        let activityVC = UIActivityViewController(
                                            activityItems: [jsonString],
                                            applicationActivities: nil
                                        )
                                        
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let rootVC = windowScene.windows.first?.rootViewController {
                                            rootVC.present(activityVC, animated: true)
                                        }
                                    }
                                }
                            }
                    }
            }
    }
    
    func openPrivacyPolicy() {
        Hx.tap()
    }
    
    func openTerms() {
        Hx.tap()
    }
    
    private func calculateStorage() {
        // TODO: Calculate actual storage usage
        storageUsed = Int.random(in: 50...200)
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @ObservedObject var vm: MeVM
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var heightString: String = ""
    @State private var weightString: String = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Edit Profile")
                                .font(.title.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Update your personal and health information")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 22)
                        .padding(.top, 8)
                        
                        GlassCard {
                            VStack(spacing: 20) {
                                // Personal Information Section
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.blue)
                                        Text("Personal Information")
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.9))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("First Name")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.9))
                                        
                                        TextField("Enter first name", text: $firstName)
                                            .textFieldStyle(.plain)
                                            .padding(16)
                                            .background(Color.white.opacity(0.1))
                                            .foregroundStyle(.white)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Last Name")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.9))
                                        
                                        TextField("Enter last name", text: $lastName)
                                            .textFieldStyle(.plain)
                                            .padding(16)
                                            .background(Color.white.opacity(0.1))
                                            .foregroundStyle(.white)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Date of Birth")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.9))
                                        
                                        DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                            .colorScheme(.dark)
                                            .padding(12)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                
                                // Health Information Section
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "heart.text.square.fill")
                                            .font(.title3)
                                            .foregroundStyle(.red)
                                        Text("Health Information")
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.9))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Height")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.9))
                                        
                                        HStack(spacing: 12) {
                                            TextField("70", text: $heightString)
                                                .keyboardType(.decimalPad)
                                                .textFieldStyle(.plain)
                                                .padding(16)
                                                .background(Color.white.opacity(0.1))
                                                .foregroundStyle(.white)
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                )
                                                .frame(maxWidth: 100)
                                            
                                            Text("inches")
                                                .font(.subheadline)
                                                .foregroundStyle(.white.opacity(0.7))
                                            
                                            Spacer()
                                        }
                                        
                                        Text("Example: 70 = 5'10\"")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Weight")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.9))
                                        
                                        HStack(spacing: 12) {
                                            TextField("150", text: $weightString)
                                                .keyboardType(.decimalPad)
                                                .textFieldStyle(.plain)
                                                .padding(16)
                                                .background(Color.white.opacity(0.1))
                                                .foregroundStyle(.white)
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                )
                                                .frame(maxWidth: 100)
                                            
                                            Text("pounds")
                                                .font(.subheadline)
                                                .foregroundStyle(.white.opacity(0.7))
                                            
                                            Spacer()
                                        }
                                        
                                        Text("Your data will sync with Apple Health")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                }
                                
                                Button {
                                    saveProfile()
                                } label: {
                                    HStack {
                                        if isSaving {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                        }
                                        Text(isSaving ? "Saving..." : "Save Changes")
                                            .font(.headline.weight(.semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        in: RoundedRectangle(cornerRadius: 16)
                                    )
                                    .shadow(color: .blue.opacity(0.4), radius: 12, y: 4)
                                }
                                .disabled(isSaving || firstName.isEmpty)
                                .padding(.top, 8)
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 22)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your profile has been updated successfully.")
            }
            .onAppear {
                loadCurrentProfile()
            }
        }
    }
    
    private func loadCurrentProfile() {
        let components = vm.displayName.components(separatedBy: " ")
        firstName = components.first ?? ""
        lastName = components.dropFirst().joined(separator: " ")
        dateOfBirth = vm.dateOfBirth
        
        // Load height and weight
        if vm.height > 0 {
            heightString = String(format: "%.1f", vm.height)
        }
        if vm.weight > 0 {
            weightString = String(format: "%.1f", vm.weight)
        }
    }
    
    private func saveProfile() {
        guard !firstName.isEmpty, let uid = vm.uid else {
            errorMessage = "Please enter your first name."
            showError = true
            return
        }
        
        // Validate and parse height
        var heightValue: Double = 0
        if !heightString.isEmpty {
            if let h = Double(heightString.trimmingCharacters(in: .whitespaces)) {
                guard h > 0 && h < 120 else {
                    errorMessage = "Please enter a valid height between 1 and 120 inches."
                    showError = true
                    return
                }
                heightValue = h
            } else {
                errorMessage = "Please enter a valid height (e.g., 70 for 5'10\")."
                showError = true
                return
            }
        }
        
        // Validate and parse weight
        var weightValue: Double = 0
        if !weightString.isEmpty {
            if let w = Double(weightString.trimmingCharacters(in: .whitespaces)) {
                guard w > 0 && w < 1000 else {
                    errorMessage = "Please enter a valid weight between 1 and 1000 pounds."
                    showError = true
                    return
                }
                weightValue = w
            } else {
                errorMessage = "Please enter a valid weight (e.g., 150)."
                showError = true
                return
            }
        }
        
        isSaving = true
        
        // Calculate age from date of birth
        let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
        
        var updateData: [String: Any] = [
            "firstName": firstName.trimmingCharacters(in: .whitespaces),
            "lastName": lastName.trimmingCharacters(in: .whitespaces),
            "dateOfBirth": Timestamp(date: dateOfBirth),
            "age": age,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Include height/weight only if provided
        if heightValue > 0 {
            updateData["height"] = heightValue
        }
        if weightValue > 0 {
            updateData["weight"] = weightValue
        }
        
        print("💾 Saving profile data for user: \(uid)")
        print("   First Name: \(firstName)")
        print("   Last Name: \(lastName)")
        print("   DOB: \(dateOfBirth)")
        print("   Height: \(heightValue > 0 ? String(heightValue) : "not set")")
        print("   Weight: \(weightValue > 0 ? String(weightValue) : "not set")")
        
        // Use async/await with race pattern for timeout
        Task { @MainActor in
            do {
                // Race between Firestore save and timeout
                let result = try await withThrowingTaskGroup(of: Bool.self) { group in
                    // Firestore save task
                    group.addTask {
                        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                            let db = Firestore.firestore()
                            print("📤 Starting Firestore save to document: \(uid)")
                            print("   Update data: \(updateData)")
                            
                            db.collection("users").document(uid).setData(updateData, merge: true) { error in
                                if let error = error {
                                    print("❌ Firestore error: \(error.localizedDescription)")
                                    print("   Error code: \((error as NSError).code)")
                                    print("   Error domain: \((error as NSError).domain)")
                                    continuation.resume(throwing: error)
                                } else {
                                    print("✅ Profile saved successfully to Firestore")
                                    continuation.resume(returning: true)
                                }
                            }
                        }
                    }
                    
                    // Timeout task
                    group.addTask {
                        try await Task.sleep(nanoseconds: 15_000_000_000) // 15 seconds
                        throw NSError(domain: "TimeoutError", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Request timed out"])
                    }
                    
                    // Wait for first task to complete
                    let firstResult = try await group.next()!
                    group.cancelAll() // Cancel remaining tasks
                    return firstResult
                }
                
                // Success - update UI
                print("✅ Save operation completed successfully")
                isSaving = false
                
                // Update VM immediately
                if lastName.isEmpty {
                    vm.displayName = firstName
                } else {
                    vm.displayName = "\(firstName) \(lastName)"
                }
                vm.dateOfBirth = dateOfBirth
                
                // Update height and weight in VM and HealthKitManager
                if heightValue > 0 {
                    print("💾 Updating height: \(heightValue) inches")
                    vm.height = heightValue
                    HealthKitManager.shared.healthData.height = heightValue
                }
                if weightValue > 0 {
                    print("💾 Updating weight: \(weightValue) pounds")
                    vm.weight = weightValue
                    HealthKitManager.shared.healthData.weight = weightValue
                }
                
                // Save to HealthKit if available and values are provided
                if heightValue > 0 || weightValue > 0 {
                    Task {
                        print("💾 Syncing to HealthKit...")
                        if heightValue > 0 {
                            await HealthKitManager.shared.saveHeight(inches: heightValue)
                            print("✅ Height saved to HealthKit")
                        }
                        if weightValue > 0 {
                            await HealthKitManager.shared.saveWeight(pounds: weightValue)
                            print("✅ Weight saved to HealthKit")
                        }
                        let bmi = HealthKitManager.shared.healthData.bmi
                        print("✅ HealthKit sync completed - BMI: \(bmi?.description ?? "N/A")")
                    }
                }
                
                // Reload profile to ensure data is fresh
                vm.loadProfile()
                
                Hx.ok()
                showSuccess = true
                
            } catch {
                // Error or timeout
                print("❌ Save failed with error: \(error.localizedDescription)")
                isSaving = false
                let errorMsg = error.localizedDescription.contains("timed out") || (error as NSError).code == -1001
                    ? "Request timed out. Please check your internet connection and try again."
                    : "Failed to save profile: \(error.localizedDescription)"
                errorMessage = errorMsg
                showError = true
            }
        }
    }
}

// MARK: - Change Password View

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isChanging = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Text("Change Password")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 22)
                        
                        GlassCard {
                            VStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current Password")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.9))
                                    
                                    SecureField("Current Password", text: $currentPassword)
                                        .textFieldStyle(.plain)
                                        .padding(14)
                                        .background(Color.white.opacity(0.1))
                                        .foregroundStyle(.white)
                                        .cornerRadius(12)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("New Password")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.9))
                                    
                                    SecureField("New Password", text: $newPassword)
                                        .textFieldStyle(.plain)
                                        .padding(14)
                                        .background(Color.white.opacity(0.1))
                                        .foregroundStyle(.white)
                                        .cornerRadius(12)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm New Password")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.9))
                                    
                                    SecureField("Confirm New Password", text: $confirmPassword)
                                        .textFieldStyle(.plain)
                                        .padding(14)
                                        .background(Color.white.opacity(0.1))
                                        .foregroundStyle(.white)
                                        .cornerRadius(12)
                                }
                                
                                Button {
                                    changePassword()
                                } label: {
                                    Text(isChanging ? "Changing..." : "Change Password")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            LinearGradient(
                                                colors: [.purple.opacity(0.9), .blue.opacity(0.9)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            in: RoundedRectangle(cornerRadius: 16)
                                        )
                                }
                                .disabled(isChanging || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 22)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your password has been changed successfully.")
            }
        }
    }
    
    private func changePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "New passwords do not match."
            showError = true
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            showError = true
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user logged in."
            showError = true
            return
        }
        
        isChanging = true
        
        // Reauthenticate first
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: currentPassword)
        user.reauthenticate(with: credential) { authResult, error in
            if let error = error {
                DispatchQueue.main.async {
                    isChanging = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
                return
            }
            
            // Update password
            user.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    isChanging = false
                    
                    if let error = error {
                        errorMessage = error.localizedDescription
                        showError = true
                    } else {
                        Hx.ok()
                        showSuccess = true
                    }
                }
            }
        }
    }
}

// uid already exists in MeVM, no extension needed

#Preview {
    MeView()
}

