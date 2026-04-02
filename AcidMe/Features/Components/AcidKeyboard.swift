import Foundation
import SwiftUI
import UIKit

// MARK: - Matemática (testeable)

enum AcidKeyboardMath {
    /// Desplazamiento de octava respecto a do central (C4 = MIDI 60). RF-203: ±3 octavas.
    static let minOctaveOffset = -3
    static let maxOctaveOffset = 3

    /// MIDI de la nota C inferior del teclado de una octava (12 semitonos: C…B).
    static func rootMidi(octaveOffset: Int) -> Int {
        let o = max(minOctaveOffset, min(maxOctaveOffset, octaveOffset))
        let base = 60 + o * 12
        return min(127 - 11, max(0, base))
    }

    /// Frecuencia en Hz (temperamento igual, A4 = 440 Hz).
    static func frequencyHz(midiNote: Int) -> Double {
        let n = Double(min(127, max(0, midiNote)))
        return 440.0 * pow(2.0, (n - 69.0) / 12.0)
    }

    /// Semitonos de las teclas blancas desde la raíz (do mayor).
    static let whiteKeySemitonesFromRoot = [0, 2, 4, 5, 7, 9, 11]
    /// Semitonos de las teclas negras (sostenidos) en la misma octava.
    static let blackKeySemitonesFromRoot = [1, 3, 6, 8, 10]

    /// Pares (índice tecla blanca izq., der.) bajo los que se dibuja cada negra.
    static let blackKeyWhiteSlotIndices: [(Int, Int)] = [
        (0, 1), (1, 2), (3, 4), (4, 5), (5, 6),
    ]

    /// Nombre de la nota **do** inferior del teclado (p. ej. MIDI 60 → \"C4\").
    static func rootOctaveScientificName(rootMidi: Int) -> String {
        let m = min(127, max(0, rootMidi))
        let octaveNumber = m / 12 - 1
        return "C\(octaveNumber)"
    }

    /// Texto de desplazamiento de octava respecto a C4: `0`, `+1`, `-2`, …
    static func octaveOffsetDisplay(offset: Int) -> String {
        if offset == 0 { return "0" }
        if offset > 0 { return "+\(offset)" }
        return "\(offset)"
    }
}

// MARK: - Tecla

private struct AcidKeyboardKey: View {
    let midiNote: Int
    let label: String
    let isBlack: Bool
    let isPressed: Bool
    let whiteWidth: CGFloat
    let whiteHeight: CGFloat
    let gap: CGFloat
    let onNoteOn: () -> Void
    let onNoteOff: () -> Void

    private var blackWidth: CGFloat { max(18, whiteWidth * 0.58) }
    private var blackHeight: CGFloat { whiteHeight * 0.58 }

    var body: some View {
        Group {
            if isBlack {
                keyShape(
                    width: blackWidth,
                    height: blackHeight,
                    corner: 4,
                    fillTop: Color(white: isPressed ? 0.22 : 0.12),
                    fillBottom: Color(white: isPressed ? 0.08 : 0.04),
                    stroke: Color(white: 0.38)
                )
            } else {
                keyShape(
                    width: whiteWidth,
                    height: whiteHeight,
                    corner: 5,
                    fillTop: Color(white: isPressed ? 0.92 : 0.99),
                    fillBottom: Color(white: isPressed ? 0.72 : 0.82),
                    stroke: Color(white: 0.42)
                )
                .overlay(alignment: .bottom) {
                    Text(label)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(white: 0.2))
                        .padding(.bottom, 6)
                }
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                if pressing {
                    onNoteOn()
                } else {
                    onNoteOff()
                }
            },
            perform: {}
        )
        .accessibilityLabel("\(label), MIDI \(midiNote)")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private func keyShape(
        width: CGFloat,
        height: CGFloat,
        corner: CGFloat,
        fillTop: Color,
        fillBottom: Color,
        stroke: Color
    ) -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [fillTop, fillBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(stroke, lineWidth: isBlack ? 0.75 : 1)
            )
            .frame(width: width, height: height)
    }
}

// MARK: - Vista principal

struct AcidKeyboard: View {
    var octaveOffset: Int
    var pressedMidiNotes: Set<Int>
    var onOctaveOffsetChange: (Int) -> Void
    var onNoteOn: (Int, Double) -> Void
    var onNoteOff: (Int) -> Void

    private let keyGap: CGFloat = 3
    private let keyboardHeight: CGFloat = 160

    private var rootMidi: Int { AcidKeyboardMath.rootMidi(octaveOffset: octaveOffset) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Teclado")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                octaveSelectorRow
            }

