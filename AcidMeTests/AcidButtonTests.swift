import Testing

@testable import AcidMe

@Suite("AcidButtonStyleMath")
struct AcidButtonStyleMathTests {
    @Test
    func metalPromedioMasOscuroCuandoEstaPulsado() {
        let up = AcidButtonStyleMath.averageMetalLuminance(pressed: false)
        let down = AcidButtonStyleMath.averageMetalLuminance(pressed: true)
        #expect(down < up)
    }

    @Test
    func etiquetaEsMasLuminosaQueElMetal_sinPulsar() {
        #expect(AcidButtonStyleMath.labelIsBrighterThanMetal(pressed: false))
    }

    @Test
    func etiquetaEsMasLuminosaQueElMetal_pulsado() {
        #expect(AcidButtonStyleMath.labelIsBrighterThanMetal(pressed: true))
    }

    @Test
    func luminanciaMediaEtiquetaEsAlta() {
        #expect(AcidButtonStyleMath.averageLabelLuminance() > 0.88)
    }
}
