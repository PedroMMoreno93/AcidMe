import Foundation
import Testing

@testable import AcidMe

@Suite
struct SynthParamsMathTests {
    @Test
    func lowPassCutoffHz_extremos() {
        let lo = SynthParamsMath.lowPassCutoffHz(normalized01: 0)
        let hi = SynthParamsMath.lowPassCutoffHz(normalized01: 1)
        #expect(lo < hi)
        #expect(lo >= 150)
        #expect(hi <= 14_000)
    }

    @Test
    func lowPassCutoffHz_acotaFueraDeRango() {
        let a = SynthParamsMath.lowPassCutoffHz(normalized01: -1)
        let b = SynthParamsMath.lowPassCutoffHz(normalized01: 2)
        #expect(a == SynthParamsMath.lowPassCutoffHz(normalized01: 0))
        #expect(b == SynthParamsMath.lowPassCutoffHz(normalized01: 1))
    }

    @Test
    func lowPassCutoffHz_extremosNumericosExactos() {
        #expect(SynthParamsMath.lowPassCutoffHz(normalized01: 0) == 150)
        #expect(SynthParamsMath.lowPassCutoffHz(normalized01: 1) == 14_000)
    }

    @Test
    func lowPassCutoffHz_esCrecienteEn01() {
        let steps = stride(from: 0.0, through: 1.0, by: 0.1).map { Double($0) }
        var previous = SynthParamsMath.lowPassCutoffHz(normalized01: steps[0])
        for n in steps.dropFirst() {
            let next = SynthParamsMath.lowPassCutoffHz(normalized01: n)
            #expect(next >= previous)
            previous = next
        }
    }
}
