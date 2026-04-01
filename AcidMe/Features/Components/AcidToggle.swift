import SwiftUI
import UIKit

// MARK: - Modelo (testeable)

/// Posición del interruptor vertical (p. ej. forma de onda A/B o FX off/on).
enum AcidToggleSelection: Equatable, CaseIterable {
    case upper
    case lower

    mutating func toggle() {
        self = Self.toggled(self)
    }

    static func toggled(_ current: Self) -> Self {
        current == .upper ? .lower : .upper
    }
}

// MARK: - Vista

/// Interruptor **vertical** estilo hardware: dos posiciones; un **toque** alterna y actualiza el binding.
struct AcidToggle: View {
    @Binding var selection: AcidToggleSelection
    var upperLabel: String
    var lowerLabel: String
    var trackWidth: CGFloat = 40
    var trackHeight: CGFloat = 104
    var usesHaptics: Bool = true

    private let thumbSize: CGFloat = 28

    private var thumbCenterY: CGFloat {
        switch selection {
        case .upper:
            return trackHeight * 0.28
        case .lower:
            return trackHeight * 0.72
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(upperLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(minWidth: trackWidth + 24)

            ZStack {
                trackChrome
                thumb
            }
            .frame(width: trackWidth, height: trackHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                toggleSelection()
            }

            Text(lowerLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(minWidth: trackWidth + 24)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(upperLabel) o \(lowerLabel)")
        .accessibilityValue(selection == .upper ? upperLabel : lowerLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Alternar") {
            toggleSelection()
        }
    }

    private var trackChrome: some View {
        RoundedRectangle(cornerRadius: trackWidth / 2, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(white: 0.48),
                        Color(white: 0.32),
                        Color(white: 0.4),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: trackWidth / 2, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(white: 0.6),
                                Color(white: 0.22),
                                Color(white: 0.45),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
    }

    private var thumb: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(white: 0.75),
                        Color(white: 0.42),
                        Color(white: 0.34),
                    ],
                    center: .init(x: 0.35, y: 0.3),
                    startRadius: 0,
                    endRadius: thumbSize
                )
            )
            .overlay(
                Circle()
                    .strokeBorder(Color(white: 0.2), lineWidth: 1)
            )
            .frame(width: thumbSize, height: thumbSize)
            .position(x: trackWidth / 2, y: thumbCenterY)
    }

    private func toggleSelection() {
        if usesHaptics {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            selection = AcidToggleSelection.toggled(selection)
        }
    }
}

#Preview("AcidToggle onda") {
    struct Host: View {
        @State private var sel = AcidToggleSelection.upper
        var body: some View {
            ZStack {
                Color.black.opacity(0.15)
                AcidToggle(
                    selection: $sel,
                    upperLabel: "SAW",
                    lowerLabel: "SQR"
                )
            }
        }
    }
    return Host()
}
