import AudioKit
import AVFoundation
import ComposableArchitecture
import Foundation

// MARK: - Motor en vivo (AudioKit)

@MainActor
final class LiveAudioKitEngine {
    static let shared = LiveAudioKitEngine()

    private var engine: AudioEngine?

    private init() {}

    /// Configura la sesión de audio, crea un grafo mínimo (oscilador en silencio) y arranca el motor.
    func prepare() throws {
        guard engine == nil else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)

        let oscillator = PlaygroundOscillator(waveform: Table(.sine), frequency: 440, amplitude: 0)
        let eng = AudioEngine()
        eng.output = oscillator
        try eng.start()
        engine = eng
    }
}

// MARK: - Dependencia TCA

struct AudioClient: Sendable {
    var prepare: @Sendable () async throws -> Void
}

extension AudioClient: DependencyKey {
    static let liveValue = AudioClient(
        prepare: {
            try await LiveAudioKitEngine.shared.prepare()
        }
    )

    static let testValue = AudioClient(prepare: {})
}

extension DependencyValues {
    var audioClient: AudioClient {
        get { self[AudioClient.self] }
        set { self[AudioClient.self] = newValue }
    }
}
