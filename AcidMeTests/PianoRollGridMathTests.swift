import Foundation
import Testing

@testable import AcidMe

@Suite("PianoRollGridMath")
struct PianoRollGridMathTests {
    @Test
    func filasYResolucion() {
        #expect(PianoRollGridMath.rowCount == 12)
        #expect(PianoRollGridMath.stepsPerBar == 16)
        #expect(PianoRollGridMath.allowedGridSteps == [4, 8, 16])
        #expect(PianoRollGridMath.normalizedGridSteps(16) == 16)
        #expect(PianoRollGridMath.normalizedGridSteps(8) == 8)
        #expect(PianoRollGridMath.normalizedGridSteps(4) == 4)
        #expect(PianoRollGridMath.normalizedGridSteps(0) == 4)
        #expect(PianoRollGridMath.normalizedGridSteps(6) == 8)
        #expect(PianoRollGridMath.normalizedGridSteps(20) == 16)
    }

    @Test
    func isValidPaso() {
        #expect(PianoRollGridMath.isValid(row: 0, step: 0, stepCount: 16))
        #expect(PianoRollGridMath.isValid(row: 11, step: 15, stepCount: 16))
        #expect(!PianoRollGridMath.isValid(row: 12, step: 0, stepCount: 16))
        #expect(!PianoRollGridMath.isValid(row: 0, step: 16, stepCount: 16))
    }

    @Test
    func togglingStep_anadeYQuitaNotaDeUnPaso() {
        var notes: [PianoRollNote] = []
        notes = PianoRollGridMath.togglingStep(notes: notes, row: 3, step: 7, stepCount: 16)
        #expect(notes.count == 1)
        #expect(notes[0].row == 3)
        #expect(notes[0].startStep == 7)
        #expect(notes[0].lengthSteps == 1)
        notes = PianoRollGridMath.togglingStep(notes: notes, row: 3, step: 7, stepCount: 16)
        #expect(notes.isEmpty)
    }

    @Test
    func togglingStep_fueraDeRangoNoCambia() {
        let notes: [PianoRollNote] = []
        #expect(
            PianoRollGridMath.togglingStep(notes: notes, row: -1, step: 0, stepCount: 16) == notes
        )
        #expect(
            PianoRollGridMath.togglingStep(notes: notes, row: 0, step: 99, stepCount: 16) == notes
        )
    }

    @Test
    func strideStepDelta_simetricoIzquierdaYDerecha() {
        let stride: CGFloat = 30
        #expect(PianoRollGridMath.strideStepDelta(translationWidth: 31, stride: stride) == 1)
        #expect(PianoRollGridMath.strideStepDelta(translationWidth: -31, stride: stride) == -1)
        #expect(PianoRollGridMath.strideStepDelta(translationWidth: -62, stride: stride) == -2)
        #expect(PianoRollGridMath.strideStepDelta(translationWidth: 5, stride: stride) == 0)
        #expect(PianoRollGridMath.strideStepDelta(translationWidth: -5, stride: stride) == 0)
    }

    @Test
    func paintSteps_creaRango() {
        let notes: [PianoRollNote] = []
        let out = PianoRollGridMath.paintSteps(
            notes: notes,
            row: 2,
            fromStep: 7,
            toStep: 3,
            stepCount: 16
        )
        #expect(out.count == 1)
        #expect(out[0].row == 2)
        #expect(out[0].startStep == 3)
        #expect(out[0].lengthSteps == 5)
    }

    @Test
    func resizingNote_cambiaLongitud() {
        let id = UUID()
        let notes = [PianoRollNote(id: id, row: 0, startStep: 0, lengthSteps: 1)]
        let out = PianoRollGridMath.resizingNote(notes: notes, id: id, newLength: 4, stepCount: 16)
        #expect(out.count == 1)
        #expect(out[0].lengthSteps == 4)
        #expect(out[0].startStep == 0)
    }

    @Test
    func clampedLeadingResize_extiendeHaciaLaIzquierda() {
        let id = UUID()
        let row: [PianoRollNote] = []
        let pair = PianoRollGridMath.clampedLeadingResize(
            initialStart: 6,
            initialLength: 2,
            deltaSteps: -2,
            noteId: id,
            notesOnRow: row,
            stepCount: 16
        )
        #expect(pair.start == 4)
        #expect(pair.length == 4)
    }

    @Test
    func applyNoteSpan_mueveInicio() {
        let id = UUID()
        let notes = [PianoRollNote(id: id, row: 0, startStep: 6, lengthSteps: 2)]
        let out = PianoRollGridMath.applyNoteSpan(
            notes: notes,
            id: id,
            newStart: 4,
            newLength: 4,
            stepCount: 16
        )
        #expect(out.count == 1)
        #expect(out[0].startStep == 4)
        #expect(out[0].lengthSteps == 4)
    }

    @Test
    func clampedNotes_eliminaNotasFueraDeRango() {
        let id = UUID()
        let notes = [PianoRollNote(id: id, row: 0, startStep: 20, lengthSteps: 1)]
        let clipped = PianoRollGridMath.clampedNotes(notes, stepCount: 16)
        #expect(clipped.isEmpty)
    }

    @Test
    func clampedNotes_recortaLongitudAlFinalDeRejilla() {
        let id = UUID()
        let notes = [PianoRollNote(id: id, row: 0, startStep: 10, lengthSteps: 20)]
        let clipped = PianoRollGridMath.clampedNotes(notes, stepCount: 16)
        #expect(clipped.count == 1)
        #expect(clipped[0].lengthSteps == 6)
    }

    @Test
    func noteLabel_filaInferiorEsDo() {
        #expect(PianoRollGridMath.noteLabel(forRow: 11) == "C")
        #expect(PianoRollGridMath.noteLabel(forRow: 0) == "B")
    }
}
