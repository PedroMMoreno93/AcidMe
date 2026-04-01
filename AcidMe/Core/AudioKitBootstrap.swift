import AudioKit
import Foundation

/// Garantiza enlace del módulo AudioKit (SPM) sin arrancar motor de audio en el arranque.
enum AudioKitBootstrap {
    static var isModuleLinked: Bool {
        _ = AudioEngine.self
        return true
    }
}
