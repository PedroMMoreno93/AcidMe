import SwiftUI

// MARK: - Lógica pura (testeable)

enum AcidKnobMath {
    /// Recorre vertical completo en `pixelsForFullRange` puntos ⇒ delta 1.0 (hacia arriba aumenta).
    static func valueAfterVerticalDrag(
        origin: Double,
        translationHeight: CGFloat,
        pixelsForFullRange: CGFloat
    ) -> Double {
        guard pixelsForFullRange > 0 else { return clamp(origin) }
        let delta = -Double(translationHeight) / Double(pixelsForFullRange)
        return clamp(origin + delta)
    }

    static func clamp(_ value: Double) -> Double {
        min(1, max(0, value))
    }

    /// Ángulo del indicador: 0 → mínimo, 1 → máximo (arco ~270°).
    static func indicatorDegrees(value: Double) -> Double {
        let v = clamp(value)
        return -135 + v * 270
    }
}

// MARK: - Vista

/// Control rotatorio estilo hardware: arrastre **vertical** mapea a `0...1` y el dial gira.
struct AcidKnob: View {
    @Binding var value: Double
    var label: String?
    /// Diámetro del knob.
    var size: CGFloat = 88
    /// Píxeles de arrastre vertical para recorrer todo el rango 0→1.
    var pixelsForFullRange: CGFloat = 200

    @State private var isDragging = false
    @State private var valueAtDragStart: Double = 0

    private var clampedBinding: Binding<Double> {
        Binding(
            get: { AcidKnobMath.clamp(value) },
            set: { value = AcidKnobMath.clamp($0) }
        )
    }

    var body: some View {
        VStack(spacing: 6) {
            knobBody
            if let label {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "Parámetro")
        .accessibilityValue("\(Int(AcidKnobMath.clamp(value) * 100)) por ciento")
        .accessibilityAdjustableAction { direction in
            let step = 0.02
            switch direction {
            case .increment:
                clampedBinding.wrappedValue = AcidKnobMath.clamp(clampedBinding.wrappedValue + step)
            case .decrement:
                clampedBinding.wrappedValue = AcidKnobMath.clamp(clampedBinding.wrappedValue - step)
            @unknown default:
                break
            }
        }
    }

    private var knobBody: some View {
        ZStack {
            Circle()
                .fill(metalKnobFill)
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(white: 0.55),
                            Color(white: 0.22),
                            Color(white: 0.4),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(2, size * 0.04)
                )
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.35), Color.clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.9
                    )
                )
                .padding(size * 0.08)

            indicator
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    if !isDragging {
                        isDragging = true
                        valueAtDragStart = AcidKnobMath.clamp(value)
                    }
                    let next = AcidKnobMath.valueAfterVerticalDrag(
                        origin: valueAtDragStart,
                        translationHeight: gesture.translation.height,
                        pixelsForFullRange: pixelsForFullRange
                    )
                    value = next
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }

    private var indicator: some View {
        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
            .fill(Color(white: 0.12))
            .frame(width: max(3, size * 0.045), height: size * 0.22)
            .offset(y: -size * 0.31)
            .rotationEffect(.degrees(AcidKnobMath.indicatorDegrees(value: value)))
    }

    private var metalKnobFill: some ShapeStyle {
        RadialGradient(
            colors: [
                Color(white: 0.52),
                Color(white: 0.38),
                Color(white: 0.28),
                Color(white: 0.42),
            ],
            center: .init(x: 0.35, y: 0.3),
            startRadius: 0,
            endRadius: size
        )
    }
}

#Preview("AcidKnob") {
    struct PreviewHost: View {
        @State private var v = 0.35
        var body: some View {
            ZStack {
                Color.black.opacity(0.2)
                AcidKnob(value: $v, label: "DEMO")
            }
        }
    }
    return PreviewHost()
}
