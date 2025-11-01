import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AnimatedBrandBackground().ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Terms of Service")
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
                            title: "1. Acceptance of Terms",
                            content: """
                            By accessing and using Preventa, you accept and agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.
                            """
                        )
                        
                        PolicySection(
                            title: "2. Description of Service",
                            content: """
                            Preventa is a preventive health management app that provides:
                            
                            • Health data tracking and insights
                            • AI-powered health assistant (Preventa Pulse)
                            • Medication reminders and check-ins
                            • Educational resources and health information
                            • Connection to healthcare resources
                            """
                        )
                        
                        PolicySection(
                            title: "3. Medical Disclaimer",
                            content: """
                            IMPORTANT: Preventa is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition. Never disregard professional medical advice or delay in seeking it because of something you have read or learned in this app.
                            
                            The health information provided is for general educational purposes only and should not be used as a substitute for professional medical care.
                            """
                        )
                        
                        PolicySection(
                            title: "4. User Responsibilities",
                            content: """
                            You agree to:
                            
                            • Provide accurate and truthful information
                            • Use the app only for lawful purposes
                            • Not share your account credentials
                            • Not attempt to hack, reverse engineer, or compromise the app
                            • Respect the intellectual property rights of Preventa and third parties
                            • Report any security vulnerabilities responsibly
                            """
                        )
                        
                        PolicySection(
                            title: "5. Account Security",
                            content: """
                            You are responsible for maintaining the confidentiality of your account and password. You agree to notify us immediately of any unauthorized use of your account. We are not liable for any loss or damage arising from your failure to protect your account.
                            """
                        )
                        
                        PolicySection(
                            title: "6. Intellectual Property",
                            content: """
                            All content, features, and functionality of Preventa are owned by us or our licensors and are protected by copyright, trademark, and other intellectual property laws. You may not copy, modify, distribute, or create derivative works without our express written permission.
                            """
                        )
                        
                        PolicySection(
                            title: "7. Limitation of Liability",
                            content: """
                            TO THE MAXIMUM EXTENT PERMITTED BY LAW, PREVENTA AND ITS PROVIDERS SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS OR REVENUES, WHETHER INCURRED DIRECTLY OR INDIRECTLY, OR ANY LOSS OF DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES.
                            """
                        )
                        
                        PolicySection(
                            title: "8. Service Availability",
                            content: """
                            We strive to keep Preventa available 24/7, but we do not guarantee uninterrupted access. We may perform maintenance, updates, or modifications that temporarily interrupt service. We are not liable for any damages resulting from service interruptions.
                            """
                        )
                        
                        PolicySection(
                            title: "9. Termination",
                            content: """
                            We reserve the right to terminate or suspend your account at any time for violations of these terms. You may delete your account at any time through the app settings. Upon termination, your right to use the app will immediately cease.
                            """
                        )
                        
                        PolicySection(
                            title: "10. Changes to Terms",
                            content: """
                            We may modify these Terms of Service at any time. We will notify you of significant changes through the app or email. Your continued use of Preventa after changes constitutes acceptance of the new terms.
                            """
                        )
                        
                        PolicySection(
                            title: "11. Governing Law",
                            content: """
                            These Terms of Service are governed by the laws of the jurisdiction in which Preventa operates. Any disputes arising from these terms shall be resolved through binding arbitration or in the appropriate courts.
                            """
                        )
                        
                        PolicySection(
                            title: "12. Contact",
                            content: """
                            If you have questions about these Terms of Service, please contact us at:
                            
                            Email: legal@preventa.app
                            
                            We are committed to addressing your concerns and ensuring a positive experience.
                            """
                        )
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Terms of Service")
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

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}

