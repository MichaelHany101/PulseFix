import Testing
#if SWIFT_PACKAGE
@testable import PulseFixCore
#else
@testable import PulseFix
#endif

@MainActor
struct AppModelTests {
    @Test func showsMockAnswer() async {
        // جهز مدير التطبيق بخدمات تجريبية، من غير Gemini الحقيقي.
        let app = AppModel(ingestor: MockIngestor(), retriever: LexicalChunkRetriever(), provider: MockProvider())
        app.chunks = [SampleData.chunk]
        app.query = "vibration"

        // شغل التشخيص.
        await app.diagnose()

        // المفروض الإجابة التجريبية تظهر والانتظار يخلص.
        #expect(app.diagnosis?.summary == "Check the pump manual.")
        #expect(app.isRunning == false)
    }

    @Test func showsErrorWhenProviderFails() async {
        // المرة دي بنطلب من البديل التجريبي يرجع خطأ.
        let app = AppModel(ingestor: MockIngestor(), retriever: LexicalChunkRetriever(), provider: MockProvider(shouldFail: true))
        app.chunks = [SampleData.chunk]
        app.query = "vibration"

        await app.diagnose()

        #expect(app.errorMessage == "Gemini returned an invalid response.")
        #expect(app.diagnosis == nil)
        #expect(app.isRunning == false)
    }
}
