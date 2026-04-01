import SwiftUI
import UIKit

// MARK: - Estilo

/// Botón metálico: aspecto “pulsado” mientras el dedo está abajo; la acción de SwiftUI se ejecuta al **soltar** dentro del área (Gherkin HU 3).
struct AcidMetalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(metalFill(pressed: configuration.isPressed))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(white: configuration.isPressed ? 0.35 : 0.55),
                                Color(white: 0.2),
                                Color(white: configuration.isPressed ? 0.3 : 0.45),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: configuration.isPressed ? 1.5 : 2
                    )
            )
            .shadow(color: .black.opacity(configuration.isPressed ? 0.12 : 0.28), radius: configuration.isPressed ? 1 : 3, y: configuration.isPressed ? 0 : 2)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private func metalFill(pressed: Bool) -> LinearGradient {
        LinearGradient(
            colors: pressed
                ? [Color(white: 0.32), Color(white: 0.22), Color(white: 0.27)]
                : [Color(white: 0.42), Color(white: 0.30), Color(white: 0.36)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Vista

struct AcidButton: View {
    /// Color de etiqueta e icono (legible sobre el metal del estilo).
    static let labelColor = Color(red: 0.04, green: 0.04, blue: 0.05)

    var title: String
    var systemImage: String?
    var usesHaptics: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            if usesHaptics {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.bold))
                        .symbolRenderingMode(.monochrome)
                }
                Text(title)
                    .font(.subheadline.weight(.bold))
            }
            // Casi negro sobre metal gris: contraste alto (antes ~12% gris sobre ~45% gris).
            .foregroundStyle(AcidButton.labelColor)
        }
        .buttonStyle(AcidMetalButtonStyle())
        .tint(AcidButton.labelColor)
    }
}

#Preview("AcidButton") {
    VStack(spacing: 16) {
        AcidButton(title: "PLAY", systemImage: "play.fill") {}
        AcidButton(title: "CLEAR", systemImage: "trash") {}
    }
    .padding()
    .background(Color(red: 0.95, green: 0.85, blue: 0.15).opacity(0.2))
}
