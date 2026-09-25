import Foundation
#if SWIFT_PACKAGE
@testable import PulseFixCore
#else
@testable import PulseFix
#endif

// بيانات صغيرة مشتركة علشان ما نكررش كتابتها في كل اختبار.
@MainActor
enum SampleData {
    static let chunk = ManualChunk(
        id: "pump-1",
        manualID: UUID(),
        manualName: "Pump.pdf",
        pageNumber: 1,
        section: "Vibration",
        content: "Vibration. Safety prerequisites: isolate power; lockout; verify zero energy; wear PPE."
    )

    static let answer = DiagnosticResult(
        status: .grounded,
        summary: "Check the pump manual.",
        safetyPrerequisites: ["Isolate power"],
        recommendedActions: ["Read the manual"],
        citations: [Citation(sourceID: "pump-1", manualName: "Pump.pdf", pageNumber: 1)],
        workOrder: nil
    )
}

// بديل Gemini: إما يرسل الإجابة الجاهزة، أو يبلغ عن خطأ.
@MainActor
struct MockProvider: DiagnosticProviding {
    var shouldFail = false

    func streamDiagnosis(query: String, evidence: [RetrievedChunk], language: AppLanguage) -> AsyncThrowingStream<StreamEvent, Error> {
        AsyncThrowingStream { stream in
            if shouldFail {
                stream.finish(throwing: PulseFixError.invalidResponse)
            } else {
                stream.yield(.completed(SampleData.answer))
                stream.finish()
            }
        }
    }
}

// AppModel محتاج أداة استيراد عند إنشائه، لكن الاختبارات دي مش بتستورد ملفات.
@MainActor
struct MockIngestor: ManualIngesting {
    func ingest(url: URL) async throws -> (ManualDocument, [ManualChunk]) {
        throw PulseFixError.unsupportedDocument
    }
}
