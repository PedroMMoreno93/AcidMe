import ComposableArchitecture
import Perception
import SwiftUI

struct AppView: View {
    /// `Perception.Bindable` evita la ambigüedad con `SwiftUI.Bindable` y enlaza el `Store` a Perception.
    @Perception.Bindable var store: StoreOf<AppFeature>

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 24) {
                Text("AcidMe!")
                    .font(.largeTitle.bold())
                Text("HU 4–8 · Roll + secuenciador + teclado + motor + cutoff / onda")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                AcidPianoRoll(
                    gridSteps: store.pianoRollGridSteps,
                    notes: store.pianoRollNotes,
                    playheadStep: store.sequencerIsRunning ? store.sequencerPlayheadStep : nil,
                    onGridStepsChange: { store.send(.pianoRollGridStepsChanged($0)) },
                    onStepTap: { row, step in store.send(.pianoRollStepToggled(row: row, step: step)) },
                    onStepsPainted: { row, a, b in
                        store.send(.pianoRollStepsPainted(row: row, startStep: a, endStep: b))
                    },
                    onNoteRemove: { store.send(.pianoRollNoteRemoved($0)) },
                    onNoteResize: { id, start, length in
                        store.send(.pianoRollNoteResized(id: id, startStep: start, length: length))
                    }
                )
                .padding(.horizontal, 8)

                AcidKeyboard(
                    octaveOffset: store.keyboardOctaveOffset,
                    pressedMidiNotes: store.keyboardPressedMidiNotes,
                    onOctaveOffsetChange: { store.send(.keyboardOctaveOffsetChanged($0)) },
                    onNoteOn: { midi, hz in store.send(.keyboardNoteOn(midiNote: midi, frequencyHz: hz)) },
                    onNoteOff: { store.send(.keyboardNoteOff(midiNote: $0)) }
                )
                .padding(.horizontal, 8)

                if let last = store.keyboardLastNoteOn {
                    Text("Último Note On: MIDI \(last.midiNote) · \(String(format: "%.2f", last.frequencyHz)) Hz")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 16) {
                    AcidButton(title: "PLAY", systemImage: "play.fill") {
                        store.send(.demoPlayButtonReleased)
                    }
                    AcidButton(title: "STOP", systemImage: "stop.fill") {
                        store.send(.sequencerStopTapped)
                    }
                    AcidButton(title: "CLEAR", systemImage: "trash") {
                        store.send(.demoClearButtonReleased)
                    }
                    Text(
                        "PLAY \(store.demoPlayButtonReleaseCount) · CLEAR \(store.demoClearButtonReleaseCount)"
                            + (store.sequencerIsRunning ? " · \(Int(store.sequencerBPM)) BPM" : "")
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                }

                HStack(alignment: .center, spacing: 48) {
                    VStack(spacing: 8) {
                        AcidKnob(
                            value: $store.demoKnobValue,
                            label: "CUTOFF"
                        )
                        Text(String(format: "valor: %.3f", store.demoKnobValue))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }

                    AcidToggle(
                        selection: $store.demoToggleSelection,
                        leadingLabel: "SAW",
                        trailingLabel: "SQR"
                    )

                    Text(store.demoToggleSelection == .upper ? "Onda: sierra" : "Onda: cuadrada")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 120, alignment: .leading)
                }

                if let err = store.audioEnginePrepareError {
                    Text("Audio: \(err)")
                        .font(.caption2)
                        .foregroundStyle(.red)
                } else if store.audioEnginePrepared {
                    Text("Motor de audio listo")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else if AudioKitBootstrap.isModuleLinked {
                    Text("Iniciando motor de audio…")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.95, green: 0.85, blue: 0.15).opacity(0.15))
            .task {
                await store.send(.prepareAudioEngine).finish()
            }
        }
    }
}

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
