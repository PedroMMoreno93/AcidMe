import AudioKit
import AVFoundation
import ComposableArchitecture
import Foundation

// MARK: - Motor en vivo (AudioKit)

@MainActor
final class LiveAudioKitEngine {
    static let shared = LiveAudioKitEngine()

    private var engine: AudioEngine?
    private var sawOsc: PlaygroundOscillator?
    private var sqrOsc: PlaygroundOscillator?
    private var lowPass: LowPassFilter?

    private init() {}

    /// Configura la sesión, monta dos osciladores (sierra/cuadrado) → mezcla → LPF y arranca el motor.
    func prepare() throws {
        guard engine == nil else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)

        let saw = PlaygroundOscillator(waveform: Table(.sawtooth), frequency: 110, amplitude: 0)
        let sqr = PlaygroundOscillator(waveform: Table(.square), frequency: 110, amplitude: 0)
        saw.start()
        sqr.start()

        let mixer = Mixer(saw, sqr)
        let filter = LowPassFilter(mixer, cutoffFrequency: 6_900, resonance: 2)
        let eng = AudioEngine()
        eng.output = filter
        try eng.start()

        engine = eng
        sawOsc = saw
        sqrOsc = sqr
        lowPass = filter
    }

    /// Aplica cutoff (knob 0…1) y selección de onda.
    /// El cutoff del `LowPassFilter` (Audio Unit de Apple) suele **no** admitir `NodeParameter.ramp`;
    /// si se llama a `ramp`, no actualiza el valor. Asignación directa al `@Parameter` sí.
    /// `PlaygroundOscillator.amplitude` no es `@Parameter`: solo asignación directa.
    func applyDemoSynthParams(knobNormalized: Double, toggle: AcidToggleSelection) {
        guard let lowPass, let sawOsc, let sqrOsc else { return }

        let hz = AUValue(SynthParamsMath.lowPassCutoffHz(normalized01: knobNormalized))
        lowPass.cutoffFrequency = hz

        let level = DemoSynth.oscLevel
        switch toggle {
        case .upper:
            sawOsc.amplitude = level
            sqrOsc.amplitude = 0
        case .lower:
            sawOsc.amplitude = 0
            sqrOsc.amplitude = level
        }
    }

    /// Ajusta la frecuencia de ambos osciladores al paso del secuenciador (suena el que tenga amplitud > 0).
    func triggerSequencerNote(midiNote _: Int, frequencyHz: Double) {
        guard let sawOsc, let sqrOsc else { return }
        let f = Float(frequencyHz)
        sawOsc.frequency = f
        sqrOsc.frequency = f
    }
}

private enum DemoSynth {
    static let oscLevel: AUValue = 0.03
}

// MARK: - Dependencia TCA

struct AudioClient: Sendable {
    var prepare: @Sendable () async throws -> Void
    var applyDemoSynthParams: @Sendable (Double, AcidToggleSelection) async -> Void
    var triggerSequencerNote: @Sendable (Int, Double) async -> Void
}

extension AudioClient: DependencyKey {
    static let liveValue = AudioClient(
        prepare: {
            try await LiveAudioKitEngine.shared.prepare()
        },
        applyDemoSynthParams: { knob, toggle in
            await LiveAudioKitEngine.shared.applyDemoSynthParams(knobNormalized: knob, toggle: toggle)
        },
        triggerSequencerNote: { midi, hz in
            await LiveAudioKitEngine.shared.triggerSequencerNote(midiNote: midi, frequencyHz: hz)
        }
    )

    static let testValue = AudioClient(
        prepare: {},
        applyDemoSynthParams: { _, _ in },
        triggerSequencerNote: { _, _ in }
    )
}

extension DependencyValues {
    var audioClient: AudioClient {
        get { self[AudioClient.self] }
        set { self[AudioClient.self] = newValue }
    }
}
