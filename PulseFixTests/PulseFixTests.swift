import Testing
#if SWIFT_PACKAGE
@testable import PulseFixCore
#else
@testable import PulseFix
#endif

@MainActor
struct DiagnosisUseCaseTests {
    @Test func noEvidenceMeansNoSafety() {
        // مفيش أدلة: المفروض فحص السلامة يرفض.
        let result = DiagnosisUseCase.hasSafetyPrerequisites([])
        #expect(result == false)
    }

    @Test func refusalHasNoWorkOrder() {
        // جهز رفض بسبب نقص المعلومات.
        let result = DiagnosisUseCase.refusal(.insufficientEvidence, language: .english)

        // الرفض ما ينفعش يكون معاه أمر عمل.
        #expect(result.workOrder == nil)
        #expect(result.recommendedActions.isEmpty)
    }
}
