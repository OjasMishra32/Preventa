import SwiftUI
import UIKit

enum Brand {
    static let grad = LinearGradient(
        colors: [Color.purple.opacity(0.92), Color.blue.opacity(0.86)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let glow = LinearGradient(
        colors: [Color.blue.opacity(0.88), Color.purple.opacity(0.88)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let chipBG = Color.white.opacity(0.10)
    static let chipStroke = Color.white.opacity(0.20)
    static let surfaceA = Color.white.opacity(0.08)
    static let surfaceB = Color.white.opacity(0.06)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.9)
}

enum Hx {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func strong() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
    static func ok() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warn() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

// Shared gradient for app views
let appGradient = [Color.purple.opacity(0.9), Color.blue.opacity(0.8)]