            GeometryReader { geo in
                let w = geo.size.width
                let whiteCount = 7
                let totalGaps = keyGap * CGFloat(whiteCount - 1)
                let whiteW = max(24, (w - totalGaps) / CGFloat(whiteCount))
                let whiteH = keyboardHeight

                ZStack(alignment: .topLeading) {
                    HStack(spacing: keyGap) {
                        ForEach(Array(AcidKeyboardMath.whiteKeySemitonesFromRoot.enumerated()), id: \.offset) { _, semi in
                            let midi = rootMidi + semi
                            AcidKeyboardKey(
                                midiNote: midi,
                                label: whiteLabel(semitone: semi),
                                isBlack: false,
                                isPressed: pressedMidiNotes.contains(midi),
                                whiteWidth: whiteW,
                                whiteHeight: whiteH,
                                gap: keyGap,
                                onNoteOn: {
                                    onNoteOn(midi, AcidKeyboardMath.frequencyHz(midiNote: midi))
                                },
                                onNoteOff: { onNoteOff(midi) }
                            )
                        }
                    }

                    ForEach(Array(AcidKeyboardMath.blackKeySemitonesFromRoot.enumerated()), id: \.offset) { idx, semi in
                        let pair = AcidKeyboardMath.blackKeyWhiteSlotIndices[idx]
                        let midi = rootMidi + semi
                        let xOffset =
                            CGFloat(pair.0) * (whiteW + keyGap)
                            + whiteW
                            + keyGap * 0.5
                            - max(18, whiteW * 0.58) / 2
                        AcidKeyboardKey(
                            midiNote: midi,
                            label: "",
                            isBlack: true,
                            isPressed: pressedMidiNotes.contains(midi),
                            whiteWidth: whiteW,
                            whiteHeight: whiteH,
                            gap: keyGap,
                            onNoteOn: {
                                onNoteOn(midi, AcidKeyboardMath.frequencyHz(midiNote: midi))
                            },
                            onNoteOff: { onNoteOff(midi) }
                        )
                        .offset(x: xOffset, y: 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: keyboardHeight)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "Teclado musical, una octava, desplazamiento de octava \(AcidKeyboardMath.octaveOffsetDisplay(offset: octaveOffset))"
        )
    }

    private var octaveSelectorRow: some View {
        HStack(spacing: 14) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onOctaveOffsetChange(octaveOffset - 1)
            } label: {
                Text("-")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .frame(minWidth: 22, minHeight: 22)
                    .foregroundStyle(acidMetalLabelGradient)
                    .shadow(color: .black.opacity(0.55), radius: 0, x: 0, y: 1)
            }
            .buttonStyle(AcidMetalButtonStyle(horizontalPadding: 14, verticalPadding: 10))
            .disabled(octaveOffset <= AcidKeyboardMath.minOctaveOffset)
            .opacity(octaveOffset <= AcidKeyboardMath.minOctaveOffset ? 0.42 : 1)
            .accessibilityLabel("Bajar una octava")

            Text(AcidKeyboardMath.octaveOffsetDisplay(offset: octaveOffset))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color(white: 0.12))
                .frame(minWidth: 56)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Octava \(AcidKeyboardMath.octaveOffsetDisplay(offset: octaveOffset))")

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onOctaveOffsetChange(octaveOffset + 1)
            } label: {
                Text("+")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .frame(minWidth: 22, minHeight: 22)
                    .foregroundStyle(acidMetalLabelGradient)
                    .shadow(color: .black.opacity(0.55), radius: 0, x: 0, y: 1)
            }
            .buttonStyle(AcidMetalButtonStyle(horizontalPadding: 14, verticalPadding: 10))
            .disabled(octaveOffset >= AcidKeyboardMath.maxOctaveOffset)
            .opacity(octaveOffset >= AcidKeyboardMath.maxOctaveOffset ? 0.42 : 1)
            .accessibilityLabel("Subir una octava")
        }
    }

    private var acidMetalLabelGradient: LinearGradient {
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
    }

    private func whiteLabel(semitone: Int) -> String {
        switch semitone {
        case 0: return "C"
        case 2: return "D"
        case 4: return "E"
        case 5: return "F"
        case 7: return "G"
        case 9: return "A"
        case 11: return "B"
        default: return "?"
        }
    }
}

#Preview("AcidKeyboard") {
    struct Host: View {
        @State private var oct = 0
        @State private var down: Set<Int> = []
        var body: some View {
            AcidKeyboard(
                octaveOffset: oct,
                pressedMidiNotes: down,
                onOctaveOffsetChange: { oct = $0 },
                onNoteOn: { m, hz in
                    down.insert(m)
                    _ = hz
                },
                onNoteOff: { m in down.remove(m) }
            )
            .padding()
        }
    }
    return Host()
}
