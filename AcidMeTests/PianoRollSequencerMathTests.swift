import Foundation
import Testing

@testable import AcidMe

@Suite
struct PianoRollSequencerMathTests {
    @Test
    func secondsPerStep_bpm120_16pasos() {
        let s = PianoRollSequencerMath.secondsPerStep(bpm: 120, stepCount: 16)
        #expect(abs(s - 0.125) < 0.0001)
    }

    @Test
    func secondsPerStep_acotaBPM() {
        let low = PianoRollSequencerMath.secondsPerStep(bpm: 10, stepCount: 16)
        let high = PianoRollSequencerMath.secondsPerStep(bpm: 400, stepCount: 16)
        let ref40 = PianoRollSequencerMath.secondsPerStep(bpm: 40, stepCount: 16)
        let ref220 = PianoRollSequencerMath.secondsPerStep(bpm: 220, stepCount: 16)
        #expect(low == ref40)
        #expect(high == ref220)
    }

    @Test
    func midiForRow_alineadoConTecladoOctava0() {
        let bottom = PianoRollSequencerMath.midiForRow(11, keyboardOctaveOffset: 0)
        #expect(bottom == AcidKeyboardMath.rootMidi(octaveOffset: 0))
        let top = PianoRollSequencerMath.midiForRow(0, keyboardOctaveOffset: 0)
        #expect(top == AcidKeyboardMath.rootMidi(octaveOffset: 0) + 11)
    }

    @Test
    func notesStarting_filtraPorPaso() {
        let notes = [
            PianoRollNote(id: UUID(), row: 0, startStep: 0, lengthSteps: 1),
            PianoRollNote(id: UUID(), row: 1, startStep: 3, lengthSteps: 2)
        ]
        let a = PianoRollSequencerMath.notesStarting(atStep: 0, in: notes)
        #expect(a.count == 1)
        #expect(a[0].row == 0)
        let b = PianoRollSequencerMath.notesStarting(atStep: 3, in: notes)
        #expect(b.count == 1)
        #expect(b[0].row == 1)
        #expect(PianoRollSequencerMath.notesStarting(atStep: 1, in: notes).isEmpty)
    }
}
