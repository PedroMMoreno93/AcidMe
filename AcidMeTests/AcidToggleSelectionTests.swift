import Testing

@testable import AcidMe

@Suite("AcidToggleSelection")
struct AcidToggleSelectionTests {
    @Test func toggledAlterna() {
        #expect(AcidToggleSelection.toggled(.upper) == .lower)
        #expect(AcidToggleSelection.toggled(.lower) == .upper)
    }

    @Test func toggleMutating() {
        var s = AcidToggleSelection.upper
        s.toggle()
        #expect(s == .lower)
        s.toggle()
        #expect(s == .upper)
    }
}
