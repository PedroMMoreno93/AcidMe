import Testing

@testable import AcidMe

@Suite("AcidKeyboardMath")
struct AcidKeyboardMathTests {
    @Test
    func rootMidi_octavaC4() {
        #expect(AcidKeyboardMath.rootMidi(octaveOffset: 0) == 60)
    }

    @Test
    func rootMidi_limitesOctavas() {
        #expect(AcidKeyboardMath.rootMidi(octaveOffset: -3) == 24)
        #expect(AcidKeyboardMath.rootMidi(octaveOffset: 3) == 96)
    }

    @Test
    func rootMidi_clampFueraDeRango() {
        #expect(AcidKeyboardMath.rootMidi(octaveOffset: -99) == 24)
        #expect(AcidKeyboardMath.rootMidi(octaveOffset: 99) == 96)
    }

    @Test
    func frequencyHz_A4() {
        let hz = AcidKeyboardMath.frequencyHz(midiNote: 69)
        #expect(abs(hz - 440.0) < 0.001)
    }

    @Test
    func frequencyHz_C4() {
        let hz = AcidKeyboardMath.frequencyHz(midiNote: 60)
        #expect(abs(hz - 261.6255653005986) < 0.01)
    }

    @Test
    func frequencyHz_clampMidi() {
        let low = AcidKeyboardMath.frequencyHz(midiNote: -5)
        let high = AcidKeyboardMath.frequencyHz(midiNote: 200)
        #expect(low == AcidKeyboardMath.frequencyHz(midiNote: 0))
        #expect(high == AcidKeyboardMath.frequencyHz(midiNote: 127))
    }
}
