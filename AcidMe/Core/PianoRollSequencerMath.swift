import Foundation

/// Secuenciador paso a paso alineado con el piano roll y el teclado (HU 8).
enum PianoRollSequencerMath {
    /// Duración de un paso en segundos: un compás (4 pulsos) repartido en `stepCount` pasos.
    static func secondsPerStep(bpm: Double, stepCount: Int) -> Double {
        let beatsPerBar = 4.0
        let clampedBpm = min(220, max(40, bpm))
        let steps = max(1, stepCount)
        return (60.0 / clampedBpm) * beatsPerBar / Double(steps)
    }

    /// Fila del roll (0 = arriba B, 11 = abajo C) → MIDI con la misma raíz que el teclado.
    static func midiForRow(_ row: Int, keyboardOctaveOffset: Int) -> Int {
        guard row >= 0, row < PianoRollGridMath.rowCount else { return 60 }
        let fromBottom = PianoRollGridMath.rowCount - 1 - row
        let root = AcidKeyboardMath.rootMidi(octaveOffset: keyboardOctaveOffset)
        return min(127, max(0, root + fromBottom))
    }

    /// Notas con ataque en `step` (inicio de nota en ese paso).
    static func notesStarting(atStep step: Int, in notes: [PianoRollNote]) -> [PianoRollNote] {
        notes.filter { $0.startStep == step }
    }
}
