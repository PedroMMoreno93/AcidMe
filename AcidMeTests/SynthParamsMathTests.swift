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
}
