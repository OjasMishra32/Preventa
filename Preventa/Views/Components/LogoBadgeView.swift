import SwiftUI

struct LogoBadgeView: View {
    var size: CGFloat = 140

    var body: some View {
        Image("Preventa Shield Logo Design") // asset name
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(Circle()) // circular logo
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
            )
            .shadow(radius: 10)
    }
}

#Preview {
    LogoBadgeView()
}
