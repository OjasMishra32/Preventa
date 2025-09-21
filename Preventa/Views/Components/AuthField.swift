import SwiftUI

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
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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
