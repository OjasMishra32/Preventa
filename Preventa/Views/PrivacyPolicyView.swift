import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AnimatedBrandBackground().ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                        Text("Last Updated: \(DateFormatter.policyDateFormatter.string(from: Date()))")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 20) {
                        PolicySection(
                            title: "1. Introduction",
                            content: """
                            Welcome to Preventa. We are committed to protecting your privacy and ensuring you have a positive experience on our app. This Privacy Policy explains how we collect, use, and safeguard your personal information.
                            """
                        )
                        
                        PolicySection(
                            title: "2. Information We Collect",
                            content: """
                            We collect the following types of information:
                            
                            • Account Information: Your name, email address, and profile data
                            • Health Data: Steps, heart rate, sleep, and other health metrics (with your explicit permission)
                            • Usage Data: How you interact with the app to improve our services
                            • Device Information: Device type, operating system, and app version
                            """
                        )
                        
                        PolicySection(
                            title: "3. How We Use Your Information",
                            content: """
                            We use your information to:
                            
                            • Provide personalized health insights and recommendations
                            • Improve our AI-powered health assistant (Preventa Pulse)
                            • Track your health goals and progress
                            • Send you important app updates and notifications
                            • Ensure app security and prevent fraud
                            """
                        )
                        
                        PolicySection(
                            title: "4. Health Data",
                            content: """
                            Your health data is extremely sensitive and we treat it with the utmost care:
                            
                            • All health data is encrypted in transit and at rest
                            • We never share your health data with third parties without your explicit consent
                            • Health data is stored locally on your device when possible
                            • You can delete your health data at any time from your account settings
                            • We comply with HIPAA and other applicable health data regulations
                            """
                        )
                        
                        PolicySection(
                            title: "5. Data Security",
                            content: """
                            We implement industry-standard security measures:
                            
                            • End-to-end encryption for sensitive data
                            • Secure authentication and access controls
                            • Regular security audits and updates
                            • Secure cloud storage with Firebase
                            • Your data is protected by robust security protocols
                            """
                        )
                        
                        PolicySection(
                            title: "6. Third-Party Services",
                            content: """
                            We use the following third-party services:
                            
                            • Firebase (Google): For authentication and cloud storage
                            • Apple HealthKit: To access your health data (with your permission)
                            • These services have their own privacy policies and security measures
                            """
                        )
                        
                        PolicySection(
                            title: "7. Your Rights",
                            content: """
                            You have the right to:
                            
                            • Access your personal data
                            • Correct inaccurate information
                            • Delete your account and all associated data
                            • Export your data at any time
                            • Opt-out of non-essential data collection
                            • Withdraw consent for health data access
                            """
                        )
                        
                        PolicySection(
                            title: "8. Children's Privacy",
                            content: """
                            Preventa is not intended for users under the age of 13. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.
                            """
                        )
                        
                        PolicySection(
                            title: "9. Changes to This Policy",
                            content: """
                            We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. Significant changes will be communicated through the app or email.
                            """
                        )
                        
                        PolicySection(
                            title: "10. Contact Us",
                            content: """
                            If you have questions about this Privacy Policy or our data practices, please contact us at:
                            
                            Email: privacy@preventa.app
                            
                            We are committed to addressing your concerns and protecting your privacy.
                            """
                        )
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
                .foregroundStyle(.white)
            }
        }
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            
            Text(content)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

extension DateFormatter {
    static let policyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}

