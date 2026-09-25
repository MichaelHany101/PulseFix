import Testing
#if SWIFT_PACKAGE
@testable import PulseFixCore
#else
@testable import PulseFix
#endif

@MainActor
struct LocalRetrieverTests {
    @Test func findsMatchingText() async {
        // جهز الباحث ومقطع مكتوب فيه اهتزاز بالإنجليزي.
        let search = LexicalChunkRetriever()
        let chunk = SampleData.chunk

        // اسأل بالعربي.
        let results = await search.retrieve(query: "اهتزاز", from: [chunk], limit: 5)

        // المفروض يرجع نفس المقطع.
        #expect(results.count == 1)
        #expect(results.first?.chunk.id == chunk.id)
    }

    @Test func unrelatedQuestionReturnsNothing() async {
        let search = LexicalChunkRetriever()

        // الكلمة دي مش موجودة في المقطع.
        let results = await search.retrieve(query: "banana", from: [SampleData.chunk], limit: 5)

        #expect(results.isEmpty)
    }
}
