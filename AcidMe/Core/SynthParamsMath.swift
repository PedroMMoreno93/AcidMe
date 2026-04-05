import Foundation

/// Mapeos de parámetros de síntesis (HU 7) desacoplados de AudioKit.
enum SynthParamsMath {
    /// Mapea 0…1 a frecuencia de corte (Hz) con progresión logarítmica.
    static func lowPassCutoffHz(normalized01: Double) -> Float {
        let n = min(1, max(0, normalized01))
        let minHz: Float = 150
        let maxHz: Float = 14_000
        return minHz * pow(maxHz / minHz, Float(n))
    }
}
