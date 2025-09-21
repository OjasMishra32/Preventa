import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.8)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)

                Text("Welcome to Preventa")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)

                Text("You’re all set. We’ll start with a quick overview next.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))

                Spacer(minLength: 0)
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview { HomeView() }
