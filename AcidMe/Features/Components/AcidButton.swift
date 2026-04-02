import SwiftUI
import UIKit

// MARK: - Valores testeables (contraste texto / metal)

enum AcidButtonStyleMath {
    /// Stops `Color(white:)` del relleno metálico (sin pulsar / pulsado).
    static let metalLuminancesUnpressed: [Double] = [0.36, 0.24, 0.30]
    static let metalLuminancesPressed: [Double] = [0.28, 0.18, 0.22]

    static func averageMetalLuminance(pressed: Bool) -> Double {
        let xs = pressed ? metalLuminancesPressed : metalLuminancesUnpressed
        return xs.reduce(0, +) / Double(xs.count)
    }

    /// RGB del gradiente de etiqueta (sRGB 0…1).
    static let labelTopRGB = (r: 1.0, g: 0.99, b: 0.95)
    static let labelBottomRGB = (r: 0.94, g: 0.90, b: 0.82)

    private static func sdrLuminance(_ rgb: (r: Double, g: Double, b: Double)) -> Double {
        0.2126 * rgb.r + 0.7152 * rgb.g + 0.0722 * rgb.b
    }

    static func averageLabelLuminance() -> Double {
        (sdrLuminance(labelTopRGB) + sdrLuminance(labelBottomRGB)) / 2
    }

    /// Regresión: el texto claro debe destacar claramente sobre el metal.
    static func labelIsBrighterThanMetal(pressed: Bool, margin: Double = 0.22) -> Bool {
        averageLabelLuminance() > averageMetalLuminance(pressed: pressed) + margin
    }
}

// MARK: - Estilo

/// Botón metálico: aspecto “pulsado” mientras el dedo está abajo; la acción de SwiftUI se ejecuta al **soltar** dentro del área (Gherkin HU 3).
struct AcidMetalButtonStyle: ButtonStyle {
    var horizontalPadding: CGFloat = 18
    var verticalPadding: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
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
        let stops = pressed
            ? AcidButtonStyleMath.metalLuminancesPressed
            : AcidButtonStyleMath.metalLuminancesUnpressed
        return LinearGradient(
            colors: stops.map { Color(white: $0) },
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Vista

struct AcidButton: View {
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
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(
                            red: AcidButtonStyleMath.labelTopRGB.r,
                            green: AcidButtonStyleMath.labelTopRGB.g,
                            blue: AcidButtonStyleMath.labelTopRGB.b
                        ),
                        Color(
                            red: AcidButtonStyleMath.labelBottomRGB.r,
                            green: AcidButtonStyleMath.labelBottomRGB.g,
                            blue: AcidButtonStyleMath.labelBottomRGB.b
                        ),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            // Contorno suave para leer sobre zonas claras del bisel metálico.
            .shadow(color: .black.opacity(0.55), radius: 0, x: 0, y: 1)
        }
        .buttonStyle(AcidMetalButtonStyle())
        .tint(.white)
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
