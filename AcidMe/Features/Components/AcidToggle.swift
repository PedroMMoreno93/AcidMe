import SwiftUI
import UIKit

// MARK: - Modelo (testeable)

/// Dos posiciones del interruptor: **`.upper`** = extremo **leading** (izquierda en LTR), **`.lower`** = **trailing** (derecha).
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

/// Interruptor **horizontal** estilo hardware: carril ancho, thumb izquierda/derecha; un **toque** alterna el binding.
struct AcidToggle: View {
    @Binding var selection: AcidToggleSelection
    /// Etiqueta del lado **leading** (opción `.upper`).
    var leadingLabel: String
    /// Etiqueta del lado **trailing** (opción `.lower`).
    var trailingLabel: String
    /// Longitud horizontal del carril.
    var trackWidth: CGFloat = 104
    /// Grosor vertical del carril.
    var trackHeight: CGFloat = 40
    var usesHaptics: Bool = true

    private let thumbSize: CGFloat = 28

    private var thumbCenterX: CGFloat {
        switch selection {
        case .upper:
            return trackWidth * 0.28
        case .lower:
            return trackWidth * 0.72
        }
    }

    private var trackCornerRadius: CGFloat {
        trackHeight / 2
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(leadingLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(minWidth: 36, alignment: .trailing)

            ZStack {
                trackChrome
                thumb
            }
            .frame(width: trackWidth, height: trackHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                toggleSelection()
            }

            Text(trailingLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(minWidth: 36, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(leadingLabel) o \(trailingLabel)")
        .accessibilityValue(selection == .upper ? leadingLabel : trailingLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Alternar") {
            toggleSelection()
        }
    }

    private var trackChrome: some View {
        RoundedRectangle(cornerRadius: trackCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(white: 0.48),
                        Color(white: 0.32),
                        Color(white: 0.4),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: trackCornerRadius, style: .continuous)
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
            .position(x: thumbCenterX, y: trackHeight / 2)
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
                    leadingLabel: "SAW",
                    trailingLabel: "SQR"
                )
            }
        }
    }
    return Host()
}
