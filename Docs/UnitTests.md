# Simple unit tests

Six beginner-friendly tests cover the assessment's three requested areas:

- `PulseFixTests/PulseFixTests.swift`: no evidence fails the safety check; refusal has no work order or actions.
- `PulseFixTests/LocalRetrieverTests.swift`: Arabic vibration query finds English text; an unrelated question returns nothing.
- `PulseFixTests/AppModelTests.swift`: shows a fixed mock answer; handles a mock provider error.
- `PulseFixTests/TestDoubles.swift`: one sample chunk, one sample answer, a success/failure provider, and an unused ingestion stub.

Each test follows **Arrange → Act → Assert**, with Egyptian Arabic comments. The advanced fixtures, recording repository, delayed streams, parameterized cases and concurrency scenarios were removed to keep this learning version small. Coverage is intentionally narrower than the original suite.

## Run

Requires Xcode 26 / Swift 6.2+:

```sh
swift test
```

Run from the repository root. No API key or network is required. Open `Package.swift` in Xcode and choose its package scheme and **My Mac**, then **Product → Test**, as an alternative.

`Package.swift` points to the existing `PulseFixTests` directory. Conditional imports let the same test files use `PulseFixCore` under SwiftPM and `PulseFix` under the existing iOS test target. That Xcode target was preserved; its simulator execution has not been verified in this restricted session.

The tests compile the original application logic. They do not test rendered UI, PDFKit, SwiftData, live Gemini or all safety edge cases. The AppModel tests use the real local retriever with small sample data and a mock provider.

GitHub Actions still runs `swift test`. Hosted results require pushing and running the workflow.

## Local result

2026-09-25: all **6 tests in 3 suites passed** on macOS using Swift 6.2. Application source was unchanged.
