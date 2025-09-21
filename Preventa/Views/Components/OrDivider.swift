import SwiftUI

struct OrDivider: View {
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(height: 1)

            Text("or")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 6)

            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(height: 1)
        }
        .padding(.vertical, 4)
    }
}
