import Testing

@testable import AcidMe

@Suite("AcidKnobMath")
struct AcidKnobMathTests {
    @Test func clampMantieneRango() {
        #expect(AcidKnobMath.clamp(-0.5) == 0)
        #expect(AcidKnobMath.clamp(0) == 0)
        #expect(AcidKnobMath.clamp(0.5) == 0.5)
        #expect(AcidKnobMath.clamp(1) == 1)
        #expect(AcidKnobMath.clamp(1.25) == 1)
    }

    @Test func dragHaciaArribaAumentaValor() {
        let next = AcidKnobMath.valueAfterVerticalDrag(
            origin: 0.5,
            translationHeight: -100,
            pixelsForFullRange: 200
        )
        #expect(next == 1.0)
    }

    @Test func dragHaciaAbajoDisminuyeValor() {
        let next = AcidKnobMath.valueAfterVerticalDrag(
            origin: 0.5,
            translationHeight: 100,
            pixelsForFullRange: 200
        )
        #expect(next == 0)
    }

    @Test func indicadorExtremos() {
        #expect(AcidKnobMath.indicatorDegrees(value: 0) == -135)
        #expect(AcidKnobMath.indicatorDegrees(value: 1) == 135)
    }
}
